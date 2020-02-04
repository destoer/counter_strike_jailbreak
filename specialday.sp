#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <entity>
#include "colorvariables.inc"

/*
 TODO
 add infinite ammo for last man standing!
 currently just gives a ton in current ammo
*/

// if running gangs or ct bans with this define to prevent issues :)
#define GANGS
#define CT_BAN


#if defined CT_BAN
#undef REQUIRE_PLUGIN
#include "ctban.inc"
#define REQUIRE_PLUGIN
bool ctban_running = false;
#endif

#if defined GANGS
bool gang_running = false;
#endif


#define SPECIALDAY_PREFIX "\x04[Vi Special Day]\x07F8F8FF"
#define FFA_CONDITION(%1,%2) (1 <= %1 <= MaxClients && 1 <= %2 <= MaxClients && %1 != %2 && GetClientTeam(%1) == GetClientTeam(%2))

// set up sv_cheats in server config so we can add test bots lol

// requires mp_autokick set to false (0)
 

// sadly we cant scope these
enum SpecialDay
{
	normal_day,
	tank_day,
	dodgeball_day,
	fly_day,
	hide_day,
	friendly_fire_day,
	grenade_day,
	zombie_day
};


enum SdState
{
	sd_started,
	sd_active,
	sd_inactive
};

SpecialDay special_day = normal_day;
SdState sd_state = sd_inactive;

// state toggles
bool fr = false; // are people frozen
bool ff = false; // is friendly fire on?
bool no_damage = false; // is damage disabled
bool hp_steal = false; // is hp steal on
int sdtimer = 20; // timer for sd



// sd specific vars
int tank = -1; // hold client id of the tank

int patient_zero = -1;

// team saves
int validclients = 0; // number of clients able to partake in sd
int game_clients[64];
int teams[64]; // should store in a C struct but cant


Handle g_hFriendlyFire; // mp_friendlyfire var
Handle g_autokick; // turn auto kick off for friednly fire


// backups
// (unused)
//new b_hFriendlyFire; // mp_friendlyfire var
//new b_autokick; // turn auto kick off for friednly fire

// gun removal
new g_WeaponParent;

#define VERSION "1.4.4"

public Plugin myinfo = {
	name = "Jailbreak Special Days",
	author = "destoer",
	description = "special days for jailbreak",
	version = VERSION,
	url = "https://github.com/destoer/css_jailbreak_plugins"
};


public OnPluginStart() 
{

	HookEvent("player_death", OnPlayerDeath,EventHookMode_Post);


	// register our special day console command	
	RegAdminCmd("sd", command_special_day, ADMFLAG_BAN);
	RegAdminCmd("sd_cancel", command_cancel_special_day, ADMFLAG_BAN);
	// freeze stuff
	RegAdminCmd("fr", Freeze,ADMFLAG_BAN);
	RegAdminCmd("uf",UnFreeze,ADMFLAG_BAN);
	
	RegConsoleCmd("sdv", sd_version);

	
	// gun removal
	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

	
	// hook disonnect incase a vital member leaves
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
	
	

#if defined GANGS
	gang_running = GetCommandFlags("sm_gang") != INVALID_FCVAR_FLAGS;
#endif
	
#if defined CT_BAN	
	ctban_running = GetCommandFlags("sm_ctban") != INVALID_FCVAR_FLAGS;
#endif
	
	g_hFriendlyFire = FindConVar("mp_friendlyfire"); // get the friendly fire var
	g_autokick = FindConVar("mp_autokick");
	SetConVarBool(g_autokick, false);	
	//b_autokick = GetConVarBool(g_autokick);
	//b_hFriendlyFire = GetConVarBool(g_hFriendlyFire);
	
	HookEvent("round_start", OnRoundStart); // reset variables after a sd
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_team", join_team, EventHookMode_Post);
	
	
	for(int i = 1;i < MaxClients;i++)
	{
		if(IsValidClient(i))
		{
			OnClientPutInServer(i);
		}
	}

}


public Action sd_version(int client, int args)
{
	PrintToChat(client, "%s SD VERSION: %s",SPECIALDAY_PREFIX, VERSION);
}


