
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <entity>

#include "lib.inc"
#include "specialday/specialday.inc"
// make this possible to be standalone later
#include "jailbreak/jailbreak.inc"


#define VERSION "2.6.1  - Violent Intent Jailbreak"

public Plugin myinfo = {
	name = "Jailbreak Special Days",
	author = "destoer",
	description = "special days for jailbreak",
	version = VERSION,
	url = "https://github.com/destoer/css_jailbreak_plugins"
};

// todo
// ff toggles on individual rounds
// headshot only (done)
// shotgun wars
// sd can start after x number of rounds on warden trigger (done)
// human only fog on zombies


// if running gangs or ct bans with this define to prevent issues :)
//#define GANGS
#define CT_BAN
#define STORE

#define USE_CUSTOM_ZOMBIE_MODEL
#define CUSTOM_ZOMBIE_MUSIC

#define SD_ADMIN_FLAG ADMFLAG_UNBAN

#define FREEZE_COMMANDS

#if defined CT_BAN
#undef REQUIRE_PLUGIN
#include "thirdparty/ctban.inc"
#define REQUIRE_PLUGIN
#endif

#if defined STORE
#undef REQUIRE_PLUGIN
ConVar store_kill_ammount_cvar;
int store_kill_ammount_backup = 0;
#include "thirdparty/store.inc"
#define REQUIRE_PLUGIN
#endif


#include "thirdparty/colorvariables.inc"

#if defined GANGS

#endif

//#define SPECIALDAY_PREFIX "\x04[Vi Special Day]\x07F8F8FF"
//#define SPECIALDAY_PREFIX "\x04[GK Special Day]\x07F8F8FF"
//#define SPECIALDAY_PREFIX "\x04[GP Special Day]\x07F8F8FF"
//#define SPECIALDAY_PREFIX "\x04[3E Special Day]\x07F8F8FF"
#define SPECIALDAY_PREFIX_CSS "\x04[GP Special Day]\x07F8F8FF"
#define SPECIALDAY_PREFIX_CSGO "\x04[GP Special Day]\x02"

char SPECIALDAY_PREFIX[] = SPECIALDAY_PREFIX_CSS

// set up sv_cheats in server config so we can add test bots lol

// requires mp_autokick set to false (0)
 
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
	"Headshot"
};



SpecialDay special_day = normal_day;
SdState sd_state = sd_inactive;

typedef SD_INIT_FUNC = function void (int client);

// function pointer set to tell us how to handle initilaze players on sds
// set back to invalid on endsd to make sure we set it properly for each sd
SD_INIT_FUNC sd_player_init_fptr;



// sd modifiers

// underlying convar handles
Handle g_hFriendlyFire; // mp_friendlyfire var
Handle g_autokick; // turn auto kick off for friednly fire
Handle g_ignore_round_win; 

bool fr = false; // are people frozen
bool ff = false; // is friendly fire on?
bool no_damage = false; // is damage disabled
bool hp_steal = false; // is hp steal on
bool ignore_round_end = false;
int fog_ent;


// round end timer 
int round_delay_timer = 0;



int sdtimer = 20; // timer for sd


// team saves
int validclients = 0; // number of clients able to partake in sd
int game_clients[64];
int teams[64]; // should store in a C struct but cant

// for scoutknifes
int player_kills[64] =  { 0 };

// for zombies
float death_cords[64][3];


int sd_winner = -1;


// backups
// (unused)
//new b_hFriendlyFire; // mp_friendlyfire var
//new b_autokick; // turn auto kick off for friednly fire

// gun removal
int g_WeaponParent;


int rounds_since_warden_sd = 0;

// csgo ff
ConVar convar_mp_teammates_are_enemies;
bool mp_teammates_are_enemies;
// split files for sd
#include "specialday/ffd.inc"
#include "specialday/tank.inc"
#include "specialday/ffdg.inc"
#include "specialday/skywars.inc"
#include "specialday/hide.inc"
#include "specialday/dodgeball.inc"
#include "specialday/grenade.inc"
#include "specialday/zombie.inc"
#include "specialday/gungame.inc"
#include "specialday/knife.inc"
#include "specialday/scoutknifes.inc"
#include "specialday/deathmatch.inc"
#include "specialday/laserwars.inc"
#include "specialday/spectre.inc"
#include "specialday/headshot.inc"
#include "specialday/debug.inc"


