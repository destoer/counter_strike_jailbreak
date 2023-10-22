#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include "lib.inc"
#include "specialday/specialday.inc"


#include "jailbreak/jailbreak.inc"


// need to supply models + audio if these are uncommented
//#define USE_CUSTOM_ZOMBIE_MODEL
//#define CUSTOM_ZOMBIE_MUSIC


#define VERSION "2.9 - Violent Intent Jailbreak"

public Plugin myinfo = {
	name = "Jailbreak Special Days",
	author = "destoer(organ harvester)",
	description = "special days for jailbreak",
	version = VERSION,
	url = "https://github.com/destoer/css_jailbreak_plugins"
};

// todo
// shotgun wars
// human only fog on zombies


// override duration of zombie sd


#define SD_ADMIN_FLAG ADMFLAG_UNBAN

#define FREEZE_COMMANDS


#undef REQUIRE_PLUGIN
#include "thirdparty/ctban.inc"
#define REQUIRE_PLUGIN


#undef REQUIRE_PLUGIN
ConVar store_kill_ammount_cvar;
int store_kill_ammount_backup = 0;
#include "thirdparty/store.inc"
#define REQUIRE_PLUGIN

// gun menu
Menu gun_menu;

// Handle for function call
Handle SetCollisionGroup;


const int SD_SIZE = 15;
new const String:sd_list[SD_SIZE][] =
{	
	"Friendly Fire Day", 
	"Tank Day",
	"Friendly Fire Juggernaut Day",
	"Sky Wars",
	"Hide and Seek",
	"Dodgeball",
	"Grenade",
	"Zombie",
	"Gun Game",
	"Knife",
	"Scout Knives",
	"Death Match",
	"Laser Wars",
	"Spectre",
	"Headshot",
	//"VIP",
};



void callback_dummy()
{

}


typedef SD_INIT_FUNC = function void (int client);

typedef SD_STATE_FUNC = function void();

//typedef SD_

// for some reason we cannot just init these with an initalizer
// so we do it in a func...
SD_STATE_FUNC end_fptr[SD_SIZE];
SD_STATE_FUNC start_fptr[SD_SIZE];
SD_STATE_FUNC init_fptr[SD_SIZE];


// sd modifiers

// underlying convar handles
Handle g_hFriendlyFire; // mp_friendlyfire var
Handle g_autokick; // turn auto kick off for friednly fire
Handle g_ignore_round_win; 

int fog_ent;

#define SD_DELAY 15


// team saves
int validclients = 0; // number of clients able to partake in sd
int game_clients[MAXPLAYERS+1];
int teams[MAXPLAYERS+1]; // should store in a C struct but cant

enum struct Context
{
	// are sd's active and if so which one
	SpecialDay special_day;
	SdState sd_state;

	// function pointer set to tell us how to handle initilaze players on sds
	// set back to invalid on endsd to make sure we set it properly for each sd
	SD_INIT_FUNC player_init;

	bool sd_init_failure;

	// how long till sd starts?
	int sd_timer;
	
	// what gun is only allowed
	// NOTE: we still switch for sds with more complicated logic
	char weapon_restrict[20];

	// how long does sd last
	int round_delay_timer;
	bool ignore_round_end;

	bool fr; // are people frozen
	bool ff; // is friendly fire on?

	bool no_damage; // damage disable
	bool hp_steal; // gain hp from kills

	// boss in sd, e.g patient zero, laser, tank, spectre etc
	int boss;
	int rigged_client;

	// warden sd
	int warden_sd_available;
	int rounds_since_warden_sd;
	bool wsd_ff;

	int sd_winner;
}

enum struct Player
{
	int kills;

	float death_cords[3];

	// gun game level
	int gungame_level;
}

Player players[MAXPLAYERS+1];
Context global_ctx;

const int INVALID_BOSS = -1;

void reset_context()
{
	global_ctx.special_day = normal_day;
	global_ctx.sd_state = sd_inactive;

	global_ctx.sd_timer = SD_DELAY;

	global_ctx.sd_init_failure = false;

	global_ctx.player_init = sd_player_init_invalid;

	global_ctx.round_delay_timer = 0;
	global_ctx.ignore_round_end = false;

	global_ctx.fr = false;
	global_ctx.ff = false;
	global_ctx.no_damage = false;
	global_ctx.hp_steal = false;

	global_ctx.boss = INVALID_BOSS;
	global_ctx.rigged_client = INVALID_BOSS;
	global_ctx.wsd_ff = false;

	global_ctx.weapon_restrict = "";

	// dont init warden sd rounds

	global_ctx.ignore_round_end = false;

	global_ctx.sd_winner = -1;
}

void reset_player(int client)
{
	players[client].kills = 0;
	players[client].gungame_level = 0;

	for(int i = 0; i < 3; i++)
	{
		players[client].death_cords[i] = 0.0;
	}
}

