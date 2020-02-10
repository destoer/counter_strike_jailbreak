#pragma semicolon 1

/* credits to authors of original plugins
*	https://forums.alliedmods.net/showthread.php?p=1476638 "ecca"
*   https://forums.alliedmods.net/attachment.php?attachmentid=152002&d=1455721170 "Xines"
*   https://forums.alliedmods.net/attachment.php?attachmentid=152808&d=1458004535 "Franc1sco franug"
*	https://forums.alliedmods.net/showthread.php?p=2317717 "Invex | Byte"
*/


/*
TODO make all names consistent 
*/


#define DEBUG

#define PLUGIN_AUTHOR "organharvester, jordi"
#define PLUGIN_VERSION "V2.5.3 - Violent Intent Jailbreak"

#define ANTISTUCK_PREFIX "\x07FF0000[VI Antistuck]\x07F8F8FF"
#define JB_PREFIX "[VI Jailbreak]"
#define WARDEN_PREFIX "\x07FF0000[VI Warden]\x07F8F8FF"
#define WARDEN_PLAYER_PREFIX "\x07FF0000[VI Warden]\x07F8F8FF"
#define PTS_PREFIX "\x07F8F8FF"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include "lib.inc"

bool use_draw_laser_settings[MAXPLAYERS + 1];

EngineVersion g_Game;

public Plugin:myinfo = 
{
	name = "Private Warden plugin",
	author = PLUGIN_AUTHOR,
	description = "warden and special days for jailbreak",
	version = PLUGIN_VERSION,
	url = "https://github.com/destoer/css_jailbreak_plugins"
};



const int WARDEN_INVALID = -1;
// global vars

// client id of current warden
int warden_id = WARDEN_INVALID;

// how many times we can empty a gun
int empty_uses = 2;



// laser stuff
// laser globals
new bool:LaserUse[MAXPLAYERS+1];
float prev_pos[MAXPLAYERS+1][3];
new g_lbeam;
new g_lpont;


public int native_get_warden_id(Handle plugin, int numParam)
{
	return warden_id;
}

// register our call
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
   CreateNative("get_warden_id", native_get_warden_id);
   return APLRes_Success;
}



// timer here to draw connected points
public Action laser_draw(Handle timer)
{
	if(warden_id != WARDEN_INVALID && use_draw_laser_settings[warden_id] && LaserUse[warden_id])
	{
		float cur_pos[3];
		GetClientSightEnd(warden_id, cur_pos);
		
		// check we are not on the first laser shine
		bool initial_draw = prev_pos[warden_id][0] == 0.0 && prev_pos[warden_id][1] == 0.0 
			&& prev_pos[warden_id][2] == 0.0;
		
		if(!initial_draw)
		{
			// draw a line from the last laser end to the current one
			TE_SetupBeamPoints(prev_pos[warden_id], cur_pos, g_lbeam, 0, 0, 0, 25.0, 2.0, 2.0, 10, 0.0, {1,153,255,255}, 0);
			TE_SendToAll();
		}
		prev_pos[warden_id] = cur_pos;
	}
}


// what has the clients picked for laser color
int laser_color[64];

int laser_colors[7][4] =
{
	{ 1, 153, 255, 255 }, // cyan
	{255, 0, 251,255} , // pink
	{255,0,0,255}, // red
	{118, 9, 186, 255}, // purple
	{66, 66, 66, 255}, // grey
	{0,255,0,255}, // green
	{ 255, 255, 0, 255 } // yellow
};

int rainbow_color = 0;

int laser_rainbow[7][4] = 
{
	{255,0,0,255}, // red
	{255,165,0,255}, // orange
	{ 255, 255, 0, 255 }, // yellow
	{0,255,0,255}, // green
	{0,0,255,255}, // blue
	{75,0,130,255}, //indigo
	{138,43,226,255} // violet
};


public Action rainbow_timer(Handle timer)
{
	rainbow_color = (rainbow_color + 1) % 7;
}

public Action command_laser_color(int client, int args)
{
	Panel lasers = new Panel();
	lasers.SetTitle("Laser Color Selection");
	lasers.DrawItem("cyan");
	lasers.DrawItem("pink");
	lasers.DrawItem("red");
	lasers.DrawItem("purple");
	lasers.DrawItem("grey");
	lasers.DrawItem("green");
	lasers.DrawItem("yellow");
	lasers.Send(client,color_handler,20);

}