// we can then just call this rather than having to switch on the sds in many places
void sd_player_init(int client)
{
	if(sd_state != sd_inactive && IsClientConnected(client) && IsClientInGame(client) && is_on_team(client))
	{
		Call_StartFunction(null, sd_player_init_fptr);
		Call_PushCell(client);
		Call_Finish();
	}
}

// no valid pointer set 
// (lets us know if we forget to set one)
void sd_player_init_invalid(int client)
{
	ThrowNativeError(SP_ERROR_NATIVE, "invalid sd_init function %d:%d:%d\n", client, sd_state, special_day);
}


public start_round_delay(int seconds)
{
	round_delay_timer = seconds;
	CreateTimer(1.0,round_delay_tick);
	disable_round_end();
}

public Action round_delay_tick(Handle Timer)
{
	if(round_delay_timer > 0)
	{
		round_delay_timer -= 1;
		CreateTimer(1.0,round_delay_tick);
	}
	
	else
	{
		if(sd_state == sd_active)
		{
			enable_round_end();
			slay_all();
		}
		
		else
		{
			for (int i = 0; i < MaxClients; i++)
			{
				if(is_valid_client(i))
				{
					PrintToConsole(i,"[DEBUG] Warning attempted to slay for inactive sd. was there a cancel?");
				}
			}
		}
	}
}

void enable_friendly_fire()
{
	ff = true;
	SetConVarBool(g_hFriendlyFire, true); 

	if(GetEngineVersion() == Engine_CSGO)
	{
		SetConVarBool(convar_mp_teammates_are_enemies,true);
	}

}

void disable_friendly_fire()
{
	ff = false;
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
#if defined STORE
	if(store_kill_ammount_cvar != null)
	{
		SetConVarInt(store_kill_ammount_cvar, 0); 
	}
#endif
	
	ignore_round_end = true;
	SetConVarBool(g_ignore_round_win, true);
}

void enable_round_end()
{
	ignore_round_end = false;
	SetConVarBool(g_ignore_round_win, false);
}

public int native_sd_state(Handle plugin, int numParam)
{
	return view_as<int>(sd_state);
}

public int native_current_day(Handle plugin, int numParam)
{
	return view_as<int>(special_day);
}


// register our call
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
#if defined STORE
	MarkNativeAsOptional("Store_GetClientCredits");
	MarkNativeAsOptional("Store_SetClientCredits");
#endif

#if defined CT_BAN
	MarkNativeAsOptional("CTBan_IsClientBanned");
#endif


   CreateNative("sd_current_state", native_sd_state);
   CreateNative("sd_current_day", native_current_day);
   return APLRes_Success;
}

public OnPluginStart() 
{
	// init text
	EngineVersion game = GetEngineVersion();
	if(game == Engine_CSGO)
	{
		Format(SPECIALDAY_PREFIX,strlen(SPECIALDAY_PREFIX),SPECIALDAY_PREFIX_CSGO);
	}
	
	SetCollisionGroup = init_set_collision();
	
		
	
	
	HookEvent("player_death", OnPlayerDeath,EventHookMode_Post);
	HookEvent("player_hurt", OnPlayerHurt); 

	// warden trigger random sd
	RegConsoleCmd("wsd", command_warden_special_day);
	// register our special day console command	
	RegAdminCmd("sd", command_special_day, SD_ADMIN_FLAG);
	RegAdminCmd("sd_cancel", command_cancel_special_day, SD_ADMIN_FLAG);
	
#if defined FREEZE_COMMANDS
	// freeze stuff
	RegAdminCmd("fr", Freeze,ADMFLAG_BAN);
	RegAdminCmd("uf",UnFreeze,ADMFLAG_BAN);
#endif

	RegConsoleCmd("sdspawn", sd_spawn); // spawn during zombie if late joiner
	RegConsoleCmd("sd_list", sd_list_callback); // list sds
	
	// gun removal
	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

	
	// hook disonnect incase a vital member leaves
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);

	

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
	
	RegConsoleCmd("sdv", sd_version);
	
	for(int i = 1;i < MaxClients;i++)
	{
		if(is_valid_client(i))
		{
			OnClientPutInServer(i);
		}
	}
	
	//set our initial function pointer
	sd_player_init_fptr = sd_player_init_invalid;
	
	// timer for printing current sd info
	CreateTimer(1.0, print_specialday_text_all, _, TIMER_REPEAT);
	CreateTimer(0.1, check_movement, _, TIMER_REPEAT);
	
	
	
	// init gun game list
	for (int i = 0; i < GUNS_SIZE; i++)
	{
		gungame_gun_idx[i] = i;
	}
}