// backups
// (unused)
//new b_hFriendlyFire; // mp_friendlyfire var
//new b_autokick; // turn auto kick off for friednly fire

// gun removal
int g_WeaponParent;

// csgo ff
ConVar convar_mp_teammates_are_enemies;
bool mp_teammates_are_enemies;

// laser sprites
int g_lbeam;
int g_lpoint;

// split files for sd
#include "specialday/config.sp"
#include "specialday/ffd.sp"
#include "specialday/tank.sp"
#include "specialday/ffdg.sp"
#include "specialday/skywars.sp"
#include "specialday/hide.sp"
#include "specialday/dodgeball.sp"
#include "specialday/grenade.sp"
#include "specialday/zombie.sp"
#include "specialday/gungame.sp"
#include "specialday/knife.sp"
#include "specialday/scoutknifes.sp"
#include "specialday/deathmatch.sp"
#include "specialday/laserwars.sp"
#include "specialday/spectre.sp"
#include "specialday/headshot.sp"
//#include "specialday/vip.sp"
#include "specialday/debug.sp"
//#include "specialday/spawn.sp"
#include "specialday/hook.sp"

// we can then just call this rather than having to switch on the sds in many places
void sd_player_init(int client)
{
	if(global_ctx.sd_state != sd_inactive && IsClientConnected(client) && IsClientInGame(client) && is_on_team(client))
	{
		Call_StartFunction(null, global_ctx.player_init);
		Call_PushCell(client);
		Call_Finish();
	}
}

// no valid pointer set 
// (lets us know if we forget to set one)
void sd_player_init_invalid(int client)
{
	ThrowNativeError(SP_ERROR_NATIVE, "invalid sd_init function %d:%d:%d\n", client, global_ctx.sd_state, global_ctx.special_day);
}


public start_round_delay(int seconds)
{
	global_ctx.round_delay_timer = seconds;
	CreateTimer(1.0,round_delay_tick);
	disable_round_end();
}

public Action round_delay_tick(Handle Timer)
{
	if(global_ctx.round_delay_timer > 0)
	{
		global_ctx.round_delay_timer -= 1;
		CreateTimer(1.0,round_delay_tick);
	}
	
	else
	{
		if(global_ctx.sd_state == sd_active)
		{
			enable_round_end();
			slay_all();
		}
		
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if(is_valid_client(i))
				{
					PrintToConsole(i,"[DEBUG] Warning attempted to slay for inactive sd. was there a cancel?");
				}
			}
		}
	}

	return Plugin_Continue;
}

void pick_boss()
{
	if(global_ctx.rigged_client == INVALID_BOSS)
	{
		while(!is_valid_client(global_ctx.boss))
		{
			int rand = GetRandomInt( 0, (validclients-1) );
			
			// select the first zombie
			global_ctx.boss = game_clients[rand];
		} 
	}

	else
	{
		global_ctx.boss = global_ctx.rigged_client;
	}	
}

void pick_boss_discon(int client)
{
	// while the current disconnecter
	while(global_ctx.boss == client && !is_valid_client(global_ctx.boss))
	{
		int rand = GetRandomInt( 0, (validclients-1) );
		global_ctx.boss = game_clients[rand]; // select the lucky client
	}	
}

void enable_friendly_fire()
{
	global_ctx.ff = true;
	SetConVarBool(g_hFriendlyFire, true); 

	if(GetEngineVersion() == Engine_CSGO)
	{
		SetConVarBool(convar_mp_teammates_are_enemies,true);
	}

}

void disable_friendly_fire()
{
	global_ctx.ff = false;
	SetConVarBool(g_hFriendlyFire, false); 	

	if(GetEngineVersion() == Engine_CSGO)
	{
		SetConVarBool(convar_mp_teammates_are_enemies,mp_teammates_are_enemies);
	}

}

void disable_round_end()
{
	// if we have a "indefinite" game
	// do not award credits for kills
	if(store && store_kill_ammount_cvar != null)
	{
		SetConVarInt(store_kill_ammount_cvar, 0); 
	}
	
	global_ctx.ignore_round_end = true;
	SetConVarBool(g_ignore_round_win, true);
}

void enable_round_end()
{
	global_ctx.ignore_round_end = false;
	SetConVarBool(g_ignore_round_win, false);
}

public int native_sd_state(Handle plugin, int numParam)
{
	return view_as<int>(global_ctx.sd_state);
}

public int native_current_day(Handle plugin, int numParam)
{
	return view_as<int>(global_ctx.special_day);
}


// register our call
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(!store)
	{
		MarkNativeAsOptional("Store_GetClientCredits");
		MarkNativeAsOptional("Store_SetClientCredits");
	}

	if(ct_ban)
	{
		MarkNativeAsOptional("CTBan_IsClientBanned");
	}

	MarkNativeAsOptional("get_warden_id");
	MarkNativeAsOptional("remove_warden");

	CreateNative("sd_current_state", native_sd_state);
	CreateNative("sd_current_day", native_current_day);
	return APLRes_Success;
}

