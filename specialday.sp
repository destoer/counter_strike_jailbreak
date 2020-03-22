#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <entity>
#include "colorvariables.inc"
#include "lib.inc"

// if running gangs or ct bans with this define to prevent issues :)
#define GANGS
#define CT_BAN
#define STORE

#define USE_CUSTOM_ZOMBIE_MODEL

#define SD_ADMIN_FLAG ADMFLAG_GENERIC

#if defined CT_BAN
#undef REQUIRE_PLUGIN
#include "ctban.inc"
#define REQUIRE_PLUGIN
#endif

#if defined STORE
#undef REQUIRE_PLUGIN
#include "store.inc"
#define REQUIRE_PLUGIN
#endif


#if defined GANGS

#endif

//#define SPECIALDAY_PREFIX "\x04[Vi Special Day]\x07F8F8FF"
#define SPECIALDAY_PREFIX "\x04[GK Special Day]\x07F8F8FF"
#define FFA_CONDITION(%1,%2) (1 <= %1 <= MaxClients && 1 <= %2 <= MaxClients && %1 != %2 && GetClientTeam(%1) == GetClientTeam(%2))

// set up sv_cheats in server config so we can add test bots lol

// requires mp_autokick set to false (0)
 
// gun menu
Menu gun_menu;



const int SD_SIZE = 12;
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
	"Scout Knifes",
	"Death Match"
};


// sadly we cant scope these
enum SpecialDay
{
	friendly_fire_day,
	tank_day,
	juggernaut_day,
	fly_day,
	hide_day,
	dodgeball_day,
	grenade_day,
	zombie_day,
	gungame_day,
	knife_day,
	scoutknife_day,
	deathmatch_day,
	normal_day,
};


enum SdState
{
	sd_started,
	sd_active,
	sd_inactive
};

SpecialDay special_day = normal_day;
SdState sd_state = sd_inactive;

typedef SD_INIT_FUNC = function void (int client);

// function pointer set to tell us how to handle initilaze players on sds
// set back to invalid on endsd to make sure we set it properly for each sd
SD_INIT_FUNC sd_player_init_fptr;

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


/* heres all our pointers for our current sd */


// ffd do a gun menu
void ffd_player_init(int client)
{
	WeaponMenu(client);
}

// tank give a gun menu
void tank_player_init(int client)
{
	WeaponMenu(client);
}

// ffdg
void ffdg_player_init(int client)
{
	WeaponMenu(client);
}

void client_fly(int client)
{
	set_client_speed(client,2.5);
	SetEntityMoveType(client, MOVETYPE_FLY);
}

// flying day
void flying_player_init(int client)
{
	// give player guns if we are just starting
	if(sd_state == sd_started)
	{
		WeaponMenu(client);
	}
	
	client_fly(client);
}

// hide and seek
void hide_player_init(int client)
{
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		// make players invis
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 0, 0, 0, 0);
	}
	
	else if(GetClientTeam(client) == CS_TEAM_CT)
	{
		CS_RespawnPlayer(client);
		WeaponMenu(client);
		set_client_speed(client, 0.0);
		SetEntityHealth(client,500); // set health to 500
	}
}

// dodgeball day
void dodgeball_player_init(int client)
{
	SetEntityHealth(client,1); // set health to 1
	strip_all_weapons(client); // remove all the players weapons
	GivePlayerItem(client, "weapon_flashbang");
	SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);  
	SetEntityGravity(client, 0.6);
}

// grenade day
void grenade_player_init(int client)
{
	// when coming off ladders and using the reset
	// we dont wanna regive the nades
	strip_all_weapons(client); // remove all the players weapons
	GivePlayerItem(client, "weapon_hegrenade");
	SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);  
	SetEntityGravity(client, 0.6);
}


// zombie day
void zombie_player_init(int client)
{
	// not active give guns
	if(sd_state == sd_started)
	{
		WeaponMenu(client);
	}
	
	// just make a zombie
	else
	{
		MakeZombie(client);
	}
}

// gun game
void gun_game_player_init(int client)
{
	GiveGunGameGun(client);
}

void knife_player_init(int client)
{
	strip_all_weapons(client);
	GivePlayerItem(client,"weapon_knife");
}

void scout_player_init(int client)
{
	strip_all_weapons(client);
	GivePlayerItem(client, "weapon_scout");
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "item_assaultsuit");
	SetEntityGravity(client, 0.1)
}

void deathmatch_player_init(int client)
{
	WeaponMenu(client);
}


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



// round end timer 
int round_delay_timer = 0;


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
		enable_round_end();
		slay_all();
	}
}

void enable_friendly_fire()
{
	ff = true;
	SetConVarBool(g_hFriendlyFire, true); 	
}

void disable_friendly_fire()
{
	ff = false;
	SetConVarBool(g_hFriendlyFire, false); 	
}