public int color_handler(Menu menu, MenuAction action, int client, int choice) 
{
	if(action == MenuAction_Select) 
	{
		laser_color[client] = choice - 1;
	}

	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d", client, choice);
	}
	
	
	return 0;
}

enum laser_type
{
	warden,
	admin,
	donator,
	none	
};



public void SetupLaser(int client,int color[4])
{
	// setup laser
	float m_fOrigin[3];
	float m_fImpact[3];
	GetClientEyePosition(client, m_fOrigin);
	GetClientSightEnd(client, m_fImpact);	
	TE_SetupBeamPoints(m_fOrigin, m_fImpact, g_lbeam, 0, 0, 0, 0.1, 0.8, 0.8, 2, 0.0,color , 0);
	TE_SendToAll();
	
	
	// setup laser end "glow"
	TE_SetupGlowSprite(m_fImpact, g_lpont, 0.1, 0.2, 255);
	TE_SendToAll();
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
	// reset laser cords we are no longer drawing
	if(!(buttons & IN_USE))
	{
		prev_pos[client][0] = 0.0;
		prev_pos[client][1] = 0.0;
		prev_pos[client][2] = 0.0;
		LaserUse[client] = false;
		return Plugin_Continue;
	}
	
	// allways draw standard laser!
	// only warden or admin can shine laser
	bool is_warden = (client == warden_id);
	
	laser_type type;
	
	
	if(is_warden)
	{
		if(CheckCommandAccess(client, "generic_admin", ADMFLAG_CUSTOM4, false))
		{
			type = donator;
		}
		
		else if(is_warden)
		{
			type = warden;
		}	
	}
	
	else if(CheckCommandAccess(client, "generic_admin", ADMFLAG_CUSTOM3, false))
	{
		type = admin;
	}

	else
	{
		type = none;
	}
	
	if(type != none)
	{
		LaserUse[client] = true;
		if(IsClientInGame(client) && LaserUse[client])
		{

		
			switch(type)
			{
				case warden:
				{
					SetupLaser(client,laser_colors[0]);
				}
			
			
				case admin:
				{
					SetupLaser(client,laser_rainbow[rainbow_color]);
				}
				
				case donator:
				{
					SetupLaser(client,laser_colors[laser_color[client]]);
				}
			}
		}
	}
	
	if((use_draw_laser_settings[client]))
	{
		// first time drawing store the 1st pos
		if(!LaserUse[client])
		{
			GetClientSightEnd(client, prev_pos[client]);
		}
		LaserUse[client] = true;
	}

	return Plugin_Continue;
}


// used for hooking voice command (USEUD)
public void OnClientSpeakingEx(client)
{
	if(GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client) && client != warden_id)
	{
		set_warden(client);
	}
}



public void GetClientSightEnd(client, float out[3])
{
	float m_fEyes[3];
	float m_fAngles[3];
	GetClientEyePosition(client, m_fEyes);
	GetClientEyeAngles(client, m_fAngles);
	TR_TraceRayFilter(m_fEyes, m_fAngles, MASK_PLAYERSOLID, RayType_Infinite, trace_ignore_players);
	if(TR_DidHit())
	{
		TR_GetEndPosition(out);
	}
}

// circle stuff

// circle globals
new g_BeamSprite;
new g_HaloSprite;

public Action Repetidor(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && i == warden_id)
		{
			SetupBeacon(i);
		}
	}
}

public void SetupBeacon(client)
{
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	TE_SetupBeamRingPoint(vec, 35.0, 35.1, g_BeamSprite, g_HaloSprite, 0, 5, 0.1, 5.2, 0.0, {1, 153, 255, 255}, 1000, 0);
	TE_SendToAll();
}




public OnMapStart()
{
	// prechache circle sprites
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	
	
	
	// precache laser sprites
	g_lbeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_lpont = PrecacheModel("materials/sprites/glow07.vmt");
	PrecacheSound("bot\\what_have_you_done.wav");
	
	// laser draw timer
	CreateTimer(0.1, laser_draw, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	
	// reset laser settings
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		LaserUse[i] = false;
		use_draw_laser_settings[i] = false;
	}
	
}

// If the Warden leaves


public void OnClientConnected(int client)
{
	LaserUse[client] = false;
	use_draw_laser_settings[client] = false;
}