public OnPluginStart() 
{
	create_sd_convar();
	setup_sd_convar();


	SetCollisionGroup = init_set_collision();
	
		
	
	
	HookEvent("player_death", OnPlayerDeath,EventHookMode_Post);
	HookEvent("player_hurt", OnPlayerHurt); 

	// warden trigger random sd
	if(!standalone)
	{
		RegConsoleCmd("wsd", command_warden_special_day);
		RegConsoleCmd("wsd_ff",command_warden_special_day_ff);
	}

	// register our special day console command	
	RegAdminCmd("sd", command_special_day, SD_ADMIN_FLAG);
	RegAdminCmd("sd_ff", command_ff_special_day, SD_ADMIN_FLAG);
	RegAdminCmd("sd_cancel", command_cancel_special_day, SD_ADMIN_FLAG);
	
	if(freeze)
	{
		// freeze stuff
		RegAdminCmd("fr", Freeze,ADMFLAG_BAN);
		RegAdminCmd("uf",UnFreeze,ADMFLAG_BAN);
	}

	RegConsoleCmd("sdspawn", sd_spawn); // spawn during zombie if late joiner
	RegConsoleCmd("sd_spawn", sd_spawn);
	RegConsoleCmd("sd_list", sd_list_callback); // list sds
	
	RegConsoleCmd("sm_samira", samira_EE);

	// gun removal
	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

	
	// hook disonnect incase a vital member leaves
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);

	EngineVersion game = GetEngineVersion();

	g_hFriendlyFire = FindConVar("mp_friendlyfire"); // get the friendly fire var
	if(game == Engine_CSGO)
	{
		convar_mp_teammates_are_enemies = FindConVar("mp_teammates_are_enemies");
		mp_teammates_are_enemies = GetConVarBool(convar_mp_teammates_are_enemies);
	}
	// note on csgo this will prevent it when one team dies
	// but not both!
	g_ignore_round_win = FindConVar("mp_ignore_round_win_conditions");
	g_autokick = FindConVar("mp_autokick");
	SetConVarBool(g_autokick, false);	

	// should really save the defaults but ehhh
	//b_autokick = GetConVarBool(g_autokick);
	//b_hFriendlyFire = GetConVarBool(g_hFriendlyFire);
	
	HookEvent("round_start", OnRoundStart); // reset variables after a sd
	HookEvent("round_end", OnRoundEnd);
	
	RegConsoleCmd("sd_info", sd_info_cmd);
	RegAdminCmd("enable_wsd",enable_wsd,ADMFLAG_CUSTOM6);
	RegAdminCmd("rig", rig_client,ADMFLAG_CUSTOM6);
	
	if(standalone)
	{
		RegConsoleCmd("guns", weapon_menu);
	}

	for(int i = 1; i <= MaxClients;i++)
	{
		if(is_valid_client(i))
		{
			OnClientPutInServer(i);
		}
	}
	
	//set our initial function pointer
	global_ctx.player_init = sd_player_init_invalid;
	
	// timer for printing current sd info
	CreateTimer(1.0, print_specialday_text_all, _, TIMER_REPEAT);
	CreateTimer(0.1, check_movement, _, TIMER_REPEAT);
	
	
	
	// init gun game list
	for (int i = 0; i < GUNS_SIZE; i++)
	{
		gungame_gun_idx[i] = i;
	}

	init_function_pointers();
	
	reset_context();
}