void disable_round_end()
{
	ignore_round_end = true;
	SetConVarBool(g_ignore_round_win, true);
}

void enable_round_end()
{
	ignore_round_end = false;
	SetConVarBool(g_ignore_round_win, false);
}

int sdtimer = 20; // timer for sd


// sd specific vars
int tank = -1; // hold client id of the tank
int patient_zero = -1;



// team saves
int validclients = 0; // number of clients able to partake in sd
int game_clients[64];
int teams[64]; // should store in a C struct but cant

// for scoutknifes
int player_kills[64] =  { 0 };


// gun game current progression
#define GUNGAME_SIZE 9



new const String:guns_list[GUNGAME_SIZE][] = 
{
	"weapon_ak47",
	"weapon_awp",
	"weapon_m4a1",
	"weapon_mp5navy",
	"weapon_deagle",
	"weapon_elite",
	"weapon_p90",
	"weapon_famas",
	"weapon_usp"
};

// level of progression the player is on
int gun_counter[64] =  { 0 };


// backups
// (unused)
//new b_hFriendlyFire; // mp_friendlyfire var
//new b_autokick; // turn auto kick off for friednly fire

// gun removal
int g_WeaponParent;

#define VERSION "2.0.0 - Violent Intent Jailbreak"

public Plugin myinfo = {
	name = "Jailbreak Special Days",
	author = "destoer",
	description = "special days for jailbreak",
	version = VERSION,
	url = "https://github.com/destoer/css_jailbreak_plugins"
};




public int native_sd_active(Handle plugin, int numParam)
{
	return sd_state != sd_inactive;
}

// register our call
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
#if defined STORE
	MarkNativeAsOptional("Store_GetClientCredits");
	MarkNativeAsOptional("Store_SetClientCredits");
#endif

   CreateNative("sd_active", native_sd_active);
   return APLRes_Success;
}

public OnPluginStart() 
{
	HookEvent("player_death", OnPlayerDeath,EventHookMode_Post);


	// register our special day console command	
	RegAdminCmd("sd", command_special_day, SD_ADMIN_FLAG);
	RegAdminCmd("sd_cancel", command_cancel_special_day, SD_ADMIN_FLAG);
	// freeze stuff
	RegAdminCmd("fr", Freeze,ADMFLAG_BAN);
	RegAdminCmd("uf",UnFreeze,ADMFLAG_BAN);
	
	RegConsoleCmd("sdv", sd_version); // print version
	RegConsoleCmd("zspawn", zspawn); // spawn during zombie if late joiner
	RegConsoleCmd("sd_list", sd_list_callback); // list sds
	
	// gun removal
	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

	
	// hook disonnect incase a vital member leaves
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);

	// hook disonnect incase a vital member leaves
	HookEvent("player_connect", player_connect_event, EventHookMode_Post);
	

	g_hFriendlyFire = FindConVar("mp_friendlyfire"); // get the friendly fire var
	g_ignore_round_win = FindConVar("mp_ignore_round_win_conditions");
	g_autokick = FindConVar("mp_autokick");
	SetConVarBool(g_autokick, false);	
	// should really save the defaults but ehhh
	//b_autokick = GetConVarBool(g_autokick);
	//b_hFriendlyFire = GetConVarBool(g_hFriendlyFire);
	
	HookEvent("round_start", OnRoundStart); // reset variables after a sd
	HookEvent("round_end", OnRoundEnd);
	AddCommandListener(join_team,"jointeam");
	
	
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
}


public Action sd_version(int client, int args)
{
	PrintToChat(client, "%s SD VERSION: %s",SPECIALDAY_PREFIX, VERSION);
}


public Action zspawn(int client, int args)
{
	if(sd_state != sd_active || special_day != zombie_day) 
	{
		PrintToChat(client, "%s zombie day is not running", SPECIALDAY_PREFIX);
		return;
	}
	CreateTimer(3.0, ReviveZombie, client);
}


public Action WeaponMenu(int client)
{
	gun_menu.Display(client, 20);
}

public Action hide_timer_callback(Handle timer)
{
	make_invis_t();

	if(special_day == hide_day)
	{
		CreateTimer(5.0, hide_timer_callback);
	}
}