public Action WeaponMenu(int client)
{
	gun_menu.Display(client, 20);
}

public Action sd_spawn(int client, int args)
{
	// sd not active so we dont care
	// or player alive so dont care
	if(sd_state == sd_inactive || IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}	

	// invalid or not on a real team
	if (!is_valid_client(client) || !is_on_team(client))
	{	
		return Plugin_Continue; 
    }	
	
	// less than 20 seconds set them up
	if(sd_state == sd_started)
	{
		CS_RespawnPlayer(client);
		sd_player_init(client);
	}
	
	// sd is running (20 secs in cant join) for most sds
	else if(sd_state == sd_active)
	{
		
		switch(special_day)
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
	if(sd_state != sd_inactive) 
	{ 
		PrintToChat(client,"%s Can't freeze players during Special Day", SPECIALDAY_PREFIX);
		return Plugin_Handled; 
		
	} // dont allow freezes during an sd

	fr = true;
	for(int i = 1; i < MaxClients; i++)
	{ 
		if(IsClientInGame(i))
		{
			set_client_speed(i, 0.0);
		}
	
	}
	no_damage = true;
	return Plugin_Handled;
}

// unfreeze all players off
public Action UnFreeze(client,args)
{
	if(sd_state != sd_inactive) 
	{ 
		PrintToChat(client,"%s Can't unfreeze players during Special Day", SPECIALDAY_PREFIX);
		return Plugin_Handled; 		
	} // dont allow freezes during an sd
	if(fr == false) 
	{
		PrintToChat(client,"%s Can't unfreeze if not already frozen", SPECIALDAY_PREFIX);
		return Plugin_Handled; 
	} // can only unfreeze if frozen
	fr = false;
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			set_client_speed(i, 1.0);
		}
	
	}
	no_damage = false;
	PrintCenterTextAll("Game play active");
	return Plugin_Handled;
}


public void OnClientPutInServer(int client)
{
	// for sd
	SDKHook(client, SDKHook_TraceAttack, HookTraceAttack); // block damage
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip); // block weapon pickups
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}



//remove damage and aimpunch
public Action HookTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) 
{
		if(no_damage)
		{
			return Plugin_Handled;
		}
		
		
		return Plugin_Continue;
}


public Action PlayerDisconnect_Event(Handle event, const String:name[], bool dontBroadcast)
{

	int client = GetClientOfUserId(GetEventInt(event,"userid"));


	if(sd_state == sd_started)
	{
		switch(special_day)
		{
			case tank_day:
			{
				if(client == tank)
				{
					tank_discon_started(client);
				}
			}
			
			case spectre_day:
			{
				if(client == spectre)
				{
					spectre_discon_started(client);
				}
			}
			
			
			case zombie_day:
			{
				if(client == patient_zero)
				{
					zombie_discon_started(client);
				}
			}
			
			default: {}
		}
	}
	
	else if(sd_state == sd_active)
	{
		switch(special_day)
		{
			case tank_day:
			{	
				if(client == tank)
				{
					tank_discon_active(client);
				}
			}
			
			case spectre_day:
			{
				if(client == spectre)
				{
					spectre_discon_active(client);
				}
			}
			
			
			case zombie_day:
			{
				if(client == patient_zero)
				{
					zombie_discon_active(client);
				}
			}
			
			default: {}
		}
	}



	return Plugin_Continue;
}


Menu sd_menu;
Menu sd_list_menu;