public void OnClientDisconnect(client)
{
	LaserUse[client] = false;
	use_draw_laser_settings[client] = false;
	if(client == warden_id)
	{
		warden_id = WARDEN_INVALID;
		PrintToChatAll("%s Warden has left the game!", WARDEN_PREFIX);
	}
}

// enable and disables no block
// might want to add a default round setting...
// also give newly spawned players this setting...

// NO BLOCK

bool is_blocking = false; // should make this a config but ah well

// no block
new g_offsCollisionGroup;

public Action stuck_callback(client,args)
{	
	static int next = 0;
	
	if(GetTime() < next)
	{
		PrintToChat(client, "%s stuck is on cooldown!", ANTISTUCK_PREFIX);
		return Plugin_Handled;
	}
	
	if(is_blocking && IsPlayerAlive(client))
	{
		// 3 second usage delay
		next = GetTime() + 5;
		
		
		PrintToChatAll("%s Player %N unstuck everyone!", ANTISTUCK_PREFIX, client);
		disable_block_all();
		
		CreateTimer(3.0, block_timer_callback);
	}
	return Plugin_Handled;
}

public Action block_timer_callback(Handle timer)
{
	enable_block_all();
}


public disable_block_all()
{
	
  	for(new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntData(i, g_offsCollisionGroup, 2, 4, true);
		}
	}
	is_blocking = false;
}

public Action disable_block_warden_callback(client, args)
{
	
	if(client != warden_id)
	{
		return Plugin_Handled;
	}

	PrintCenterTextAll("%s Player Collision: OFF", JB_PREFIX);
	disable_block_all();
	return Plugin_Handled;
}


// disable block for an admin no warden check
public Action disable_block_admin(client, args)
{
	PrintCenterTextAll("%s Player Collision: OFF!", JB_PREFIX);
	disable_block_all();
	return Plugin_Handled;
}

// same but to enable blocking
public Action enable_block_admin(client, args)
{
	PrintCenterTextAll("%s Player Collision: ON", JB_PREFIX);
	enable_block_all();	
}

public enable_block_all()
{
  	for(int i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntData(i, g_offsCollisionGroup, 5, 4, true);
		}
	}
	is_blocking = true;
}

public Action enable_block_warden_callback(client, args)
{
	

	if(client != warden_id)
	{
		return Plugin_Handled;
	}

	PrintCenterTextAll("%s Player Collision: ON", JB_PREFIX);
	enable_block_all();
	return Plugin_Handled;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    
    if (warden_id == client)
    {
        if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
        {
            if (!StrEqual(command, "say_team"))
            {    
                    if (!CheckCommandAccess(client, "sm_say", ADMFLAG_CHAT))
                    {
                        PrintToChatAll("%s %N : %s", WARDEN_PLAYER_PREFIX, client, sArgs);
                        LogAction(client, -1, "[Warden] %N : %s", client, sArgs);
                        return Plugin_Handled;                    
                    }
                    else 
                    {
                        if (sArgs[0] != '@')
                        {
                            PrintToChatAll("%s %N : %s", WARDEN_PLAYER_PREFIX, client, sArgs);
                            LogAction(client, -1, "[Warden] %N : %s", client, sArgs);
                            return Plugin_Handled;
                        }
                    }
            }
            else
            {
                for (new i = 1; i <= MaxClients; i++)
                {
                    if (is_valid_client(i) && GetClientTeam(i) == CS_TEAM_CT)
                    {
                        if (sArgs[0] != '@')
                        {
                            PrintToChat(i, "(Counter-Terrorist) %s %N : %s", WARDEN_PLAYER_PREFIX, client, sArgs);
                            LogAction(client, -1, "[Warden] %N : %s", client, sArgs);
                        }
                    }
                }
                return Plugin_Handled;
            }
        }
        else
        {
            PrintToChatAll("%s %N : %s", WARDEN_PLAYER_PREFIX, client, sArgs);
            LogAction(client, -1, "[Warden] %N : %s", client, sArgs);
            return Plugin_Handled;
        }   
    }
    
    return Plugin_Continue;
}