public Action WeaponMenu(int client)
{
	Panel guns = new Panel();
	guns.SetTitle("Weapon Selection");
	guns.DrawItem("AK47");
	guns.DrawItem("M4A1");
	guns.DrawItem("AWP");
	guns.DrawItem("SHOTGUN");
	guns.DrawItem("P90");
	guns.DrawItem("M249");
	guns.Send(client,WeaponHandler , 20);

	delete guns;
}

public Action hide_timer_callback(Handle timer)
{
	make_invis_t();

	if(special_day == hide_day)
	{
		CreateTimer(5.0, hide_timer_callback);
	}
}

public Action join_team(Handle event, const String: name[], bool bDontBroadcast)
{	
	// sd is running (20 secs in cant join)
	// or not active so we dont care
	if(sd_state == sd_inactive || sd_active)
	{
		return Plugin_Continue;
	}
	
	// special day has been called but is not running
	// if a player joins at this point we need to give them 
	// the same action as in the main handler
	int client = GetClientOfUserId(GetEventInt(event, "userid")); 
	if (!IsValidClient(client))
	{   
        return Plugin_Continue; 
    }
	
	int team = GetClientTeam(client)
	if(team != CS_TEAM_CT || team != CS_TEAM_T)
	{
		return Plugin_Continue;
	}	
	
	// if they are dead revive them
	if(!IsPlayerAlive(client))
	{
		CS_RespawnPlayer(client)
	}
	
	
	switch(special_day)
	{
		case friendly_fire_day:
		{
			WeaponMenu(client); 
		}
		
		case tank_day:
		{
			WeaponMenu(client); 
		}		
		
		case fly_day:
		{
			SetClientSpeed(client,2.5);
			SetEntityMoveType(client, MOVETYPE_FLY); // should add the ability to toggle with a weapon switch
															// to make navigation easy (as brushing on the floor sucks)
			GivePlayerItem(client, "weapon_m3"); // all ways give a deagle
			GivePlayerItem(client, "item_assaultsuit");		
		}
		
		case dodgeball_day:
		{
			SetEntityHealth(client, 1); // set health to 1
			StripAllWeapons(client); // remove all the players weapons
			GivePlayerItem(client, "weapon_flashbang");
			SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);  	
		}
		
		case grenade_day:
		{
			StripAllWeapons(client); // remove all the players weapons
			GivePlayerItem(client, "weapon_hegrenade");
			SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);  	
		}
		
		case hide_day:
		{
			if(team == CS_TEAM_T)
			{
				// make players invis
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 0, 0, 0, 0);	
			}
						
			else if(team == CS_TEAM_CT)
			{
						
				StripAllWeapons(client);
				GivePlayerItem(client, "weapon_m3"); // give a shotty
				// give em shit tons of ammo
				int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
				SetReserveAmmo(client , weapon, 999)
				// freeze the player in place
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);			
			}
		}
		
		case zombie_day:
		{
			WeaponMenu(client);
		}
		
		case normal_day:
		{
			// do nothing
		}
		

		
		default:
		{
			ThrowNativeError(SP_ERROR_NATIVE, "special day %d not handled in join_team",special_day);
		}
	
	}
	


	return Plugin_Continue;
}

// freeze all players and turn ff on
public Action Freeze(client,args)
{
	if(sd_state != sd_inactive) { 
		PrintToChat(client,"%s Can't freeze players during Special Day", SPECIALDAY_PREFIX);
		return Plugin_Handled; 
		
	} // dont allow freezes during an sd

	fr = true;
	for(int i = 1; i < MaxClients; i++)
	{ 
		if(IsClientInGame(i))
		{
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 0.0);
		}
	
	}
	no_damage = true;
	return Plugin_Handled;
}

// unfreeze all players off
public Action UnFreeze(client,args)
{
	if(sd_state != sd_inactive) { 
		PrintToChat(client,"%s Can't unfreeze players during Special Day", SPECIALDAY_PREFIX);
		return Plugin_Handled; 		
	} // dont allow freezes during an sd
	if(fr == false) {
		PrintToChat(client,"%s Can't unfreeze if not already frozen", SPECIALDAY_PREFIX);
		return Plugin_Handled; 
	} // can only unfreeze if frozen
	fr = false;
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
		}
	
	}
	no_damage = false;
	PrintCenterTextAll("Game play active");
	return Plugin_Handled;
}


bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
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
	new client;
	new clientid;
	
	clientid = GetEventInt(event,"userid");
	client = GetClientOfUserId(clientid);

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
			new rand = GetRandomInt( 0, (validclients-1) );
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




bool use_custom_zombie_model = false;

// custom alien zombie model (will use stock hl2 zombie if it cant find it)
public bool CacheCustomZombieModel()
{
// these apparently just fail silently...
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien.dx80.vtx")
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien.dx90.vtx");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien.mdl");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien.phy");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien.vvd");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien.sw.vtx");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien.xbox.vtx");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_head.dx80.vtx");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_head.dx90.vtx");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_head.mdl");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_head.phy");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_head.sw.vtx");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_head.vvd");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_head.xbox.vtx");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_hs.dx80.vtx");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_hs.dx90.vtx");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_hs.mdl");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_hs.phy");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_hs.sw.vtx");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_hs.vvd");
AddFileToDownloadsTable("models/player/slow/aliendrone/slow_alien_hs.xbox.vtx");
AddFileToDownloadsTable("materials/models/player/slow/aliendrone/drone_arms.vmt");
AddFileToDownloadsTable("materials/models/player/slow/aliendrone/drone_arms.vtf");
AddFileToDownloadsTable("materials/models/player/slow/aliendrone/drone_arms_normal.vtf");
AddFileToDownloadsTable("materials/models/player/slow/aliendrone/drone_head.vmt");
AddFileToDownloadsTable("materials/models/player/slow/aliendrone/drone_head.vtf");
AddFileToDownloadsTable("materials/models/player/slow/aliendrone/drone_head_normal.vtf");
AddFileToDownloadsTable("materials/models/player/slow/aliendrone/drone_legs.vmt");
AddFileToDownloadsTable("materials/models/player/slow/aliendrone/drone_legs.vtf");
AddFileToDownloadsTable("materials/models/player/slow/aliendrone/drone_legs_normal.vtf");
AddFileToDownloadsTable("materials/models/player/slow/aliendrone/drone_torso.vmt");
AddFileToDownloadsTable("materials/models/player/slow/aliendrone/drone_torso.vtf");
AddFileToDownloadsTable("materials/models/player/slow/aliendrone/drone_torso_normal.vtf");
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien.dx80.vtx")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien.dx90.vtx")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien.mdl")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien.phy")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien.sw.vtx")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien.vvd")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien.xbox.vtx")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_head.dx80.vtx")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_head.dx90.vtx")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_head.mdl")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_head.phy")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_head.sw.vtx")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_head.vvd")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_head.xbox.vtx")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_hs.dx80.vtx")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_hs.dx90.vtx")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_hs.mdl")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_hs.phy")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_hs.sw.vtx")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_hs.vvd")) return false;
if(!PrecacheModel("models/player/slow/aliendrone/slow_alien_hs.xbox.vtx")) return false;
if(!PrecacheModel("materials/models/player/slow/aliendrone/drone_arms.vmt")) return false;
if(!PrecacheModel("materials/models/player/slow/aliendrone/drone_arms.vtf")) return false;
if(!PrecacheModel("materials/models/player/slow/aliendrone/drone_arms_normal.vtf")) return false;
if(!PrecacheModel("materials/models/player/slow/aliendrone/drone_head.vmt")) return false;
if(!PrecacheModel("materials/models/player/slow/aliendrone/drone_head.vtf")) return false;
if(!PrecacheModel("materials/models/player/slow/aliendrone/drone_head_normal.vtf")) return false;
if(!PrecacheModel("materials/models/player/slow/aliendrone/drone_legs.vmt")) return false;
if(!PrecacheModel("materials/models/player/slow/aliendrone/drone_legs.vtf")) return false;
if(!PrecacheModel("materials/models/player/slow/aliendrone/drone_legs_normal.vtf")) return false;
if(!PrecacheModel("materials/models/player/slow/aliendrone/drone_torso.vmt")) return false;
if(!PrecacheModel("materials/models/player/slow/aliendrone/drone_torso.vtf")) return false;
if(!PrecacheModel("materials/models/player/slow/aliendrone/drone_torso_normal.vtf")) return false;
return true;
}