public Action weapon_menu(int client, int args)
{
	if(global_ctx.sd_state == sd_inactive)
	{
		return Plugin_Continue;
	}

	if(IsClientConnected(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		gun_menu.Display(client,20);
	}

	return Plugin_Continue;
}



public void panic_unimplemented()
{
	ThrowNativeError(SP_ERROR_NATIVE, "did not initalize sd %d\n",view_as<int>(global_ctx.special_day));
}

// just sourcemod things
public void init_function_pointers()
{

	// incase we forget to init a ptr
	for(int i = 0; i < SD_SIZE; i++)
	{
		end_fptr[i] = panic_unimplemented;
		start_fptr[i] = panic_unimplemented;
		init_fptr[i] = panic_unimplemented;
	}

	for(int i = 0; i < SD_SIZE; i++)
	{
		SpecialDay day = view_as<SpecialDay>(i);

		switch(day)
		{
			case friendly_fire_day:
			{
				end_fptr[i] = end_ffd;
				start_fptr[i] = StartFFD;
				init_fptr[i] = init_ffd;
			}

			case tank_day:
			{
				end_fptr[i] = end_tank;
				start_fptr[i] = StartTank;
				init_fptr[i] = init_tank;
			}

			case juggernaut_day:
			{
				end_fptr[i] = end_juggernaut;
				start_fptr[i] = StartJuggernaut;
				init_fptr[i] = init_ffdg;
			}

			case fly_day:
			{
				end_fptr[i] = callback_dummy;
				start_fptr[i] = StartFly;
				init_fptr[i] = init_skywars;
			}

			case hide_day:
			{
				end_fptr[i] = callback_dummy;
				start_fptr[i] = StartHide;
				init_fptr[i] = init_hide;
			}

			case dodgeball_day:
			{
				end_fptr[i] = callback_dummy;
				start_fptr[i] = StartDodgeball;
				init_fptr[i] = dodgeball_init;
			}

			case grenade_day:
			{
				end_fptr[i] = callback_dummy;
				start_fptr[i] = StartGrenade;
				init_fptr[i] = grenade_init;
			}

			case zombie_day:
			{
				end_fptr[i] = end_zombie;
				start_fptr[i] = StartZombie;
				init_fptr[i] = init_zombie;
			}

			case gungame_day:
			{
				end_fptr[i] = end_gungame;
				start_fptr[i] = StartGunGame;
				init_fptr[i] = init_gungame;
			}

			case knife_day:
			{
				end_fptr[i] = callback_dummy;
				start_fptr[i] = StartKnife;
				init_fptr[i] = knife_init;
			}

			case scoutknife_day:
			{
				end_fptr[i] = end_scout;
				start_fptr[i] = StartScout;
				init_fptr[i] = scoutknife_init;
			}

			case deathmatch_day:
			{
				end_fptr[i] = end_deathmatch;
				start_fptr[i] = StartDeathMatch;
				init_fptr[i] = deathmatch_init;
			}
		
			case laser_day:
			{
				end_fptr[i] = end_laser;
				start_fptr[i] = StartLaser;
				init_fptr[i] = laser_init;
			}
		

			case spectre_day:
			{
				end_fptr[i] = end_spectre;
				start_fptr[i] = StartSpectre;
				init_fptr[i] = spectre_init;
			}

			case headshot_day:
			{
				end_fptr[i] = callback_dummy;
				start_fptr[i] = StartHeadshot;
				init_fptr[i] = headshot_init;
			}
/*
			case vip_day:
			{
				end_fptr[i] = callback_dummy;
				start_fptr[i] = StartVip;
				init_fptr[i] = vip_init;				
			}
*/
			default:
			{
				ThrowNativeError(SP_ERROR_NATIVE, "did not initalize sd %d", i);				
			}
		}
	}
}


public Action WeaponMenu(int client)
{
	gun_menu.Display(client, 20);

	return Plugin_Continue;
}

public Action sd_spawn(int client, int args)
{
	// sd not active so we dont care
	// or player alive so dont care
	if(global_ctx.sd_state == sd_inactive || IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}	

	// invalid or not on a real team
	if (!is_valid_client(client) || !is_on_team(client))
	{	
		return Plugin_Continue; 
    }	
	
	// less than 20 seconds set them up
	if(global_ctx.sd_state == sd_started)
	{
		CS_RespawnPlayer(client);
		sd_player_init(client);
	}
	
	// sd is running (20 secs in cant join) for most sds
	else if(global_ctx.sd_state == sd_active)
	{
		
		switch(global_ctx.special_day)
		{
			case zombie_day:
			{
				CreateTimer(3.0, ReviveZombie, client);
			}
			
			case gungame_day:
			{
				CreateTimer(3.0, ReviveGunGame, client);
			}
			
			case deathmatch_day:
			{
				CreateTimer(3.0, ReviveDeathMatch, client);
			}
			
			case scoutknife_day:
			{
				CreateTimer(3.0, ReviveScout, client);
			}
			
			case laser_day:
			{
				CreateTimer(3.0, ReviveLaser, client);
			}
			
			default: {}
			
		}
		
	}
	
	
	return Plugin_Continue;
}


// freeze all players and turn ff on
public Action Freeze(client,args)
{
	if(global_ctx.sd_state != sd_inactive) 
	{ 
		PrintToChat(client,"%s Can't freeze players during Special Day", SPECIALDAY_PREFIX);
		return Plugin_Handled; 
		
	} // dont allow freezes during an sd

	global_ctx.fr = true;
	for(int i = 1; i <= MaxClients; i++)
	{ 
		if(IsClientInGame(i))
		{
			set_client_speed(i, 0.0);
		}
	
	}
	global_ctx.no_damage = true;
	return Plugin_Handled;
}

// unfreeze all players off
public Action UnFreeze(client,args)
{
	if(global_ctx.sd_state != sd_inactive) 
	{ 
		PrintToChat(client,"%s Can't unfreeze players during Special Day", SPECIALDAY_PREFIX);
		return Plugin_Handled; 		
	}
	 // dont allow freezes during an sd
	if(!global_ctx.fr) 
	{
		PrintToChat(client,"%s Can't unfreeze if not already frozen", SPECIALDAY_PREFIX);
		return Plugin_Handled; 
	} 
	
	// can only unfreeze if frozen
	global_ctx.fr = false;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			set_client_speed(i, 1.0);
		}
	
	}
	global_ctx.no_damage = false;
	PrintCenterTextAll("Game play active");
	return Plugin_Handled;
}