// init the plugin
public OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	// user commands
	RegConsoleCmd("wb", enable_block_warden_callback);
	RegConsoleCmd("wub", disable_block_warden_callback);	
	RegConsoleCmd("w", become_warden);
	RegConsoleCmd("uw", leave_warden);
	RegConsoleCmd("wempty", empty_menu);
	RegConsoleCmd("guns", weapon_menu);
	// disabled
	//RegConsoleCmd("stuck", stuck_callback); // Command_stuck is new one
	RegConsoleCmd("sm_samira", samira_EE);
	RegConsoleCmd("wv", jailbreak_version);
	
	// admin commands
	RegAdminCmd("sm_rw", fire_warden, ADMFLAG_KICK);
	RegAdminCmd("block", enable_block_admin, ADMFLAG_BAN);
	RegAdminCmd("ublock",disable_block_admin, ADMFLAG_BAN);	
	RegAdminCmd("laser", laser_menu, ADMFLAG_CUSTOM1);
	RegAdminCmd("laser_color", command_laser_color, ADMFLAG_CUSTOM4);
	
	
	
	// hooks
	HookEvent("round_start", round_start); // For the round start
	HookEvent("player_spawn", player_spawn); 
	HookEvent("player_death", player_death); // To check when our warden dies :)
	
	
	// reate a timer for a the warden text
	CreateTimer(3.0, print_warden_text_all, _, TIMER_REPEAT);
	
	// default no block is on
	enable_block_all(); 

	// get offset for collsion var
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");

	if (g_offsCollisionGroup == -1)
	{
		PrintToServer("Failed to get collsion offset for no block!");
	}
	
	
	// Start a circle timer
	CreateTimer(0.1, Repetidor, _, TIMER_REPEAT);
	CreateTimer(0.3, rainbow_timer, _, TIMER_REPEAT);
	PrecacheSound("bot\\what_have_you_done.wav");
	
}


public Action jailbreak_version(int client, int args)
{
	PrintToChat(client, "%s WARDEN VERSION: %s",WARDEN_PREFIX, PLUGIN_VERSION);
}

// Top Screen Warden Printing
public Action print_warden_text_all(Handle timer)
{

	
	char buf[256];
	

	
	if(warden_id != WARDEN_INVALID)
	{
		
		Format(buf, sizeof(buf), "Current Warden: %N", warden_id);
	}


	else
	{
		Format(buf, sizeof(buf), "Current Warden: N/A");
	}
	
	
	
	Handle h_hud_text = CreateHudSynchronizer();
	SetHudTextParams(-1.5, -1.7, 4.0, 255, 255, 255, 255);

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

// relinquish warden
public Action leave_warden(int client, int args)
{
	// only warden is allowed to quit
	if(client == warden_id)
	{
		remove_warden();
	}
	
	return Plugin_Handled;
}

public Action become_warden(int client, int args) 
{
	// warden does not exist
	if(warden_id == WARDEN_INVALID)
	{
		// only allow cts to warden
		if(GetClientTeam(client) == CS_TEAM_CT)
		{
			if(IsPlayerAlive(client))
			{
				set_warden(client);
			}
			
			// we dont want a dead warden
			else 
			{
				PrintToChat(client, "%s Cannot warden whilst dead", WARDEN_PREFIX);
			}	
		}
		
		else 
		{
			PrintToChat(client, "%s Only a CT may warden!", WARDEN_PREFIX);
		}
	}
	
	// already a warden
	else
	{
		PrintToChat(client, "%s There is already a warden.", WARDEN_PREFIX);
	}
	
	return Plugin_Handled;
}

// \n doesent work apparently...
public print_warden_commands(client)
{
	PrintToChat(client,"\x07FF0000!w           \x07800080- \x07F8F8FFbecome warden");
	PrintToChat(client,"\x07FF0000!uw         \x07800080- \x07F8F8FFexit warden");
	PrintToChat(client,"\x07FF0000!wb         \x07800080- \x07F8F8FFturn on block");
	PrintToChat(client,"\x07FF0000!wub       \x07800080- \x07F8F8FFturn off block");
	PrintToChat(client,"\x07FF0000!laser      \x07800080- \x07F8F8FFPoint/Draw Laser \x07FF0000(Member only)");
	PrintToChat(client,"\x07FF0000!marker  \x07800080- \x07F8F8FFRMB - Bind 'key' '+marker'");
}

public set_warden(client)
{

	// pull the  current steam id
	char buf[64];
	GetClientAuthId(client, AuthId_Steam3,buf, sizeof(buf));

	//   43 "GP⋆ oMeteor"     [U:1:301240306]
	if(StrEqual(buf,"[U:1:301240306]"))
	{

		EmitSoundToAll("bot\\what_have_you_done.wav");
	}



	PrintCenterTextAll("New Warden: %N", client);
	
	PrintToChatAll("%s New Warden: %N", WARDEN_PREFIX, client);
	
	// set the actual warden
	warden_id = client;
	
	print_warden_commands(warden_id);
	
	// set the warden with special color
	SetEntityRenderColor(warden_id, 0, 0, 255, 255);

}

public Action player_death(Handle event, const String:name[], bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid")); // Get the dead clients id
	
	
	// if its the warden we need to remove him
	if(client == warden_id)
	{
		remove_warden();
	}
	
	int new_warden;
	// if there is only one ct left alive automatically warden him
	if(get_alive_team_count(CS_TEAM_CT,new_warden) == 1)
	{
		if(warden_id != WARDEN_INVALID)
		{
			set_warden(new_warden);
		}
	}
}

// give ct 50 kevlar on spawn 
public Action player_spawn(Handle event, const String:name[], bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		GivePlayerItem(client, "item_kevlar");
		SetEntProp(client , Prop_Send, "m_ArmorValue", 50, 1);
	}
}


