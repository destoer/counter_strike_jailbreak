#pragma semicolon 1

/* credits to authors of original plugins
*	https://forums.alliedmods.net/showthread.php?p=1476638 "ecca" (warden core (has mostly been rewritten at this point though))
*   https://forums.alliedmods.net/attachment.php?attachmentid=152002&d=1455721170 "Xines" (laser)
*   https://forums.alliedmods.net/attachment.php?attachmentid=152808&d=1458004535 "Franc1sco franug" (circle)
*	https://forums.alliedmods.net/showthread.php?p=2317717 "Invex | Byte" (zero guns code)
*/



/*
TODO make all names consistent 
*/


// if defined these two features are locked behind custom admin flags
//#define DRAW_CUSTOM_FLAGS
//#define LASER_COLOR_CUSTOM_FLAGS

/*
	admin flags

	ADMFLAG_CUSTOM1 - allow clients to use a draw laser as warden
	ADMFLAG_CUSTOM4 - allow clients to change laser color as warden
	ADMFLAG_CUSTOM3 - rainbow laser for use anytime (restrict to admins)
	ADMFLAG_CUSTOM6 - toggle laser killing people
*/

#define DONATOR 	ADMFLAG_CUSTOM1
#define MEMBER 		ADMFLAG_CUSTOM2
#define ADMIN		ADMFLAG_BAN
#define DEBUG

#define PLUGIN_AUTHOR "destoer(organ harvester), jordi"
#define PLUGIN_VERSION "V3.5.3 - Violent Intent Jailbreak"

/*
	onwards to the new era ( ͡° ͜ʖ ͡°)
*/


#define WARDAY_ROUND_COUNT 5
int warday_round_counter = 0;
bool warday_active = false;

char warday_loc[20];


const int WARDEN_INVALID = -1;
// global vars

// client id of current warden
int warden_id = WARDEN_INVALID;


// handle for sdkcall
Handle SetCollisionGroup;




#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include "lib.inc"
#include "specialday/specialday.inc"

// cookies
#include <clientprefs>

Handle client_laser_draw_pref;
Handle client_laser_color_pref;



// split files for this plugin
#include "jailbreak/config.sp"
#include "jailbreak/stuck.sp"
#include "jailbreak/guns.sp"
#include "jailbreak/laser.sp"
#include "jailbreak/circle.sp"
#include "jailbreak/block.sp"
#include "jailbreak/debug.sp"
#include "jailbreak/cookies.sp"
#include "jailbreak/color.sp"
#include "jailbreak/warday.sp"

public Plugin:myinfo = 
{
	name = "Private Warden plugin",
	author = PLUGIN_AUTHOR,
	description = "warden and special days for jailbreak",
	version = PLUGIN_VERSION,
	url = "https://github.com/destoer/css_jailbreak_plugins"
};

// todo
// lr leaderboard (hard)
// draw toggle for t's (done)
// trivia generator (hard)


public int native_get_warden_id(Handle plugin, int num_param)
{
	return warden_id;
}

public int native_remove_warden(Handle plugin, int num_param)
{
	remove_warden();

	return 0;
}


// register our call
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("get_warden_id", native_get_warden_id);
	CreateNative("remove_warden", native_remove_warden);

	MarkNativeAsOptional("sd_current_state");
	MarkNativeAsOptional("sd_current_day");

	return APLRes_Success;
}