public Action join_team(int client, const char[] command, int args)
{	
	
	
	// sd not active so we dont care
	if(sd_state == sd_inactive)
	{
		return Plugin_Continue;
	}	
	
	// special day has been called but is not running or active
	// if a player joins at this point depending on sd we need
	// to repsawn and init them
	char team_str[3];
	GetCmdArg(1, team_str, sizeof(team_str));
	int team = StringToInt(team_str);
	
	if (!is_valid_client(client) || !(team == CS_TEAM_CT || team == CS_TEAM_T))
	{	
		return Plugin_Continue; 
    }	
	
	// less than 20 seconds set them up
	if(sd_state == sd_started)
	{
		if(!IsPlayerAlive(client))
		{
			CS_RespawnPlayer(client);
			sd_player_init(client);
		}
	}
	
	// sd is running (20 secs in cant join) for most sds
	else if(sd_state == sd_active)
	{
		if(special_day == zombie_day)
		{
			CreateTimer(3.0, ReviveZombie, client);
		}
		
		else if(special_day == gungame_day)
		{
			CreateTimer(3.0, ReviveGunGame, client);
		}
		
		else if(special_day == deathmatch_day)
		{
			CreateTimer(3.0, ReviveDeathMatch, client);
		}
		
		else if(special_day == scoutknife_day)
		{
			CreateTimer(3.0, ReviveScout, client);
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


public Action player_connect_event(Handle event, const String:name[], bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	// if valid and sd is active toggle noblock on them
	if(is_valid_client(client) && sd_state != sd_inactive)
	{
		unblock_client(client);
	}
}

public Action PlayerDisconnect_Event(Handle event, const String:name[], bool dontBroadcast)
{

	int client = GetClientOfUserId(GetEventInt(event,"userid"));


	// if the tank disconnects
	if(client == tank && sd_state == sd_inactive)
	{
		SaveTeams(true);

		int rand = GetRandomInt( 0, validclients - 1 );
		tank = game_clients[rand]; // select the lucky client
	}
	
	// if the patient_zero disconnects
	else if(client == patient_zero && sd_state == sd_inactive)
	{
		SaveTeams(false);

		int rand = GetRandomInt( 0, validclients - 1 );
		patient_zero = game_clients[rand]; // select the lucky client
	}
	
	// if the patient_zero disconnects
	else if(client == patient_zero && sd_state == sd_active)
	{
		SaveTeams(false);

		int rand = GetRandomInt( 0, validclients - 1 );
		patient_zero = game_clients[rand]; // select the lucky client
		CS_SwitchTeam(patient_zero, CS_TEAM_T);
		MakeZombie(patient_zero);
		SetEntityHealth(patient_zero, 1000 * (validclients+1) );
		SetEntityRenderColor(patient_zero, 255, 0, 0, 255);	
		PrintCenterTextAll("%N is patient zero!", patient_zero);
		
	}	
	
	
	// tankday is allready active
	else if(client == tank && sd_state == sd_active)
	{
	
	
		// restore the hp
		for(new i = 1; i < MaxClients; i++)
			if(IsClientInGame(i)) // check the client is in the game
				SetEntityHealth(i, 100);	
	
	
	
		// while the current disconnecter
		while(tank == client)
		{
			int rand = GetRandomInt( 0, (validclients-1) );
			tank = game_clients[rand]; // select the lucky client
		}
		
		

		SetEntityHealth(tank, 250 * GetClientCount(true));
		
		
		
		//reroll the tank restore hp
		CS_SwitchTeam(tank,CS_TEAM_CT);
		SetEntityRenderColor(tank, 255, 0, 0, 255);
		PrintCenterTextAll("%N is the TANK!", tank);
	
	}

	return Plugin_Handled;
}





#if defined USE_CUSTOM_ZOMBIE_MODEL
bool zombie_model_success = false;
const int ZOMBIE_MODEL_LIST_SIZE = 33;
new const String:zombie_model_list[ZOMBIE_MODEL_LIST_SIZE][] = {
"models/player/slow/aliendrone/slow_alien.dx80.vtx",
"models/player/slow/aliendrone/slow_alien.dx90.vtx",
"models/player/slow/aliendrone/slow_alien.mdl",
"models/player/slow/aliendrone/slow_alien.phy",
"models/player/slow/aliendrone/slow_alien.sw.vtx",
"models/player/slow/aliendrone/slow_alien.vvd",
"models/player/slow/aliendrone/slow_alien.xbox.vtx",
"models/player/slow/aliendrone/slow_alien_head.dx80.vtx",
"models/player/slow/aliendrone/slow_alien_head.dx90.vtx",
"models/player/slow/aliendrone/slow_alien_head.mdl",
"models/player/slow/aliendrone/slow_alien_head.phy",
"models/player/slow/aliendrone/slow_alien_head.sw.vtx",
"models/player/slow/aliendrone/slow_alien_head.vvd",
"models/player/slow/aliendrone/slow_alien_head.xbox.vtx",
"models/player/slow/aliendrone/slow_alien_hs.dx80.vtx",
"models/player/slow/aliendrone/slow_alien_hs.dx90.vtx",
"models/player/slow/aliendrone/slow_alien_hs.mdl",
"models/player/slow/aliendrone/slow_alien_hs.phy",
"models/player/slow/aliendrone/slow_alien_hs.sw.vtx",
"models/player/slow/aliendrone/slow_alien_hs.vvd",
"models/player/slow/aliendrone/slow_alien_hs.xbox.vtx",
"materials/models/player/slow/aliendrone/drone_arms.vmt",
"materials/models/player/slow/aliendrone/drone_arms.vtf",
"materials/models/player/slow/aliendrone/drone_arms_normal.vtf",
"materials/models/player/slow/aliendrone/drone_head.vmt",
"materials/models/player/slow/aliendrone/drone_head.vtf",
"materials/models/player/slow/aliendrone/drone_head_normal.vtf",
"materials/models/player/slow/aliendrone/drone_legs.vmt",
"materials/models/player/slow/aliendrone/drone_legs.vtf",
"materials/models/player/slow/aliendrone/drone_legs_normal.vtf",
"materials/models/player/slow/aliendrone/drone_torso.vmt",
"materials/models/player/slow/aliendrone/drone_torso.vtf",
"materials/models/player/slow/aliendrone/drone_torso_normal.vtf"
};

// custom alien zombie model 
bool CacheCustomZombieModel()
{
	// these apparently just fail silently...
	for (int i = 0; i < ZOMBIE_MODEL_LIST_SIZE; i++)
	{
		AddFileToDownloadsTable(zombie_model_list[i]);
	}


	for (int i = 0; i < ZOMBIE_MODEL_LIST_SIZE; i++)
	{
		if(!PrecacheModel(zombie_model_list[i]))
		{
			return false;
		}
	}

	return true;
}
#endif

int fog_ent;
Menu sd_menu;
Menu sd_list_menu;

// Clean up our variables just to be on the safe side
public OnMapStart()
{
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

int sd_winner = -1;

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
			PrintToChatAll("%s Tank day over", SPECIALDAY_PREFIX);
			RestoreTeams();
			SetEntityRenderColor(tank, 255, 255, 255, 255);
			tank = -1;	
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
		
		case scoutknife_day:
		{
			int cli = get_client_max_kills();
			
			if(IsClientConnected(cli) && IsClientInGame(cli) && is_on_team(cli))
			{
				PrintToChatAll("%s %N won scoutknifes", SPECIALDAY_PREFIX, cli);
			}
			sd_winner = cli;
		}
		
		case deathmatch_day:
		{
			int cli = get_client_max_kills();
			
			if(IsClientConnected(cli) && IsClientInGame(cli) && is_on_team(cli))
			{
				PrintToChatAll("%s %N won deathmatch", SPECIALDAY_PREFIX, cli);
			}
			sd_winner = cli;
		}
		
		
		// need to turn off ignore round win here :)
		case gungame_day:
		{
			enable_round_end();
		}
		
		case zombie_day:
		{
			RestoreTeams();
			patient_zero = -1;
			AcceptEntityInput(fog_ent, "TurnOff");
		}
		
		default:
		{
			ThrowNativeError(SP_ERROR_NATIVE, "special day %d not handled in round_end",special_day);
		}
	}
	
	
	if(ff == true)
	{
		disable_friendly_fire();
	}	
	
#if defined CT_BAN
	if(sd_state != sd_inactive && check_command_exists("sm_ctban"))
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				CTBan_UnForceCT(i);
			}
		}
	}