public Action sd_list_callback(int client, int args)
{
	sd_list_menu.Display(client, 20);

	return Plugin_Continue;
}

// dummy sd list to show what ones there are
public int SdListHandler(Menu menu, MenuAction action, int client, int param2)
{
	return 0;
}

public SetupFog()
{
	int ent = fog_ent;
	
	if(ent != -1)
	{
		DispatchKeyValue(ent, "fogblend", "0");
		DispatchKeyValue(ent, "fogcolor", "0 0 0");
		DispatchKeyValue(ent, "fogcolor2", "0 0 0");
		DispatchKeyValueFloat(ent, "fogstart", 350.0);
		DispatchKeyValueFloat(ent, "fogend", 750.0);
		DispatchKeyValueFloat(ent, "fogmaxdensity", 50.0);	
	}
}




int get_client_max_kills()
{
	int max = 0;
	int cli = 1;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(players[i].kills > max)
		{
			max = players[i].kills;
			cli = i;
		}
	}
	
	return cli;
}

void EndSd(bool forced=false)
{
	// no sd running we dont need to do anything
	if(global_ctx.sd_state == sd_inactive)
	{
		return;
	}

	if(forced)
	{
		PrintToChatAll("%s Specialday cancelled!", SPECIALDAY_PREFIX);
	}
	
	// enable lr
	if(lr)
	{
		enable_lr();
	}



	// call sd cleanup
	int idx = view_as<int>(global_ctx.special_day);

	SD_STATE_FUNC end_func = end_fptr[idx];

	Call_StartFunction(null, end_func);
	Call_Finish();

	// just in case
	enable_round_end();	

	if(global_ctx.ff)
	{
		disable_friendly_fire();
	}
	
	// give winner creds
	if(store && !forced)
	{
		if(global_ctx.sd_winner != -1 && check_command_exists("sm_store"))
		{
			Store_SetClientCredits(global_ctx.sd_winner, Store_GetClientCredits(global_ctx.sd_winner)+20);
			PrintToChat(global_ctx.sd_winner,"%s you won 20 credits for winning the sd!",SPECIALDAY_PREFIX)
		}
	}

	// purge global sd state
	reset_context();

	for(int i = 1; i <= MAXPLAYERS; i++)
	{
		reset_player(i);
	}

	// reset the store kill ammount
	if(store && store_kill_ammount_cvar != null)
	{
		SetConVarInt(store_kill_ammount_cvar, store_kill_ammount_backup);
	}		

	// deal with nade blocking
	if(standalone)
	{
		ConVar nade_var = FindConVar("sm_noblock_nades");

		if(nade_var)
		{
			SetConVarBool(nade_var,true);
		}
	}



	// reset the alpha just to be safe
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT))
		{
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
			SetEntityRenderColor(i, 255, 255, 255, 255);
			SetEntityGravity(i, 1.0); // reset the gravity
			
			SetEntityMoveType(i, MOVETYPE_WALK);
			set_client_speed(i, 1.0);
		}
	}	

	// reset our function pointer
	global_ctx.player_init = sd_player_init_invalid;
}


public Menu build_sd_menu(MenuHandler handler)
{
	Menu menu = new Menu(handler);

	for (int i = 0; i < SD_SIZE; i++)
	{
		menu.AddItem(sd_list[i], sd_list[i]);
	}
	menu.SetTitle("Special Days");
	return menu;
}


// Top Screen Warden Printing
public Action print_specialday_text_all(Handle timer)
{
	char buf[256];
	


	if(global_ctx.sd_state == sd_inactive)
	{
		return Plugin_Continue;
	}

	// active show current states
	else if(global_ctx.sd_state == sd_active)
	{	
		switch(global_ctx.special_day)
		{
			case tank_day:
			{
				Format(buf, sizeof(buf), "current tank: %N", global_ctx.boss);
			}
			
			case zombie_day:
			{
				if(standalone)
				{
					Format(buf, sizeof(buf), "patient zero %d: %N",global_ctx.round_delay_timer, global_ctx.boss);
				}

				else
				{
					Format(buf, sizeof(buf), "patient zero %N",global_ctx.boss);
				}
			}
			
			case scoutknife_day:
			{
				Format(buf, sizeof(buf), "scout knife: %d", global_ctx.round_delay_timer);
			}

			case deathmatch_day:
			{
				Format(buf, sizeof(buf), "death match: %d", global_ctx.round_delay_timer);	
			}			
			
			case laser_day:
			{
				Format(buf, sizeof(buf), "laser: %N", global_ctx.boss);	
			}
		
			case spectre_day:
			{
				Format(buf, sizeof(buf), "spectre: %N", global_ctx.boss);
			}

			default:
			{
				Format(buf, sizeof(buf), "%s", sd_list[global_ctx.special_day]);
			}
		}
	}
	
	// sd_started just show current
	else
	{	
		Format(buf, sizeof(buf), "%s", sd_list[global_ctx.special_day]);	
	}
	
	
	Handle h_hud_text = CreateHudSynchronizer();
	SetHudTextParams(-1.5, -1.7, 1.0, 255, 255, 255, 255);


	// for each client
	for (int i = 1; i <= MaxClients; i++)
	{
		// is its a valid client
		if (is_valid_client(i))
		{
			ShowSyncHudText(i, h_hud_text, buf);
		}
	}
	
	CloseHandle(h_hud_text);
	
	return Plugin_Continue;
} 