native bool IsClientSpeaking(int client);

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
/*
	// if on a laser day dont allow lasers
	if(sd_current_day() == laser_day && sd_current_state() != sd_inactive)
	{
		return Plugin_Continue;
	}
*/	
	// reset laser cords we are no longer drawing
	if(!(buttons & IN_USE))
	{
		prev_pos[client][0] = 0.0;
		prev_pos[client][1] = 0.0;
		prev_pos[client][2] = 0.0;
		laser_use[client] = false;
		return Plugin_Continue;
	}
	
	// allways draw standard laser!
	// only warden or admin can shine laser
	bool is_warden = (client == warden_id);
	
	laser_type type;
	
	
	if(is_warden)
	{
		// custom flag required to do use color changed laser
#if defined LASER_COLOR_CUSTOM_FLAGS
		if(CheckCommandAccess(client, "generic_admin",DONATOR, false))
		{
			type = donator;
		}
		
		else
		{
			type = warden;
		}
#else
		type = donator;
#endif		
	}
	
	else if(CheckCommandAccess(client, "generic_admin", ADMIN, false))
	{
		type = admin;
	}

	else
	{
		type = none;
	}
	
	if(type != none)
	{
		laser_use[client] = true;
		if(IsClientInGame(client) && laser_use[client])
		{

		
			switch(type)
			{
				case warden:
				{
					SetupLaser(client,laser_colors[5]);
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
		if(!laser_use[client])
		{
			get_client_sight_end(client, prev_pos[client]);
		}
		laser_use[client] = true;
	}

	return Plugin_Continue;
}


// NOTE: SM 1.11 use OnClientSpeaking
public void OnClientSpeakingEx(int client)
{
	if(voice && GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client) && client != warden_id)
	{
		set_warden(client);
	}
}


public OnMapStart()
{
	// prechache circle sprites
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	
	
	
	// precache laser sprites
	g_lbeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_lpoint = PrecacheModel("materials/sprites/glow07.vmt");
	PrecacheSound("bot\\what_have_you_done.wav");
	
	// laser draw timer
	CreateTimer(0.1, laser_draw, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	
	// reset laser settings
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		laser_use[i] = false;
		use_draw_laser_settings[i] = false;
	}
	
	
	gun_menu = build_gun_menu(WeaponHandler);

	if(noblock)
	{
		disable_block_all();
	}

	else
	{
		enable_block_all();
	}
}

public OnMapEnd()
{
	delete gun_menu;
}

// If the Warden leaves


public void OnClientConnected(int client)
{
	laser_use[client] = false;
	if(!AreClientCookiesCached(client))
	{
		use_draw_laser_settings[client] = false;
		laser_color[client] = 0;
	}
}

public void OnClientDisconnect(int client)
{
	laser_use[client] = false;
	use_draw_laser_settings[client] = false;
	laser_color[client] = 0;
	if(client == warden_id)
	{
		warden_id = WARDEN_INVALID;
		PrintToChatAll("%s Warden has left the game!", WARDEN_PREFIX);
	}
}


public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	// hide commands typed by sudoers
	if(is_sudoer(client) && (sArgs[0] == '/' || sArgs[0] == '!'))
	{
		return Plugin_Handled;
	}    
	
	
	if (warden_id == client)
	{
		char color1[] = "\x07000000";
		char color2[] = "\x07FFC0CB";

		if(GetEngineVersion() == Engine_CSGO)
		{
			Format(color1,strlen(color1),"\x06");
			Format(color2,strlen(color2),"\x06");
		}

		if (is_valid_client(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	    {
	        if (!StrEqual(command, "say_team"))
	        {    
	                if (!CheckCommandAccess(client, "sm_say", ADMFLAG_CHAT))
	                {
	                    PrintToChatAll("%s %N %s: %s%s", WARDEN_PLAYER_PREFIX, client,color1,color2, sArgs);
	                    LogAction(client, -1, "[Warden] %N : %s", client, sArgs);
	                    return Plugin_Handled;                    
	                }
	                else 
	                {
	                    if (sArgs[0] != '@')
	                    {
	                        PrintToChatAll("%s %N %s: %s%s", WARDEN_PLAYER_PREFIX, client,color1,color2, sArgs);
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
	                        PrintToChat(i, "%s %N %s: %s%s", WARDEN_PLAYER_PREFIX, client,color1,color2, sArgs);
	                        LogAction(client, -1, "[Warden] %N : %s", client, sArgs);
	                    }
	                }
	            }
	            return Plugin_Handled;
	        }
	    }
		else
	    {
	        PrintToChatAll("%s %N %s: %s%s", WARDEN_PLAYER_PREFIX, client,color1,color2, sArgs);
	        LogAction(client, -1, "[Warden] %N : %s", client, sArgs);
	        return Plugin_Handled;
	    }   
	}
	
	
	
	return Plugin_Continue;
}


// init the plugin
public OnPluginStart()
{
	create_jb_convar();

	setup_jb_convar();
	
	SetCollisionGroup = init_set_collision();
	
	// user commands
	
	RegConsoleCmd("wd", warday_callback);


	if(warden_block)
	{
		RegConsoleCmd("wub", disable_block_warden_callback);
		RegConsoleCmd("wb", enable_block_warden_callback);
	}

	RegConsoleCmd("w", become_warden);
	RegConsoleCmd("uw", leave_warden);

	if(gun_commands)
	{
		RegConsoleCmd("wempty", empty_menu);
		RegConsoleCmd("guns", weapon_menu);
	}

	

	// command_stuck is push out callback
	// we currently use the noblock toggle callback
	if(stuck)
	{
		// workaround for csgo wont support this neatly
		if(SetCollisionGroup == INVALID_HANDLE)
		{
			RegConsoleCmd("stuck", command_stuck);
		}
	}
	
	
	// admin commands
	RegAdminCmd("sm_rw", fire_warden, ADMFLAG_KICK);
	RegAdminCmd("block", enable_block_admin, ADMFLAG_BAN);
	RegAdminCmd("ublock",disable_block_admin, ADMFLAG_BAN);	
	RegAdminCmd("force_open", force_open_callback, ADMFLAG_UNBAN);

	if(laser_death)
	{
		// toggle kill and safe laser
		RegAdminCmd("kill_laser", kill_laser, ADMFLAG_CUSTOM6);
		RegAdminCmd("safe_laser", safe_laser, ADMFLAG_CUSTOM6);
	}



	// custom flag required to do draw laser
#if defined DRAW_CUSTOM_FLAGS 
	RegAdminCmd("laser", laser_menu, MEMBER);
#else
	RegConsoleCmd("laser", laser_menu);
#endif


	if(t_laser)
	{
		RegConsoleCmd("tlaser", t_laser_menu);
	}

#if defined LASER_COLOR_CUSTOM_FLAGS
	RegAdminCmd("laser_color", command_laser_color, ADMFLAG_CUSTOM4);
#else
	RegConsoleCmd("laser_color", command_laser_color);
#endif
	
	RegConsoleCmd("color", warden_color);
	RegConsoleCmd("reset_color", warden_reset_color);
	
	RegConsoleCmd("wv", jailbreak_version);
	RegConsoleCmd("is_blocked", is_blocked_cmd);
	RegConsoleCmd("wd_rounds",wd_rounds);
	RegConsoleCmd("enable_wd",enable_wd);
	
	// hooks
	HookEvent("round_start", round_start); // For the round start
	HookEvent("player_spawn", player_spawn); 
	HookEvent("player_death", player_death); // To check when our warden dies :)
	HookEvent("player_team", player_team);
	
	// create a timer for a the warden text
	CreateTimer(1.0, print_warden_text_all, _, TIMER_REPEAT);
	
	// if no block is default
	if(noblock)
	{
		disable_block_all();
	}

	else
	{
		enable_block_all();
	}
	
	
	// Start a circle timer
	CreateTimer(0.1, Repetidor, _, TIMER_REPEAT);
	CreateTimer(0.3, rainbow_timer, _, TIMER_REPEAT);
	PrecacheSound("bot\\what_have_you_done.wav");
	
	register_cookies();
}


// if warden drops into spec remove them
public Action player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid")); 

	if(client == warden_id)
	{
		remove_warden();
	}

	return Plugin_Handled;
}