#endif


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
#if defined GANGS	
	if(sd_state == sd_active && check_command_exists("sm_gang"))
	{
		ServerCommand("sm plugins load hl_gangs.smx")
	}
#endif
	fr = false;
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
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			ShowSyncHudText(i, h_hud_text, buf);
		}
	}
	
	CloseHandle(h_hud_text);
	
	return Plugin_Continue;
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
	if(action == MenuAction_Select) 
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
		
		// finally give the picked gun
		GivePlayerItem(client, gun_give_list[param2]);

		
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


// make team damage the same as cross team damage

public Action OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{

	if(no_damage == true)
	{
		damage = 0.0;
		return Plugin_Changed;
	}



	if(special_day == dodgeball_day)
	{
		// any damage kills 
		// prevents cheaters from healing 
		damage = 500.0;
		return Plugin_Changed;
	}

	
	else if(special_day == zombie_day)
	{
		if (!is_valid_client(attacker)) { return Plugin_Continue; }
		
		if(GetClientTeam(victim) == CS_TEAM_T)
		{
			CreateKnockBack(victim, attacker, damage);
		}
		
		else if(GetClientTeam(attacker) == CS_TEAM_T)
		{
			// patient zero instantly kills
			if(attacker == patient_zero)
			{
				damage = 120.0;
				return Plugin_Changed;
			}
		}
	}
	
	/* Make friendly fire damage the same as real damage. */
	if(ff == true)
	{
		if (FFA_CONDITION(victim, attacker) && inflictor == attacker)
		{
			damage /= 0.35;
			return Plugin_Changed;
		}	
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


float death_cords[64][3];
// int player_kills[64] =  { 0 }; ^ defined above
public Action OnPlayerDeath(Handle event, const String:name[], bool dontBroadcast)
{
	static int ct_count = 0;
	
	// hook a death
	if(hp_steal == true)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		//PrintToChatAll("[SM] Juggernaut kill"); // debug
		// give the killer +100 hp
		int health = GetClientHealth(attacker);
		health += 100;
		SetEntityHealth(attacker, health);
	}
	
	
	if(special_day == zombie_day)
	{
		// test that first time hitting one ct
		int last_man;
		int cur_count = get_alive_team_count(CS_TEAM_CT, last_man);
		bool last_man_triggered  = (cur_count == 1) && (cur_count != ct_count)
		ct_count = cur_count;
		if(last_man_triggered)
		{
			// LAST MAN STANDING
			PrintCenterTextAll("%N IS LAST MAN STANDING!", last_man);
			SetEntityHealth(last_man, 350);
			int weapon = GetPlayerWeaponSlot(last_man, CS_SLOT_SECONDARY);
			set_clip_ammo(last_man,weapon, 999);
			weapon =  GetPlayerWeaponSlot(last_man, CS_SLOT_PRIMARY);
			set_clip_ammo(last_man,weapon, 999);
		}
		
		
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		
		int team = GetClientTeam(victim);
		// if victim is a ct -> become a zombie
		if(team == CS_TEAM_CT)
		{
			float cords[3];
			GetClientAbsOrigin(victim, cords);
			
			death_cords[victim] = cords;
			death_cords[victim][2] -= 45.0; // account for player eyesight height
			CreateTimer(0.5,NewZombie, victim)
		}
		
		// if victim is a t -> respawn on 'patient zero' if alive
		else if(team == CS_TEAM_T)
		{
			if(IsPlayerAlive(patient_zero))
			{
				CreateTimer(3.0, ReviveZombie, victim);
			}			
		}
	}
	
	else if(special_day == scoutknife_day)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		
		CreateTimer(3.0, ReviveScout, victim);
		
		player_kills[attacker]++;
	}
	
	else if(special_day == deathmatch_day)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		
		CreateTimer(3.0, ReviveDeathMatch, victim);
		
		player_kills[attacker]++;
	}	
	
	else if(special_day == gungame_day)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		int victim = GetClientOfUserId(GetEventInt(event, "userid"));
		
		// if they die by some silly means then ignore and resp
		if(!(attacker > 0 && victim <= MaxClients))
		{
			CreateTimer(3.0, ReviveGunGame, victim);
			return Plugin_Handled;
		}
		
		
		char weapon_name[64];
		GetClientWeapon(attacker, weapon_name, sizeof(weapon_name));
		
		// kill with current weapon
		if(gun_counter[attacker] < GUNGAME_SIZE && StrEqual(weapon_name, guns_list[gun_counter[attacker]]))
		{
			gun_counter[attacker]++;
			if(gun_counter[attacker] >= GUNGAME_SIZE)
			{
				// end the round
				gun_counter[attacker] = 0;
				
				// renable loss conds
				enable_round_end();
				PrintToChatAll("%s %N won gungame", SPECIALDAY_PREFIX, attacker);
				
				
				sd_winner = attacker;
				slay_all();
			}
			
			else // still going
			{
				// update gun
				GiveGunGameGun(attacker);
			}
			
		}
		
		// killed with knife dec the enemies weapon
		else if(StrEqual(weapon_name,"weapon_knife"))
		{
			gun_counter[victim]--;
			if(gun_counter[victim] < 0)
			{
				gun_counter[victim] = 0;
			}
		}
		
		
		
		
		// start a respawn for the dead player :)
		CreateTimer(3.0, ReviveGunGame, victim);
		
		
	}
	return Plugin_Continue;
}