void warden_sd_internal(int client)
{
	if(global_ctx.warden_sd_available > 0 && client == get_warden_id()
		&& global_ctx.sd_state == sd_inactive)
	{
		// randomize the sd (unused)
		//(client, GetRandomInt(0, view_as<int>(normal_day) - 1));

		// open a selection menu for 20 seconds
		sd_menu.Display(client,20);
	}	
}

public Action command_warden_special_day(int client,int args)
{
	global_ctx.wsd_ff = false;
	warden_sd_internal(client);

	return Plugin_Continue;
}

public Action command_warden_special_day_ff(int client,int args)
{
	global_ctx.wsd_ff = true;
	warden_sd_internal(client);

	return Plugin_Continue;
}

// TODO: maybe expand this into an options menu
public Action command_ff_special_day(int client, int args)
{
	PrintToChatAll("%s Special day started (friendly fire enabled)", SPECIALDAY_PREFIX);
	enable_friendly_fire();


	// open a selection menu for 20 seconds
	sd_menu.Display(client,20);
	return Plugin_Handled;
}


public Action command_special_day(int client,int args)  
{
	PrintToChatAll("%s Special day started", SPECIALDAY_PREFIX);

	// open a selection menu for 20 seconds
	sd_menu.Display(client,20);
	return Plugin_Handled;
}

public Action command_cancel_special_day(int client,args)  
{
	EndSd(true);
	return Plugin_Handled;
}



public Action WeaponMenuAll() 
{
	PrintToChatAll("%s Please select a rifle for the special day", SPECIALDAY_PREFIX);
	

	// send the weapon panel to all clients
	//PrintToChatAll("MaxClient = %d", MaxClients);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if (IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT  || GetClientTeam(i) == CS_TEAM_T)
				{
					gun_menu.Display(i,20);
				}
		}
	}	
	return Plugin_Handled;		
}

public int WeaponHandler(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select && IsPlayerAlive(client)) 
	{
		// if sd is now inactive dont give any guns
		if(global_ctx.sd_state == sd_inactive)
		{
			return -1;
		}
		
		weapon_handler_generic(client,param2);
		GivePlayerItem(client, "item_assaultsuit");
	}

	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d", client, param2);
	}
	
	return 0;
}


public CreateKnockBack(int client, int attacker, float damage)
{

	float attacker_ang[3];
	float attacker_pos[3]
	float client_pos[3]

	// attacker eye pos and angle
	GetClientEyePosition(attacker, attacker_pos);
	GetClientEyeAngles(attacker, attacker_ang);
	
	// get pos of where victim is from attacker "eyeline"
	// technically this will go until the nearest object from the attackers eyeline
	// to make handle dumb cases where a bullet hits multiple players
	// (so we wont get the victims actual pos but as we are normalizing the vector it doesent really matter)
	TR_TraceRayFilter(attacker_pos, attacker_ang, MASK_ALL, RayType_Infinite, trace_ignore_players);
	TR_GetEndPosition(client_pos);
	
	float push[3];
	
	// get position vector from attacker to victim
	MakeVectorFromPoints(attacker_pos, client_pos, push);
	
	// normalize the vector so it doesent care about how far away we are shooting from
	NormalizeVector(push, push);
	
	// scale it (may need balancing)
	float scale = damage * 3;
	ScaleVector(push, scale);

	// add the push to players velocity
	float vel[3];
	get_player_velocity(client, vel);
	
	float new_vel[3];
	AddVectors(vel, push, new_vel);
	
	set_player_velocity(client,new_vel);
}