int fog_ent;

// Clean up our variables just to be on the safe side
public OnMapStart()
{
	sd_state = sd_inactive;
	special_day = normal_day;
	SetConVarBool(g_hFriendlyFire, false);
	ff = false;
	tank = -1;
	patient_zero = -1;
	
	
	use_custom_zombie_model = CacheCustomZombieModel();
	
	if(!use_custom_zombie_model)
	{
		PrecacheModel("models/zombie/classic.mdl");
	}
	
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





// needs to be investigated for causing cvar errors
public Action:OnRoundStart(Handle event, const String:name[], bool dontBroadcast)
{

	sd_state = sd_inactive;
	special_day = normal_day;
	hp_steal = false;
	fr = false;
	tank = -1;
	patient_zero = -1;
	if(ff == true) // if we just had ffd
	{
		ff = false;
		SetConVarBool(g_hFriendlyFire, false); // disable friendly fire
	} 
	// reset the alpha just to be safe
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT))
		{
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
			SetEntityRenderColor(i, 255, 255, 255, 255);
			SetEntityGravity(i, 1.0); // reset the gravity
		}
	}	
}



public int EndSd()
{
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
			ff = false;
			SetConVarBool(g_hFriendlyFire, false); // disable friendly fire	
		}
		
		case hide_day:
		{

			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T)
				{
					SetEntityRenderMode(i, RENDER_TRANSCOLOR);
					SetEntityRenderColor(i, 255, 255, 255, 255);
				}
			}
		}
		
		case dodgeball_day: {}
		case normal_day: {}
		case fly_day: {}
		case grenade_day: {}
		
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
			ff = false;
			SetConVarBool(g_hFriendlyFire, false); // disable friendly fire	
	}	
	
#if defined CT_BAN
	if(sd_state != sd_inactive && ctban_running)
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



	special_day = normal_day;
	sd_state = sd_inactive;
}


public Action OnRoundEnd(Handle event, const String:name[], bool dontBroadcast)
{
#if defined GANGS	
	if(sd_state == sd_active && gang_running)
	{
		ServerCommand("sm plugins load hl_gangs.smx")
	}
#endif
	EndSd();
	return Plugin_Handled;
}



public Action command_special_day(int client,args)  
{

	PrintToChatAll("%s Special day started", SPECIALDAY_PREFIX);

	// construct our menu
	Panel panel = new Panel();
	panel.SetTitle("Special Days");
	panel.DrawItem("Friendly Fire Day");
	panel.DrawItem("Tank Day");
	panel.DrawItem("Friendly Fire Juggernaut Day");
	panel.DrawItem("Sky Wars");
	panel.DrawItem("Hide and Seek");
	panel.DrawItem("Dodgeball");
	panel.DrawItem("Grenade");
	panel.DrawItem("Zombie");
	// open a selection menu for 20 seconds
	panel.Send(client, SdHandler, 20);

	delete panel;

	return Plugin_Handled;

}

public Action command_cancel_special_day(int client,args)  
{

	PrintToChatAll("%s Special day cancelled!", SPECIALDAY_PREFIX);
	EndSd();
	return Plugin_Handled;

}



public Action WeaponMenuAll() {

	PrintToChatAll("%s Please select a rifle for the special day", SPECIALDAY_PREFIX);
	
	Panel guns = new Panel();
	guns.SetTitle("Weapon Selection");
	guns.DrawItem("AK47");
	guns.DrawItem("M4A1");
	guns.DrawItem("AWP");
	guns.DrawItem("SHOTGUN");
	guns.DrawItem("P90");
	guns.DrawItem("M249");
	// send the weapon panel to all clients
	//PrintToChatAll("MaxClient = %d", MaxClients);
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if (IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT  || GetClientTeam(i) == CS_TEAM_T)
				{
					guns.Send(i,WeaponHandler , 20);
				}
		}
	}
	delete guns;
			
	return Plugin_Handled;		
}