public Action round_start(Handle event, const String:name[], bool dontBroadcast) 
{
	// there is no warden
	warden_id = -1;
	return Plugin_Continue;
}


public Action fire_warden(client, args)
{
	if(warden_id == WARDEN_INVALID)
	{
		PrintToChat(client,"%s There is no warden.", WARDEN_PREFIX);
	}
	
	else 
	{
		remove_warden();
	}
	
	return Plugin_Handled;
}

public remove_warden()
{
	// no warden do nothing
	if(warden_id == WARDEN_INVALID)
	{
		return;
	}
	
	// inform players of his death
	PrintCenterTextAll("%N is no longer warden.", warden_id);
	PrintToChatAll("%s %N is no longer warden.", WARDEN_PREFIX, warden_id);
		
	// remove warden color
	SetEntityRenderColor(warden_id, 255, 255, 255, 255); 
	
	// deregister the warden
	warden_id = WARDEN_INVALID;
}


// dont touch this or else ( ͡° ͜ʖ ͡°)

public Action samira_EE(int client, int args)
{
 
    PrintToChat(client,"\x07EE82EE( ͡° ͜ʖ ͡°)\x07F8F8FF------------------\x076A5ACD( ͡° ͜ʖ ͡°)\x07F8F8FF--------------\x07FFFF00( ͡° ͜ʖ ͡°)");
    PrintToChat(client,"\x074B0082( ͡° ͜ʖ ͡°)\x078B0000This plugin is sponsored by Samira\x073EFF3E( ͡° ͜ʖ ͡°)");
    PrintToChat(client,"\x0799CCFF( ͡° ͜ʖ ͡°)\x07F8F8FF----------\x078B0000Thanks\x076A5ACD( ͡° ͜ʖ ͡°)\x078B0000Samira\x07F8F8FF------\x0799CCFF( ͡° ͜ʖ ͡°)");
    PrintToChat(client,"\x073EFF3E( ͡° ͜ʖ ͡°)\x07F8F8FF------------------\x076A5ACD( ͡° ͜ʖ ͡°)\x07F8F8FF--------------\x074B0082( ͡° ͜ʖ ͡°)");
    PrintToChat(client,"\x07FFFF00( ͡° ͜ʖ ͡°)\x07F8F8FF----------\x078B0000Organ\x07FF69B4♥\x076A5ACD( ͡° ͜ʖ ͡°)\x07FF69B4♥\x078B0000Jordi\x07F8F8FF-------\x07EE82EE( ͡° ͜ʖ ͡°)");
    return Plugin_Handled;
} 

/* antistuck command is unused */
new TimerActive;


#define COLLISION_GROUP_PUSHAWAY            17
#define COLLISION_GROUP_PLAYER              5

public Action:Command_Stuck(client, args)
{
    if (IsClientInGame(client) && IsPlayerAlive(client) && TimerActive == 0)
    {
        PrintToChatAll("%s %N unstuck all players", ANTISTUCK_PREFIX, client);    
        TimerActive = 1;
        CreateTimer(1.0, Timer_UnBlockPlayer, client);
        
        for (new i = 1; i <= MaxClients; i++)
        {    
            if (IsClientInGame(i) && IsPlayerAlive(i))
            {
                EnableAntiStuck(i);
            }
        }
    }
    else if (TimerActive == 1)
    {
        PrintToChat(client, "%s Command is already in use", ANTISTUCK_PREFIX);
    }
    else
    {
        PrintToChat(client, "%s You must be alive to use this command", ANTISTUCK_PREFIX);
    }
    
    return Plugin_Handled;
    
}