public BalTeams()
{
    int unused = 0;
    int ct = get_alive_team_count(CS_TEAM_CT, unused);
    int t = get_alive_team_count(CS_TEAM_T, unused);

    bool switch_ct = ct < t;
    
    
    SaveTeams(false);
    
    // switch for one team until we have a roughly even split
    for (int i = 1; i <= MaxClients; i++)
    {
        if(ct == t || ct == (t - 1))
        {
            break;
        }
        
        if(!is_valid_client(i))
        {
            continue;
        }
        
        if(switch_ct)
        {
            if(ct_ban)
			{
                if(GetClientTeam(i) == CS_TEAM_T && !(check_command_exists("sm_ctban") &&  CTBan_IsClientBanned(i)))
                {
                    ct += 1;
                    t -= 1;
                    CS_SwitchTeam(i,CS_TEAM_CT);
                }
			}

			else
			{
                if(GetClientTeam(i) == CS_TEAM_T)
                {
                    ct += 1;
                    t -= 1;
                    CS_SwitchTeam(i,CS_TEAM_CT);
                }            
			}
        }
        
        // switch to t
        else if(GetClientTeam(i) == CS_TEAM_CT)
        {
            ct -= 1;
            t += 1;
            CS_SwitchTeam(i,CS_TEAM_T);
        }           
    }
    
}

public SaveTeams(bool onlyct)
{
	// create an array of valid clients
	validclients = 0;

	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(is_valid_client(i))
		{
			bool valid;
			
			// if ct bans active they can only stay on t anyways
			// and thus aernt valid for consideration
			if(ct_ban)
			{
				if(check_command_exists("sm_ctban") && onlyct)
				{
					valid = is_on_team(i) && !CTBan_IsClientBanned(i);
				}
				
				else
				{
					valid = is_on_team(i);
				}
			}

			else
			{
				valid = is_on_team(i);
			}
			
			if(valid)
			{
				game_clients[validclients] = i;
				teams[validclients] = GetClientTeam(i); // save the team
				validclients++;
			}
		}
	
	}
}

public RestoreTeams()
{
	// reset the teams
	for(int i = 0; i < validclients; i++)
	{
		int client = game_clients[i]; // get the client index
		
		if(!is_valid_client(client) || !IsClientInGame(client))
		{
			continue;
		}
		
		// switch back to team actual team
		if(is_on_team(client))
		{
			CS_SwitchTeam(client,teams[i]);
		}
	}
}


public int SdHandler(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		return sd_select(client,param2);
	}
	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d",client,param2);
	}
	
	return -1;
}

public int sd_select(int client, int sd)
{
	if(global_ctx.sd_state != sd_inactive) // if sd is active dont allow two
	{
		if(client != 0)
		{
			PrintToChat(client, "%s You can't do two special days at once!", SPECIALDAY_PREFIX);
		}
		return -1;
	}



	global_ctx.sd_timer = SD_DELAY;

	// special done begun but not active
	global_ctx.sd_state = sd_started; 


	if(standalone)
	{
		// slay all hosties
		int entity = -1;

		float vec[3] = {5000.0,5000.0,5000.0};

		while((entity = FindEntityByClassname(entity, "hostage_entity")) != -1)
		{
			if(IsValidEntity(entity))
			{
				TeleportEntity(entity,vec,NULL_VECTOR,NULL_VECTOR);
			}	
		}
	}

	else
	{
		// invoked by a warden reset the round limit
		if(client == get_warden_id())
		{
			if(global_ctx.wsd_ff)
			{
				PrintToChatAll("%s Special day started (friendly fire enabled)", SPECIALDAY_PREFIX);
				enable_friendly_fire();
				global_ctx.wsd_ff = false;
			}

			else
			{
				PrintToChatAll("%s Special day started", SPECIALDAY_PREFIX);
			}

			global_ctx.warden_sd_available -= 1;
		}

		// sd is started so dont have a warden 
		remove_warden();
	}

	force_open();
	// re-spawn all players
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) // check the client is in the game
		{
			if(!IsPlayerAlive(i))  // check player is dead
			{
				if(is_on_team(i)) // check not in spec
				{
					CS_RespawnPlayer(i);
				}
			}
			// player is alive give 100 hp
			else
			{
				SetEntityHealth(i,100);
			}
		}
	}
	
	// turn off damage until sd starts
	global_ctx.no_damage = true;
	
	
	// turn off collison if its allready on this function
	// will just ignore the request
	unblock_all_clients(SetCollisionGroup);
	
	// init_func

	SD_STATE_FUNC init_func = init_fptr[sd];

	Call_StartFunction(null, init_func);
	Call_Finish();

	if(global_ctx.sd_init_failure)
	{
		return -1;
	}

	// call the initial init for all players on the function pointers we just set
	for (int i = 1; i <= MaxClients; i++)
	{
		sd_player_init(i);
	}

	

	
	
	// Create the timer to start the sd
	// this will then call into our handler when it
	// has fully elapsed
	CreateTimer(1.0, MoreTimers);	
	
	return 0;
}