stock SetReserveAmmo(int client, int weapon, int ammo)
{
  new g_Offset_Ammo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
  new iAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
  SetEntData(client, g_Offset_Ammo+(iAmmoType*4), ammo, _, true);
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
		
		StripAllWeapons(client);
		
	
		GivePlayerItem(client, "weapon_knife"); // give back a knife
	
	
	
	
		GivePlayerItem(client, "weapon_deagle"); // all ways give a deagle
		
		
		// give them plenty of deagle ammo
		new weapon;
		
		weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		SetReserveAmmo(client, weapon, 999)
		
		// give player nades
		GivePlayerItem(client, "weapon_flashbang"); 
		GivePlayerItem(client, "weapon_hegrenade"); 
		GivePlayerItem(client, "weapon_smokegrenade"); 
		// and kevlar
		GivePlayerItem(client, "item_assaultsuit"); 
		
		switch(param2)
		{
		
			case 1:
				GivePlayerItem(client, "weapon_ak47");
		
		
		
			case 2:
				GivePlayerItem(client, "weapon_m4a1");
		
			case 3:
				GivePlayerItem(client, "weapon_awp");
				
			case 4:
				GivePlayerItem(client, "weapon_m3");
				
			case 5:
				GivePlayerItem(client, "weapon_p90");
			
			case 6:
				GivePlayerItem(client, "weapon_m249");
		
		}
		
		
		// give them plenty of primary ammo
		weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		SetReserveAmmo(client, weapon, 999)
		
		
	}

	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d", client, param2);
	}
	
	
	return 0;
}

// credits "MASTER(D)"
public CreateKnockBack(int client, int attacker, float damage)
{

  	float eye_angles[3];
  	float push[3];


  	GetClientEyeAngles(client, eye_angles);

	push[0] = (FloatMul(damage - damage - damage, Cosine(DegToRad(eye_angles[1]))));

	push[1] = (FloatMul(damage - damage - damage, Sine(DegToRad(eye_angles[1]))));

	push[2] = (FloatMul(-50.0, Sine(DegToRad(eye_angles[0]))));

	//Multiply
	ScaleVector(push, 3.0);
	
	//Teleport
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, push);
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
		if (!IsValidClient(attacker)) { return Plugin_Continue; }
		
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
				if(ctban_running && onlyct)
				{
					valid = IsOnTeam(i) && !CTBan_IsClientBanned(i);
				}
				
				else
				{
					valid = IsOnTeam(i);
				}
			#else
				valid = IsOnTeam(i);
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
		
		if(!IsValidClient(client) || !IsClientInGame(client))
		{
			continue;
		}
		
		// switch back to team actual team
		if(IsOnTeam(client))
		{
			CS_SwitchTeam(client,teams[i]);
		}
	}
}


//get players alive on a team
public int get_alive_team_count(int team)
{
	int number = 0;
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team) 
		{
			number += 1;
		}
	}
	return number;
}  


public SetClipAmmo(int client, int weapon, int ammo)
{
	SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);
	SetEntProp(weapon, Prop_Send, "m_iClip2", ammo);
}


float death_cords[64][3];


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
		int cur_count = get_alive_team_count(CS_TEAM_CT);
		bool last_man_triggered  = (cur_count == 1) && (cur_count != ct_count)
		ct_count = cur_count;
		if(last_man_triggered)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientConnected(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT) 
				{
					// LAST MAN STANDING
					PrintCenterTextAll("%N IS LAST MAN STANDING!", i);
					SetEntityHealth(i, 350);
					int weapon = GetPlayerWeaponSlot(i, CS_SLOT_SECONDARY);
					SetClipAmmo(i,weapon, 999);
					weapon =  GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY);
					SetClipAmmo(i,weapon, 999);
					break;
				}			
			}
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
}

public Action NewZombie(Handle timer, int client)
{
	if(special_day != zombie_day)
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
	if(special_day != zombie_day)
	{
		return;
	}
	
	if(IsPlayerAlive(patient_zero))
	{	

		float cords[3];
		GetClientAbsOrigin(patient_zero, cords);
		CS_RespawnPlayer(client);
		TeleportEntity(client, cords, NULL_VECTOR, NULL_VECTOR);
		MakeZombie(client);
	}				
}