public Action ReviveScout(Handle Timer, int client)
{
	CS_RespawnPlayer(client);
	sd_player_init(client);
}


public Action ReviveDeathMatch(Handle Timer, int client)
{
	CS_RespawnPlayer(client);
	sd_player_init(client);
}

public Action NewZombie(Handle timer, int client)
{
	if(special_day != zombie_day || !IsClientInGame(client))
	{
		return;
	}

	
	CS_RespawnPlayer(client);
	TeleportEntity(client, death_cords[client], NULL_VECTOR, NULL_VECTOR);
	CS_SwitchTeam(client, CS_TEAM_T);
	MakeZombie(client);
	EmitSoundToAll("npc/zombie/zombie_voice_idle1.wav");
}

public Action ReviveZombie(Handle timer, int client)
{
	if(special_day != zombie_day || !IsClientInGame(client) || IsPlayerAlive(client))
	{
		return;
	}
	
	if(IsPlayerAlive(patient_zero))
	{	
		// pull cords so we can tele player to patient zero
		float cords[3];
		GetClientAbsOrigin(patient_zero, cords);
		CS_RespawnPlayer(client);
		TeleportEntity(client, cords, NULL_VECTOR, NULL_VECTOR);
		CS_SwitchTeam(client, CS_TEAM_T);
		MakeZombie(client);
	}				
}