// Clean up our variables just to be on the safe side
public OnMapStart()
{
	
#if defined STORE
	store_kill_ammount_cvar = FindConVar("sm_store_credit_amount_kill");
	if(store_kill_ammount_cvar != null)
	{
		store_kill_ammount_backup = GetConVarInt(store_kill_ammount_cvar);
	}
#endif
	
	
	g_lbeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_lpoint = PrecacheModel("materials/sprites/glow07.vmt");	
	
	sd_state = sd_inactive;
	special_day = normal_day;
	disable_friendly_fire();
	tank = -1;
	patient_zero = -1;
	
	gun_menu = build_gun_menu(WeaponHandler);
	sd_menu = build_sd_menu(SdHandler); // real sd select
	sd_list_menu = build_sd_menu(SdListHandler); // dummy sd menu for people to see sds
	
	#if defined USE_CUSTOM_ZOMBIE_MODEL
		zombie_model_success = CacheCustomZombieModel();
		if (!zombie_model_success)
		{
			PrecacheModel("models/zombie/classic.mdl");
		}
	#else
		PrecacheModel("models/zombie/classic.mdl");
	#endif
	
	PrecacheSound("npc/zombie/zombie_voice_idle1.wav");

#if defined CUSTOM_ZOMBIE_MUSIC
	AddFileToDownloadsTable("sound/music/HLA.mp3");
	PrecacheSound("music/HLA.mp3");
#else
	// dont know if we should loop this
	PrecacheSound("music/ravenholm_1.mp3");
#endif

	
	// create fog controller
	int ent;

	ent = FindEntityByClassname(-1, "env_fog_controller");

	if(ent == -1)
	{
		ent = CreateEntityByName("env_fog_controller");
		DispatchSpawn(ent); 
	}	
	
	fog_ent = ent;
	SetupFog();
	AcceptEntityInput(fog_ent, "TurnOff");
}

public OnMapEnd()
{
	delete gun_menu;
	delete sd_menu;
	delete sd_list_menu;
}



public Action sd_list_callback(int client, int args)
{
	sd_list_menu.Display(client, 20);
}