// open all doors
new const String:entity_list[][] = { "func_door", "func_movelinear","func_door_rotating","prop_door_rotating" };

public int SdHandler(Menu menu, MenuAction action, int client, int param2)
{
	if(sd_state != sd_inactive) // if sd is active dont allow two
	{
		PrintToChat(client, "%s You can't do two special days at once!", SPECIALDAY_PREFIX);
		return -1;
	
	}


	if(action == MenuAction_Select)
	{
		sdtimer = 20;
		int entity;
		// open all doors
		for(new i = 0; i < sizeof(entity_list); i++)
		{
			while((entity = FindEntityByClassname(entity, entity_list[i])) != -1)
			
			
			if(IsValidEntity(entity))
			{
				AcceptEntityInput(entity, "Open");
			}
		}
		// special done begun but not active
		sd_state = sd_started; 
		
		PrintToConsole(client, "You selected item: %d", param2); /* Debug */
		
		// re-spawn all players
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i)) // check the client is in the game
			{
				if(!IsPlayerAlive(i))  // check player is dead
				{
					if(IsOnTeam(i)) // check not in spec
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
		

		switch(param2)
		{
	
			case 1: //ffd
			{ 
				ff = true;
				special_day = friendly_fire_day;
				PrintToChatAll("%s Friendly fire day started.", SPECIALDAY_PREFIX);
				
				WeaponMenuAll(); // let player pick weapons
				
				
				// allow player to pick for 20 seconds
				PrintToChatAll("%s Please wait 20 seconds for friendly fire to be enabled", SPECIALDAY_PREFIX);
			}
			
			case 2: // tank day
			{
				SaveTeams(true);
				
				if(validclients == 0)
				{
					PrintToChatAll("%s You are all freekillers!", SPECIALDAY_PREFIX);
					return -1;
				}
				
				special_day = tank_day;
				PrintToChatAll("%s Tank day started", SPECIALDAY_PREFIX);
				
				WeaponMenuAll(); // let player pick weapons
				
				
				
				int rand = GetRandomInt( 0, (validclients-1) );
				

				tank = game_clients[rand]; // select the lucky client
			}
			
			case 3: //ffdg
			{
				hp_steal = true; 
				ff = true;
				special_day = friendly_fire_day;
				PrintToChatAll("%s Friendly fire juggernaut day  started.", SPECIALDAY_PREFIX);
				
				WeaponMenuAll(); // let player pick weapons
				
				
				// allow player to pick for 20 seconds
				PrintToChatAll("%s Please wait 20 seconds for friendly fire to be enabled", SPECIALDAY_PREFIX);
				
				PrintToConsole(client, "Timer started at : %d", sdtimer);
			}
			
			case 4: // flying day
			{
				special_day = fly_day;
				PrintToChatAll("%s Sky wars started", SPECIALDAY_PREFIX);
				for(new i = 1; i < MaxClients; i++)
				{
					if(IsClientInGame(i) && IsPlayerAlive(i)) // check the client is in the game
					{
						StripAllWeapons(i);
					
						SetClientSpeed(i,2.5);
						SetEntityMoveType(i, MOVETYPE_FLY); // should add the ability to toggle with a weapon switch
															// to make navigation easy (as brushing on the floor sucks)
						GivePlayerItem(i, "weapon_m3"); // all ways give a deagle
						GivePlayerItem(i, "item_assaultsuit");
					}
				}
			}
			
			case 5: // hide and seek day
			{
				PrintToChatAll("%s Hide and seek day started", SPECIALDAY_PREFIX);
				PrintToChatAll("Ts must hide while CTs seek");
				special_day = hide_day;
				
				CreateTimer(1.0,MoreTimers);
				
				
				
				for(new i = 1; i < MaxClients; i++)
				{
					if(!IsClientInGame(i) || !IsPlayerAlive(i))
					{
						continue;
					}			
	
					if(GetClientTeam(i) == CS_TEAM_T)
					{
						// make players invis
						SetEntityRenderMode(i, RENDER_TRANSCOLOR);
						SetEntityRenderColor(i, 0, 0, 0, 0);
					}
					
					else if(GetClientTeam(i) == CS_TEAM_CT)
					{

						StripAllWeapons(i);
	
						GivePlayerItem(i, "weapon_m3"); // give a shotty
						// give em shit tons of ammo
						int weapon = GetPlayerWeaponSlot(i, CS_SLOT_PRIMARY);
						SetReserveAmmo(i, weapon, 999)
						// freeze the player in place
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 0.0);
						SetEntityHealth(i,500); // set health to 500
						
					}
									
				}	
			}
			
			
			case 6: // dodgeball day
			{
				PrintToChatAll("%s Dodgeball day started", SPECIALDAY_PREFIX);
				CreateTimer(1.0, RemoveGuns);
				special_day = dodgeball_day;
			
				// now we need to set everyones hp to 1
				// potentailly remove armour
				
				for(new i = 1; i < MaxClients; i++)
				{
					if(IsClientInGame(i)) // check the client is in the game
					{
						if(IsPlayerAlive(i))  // check player is dead
						{
							if(IsOnTeam(i)) // check not in spec
							{
								SetEntityHealth(i,100); // set health to 1
								StripAllWeapons(i); // remove all the players weapons
								GivePlayerItem(i, "weapon_flashbang");
								SetEntProp(i, Prop_Data, "m_ArmorValue", 0.0);  
								SetEntityGravity(i, 0.6);
							}
						}
					}
				}
			}
			
			
			
			case 7: // grenade day
			{
				PrintToChatAll("%s grenade day started", SPECIALDAY_PREFIX);
				CreateTimer(1.0, RemoveGuns);
				special_day = grenade_day;
			
				for(new i = 1; i < MaxClients; i++)
				{
					if(IsClientInGame(i)) // check the client is in the game
					{
						if(IsPlayerAlive(i))  // check player is dead
						{
							if(IsOnTeam(i)) // check not in spec
							{
								SetEntityHealth(i,100); // set health to 1
								StripAllWeapons(i); // remove all the players weapons
								GivePlayerItem(i, "weapon_hegrenade");
								SetEntProp(i, Prop_Data, "m_ArmorValue", 0.0);  
								SetEntityGravity(i, 0.6);
							}
						}
					}
				}
			}
				
			case 8: // zombie day
			{
				
				SaveTeams(false);

			
				
				PrintToChatAll("%s zombie day started", SPECIALDAY_PREFIX);
				CreateTimer(1.0, RemoveGuns); 
				special_day = zombie_day;
			
				int rand = GetRandomInt( 0, (validclients-1) );
				
				// select the first zombie
				patient_zero = game_clients[rand]; 
			
				
				for(new i = 1; i < MaxClients; i++)
				{
					if(IsClientInGame(i)) // check the client is in the game
					{
						if(IsPlayerAlive(i))  // check player is dead
						{
							if(IsOnTeam(i)) // check not in spec
							{
								WeaponMenu(i);
							}
						}
					}
				}
			}
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

public bool IsOnTeam(int i)
{
	return GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T;
}


public SetClientSpeed(int client,float speed)
{
      SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed)
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
	if(gang_running)
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
		
		
		default:
		{
			ThrowNativeError(SP_ERROR_NATIVE, "attempted to start invalid sd %d", special_day);
		}
	}
}