public int SdHandler(Menu menu, MenuAction action, int client, int param2)
{
	if(sd_state != sd_inactive) // if sd is active dont allow two
	{
		if(client != 0)
		{
			PrintToChat(client, "%s You can't do two special days at once!", SPECIALDAY_PREFIX);
		}
		return -1;
	}


	if(action == MenuAction_Select)
	{
		sdtimer = 20;

		// special done begun but not active
		sd_state = sd_started; 
		
		PrintToConsole(client, "You selected item: %d", param2); /* Debug */
		
		
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
		unblock_all_clients();
		
		

		switch(param2)
		{
	
			case friendly_fire_day: //ffd
			{ 
				special_day = friendly_fire_day;
				PrintToChatAll("%s Friendly fire day started.", SPECIALDAY_PREFIX);
				
				sd_player_init_fptr = ffd_player_init;
				
				
				// allow player to pick for 20 seconds
				PrintToChatAll("%s Please wait 20 seconds for friendly fire to be enabled", SPECIALDAY_PREFIX);
			}
			
			case tank_day: // tank day
			{
				SaveTeams(true);
				
				if(validclients == 0)
				{
					PrintToChatAll("%s You are all freekillers!", SPECIALDAY_PREFIX);
					return -1;
				}
				
				special_day = tank_day;
				PrintToChatAll("%s Tank day started", SPECIALDAY_PREFIX);
				
				sd_player_init_fptr = tank_player_init;
				
				int rand = GetRandomInt( 0, (validclients-1) );
				tank = game_clients[rand]; // select the lucky client
			}
			
			case juggernaut_day: //ffdg
			{
				hp_steal = true; 
				special_day = juggernaut_day;
				PrintToChatAll("%s Friendly fire juggernaut day  started.", SPECIALDAY_PREFIX);
				
				sd_player_init_fptr = ffdg_player_init;
				
				
				// allow player to pick for 20 seconds
				PrintToChatAll("%s Please wait 20 seconds for friendly fire to be enabled", SPECIALDAY_PREFIX);
				
				PrintToConsole(client, "Timer started at : %d", sdtimer);
			}
			
			case fly_day: // flying day
			{
				special_day = fly_day;
				PrintToChatAll("%s Sky wars started", SPECIALDAY_PREFIX);
				sd_player_init_fptr = flying_player_init;
			}
			
			case hide_day: // hide and seek day
			{
				PrintToChatAll("%s Hide and seek day started", SPECIALDAY_PREFIX);
				PrintToChatAll("Ts must hide while CTs seek");
				special_day = hide_day;
				
				CreateTimer(1.0,MoreTimers);
				
				sd_player_init_fptr = hide_player_init;
			}
			
			
			case dodgeball_day: // dodgeball day
			{
				PrintToChatAll("%s Dodgeball day started", SPECIALDAY_PREFIX);
				CreateTimer(1.0, RemoveGuns);
				special_day = dodgeball_day;
			
				sd_player_init_fptr = dodgeball_player_init;
			}
			
			
			
			case grenade_day: // grenade day
			{
				PrintToChatAll("%s grenade day started", SPECIALDAY_PREFIX);
				CreateTimer(1.0, RemoveGuns);
				special_day = grenade_day;
			
				sd_player_init_fptr = grenade_player_init;
			}
				
			case zombie_day: // zombie day
			{
				
				SaveTeams(false);

			
				
				PrintToChatAll("%s zombie day started", SPECIALDAY_PREFIX);
				CreateTimer(1.0, RemoveGuns); 
				special_day = zombie_day;
			
				int rand = GetRandomInt( 0, (validclients-1) );
				
				// select the first zombie
				patient_zero = game_clients[rand]; 
			
				sd_player_init_fptr = zombie_player_init;
			}
			
			case gungame_day: // gun game
			{
				PrintToChatAll("%s gun game day started", SPECIALDAY_PREFIX);
				
				special_day = gungame_day;
				
				// reset the gun counter
				for (int i = 0; i < MaxClients; i++)
				{
					gun_counter[i] = 0;
				}
				
				sd_player_init_fptr = gun_game_player_init;
			}
			
			case knife_day: // knife day
			{
				PrintToChatAll("%s knife day started", SPECIALDAY_PREFIX);
				
				special_day = knife_day;
				sd_player_init_fptr = knife_player_init;
			}
			
			case scoutknife_day: // scout knife day
			{
				PrintToChatAll("%s scout knife day started", SPECIALDAY_PREFIX);
				special_day = scoutknife_day;
				sd_player_init_fptr = scout_player_init;
				
				// reset player kill
				for (int i = 0; i < 64; i++)
				{
					player_kills[i] = 0;
				}
			}
			
			case deathmatch_day: // deathmatch
			{
				PrintToChatAll("%s deathmatch day started", SPECIALDAY_PREFIX);
				special_day = deathmatch_day;
				sd_player_init_fptr = deathmatch_player_init;
				
				// reset player kill
				for (int i = 0; i < 64; i++)
				{
					player_kills[i] = 0;
				}		
			}
		}

		// call the initial init for all players on the function pointers we just set
		for (int i = 1; i < MaxClients; i++)
		{
			sd_player_init(i);
		}
	}
	
	else if (action == MenuAction_Cancel) 
	{
			PrintToServer("Client %d's menu was cancelled. Reason: %d",client,param2);
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
		
		default:
		{
			ThrowNativeError(SP_ERROR_NATIVE, "attempted to start invalid sd %d", special_day);
		}
	}
}