public Action force_open_callback (int client, int args)
{
	force_open();

	return Plugin_Handled;
}

// Top Screen Warden Printing
public Action print_warden_text_all(Handle timer)
{

	
	if(sd_current_state() != sd_inactive)
	{
		return Plugin_Continue;
	}
	
	char buf[256];
	

	
	if(!warday_active)
	{
		if(warden_id != WARDEN_INVALID)
		{
			
			Format(buf, sizeof(buf), "Current Warden: %N", warden_id);
		}


		else
		{
			Format(buf, sizeof(buf), "Current Warden: N/A");
		}
	}

	else
	{
		Format(buf, sizeof(buf), "Warday %s",warday_loc);
	}
	
	
	
	Handle h_hud_text = CreateHudSynchronizer();
	if(GetEngineVersion() == Engine_CSGO)
	{
		// TODO drawing is scuffed on csgo for some monitor sizes
        //SetHudTextParams(1.5, -1.7, 1.0, 255, 255, 255, 255);
	}
	
	else
	{
        SetHudTextParams(1.5, -1.7, 1.0, 255, 255, 255, 255);
    }
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
// \n doesent work apparently...
public print_warden_commands(client)
{
	char color1[] = "\x07FF0000";
	char color2[] = "\x07800080";
	char color3[] = "\x07F8F8FF";

	if(GetEngineVersion() == Engine_CSGO)
	{
		Format(color1,strlen(color1),"\x07");
		Format(color2,strlen(color2),"\x01");
		Format(color3,strlen(color3),"\x04");
	}


	PrintToChat(client,"%s!w           %s- %sbecome warden",color1,color2,color3);
	PrintToChat(client,"%s!uw         %s- %sexit warden",color1,color2,color3);

	if(warden_block)
	{
		PrintToChat(client,"%s!wb         %s- %sturn on block",color1,color2,color3);
		PrintToChat(client,"%s!wub       %s- %sturn off block",color1,color2,color3);
	}

	PrintToChat(client,"%s!laser       %s- %sswitch point/draw laser",color1,color2,color3);
	PrintToChat(client,"%s!laser_color       %s- %schange laser color",color1,color2,color3);
	PrintToChat(client,"%s!marker  %s- %s+marker, use mouse to adjust size, then -marker",color1,color2,color3);


	PrintToChat(client,"%s!wsd           %s- %sstart sd after %d rounds",color1,color2,color3,ROUND_WARDEN_SD);
	PrintToChat(client,"%s!wsd_ff           %s- %sstart ff sd after %d rounds",color1,color2,color3,ROUND_WARDEN_SD);
	PrintToChat(client,"%s!wd %s- %scall a warday %s",color1,color2,color3, warday_round_counter >= WARDAY_ROUND_COUNT? "ready" : "not ready");


	if(t_laser)
	{
		PrintToChat(client,"%s!tlaser           %s- %stoggle laser for t's'",color1,color2,color3);
	}	

	PrintToChat(client,"%s!color           %s- %scolor players'",color1,color2,color3);	
	PrintToChat(client,"%s!reset_color           %s- %sreset player colors'",color1,color2,color3);	
	

}

public set_warden(int client)
{


	// dont bother doing this on sds
	if(sd_current_state() == sd_active)
	{
		return;
	}

	if(is_sudoer(client))
	{

		EmitSoundToAll("bot\\what_have_you_done.wav");
	}



	PrintCenterTextAll("New Warden: %N", client);
	
	PrintToChatAll("%s New Warden: %N", WARDEN_PREFIX, client);
	
	// set the actual warden
	warden_id = client;
	
	print_warden_commands(warden_id);
	
	// set the warden with special color
	SetEntityRenderColor(warden_id, 0, 191, 0, 255);

}

public Action player_death(Handle event, const String:name[], bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid")); // Get the dead clients id
	
	
	// if its the warden we need to remove him
	if(client == warden_id)
	{
		remove_warden();
	}
	
	int new_warden = 0;
	// if there is only one ct left alive automatically warden him
	if(get_alive_team_count(CS_TEAM_CT,new_warden) == 1 && new_warden != 0)
	{
		if(warden_id == WARDEN_INVALID)
		{
			set_warden(new_warden);
		}
	}

	return Plugin_Continue;
}

// give ct equitment on spawn & set block
public Action player_spawn(Handle event, const String:name[], bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(is_valid_client(client))
	{
		if(sd_current_state() == sd_inactive)
		{
		
			//taking this information off clients is not functioning reliably
		
			// ignore clients setting as its unreliable
			// the first round we cant rely on it to be set as there are no players
			// apparently hoping a empty team join will force a round reset aint good enough
			
			int dummy = 0;
			bool first_round = CS_GetTeamScore(CS_TEAM_CT) + CS_GetTeamScore(CS_TEAM_T) <= 0;
			bool force_setting = first_round || get_alive_team_count(GetClientTeam(client), dummy) <= 1;

			if(noblock && (noblock_enabled(client) || force_setting))
			{
				unblock_client(client, SetCollisionGroup);
			}
	
			else if(!noblock && (!noblock_enabled(client) || force_setting))
			{
				block_client(client, SetCollisionGroup);
			}

			else
			{
				unblock_client(client, SetCollisionGroup);
			}		
		}
				
		if(GetClientTeam(client) == CS_TEAM_CT && armor)
		{
			GivePlayerItem(client, "item_assaultsuit");
			GivePlayerItem(client, "item_kevlar");
			SetEntProp(client , Prop_Send, "m_ArmorValue", 50, 1);
		}
	}

	return Plugin_Continue;
}


public Action round_start(Handle event, const String:name[], bool dontBroadcast) 
{
	warday_active = false;
	warday_round_counter++;

	reset_laser_setting();
	
	// if we are running with block on reset the status on round start
	if(noblock)
	{
		disable_block_all();
	}

	else
	{
		enable_block_all();
	}
	
	// there is no warden
	warden_id = -1;
	
	laser_kill = false;
	
	// 1 ct only on team auto warden them at start of round
	int client = 0;
	if(get_alive_team_count(CS_TEAM_CT, client) == 1 && client != 0)
	{
		set_warden(client);
	}
	
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