public int make_invis_t()
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


public MakeZombie(int client)
{
	StripAllWeapons(client);
	SetClientSpeed(client, 1.2);
	SetEntityGravity(client, 0.4);
	SetEntityHealth(client, 250);
	GivePlayerItem(client, "weapon_knife");
	
	if(!use_custom_zombie_model)
	{
		SetEntityModel(client, "models/zombie/classic.mdl");
	}
	
	else
	{
		SetEntityModel(client, "models/player/slow/aliendrone/slow_alien.mdl");
	}
}

public int StartZombie()
{

	// swap everyone other than the patient zero to the t side
	// if they were allready in ct or t
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsOnTeam(i))
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

public int StartGrenade()
{
	ff = true;
	SetConVarBool(g_hFriendlyFire, true); // enable friendly fire	
	no_damage = false;
	
	// set everyones hp to 250
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i)) // check the client is in the game
		{
			if(IsPlayerAlive(i))  // check player is dead
			{
				if(IsOnTeam(i)) // check not in spec
				{
					SetEntityHealth(i,250);
				}
			}
		}	
	}	
}

public int StartHide()
{
	// renable movement
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT) // check the client is in the game
		{
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
			SetEntityHealth(i,500); // set health to 500
		}
	}
	
	// hide everyone again just incase
	make_invis_t(); 
	
	// callbakc incase shit fucks with the color
	CreateTimer(5.0, hide_timer_callback);
	
	no_damage = false;
}