// dummy sd list to show what ones there are
public int SdListHandler(Menu menu, MenuAction action, int client, int param2)
{

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






public Action OnRoundStart(Handle event, const String:name[], bool dontBroadcast)
{
	reset_use_key();
	EndSd();
}



int get_client_max_kills()
{
	int max = 0;
	int cli = 1;
	for (int i = 1; i < MaxClients; i++)
	{
		if(player_kills[i] > max)
		{
			max = player_kills[i];
			cli = i;
		}
	}
	
	return cli;
}

void EndSd(bool forced=false)
{
	// no sd running we dont need to do anything
	if(sd_state == sd_inactive)
	{
		return;
	}

	if(forced)
	{
		PrintToChatAll("%s Specialday cancelled!", SPECIALDAY_PREFIX);
	}
	
	switch(special_day)
	{
		case tank_day:
		{
			end_tank();
		}
		
		
		case friendly_fire_day:
		{
			disable_friendly_fire();
		}
		
		case juggernaut_day:
		{
			disable_friendly_fire();
		}
		
		case hide_day: {} // we render players further down to handle maps that do messy things
		

		
		case dodgeball_day: {}
		case normal_day: {}
		case fly_day: {}
		case grenade_day: {}
		case knife_day: {}
		case laser_day: {}
		case headshot_day: {}

		case spectre_day: 
		{
			end_spectre();
		}

		case scoutknife_day:
		{
			end_scout();
		}
		
		case deathmatch_day:
		{
			end_deathmatch();
		}
		
		
		// need to turn off ignore round win here :)
		case gungame_day:
		{
			enable_round_end();
		}
		
		case zombie_day:
		{
			end_zombie();
		}
		
		default:
		{
			ThrowNativeError(SP_ERROR_NATIVE, "special day %d not handled in round_end",special_day);
		}
	}

	// just in case
	enable_round_end();	
	
	if(ff == true)
	{
		disable_friendly_fire();
	}	
	

	if(ff)
	{
		disable_friendly_fire();
	}
	
	// give winner creds
#if defined STORE
	if(!forced)
	{
		if(sd_winner != -1 && check_command_exists("sm_store"))
		{
			Store_SetClientCredits(sd_winner, Store_GetClientCredits(sd_winner)+20);
			PrintToChat(sd_winner,"%s you won 20 credits for winning the sd!",SPECIALDAY_PREFIX)
		}
	}
#endif

	special_day = normal_day;
	sd_state = sd_inactive;
	hp_steal = false;
	fr = false;
	no_damage = false;
	tank = -1;
	patient_zero = -1;
	sd_winner = -1;
	
	// reset the store kill ammount
#if defined STORE
	if(store_kill_ammount_cvar != null)
	{
		SetConVarInt(store_kill_ammount_cvar, store_kill_ammount_backup);
	}		
#endif

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
	sd_player_init_fptr = sd_player_init_invalid;
}


public Action OnRoundEnd(Handle event, const String:name[], bool dontBroadcast)
{
	if(GetClientCount(true) >= 8)
	{
		rounds_since_warden_sd += 1;
	}	


	if(rounds_since_warden_sd >= ROUND_WARDEN_SD)
	{
		PrintToChatAll("%s Warden sd available !wsd",SPECIALDAY_PREFIX);
	}
	
#if defined GANGS	
	if(sd_state == sd_active && check_command_exists("sm_gang"))
	{
		ServerCommand("sm plugins load hl_gangs.smx")
	}
#endif
	fr = false;
	no_damage = false;
	EndSd();
	return Plugin_Handled;
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
	


	if(sd_state == sd_inactive)
	{
		return Plugin_Continue;
	}

	// active show current states
	else if(sd_state == sd_active)
	{	
		switch(special_day)
		{
			case tank_day:
			{
				Format(buf, sizeof(buf), "current tank: %N", tank);
			}
			
			case zombie_day:
			{
				Format(buf, sizeof(buf), "patient zero: %N", patient_zero);
			}
			
			case scoutknife_day:
			{
				Format(buf, sizeof(buf), "scout knife: %d", round_delay_timer);
			}

			case deathmatch_day:
			{
				Format(buf, sizeof(buf), "death match: %d", round_delay_timer);	
			}			
			
			case laser_day:
			{
				Format(buf, sizeof(buf), "laser: %d", round_delay_timer);	
			}

			case spectre_day:
			{
				Format(buf, sizeof(buf), "spectre: %N", spectre);
			}

			default:
			{
				Format(buf, sizeof(buf), "%s", sd_list[special_day]);
			}
		}
	}
	
	// sd_started just show current
	else
	{	
		Format(buf, sizeof(buf), "%s", sd_list[special_day]);	
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

public Action command_warden_special_day(int client,int args)
{
	
	if(rounds_since_warden_sd >= ROUND_WARDEN_SD && client == get_warden_id()
		&& sd_state == sd_inactive)
	{
		//ect(client, GetRandomInt(0, view_as<int>(normal_day) - 1));
		command_special_day(client, args);
	}
}


public Action command_special_day(int client,int args)  
{

	PrintToChatAll("%s Special day started", SPECIALDAY_PREFIX);

	// construct our menu
	
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
	for(int i = 1; i < MaxClients; i++)
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
		if(sd_state == sd_inactive)
		{
			return -1;
		}
		
		strip_all_weapons(client);
		
	
		GivePlayerItem(client, "weapon_knife"); // give back a knife
		GivePlayerItem(client, "weapon_deagle"); // all ways give a deagle
		
		
		// give them plenty of deagle ammo
		int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		set_reserve_ammo(client, weapon, 999)
		
		// give player nades
		GivePlayerItem(client, "weapon_flashbang"); 
		GivePlayerItem(client, "weapon_hegrenade"); 
		GivePlayerItem(client, "weapon_smokegrenade");
		
		// and kevlar
		GivePlayerItem(client, "item_assaultsuit"); 
		
		EngineVersion game = GetEngineVersion();

		if(game == Engine_CSS)
		{
			// finally give the player the item
			GivePlayerItem(client, gun_give_list_css[param2]);
		}

		if(game == Engine_CSGO)
		{
			GivePlayerItem(client, gun_give_list_csgo[param2]);
		}

		
		// give them plenty of primary ammo
		weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		set_reserve_ammo(client, weapon, 999);
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



public Action OnPlayerHurt(Handle event, const String:name[], bool dont_broadcast)
{
	int hitgroup = GetEventInt(event, "hitgroup");
	
	if(sd_state == sd_active && special_day == headshot_day)
	{
		// if not a headshot cancel out damage
		if(hitgroup != HITGROUP_HEAD)
		{
			int victim = GetClientOfUserId(GetEventInt(event, "userid"));
			if(is_valid_client(victim))
			{
				// why cant i use setentityhealth here?
				SetEntProp(victim,Prop_Send,"m_iHealth",100,4);
			}
		}
	}
	
}

// make team damage the same as cross team damage

public Action OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{

	if(no_damage)
	{
		damage = 0.0;
		return Plugin_Changed;
	}

	// scale ff damage so its the same as standard dmg
	else if(ff)
	{
		if (is_ffa(victim, attacker) && inflictor == attacker)
		{
			damage /= 0.35;
		}	
	}

	if(sd_state != sd_inactive)
	{
		switch(special_day)
		{
		
			case dodgeball_day:
			{
				// any damage kills 
				// prevents cheaters from healing 
				damage = 500.0;
			}
			
			
			case zombie_day:
			{
				if (!is_valid_client(attacker)) { return Plugin_Continue; }
				
				// knockback is way to overkill on csgo
				if(GetClientTeam(victim) == CS_TEAM_T && GetEngineVersion() == Engine_CSS)
				{
					CreateKnockBack(victim, attacker, damage);
				}
				

				// patient zero instantly kills
				else if(attacker == patient_zero)
				{
					damage = 120.0;
				}
				
			}
			
			// spectre instant kills everyone
			case spectre_day:
			{
				if(attacker == spectre)
				{
					damage = 120.0;
				}	
			}

			default: {}
		}
		return Plugin_Changed;
	}

	return Plugin_Continue;
}



public SaveTeams(bool onlyct)
{
	// create an array of valid clients
	validclients = 0;

	
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			
			bool valid;
			
			// if ct bans active they can only stay on t anyways
			// and thus aernt valid for consideration
			#if defined CT_BAN 
				if(check_command_exists("sm_ctban") && onlyct)
				{
					valid = is_on_team(i) && !CTBan_IsClientBanned(i);
				}
				
				else
				{
					valid = is_on_team(i);
				}
			#else
				valid = is_on_team(i);
			#endif
			
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


//float death_cords[64][3];
// int player_kills[64] =  { 0 }; ^ defined above
public Action OnPlayerDeath(Handle event, const String:name[], bool dontBroadcast)
{

	if(hp_steal)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		// give the killer +100 hp
		int health = GetClientHealth(attacker);
		health += 100;
		SetEntityHealth(attacker, health);
	}
	
	if(sd_state == sd_inactive)
	{
		return Plugin_Continue;
	}


	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	// if the kill is from friendly fire
	// set the score so it goes up instead of down
	if(is_ffa(victim, attacker) && is_valid_client(attacker))
	{
		int frags = GetEntProp(attacker,Prop_Data, "m_iFrags");
		SetEntProp(attacker, Prop_Data, "m_iFrags", frags + 2);
	}

	switch(special_day)
	{
		case zombie_day:
		{
			zombie_death(victim);
		}
		
		case scoutknife_day:
		{	
			scoutknife_death(attacker, victim);
		}
		
		case deathmatch_day:
		{
			deathmatch_death(attacker, victim);
		}	
		
		case gungame_day:
		{
			gungame_death(attacker, victim);
		}
		
		case laser_day:
		{
			laser_death(victim);
		}
		
		default: {}
	
	}
	
	return Plugin_Continue;
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
	if(sd_state != sd_inactive) // if sd is active dont allow two
	{
		if(client != 0)
		{
			PrintToChat(client, "%s You can't do two special days at once!", SPECIALDAY_PREFIX);
		}
		return -1;
	}

	// invoked by a warden reset the round limit
	if(client == get_warden_id())
	{
		rounds_since_warden_sd = 0;
	}

	sdtimer = 20;

	// special done begun but not active
	sd_state = sd_started; 
	
	
	force_open();
	// re-spawn all players
	for(int i = 1; i < MaxClients; i++)
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
	no_damage = true;
	
	
	// turn off collison if its allready on this function
	// will just ignore the request
	unblock_all_clients(SetCollisionGroup);
	
	

	switch(sd)
	{

		case friendly_fire_day: //ffd
		{ 
			init_ffd();
		}
		
		case tank_day: // tank day
		{
			if(!init_tank())
			{
				return -1;
			}
		}
		
		case juggernaut_day: //ffdg
		{
			init_ffdg();
		}
		
		case fly_day: // flying day
		{
			init_skywars();
		}
		
		case hide_day: // hide and seek day
		{
			init_hide();
		}
		
		
		case dodgeball_day: // dodgeball day
		{
			dodgeball_init();
		}
		
		
		
		case grenade_day: // grenade day
		{
			grenade_init();
		}
			
		case zombie_day: // zombie day
		{
			init_zombie();
		}
		
		case gungame_day: // gun game
		{
			init_gungame();
		}
		
		case knife_day: // knife day
		{
			knife_init();
		}
		
		case scoutknife_day: // scout knife day
		{
			scoutknife_init();
		}
		
		case deathmatch_day: // deathmatch
		{
			deathmatch_init();
		}
		
		case laser_day: // laser day
		{
			laser_init();
		}
		

		// spectre
		case spectre_day:
		{
			if(!spectre_init())
			{
				return -1;
			}
		}
		
		// headshot only
		case headshot_day:
		{
			headshot_init();
		}
		
	}

	// call the initial init for all players on the function pointers we just set
	for (int i = 1; i < MaxClients; i++)
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
	
	if(sd_state != sd_started)
	{
		return Plugin_Handled;
	}
	
	sdtimer -= 1;
	PrintCenterTextAll("Special day begins in %d", sdtimer); 
	if(sdtimer > 0)
	{
		CreateTimer(1.0, MoreTimers);
	}

	else 
	{ 
		sdtimer = 20; 
		
		
		
		// disable kill protection
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i)) // check the client is in the game
			{
				SetEntityHealth(i, 100);
			}
		}			
			
		no_damage = false;
		
		
		StartSD(); 				
	}
	return Plugin_Continue;
}






// call the correct special day
// would be better just so set function pointers
// but cant :(
public StartSD() 
{
	// incase we cancel our sd
	if(sd_state == sd_inactive)
	{
		return;
	}
	
	sd_state = sd_active;

#if defined GANGS
	if(check_command_exists("sm_gang"))
	{
		ServerCommand("sm plugins unload hl_gangs.smx");
	}
#endif

	// sd is active so dont have a warden
	remove_warden();


	switch(special_day)
	{
		case friendly_fire_day:
		{
			StartFFD();
		}
		
		case juggernaut_day:
		{
			StartJuggernaut();
		}
		
		case tank_day:
		{
			StartTank();
		}
		
		case fly_day:
		{
			StartFly();
		}
		
		case dodgeball_day:
		{
			StartDodgeball();
		}
		
		case hide_day:
		{
			StartHide();
		}
		
		
		case grenade_day:
		{
			StartGrenade();
		}
		
		case zombie_day:
		{
			StartZombie();
		}
		
		case gungame_day:
		{
			StartGunGame();
		}
		
		case knife_day:
		{
			StartKnife();
		}
		
		case scoutknife_day:
		{
			StartScout();
		}
		
		case deathmatch_day:
		{
			StartDeathMatch();
		}
		
		case laser_day:
		{
			StartLaser();
		}

		case spectre_day:
		{
			StartSpectre();
		}
		
		case headshot_day:
		{
			StartHeadshot();
		}


		default:
		{
			ThrowNativeError(SP_ERROR_NATIVE, "attempted to start invalid sd %d", special_day);
		}
	}
}


// factor this out into each sd file

// handle nade projectiles for a sd create timers to remove them :)
public OnEntityCreated(int entity, const String:classname[])
{
	
	if(sd_state == sd_inactive)
	{
		return;
	}	
	
	switch(special_day)
	{
	
		case dodgeball_day:
		{
			if (StrEqual(classname, "flashbang_projectile"))
			CreateTimer(1.4, GiveFlash, entity);
		}
		
		case grenade_day:
		{
			if (StrEqual(classname, "hegrenade_projectile"))
			CreateTimer(1.4, GiveGrenade, entity);
		}
		
		default: {}
	
	}
}

public Action RemoveGuns(Handle timer)
{	
	if(sd_state != sd_active)
	{
		return Plugin_Handled;
	}
	
	// By Kigen (c) 2008 - Please give me credit. :)
	int maxent = GetMaxEntities();
	char weapon[64];
	for (int i=GetMaxClients(); i < maxent; i++)
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


// prevent additional weapon pickups
// factor this out into each sd file
public Action OnWeaponEquip(int client, int weapon) 
{

	if(sd_state == sd_inactive)
	{
		return Plugin_Continue;
	}

	switch(special_day)
	{
		
	
		case dodgeball_day:
		{
			char weapon_string[32];
			GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 
			if(!StrEqual(weapon_string,"weapon_flashbang"))
			{
				return Plugin_Handled;
			}
		}
		
		case grenade_day:
		{
			char weapon_string[32];
			GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 
			if(!StrEqual(weapon_string,"weapon_hegrenade"))
			{
				return Plugin_Handled;
			}
		}
		
		case knife_day:
		{
			char weapon_string[32];
			GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 
			if(!StrEqual(weapon_string,"weapon_knife"))
			{
				return Plugin_Handled;
			}
		}
	
		case scoutknife_day:
		{
			char weapon_string[32];
			GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 
			// need to check for ssg08 incase we are oncsgo
			if(!(StrEqual(weapon_string,"weapon_scout") || StrEqual(weapon_string,"weapon_knife") || StrEqual(weapon_string,"weapon_ssg08")))
			{
				return Plugin_Handled;
			}
		}
	
		case zombie_day:
		{
			if(sd_state == sd_active)
			{
				char weapon_string[32];
				GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 
				
				if(GetClientTeam(client) == CS_TEAM_T)
				{
					if(!StrEqual(weapon_string,"weapon_knife"))
					{
						return Plugin_Handled;
					}
				}
			}
		}

		// spectre can only use knife
		case spectre_day:
		{
			if(sd_state == sd_active)
			{
				char weapon_string[32];
				GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 
				if(client == spectre)
				{
					if(!StrEqual(weapon_string,"weapon_knife"))
					{
						return Plugin_Handled;
					}					
				}				
			}
		}
		
		
		case headshot_day:
		{
			if(sd_state != sd_inactive)
			{
				char weapon_string[32];
				GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 

				if(!StrEqual(weapon_string,"weapon_deagle"))
				{
					return Plugin_Handled;
				}					
									
			}
		}

		default: {}
	
	}
	return Plugin_Continue;
}



// handles movement changes off a ladder so they are what they should be for an sd

MoveType player_last_movement_type[64] = {MOVETYPE_WALK};


public Action check_movement(Handle Timer)
{
	// no sd running dont care
	if(sd_state == sd_inactive)
	{
		return Plugin_Continue;
	}
	

	for (int client = 1; client < MaxClients; client++)
	{
		// not interested is they are dead or not here
		if(is_valid_client(client) && is_on_team(client) && IsPlayerAlive(client))
		{
			
			// if it is different from the old one
			// and the old one is a ladder and we are on a sd
			// with different movement settings
			// reset the players move type
			MoveType cur_type = GetEntityMoveType(client);
			MoveType old_type = player_last_movement_type[client];
			if(cur_type != old_type && old_type == MOVETYPE_LADDER)
			{
				switch(special_day)
				{
					
					case zombie_day:
					{
						if(GetClientTeam(client) == CS_TEAM_T && sd_state == sd_active)
						{
							set_zombie_speed(client);
						}
					}
					
					// we use a button toggle i dont think we need this anymore
					case fly_day:
					{
						//client_fly(client);
					}


					case dodgeball_day: 
					{
						sd_player_init(client);
					}
					
					case grenade_day: 
					{
						sd_player_init(client);
					}					

					case scoutknife_day: 
					{
						sd_player_init(client);
					}
					
					default: {}
				}
			}
			
			//cache the last movement type
			player_last_movement_type[client] = cur_type
		}
	}	

		
	return Plugin_Continue;
}



bool use_key[MAXPLAYERS+1] = false;

void reset_use_key()
{
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		use_key[i] = false;
	}
}


// hook for laser day :)
// add callbacks if other sds do need to use this
public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
	// cant use while dead	
	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	// if not an sd we dont care
	if(sd_state == sd_inactive)	
	{
		return Plugin_Continue;
	}
	
	bool in_use = (buttons & IN_USE) == IN_USE;
	
	// kill laser
	if(in_use && special_day == laser_day && sd_state == sd_active)
	{
		setup_laser(client,{ 1, 153, 255, 255 },g_lbeam,g_lpoint,true);
	}	

	// use key press toggle fly day move type
	else if(in_use && !use_key[client] && special_day == fly_day)
	{
		if(GetEntityMoveType(client) == MOVETYPE_FLY)
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
		
		else
		{
			SetEntityMoveType(client, MOVETYPE_FLY);
		}
	}

	use_key[client] = in_use;
	
	return Plugin_Continue;
}