// consider a better way of doing this without several timers to save function call overhead
public Action MoreTimers(Handle timer)
{
	
	if(global_ctx.sd_state != sd_started)
	{
		return Plugin_Handled;
	}
	
	global_ctx.sd_timer -= 1;
	PrintCenterTextAll("Special day (%s) begins in %d",sd_list[global_ctx.special_day], global_ctx.sd_timer); 
	if(global_ctx.sd_timer > 0)
	{
		CreateTimer(1.0, MoreTimers);
	}

	else 
	{ 
		global_ctx.sd_timer = SD_DELAY; 
		
		
		
		// disable kill protection
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i)) // check the client is in the game
			{
				SetEntityHealth(i, 100);
			}
		}			
			
		global_ctx.no_damage = false;
		
		
		StartSD(); 				
	}
	return Plugin_Continue;
}






// call the correct special day
// would be better just so set function pointers
// but cant :(
public StartSD() 
{
	// deal with nade blocking
	if(standalone)
	{
		ConVar nade_var = FindConVar("sm_noblock_nades");
		if(nade_var)
		{
			SetConVarBool(nade_var,false);
		}
	}


	// incase we cancel our sd
	if(global_ctx.sd_state == sd_inactive)
	{
		return;
	}
	
	global_ctx.sd_state = sd_active;

	if(gangs)
	{
		if(check_command_exists("sm_gang"))
		{
			ServerCommand("sm plugins unload hl_gangs.smx");
		}
	}

	// disable lr
	if(lr)
	{
		disable_lr();
	}

	int idx = view_as<int>(global_ctx.special_day);
	SD_STATE_FUNC start_func = start_fptr[idx];

	Call_StartFunction(null, start_func);
	Call_Finish();
}


// factor this out into each sd file

public Action RemoveGuns(Handle timer)
{	
	if(global_ctx.sd_state != sd_active)
	{
		return Plugin_Handled;
	}
	
	// By Kigen (c) 2008 - Please give me credit. :)
	int maxent = GetMaxEntities();
	char weapon[64];
	for (int i= MaxClients; i < maxent; i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
			{
				RemoveEdict(i);
			}
		}
	}
	

	CreateTimer(1.0, RemoveGuns);
	return Plugin_Continue;
}



// dont touch this or else ( ͡° ͜ʖ ͡°)

public Action samira_EE(int client, int args)
{
	EngineVersion game = GetEngineVersion();

	if(game == Engine_CSS)
	{
		PrintToChat(client,"\x07EE82EE( ͡° ͜ʖ ͡°)\x07F8F8FF------------------\x076A5ACD( ͡° ͜ʖ ͡°)\x07F8F8FF--------------\x07FFFF00( ͡° ͜ʖ ͡°)");
		PrintToChat(client,"\x074B0082( ͡° ͜ʖ ͡°)\x078B0000This plugin is sponsored by Samira\x073EFF3E( ͡° ͜ʖ ͡°)");
		PrintToChat(client,"\x0799CCFF( ͡° ͜ʖ ͡°)\x07F8F8FF----------\x078B0000Thanks\x076A5ACD( ͡° ͜ʖ ͡°)\x078B0000Samira\x07F8F8FF------\x0799CCFF( ͡° ͜ʖ ͡°)");
		PrintToChat(client,"\x073EFF3E( ͡° ͜ʖ ͡°)\x07F8F8FF------------------\x076A5ACD( ͡° ͜ʖ ͡°)\x07F8F8FF--------------\x074B0082( ͡° ͜ʖ ͡°)");
		PrintToChat(client,"\x07FFFF00( ͡° ͜ʖ ͡°)\x07F8F8FF----------\x078B0000Organ\x07FF69B4♥\x076A5ACD( ͡° ͜ʖ ͡°)\x07FF69B4♥\x078B0000Jordi\x07F8F8FF-------\x07EE82EE( ͡° ͜ʖ ͡°)");
	}

	else if(game == Engine_CSGO)
	{
		PrintToChat(client,"\x07( ͡° ͜ʖ ͡°)\x04------------------\x02( ͡° ͜ʖ ͡°)\x02--------------\x07( ͡° ͜ʖ ͡°)");
		PrintToChat(client,"\x07( ͡° ͜ʖ ͡°)\x04This plugin is sponsored by Samira\x02( ͡° ͜ʖ ͡°)");
		PrintToChat(client,"\x07( ͡° ͜ʖ ͡°)\x04----------\x07Thanks\x02( ͡° ͜ʖ ͡°)\x07Samira\x02------\x07( ͡° ͜ʖ ͡°)");
		PrintToChat(client,"\x07( ͡° ͜ʖ ͡°)\x04------------------\x02( ͡° ͜ʖ ͡°)\x02--------------\x07( ͡° ͜ʖ ͡°)");
		PrintToChat(client,"\x07( ͡° ͜ʖ ͡°)\x04----------\x07Organ\x02♥\x07( ͡° ͜ʖ ͡°)\x02♥\x07Jordi\x04-------\x07( ͡° ͜ʖ ͡°)");
	}
	return Plugin_Handled;
} 