public int StartFly()
{
	no_damage = false;
	ff = true;
	SetConVarBool(g_hFriendlyFire, true); // enable friendly fire
}

public int StartTank()
{	
	SetEntityHealth(tank, 250 * GetClientCount(true));
	
	
	
	
	// swap everyone other than the tank to the t side
	// if they were allready in ct or t
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsOnTeam(i))
			{
				CS_SwitchTeam(i,CS_TEAM_T);
			}
		}
	}
	
	CS_SwitchTeam(tank,CS_TEAM_CT);
	SetEntityRenderColor(tank, 255, 0, 0, 255);
	PrintCenterTextAll("%N is the TANK!", tank);
}



public int StartFFD()
{
	PrintToChatAll("[SM] Friendly fire enabled");
	
	//implement a proper printing function lol
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	
	SetConVarBool(g_hFriendlyFire, true); // enable friendly fire
}


public int StartDodgeball()
{

	PrintCenterTextAll("Dodgeball active!");
	ff = true;
	SetConVarBool(g_hFriendlyFire, true); // enable friendly fire
	
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
				if(GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) ==  CS_TEAM_T ) // check not in spec
				{
					SetEntityHealth(i,1);
					SetEntProp(i, Prop_Data, "m_ArmorValue", 0.0);  // remove armor 
				}
			}
		}	
	}


}





// block flashes 
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
	// By Kigen (c) 2008 - Please give me credit. :)
	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
					RemoveEdict(i);
		}
	}

	if(special_day == dodgeball_day || special_day == grenade_day)
	{
		CreateTimer(1.0, RemoveGuns);
	}

}

public Action GiveFlash(Handle timer, any entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
	
	else 
	{
		return;
	}

	// giver person who threw a flash after a second +  set hp to one
	
	if(special_day != dodgeball_day) { return; }
	
	
	
	if(IsClientInGame(client))
	{
		if(GetClientTeam(client) == CS_TEAM_CT || GetClientTeam(client) ==  CS_TEAM_T && IsPlayerAlive(client) )
		{
			StripAllWeapons(client);
			GivePlayerItem(client, "weapon_flashbang");
			SetEntityHealth(client,1);
		}
	}
	
}


public Action GiveGrenade(Handle timer, any entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	// giver person who threw a flash after a second +  set hp to one
	
	if(special_day != grenade_day) { return; }
	
	
	
	if(IsClientInGame(client))
	{
		if(GetClientTeam(client) == CS_TEAM_CT || GetClientTeam(client) ==  CS_TEAM_T && IsPlayerAlive(client) )
		{
			StripAllWeapons(client);
			GivePlayerItem(client, "weapon_hegrenade");
		}
	}	
}


stock StripAllWeapons(client)
{
	int wepIdx;
	for (int i = 0; i < 6; i++)
	{
		if ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, wepIdx);
			AcceptEntityInput(wepIdx, "Kill");
		}
	}

}




// prevent additional weapon pickups

public Action OnWeaponEquip(int client, int weapon) 
{
	if(special_day == dodgeball_day)
	{
		char sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon)); 
		if(!StrEqual(sWeapon,"weapon_flashbang"))
		{
			return Plugin_Handled;
		}
	}
	
	if(special_day == grenade_day)
	{
		char sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon)); 
		if(!StrEqual(sWeapon,"weapon_hegrenade"))
		{
			return Plugin_Handled;
		}
	}
	
	else if(special_day == zombie_day && sd_state == sd_active)
	{
		char sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon)); 
		
		if(GetClientTeam(client) == CS_TEAM_T)
		{
			if(!StrEqual(sWeapon,"weapon_knife"))
			{
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