public void make_invis_t()
{
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(GetClientTeam(i) == CS_TEAM_T)
			{
				// make players invis
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, 0, 0, 0, 0);
			}
		}
	}	
}

public void StartDeathMatch()
{
	start_round_delay(60 * 2);
	CreateTimer(1.0, RemoveGuns);
	enable_friendly_fire();
}


public void StartScout()
{
	start_round_delay(60 * 2);
	CreateTimer(1.0, RemoveGuns);
	enable_friendly_fire();
}

public void GiveGunGameGun(int client)
{
	strip_all_weapons(client);
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "item_assaultsuit");
	GivePlayerItem(client, guns_list[gun_counter[client]]);
	PrintToChat(client, "%s Current level: %s", SPECIALDAY_PREFIX, guns_list[gun_counter[client]]);
}



public Action ReviveGunGame(Handle timer, int client)
{
	if(special_day != gungame_day)
	{
		return;
	}
	
	if(IsClientInGame(client))
	{
		CS_RespawnPlayer(client);
		GiveGunGameGun(client);
	}		
}

public void StartGunGame()
{
	enable_friendly_fire();
	PrintCenterTextAll("Gun game active");
	disable_round_end();
	CreateTimer(1.0, RemoveGuns);
}


public void StartKnife()
{
	enable_friendly_fire();
	PrintCenterTextAll("Knife day active");
	CreateTimer(1.0, RemoveGuns);
}


public void set_zombie_speed(int client)
{
	set_client_speed(client, 1.2);
	SetEntityGravity(client, 0.4);
}

public void MakeZombie(int client)
{
	strip_all_weapons(client);
	set_zombie_speed(client)
	SetEntityHealth(client, 250);
	GivePlayerItem(client, "weapon_knife");
	
	#if defined USE_CUSTOM_ZOMBIE_MODEL
		if (zombie_model_success)
		{
			SetEntityModel(client, "models/player/slow/aliendrone/slow_alien.mdl");
		}
		
		else
		{
			SetEntityModel(client, "models/zombie/classic.mdl");
		}
	#else
		SetEntityModel(client, "models/zombie/classic.mdl");
	#endif
	
}

public void StartZombie()
{

	// swap everyone other than the patient zero to the t side
	// if they were allready in ct or t
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(is_on_team(i))
			{
				CS_SwitchTeam(i,CS_TEAM_CT);
			}
		}
	}


	CS_SwitchTeam(patient_zero, CS_TEAM_T);
	MakeZombie(patient_zero);
	SetEntityHealth(patient_zero, 1000 * (validclients+1) );
	SetEntityRenderColor(patient_zero, 255, 0, 0, 255);	
	PrintCenterTextAll("%N is patient zero!", patient_zero);
	AcceptEntityInput(fog_ent, "TurnOn");
}

public void StartGrenade()
{
	enable_friendly_fire();
	
	// set everyones hp to 250
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i)) // check the client is in the game
		{
			if(IsPlayerAlive(i))  // check player is dead
			{
				if(is_on_team(i)) // check not in spec
				{
					SetEntityHealth(i,250);
				}
			}
		}	
	}	
}

public void StartHide()
{
	// renable movement
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT) // check the client is in the game
		{
			set_client_speed(i, 1.0);
			SetEntityHealth(i,500); // set health to 500
		}
	}
	
	// hide everyone again just incase
	make_invis_t(); 
	
	// callbakc incase shit fucks with the color
	CreateTimer(5.0, hide_timer_callback);

}



public void StartFly()
{
	enable_friendly_fire();
}

public void StartTank()
{	
	SetEntityHealth(tank, 250 * GetClientCount(true));
	
	
	
	
	// swap everyone other than the tank to the t side
	// if they were allready in ct or t
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(is_on_team(i))
			{
				CS_SwitchTeam(i,CS_TEAM_T);
			}
		}
	}
	
	CS_SwitchTeam(tank,CS_TEAM_CT);
	SetEntityRenderColor(tank, 255, 0, 0, 255);
	PrintCenterTextAll("%N is the TANK!", tank);
}



public void StartFFD()
{
	PrintToChatAll("%s Friendly fire enabled",SPECIALDAY_PREFIX);
	
	//implement a proper printing function lol
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	
	enable_friendly_fire();
}