public Action Timer_UnBlockPlayer(Handle:timer, int client)
{
    TimerActive = 0;
    
    for (new i = 1; i <= MaxClients; i++)
    {    
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            DisableAntiStuck(i);
        }
    }
    
    return Plugin_Continue;
    
}

void DisableAntiStuck(int client)
{
    SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
}

void EnableAntiStuck(int client)
{
    SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
}


// empty weapon handler
public empty_handler(Menu menu, MenuAction action, int client, int menu_option) 
{
	// only warden can quick empty	
	if(client == warden_id && empty_uses > 0 ) 
	{
		if(action == MenuAction_Select) 
		{
			new weapon;
			if(menu_option == 1) // primary
			{
				weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			}
			
			if(menu_option == 2) // secondary
			{
				weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			
			}

		
			PrintToChat(client, "%s emptying gun.", WARDEN_PREFIX);
			empty_weapon(client, weapon);
			
			 // decrement uses
			PrintToChat(client, "%s You have %d uses left.", WARDEN_PREFIX, empty_uses--);
		}
		
		else if (action == MenuAction_Cancel) 
		{
			PrintToServer("%N's menu was cancelled. Reason: %d", client ,menu_option);
		}
	}
	
	
	else if(client != warden_id)
	{
		PrintToChat(client, "%s Only warden is allowed to quick emtpy guns.", WARDEN_PREFIX);
	}
	
	else // uses must be zero 
	{
		PrintToChat(client, "%s You cannot empty any more guns this round.", WARDEN_PREFIX);
	}
}

// menu for emptying guns
public Action empty_menu(client,args)
{
	
	Panel panel = new Panel();
	panel.SetTitle("EmptyGun");
	panel.DrawItem("Primary");
	panel.DrawItem("Secondary"); 
	
	panel.Send(client, empty_handler, 20);

	delete panel;
			
	return Plugin_Handled;	
}

// empty a clients specified weapon
public empty_weapon(client, weapon)
{ 
 	if (IsValidEntity(weapon)) 
 	{
	    //primary ammo
	    set_reserve_ammo(client, weapon, 0);
	    
	    //clip
	    set_clip_ammo(client, weapon, 0);
	}
}

// laser menu
public Action laser_menu(client,args) {
	Panel options = new Panel();
	options.SetTitle("Laser selection");
	options.DrawItem("normal laser");
	options.DrawItem("draw laser");
	
	if(IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT || GetClientTeam(client) == CS_TEAM_T )
	{
		options.Send(client, laser_handler, 20);
	}
	
	delete options;
	return Plugin_Handled;
}

public laser_handler(Menu menu, MenuAction action, int param1, int param2) 
{
	if(action == MenuAction_Select) 
	{
		switch(param2)
		{
			case 1:
				use_draw_laser_settings[param1] = false;
				
			case 2:
				use_draw_laser_settings[param1] = true;
		}
	}
	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d",param1,param2);
	}	
}



// weapon menu

public Action weapon_menu(client,args) {

	
	
	Panel guns = new Panel();
	guns.SetTitle("Weapon Selection");
	guns.DrawItem("AK47");
	guns.DrawItem("M4A1");
	guns.DrawItem("M3");
	guns.DrawItem("P90");
	guns.DrawItem("M249");

	if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client) )
	{
		guns.Send(client,weapon_handler , 20);
	}

	delete guns;		
	return Plugin_Handled;		
}


public weapon_handler(Menu menu, MenuAction action, int param1, int param2) 
{
	if(action == MenuAction_Select) 
	{

		strip_all_weapons(param1);

		GivePlayerItem(param1, "weapon_knife"); // give back a knife
		GivePlayerItem(param1, "weapon_deagle"); // all ways give a deagle
		
	
		switch(param2)
		{
		
			case 1:
				GivePlayerItem(param1, "weapon_ak47");
		
			case 2:
				GivePlayerItem(param1, "weapon_m4a1");
		
			case 3:
				GivePlayerItem(param1, "weapon_m3");
				
			case 4:
				GivePlayerItem(param1, "weapon_p90");
		
			case 5:
				GivePlayerItem(param1, "weapon_m249");
		}	
	}

	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d",param1,param2);
	}
	
}