StartJuggernaut()
{
	PrintToChatAll("%s Friendly fire enabled",SPECIALDAY_PREFIX);
	
	enable_friendly_fire();
}

public void StartDodgeball()
{

	PrintCenterTextAll("Dodgeball active!");
	enable_friendly_fire();
	
	// right now we need to enable all our callback required
	// 1. give new flashbangs every second (needs a timer callback like moreTimers) (done)
	// 2. block all flashes (done)
	// 3. hook hp changes so we can prevent heals (done (kinda just cheats and instant kills on any damage))
	// 4. disable gun pickups (done )
	
	
	
	// give an initial flashbang
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i)) // check the client is in the game
		{
			if(IsPlayerAlive(i))  // check player is dead
			{
				if(is_on_team(i)) // check not in spec
				{
					SetEntityHealth(i,1);
					SetEntProp(i, Prop_Data, "m_ArmorValue", 0.0);  // remove armor 
				}
			}
		}	
	}
}





// handle nade projectiles for a sd create timers to remove them :)
public OnEntityCreated(int entity, const String:classname[])
{
	if(special_day == dodgeball_day)
	{
		if (StrEqual(classname, "flashbang_projectile"))
		CreateTimer(1.4, GiveFlash, entity);
	}
	
	else if(special_day == grenade_day)
	{
		if (StrEqual(classname, "hegrenade_projectile"))
		CreateTimer(1.4, GiveGrenade, entity);
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

public Action GiveFlash(Handle timer, any entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
	

	// give person who threw a flash after a second +  set hp to one
	if(special_day != dodgeball_day) 
	{ 
		return; 
	}
	
	
	if(IsClientInGame(client))
	{
		if(GetClientTeam(client) == CS_TEAM_CT || GetClientTeam(client) ==  CS_TEAM_T && IsPlayerAlive(client) )
		{
			strip_all_weapons(client);
			GivePlayerItem(client, "weapon_flashbang");
			SetEntityHealth(client,1);
		}
	}
	
}


public Action GiveGrenade(Handle timer, any entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	// giver person who threw a flash after a second +  set hp to one
	
	if(special_day != grenade_day) { return; }
	
	
	
	if(IsClientInGame(client))
	{
		if(GetClientTeam(client) == CS_TEAM_CT || GetClientTeam(client) ==  CS_TEAM_T && IsPlayerAlive(client) )
		{
			strip_all_weapons(client);
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}	
}

// prevent additional weapon pickups

public Action OnWeaponEquip(int client, int weapon) 
{
	if(special_day == dodgeball_day)
	{
		char weapon_string[32];
		GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 
		if(!StrEqual(weapon_string,"weapon_flashbang"))
		{
			return Plugin_Handled;
		}
	}
	
	else if(special_day == grenade_day)
	{
		char weapon_string[32];
		GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 
		if(!StrEqual(weapon_string,"weapon_hegrenade"))
		{
			return Plugin_Handled;
		}
	}
	
	else if(special_day == knife_day)
	{
		char weapon_string[32];
		GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 
		if(!StrEqual(weapon_string,"weapon_knife"))
		{
			return Plugin_Handled;
		}
	}

	else if(special_day == scoutknife_day)
	{
		char weapon_string[32];
		GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 
		if(!(StrEqual(weapon_string,"weapon_scout") || StrEqual(weapon_string,"weapon_knife")))
		{
			return Plugin_Handled;
		}
	}

	else if(special_day == zombie_day && sd_state == sd_active)
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
	
	return Plugin_Continue;
}



// handles movement changes off a ladder so they are what they should be for an sd

MoveType player_last_movement_type[64] = {MOVETYPE_WALK};

const int SPECIAL_MOVE_SIZE = 5;
// CANT DECLARE CONST CAUSE HECK KNOWS
SpecialDay special_move[SPECIAL_MOVE_SIZE] = { zombie_day, dodgeball_day, fly_day, grenade_day, scoutknife_day };

public Action check_movement(Handle Timer)
{
	// no sd running dont care
	if(sd_state == sd_inactive)
	{
		return Plugin_Continue;
	}
	



	for (int i = 0; i < SPECIAL_MOVE_SIZE; i++)
	{
		if(special_day == special_move[i])
		{
			
			for (int client = 1; client < MaxClients; client++)
			{
				// not interested is they are dead or not here
				if(IsClientInGame(client) && is_on_team(client) && IsPlayerAlive(client))
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
								if(GetClientTeam(client) == CS_TEAM_T)
								{
									set_zombie_speed(client);
								}
							}
							
							case fly_day:
							{
								client_fly(client);
							}

							// we dont have team swaps or weapon picks on these days
							// so just call the default handler :)
							default: 
							{
								sd_player_init(client);
							}
						}
					}
					
					//cache the last movement type
					player_last_movement_type[client] = cur_type
				}
			}
			
		}
	}
	
	return Plugin_Continue;
}