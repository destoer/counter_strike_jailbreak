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

//uncomment to make noblock default 
//#define NOBLOCK_DEFAULT


#define CT_ARMOUR  // 50 armour for ct on spawn
//#define CT_KEVLAR_HELMET // kevlar + helment for cts 
//#define STUCK
#define LASER_DEATH
#define GUN_COMMANDS
#define T_LASER

#define DONATOR 	ADMFLAG_CUSTOM1
#define MEMBER 		ADMFLAG_CUSTOM2
#define ADMIN		ADMFLAG_BAN
#define DEBUG

#define PLUGIN_AUTHOR "organharvester, jordi"
#define PLUGIN_VERSION "V3.4.2 - Violent Intent Jailbreak"

/*
#define ANTISTUCK_PREFIX "\x07FF0000[VI Antistuck]\x07F8F8FF"
#define JB_PREFIX "[VI Jailbreak]"
#define WARDEN_PREFIX "\x07FF0000[VI Warden]\x07F8F8FF"
#define WARDEN_PLAYER_PREFIX "\x07FF0000[VI Warden]\x07F8F8FF"
#define PTS_PREFIX "\x07F8F8FF"
*/


/*
#define ANTISTUCK_PREFIX "\x07FF0000[GK Antistuck]\x07F8F8FF"
#define JB_PREFIX "[GameKick Jailbreak]"
#define WARDEN_PREFIX "\x07FFFF33[GameKick - Warden]\x07F8F8FF"
#define WARDEN_PLAYER_PREFIX "\x0700008B[Warden]\x07F8F8FF"
#define PTS_PREFIX "\x07F8F8FF"
*/

/*
#define ANTISTUCK_PREFIX "\x07FF0000[3E Antistuck]\x07F8F8FF"
#define JB_PREFIX "[3E Jailbreak]"
#define WARDEN_PREFIX "\x07FF0000[3E Warden]\x07F8F8FF"
#define WARDEN_PLAYER_PREFIX "\x07FF0000[3E Warden]\x07F8F8FF"
#define PTS_PREFIX "\x07F8F8FF"
*/

/*
#define ANTISTUCK_PREFIX_CSS "\x07FF0000[Antistuck]\x07F8F8FF"
#define JB_PREFIX_CSS "\x04[GP Jailbreak]\x07F8F8FF"
#define WARDEN_PREFIX_CSS "\x04[GP Warden]\x07F8F8FF"
#define WARDEN_PLAYER_PREFIX_CSS "\x04[GP Warden]\x0700BFFF"
#define PTS_PREFIX_CSS "\x07F8F8FF"

#define ANTISTUCK_PREFIX_CSGO "\x07[Antistuck]\x07"
#define JB_PREFIX_CSGO "\x07[GP Jailbreak]\x07"
#define WARDEN_PREFIX_CSGO "\x07[GP Warden]\x07"
#define WARDEN_PLAYER_PREFIX_CSGO "\x07[GP Warden]\x07"
#define PTS_PREFIX_CSGO "\x07"
*/

/*
#define ANTISTUCK_PREFIX_CSS "\x07FF0000[Antistuck]\x07F8F8FF"
#define JB_PREFIX_CSS "\x04[3E Jailbreak]\x07F8F8FF"
#define WARDEN_PREFIX_CSS "\x04[3E Warden]\x07F8F8FF"
#define WARDEN_PLAYER_PREFIX_CSS "\x04[3E Warden]\x0700BFFF"
#define PTS_PREFIX_CSS "\x07F8F8FF"

#define ANTISTUCK_PREFIX_CSGO "\x07[Antistuck]\x07"
#define JB_PREFIX_CSGO "\x07[3E Jailbreak]\x07"
#define WARDEN_PREFIX_CSGO "\x07[3E Warden]\x07"
#define WARDEN_PLAYER_PREFIX_CSGO "\x07[3E Warden]\x07"
#define PTS_PREFIX_CSGO "\x07"
*/

/*
#define ANTISTUCK_PREFIX_CSS "\x07FF0000[Antistuck]\x07F8F8FF"
#define JB_PREFIX_CSS "\x04[EgN | Jailbreak]\x07F8F8FF"
#define WARDEN_PREFIX_CSS "\x04[EgN | Warden]\x07F8F8FF"
#define WARDEN_PLAYER_PREFIX_CSS "\x04[EgN | Warden]\x0700BFFF"
#define PTS_PREFIX_CSS "\x07F8F8FF"

#define ANTISTUCK_PREFIX_CSGO "\x07[Antistuck]\x07"
#define JB_PREFIX_CSGO "\x07[EgN | Jailbreak]\x07"
#define WARDEN_PREFIX_CSGO "\x07[EgN | Warden]\x07"
#define WARDEN_PLAYER_PREFIX_CSGO "\x07[EgN | Warden]\x07"
#define PTS_PREFIX_CSGO "\x07"
*/

#define ANTISTUCK_PREFIX_CSS "\x07FF0000[Antistuck]\x07F8F8FF"
#define JB_PREFIX_CSS "\x04[NLG | Jailbreak]\x07F8F8FF"
#define WARDEN_PREFIX_CSS "\x04[NLG | Warden]\x07F8F8FF"
#define WARDEN_PLAYER_PREFIX_CSS "\x04[NLG | Warden]\x0700BFFF"
#define PTS_PREFIX_CSS "\x07F8F8FF"

#define ANTISTUCK_PREFIX_CSGO "\x07[Antistuck]\x07"
#define JB_PREFIX_CSGO "\x07[NLG | Jailbreak]\x07"
#define WARDEN_PREFIX_CSGO "\x07[NLG | Warden]\x07"
#define WARDEN_PLAYER_PREFIX_CSGO "\x07[NLG | Warden]\x07"
#define PTS_PREFIX_CSGO "\x07"

char ANTISTUCK_PREFIX[] = ANTISTUCK_PREFIX_CSS;
char JB_PREFIX[] = JB_PREFIX_CSS;
char WARDEN_PREFIX[] = WARDEN_PREFIX_CSS;
char WARDEN_PLAYER_PREFIX[] = WARDEN_PLAYER_PREFIX_CSS;
char PTS_PREFIX[] = PTS_PREFIX_CSS;

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
#include "jailbreak/stuck.inc"
#include "jailbreak/guns.inc"
#include "jailbreak/laser.inc"
#include "jailbreak/circle.inc"
#include "jailbreak/block.inc"
#include "jailbreak/debug.inc"
#include "jailbreak/cookies.inc"
#include "jailbreak/color.inc"


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
}


// register our call
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
   CreateNative("get_warden_id", native_get_warden_id);
   CreateNative("remove_warden", native_remove_warden);
   return APLRes_Success;
}


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

/*
// used for hooking voice command (USEUD)
public void OnClientSpeakingEx(client)
{
	if(GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client) && client != warden_id)
	{
		set_warden(client);
	}
}
*/


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

#if defined NOBLOCK_DEFAULT
		disable_block_all();
#else
		enable_block_all();
#endif
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
	EngineVersion game = GetEngineVersion();
	if(game != Engine_CSGO && game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	

	// init text
	if(game == Engine_CSGO)
	{
		Format(ANTISTUCK_PREFIX,strlen(ANTISTUCK_PREFIX),ANTISTUCK_PREFIX_CSGO);
		Format(JB_PREFIX,strlen(JB_PREFIX),JB_PREFIX_CSGO);
		Format(WARDEN_PLAYER_PREFIX,strlen(WARDEN_PLAYER_PREFIX),WARDEN_PLAYER_PREFIX_CSGO);
		Format(WARDEN_PREFIX,strlen(WARDEN_PREFIX),WARDEN_PREFIX_CSGO);
		Format(PTS_PREFIX,strlen(PTS_PREFIX),PTS_PREFIX_CSGO);		
	}


	
	SetCollisionGroup = init_set_collision();
	
	// user commands
	RegConsoleCmd("wb", enable_block_warden_callback);
	RegConsoleCmd("wub", disable_block_warden_callback);	
	RegConsoleCmd("w", become_warden);
	RegConsoleCmd("uw", leave_warden);
#if defined GUN_COMMANDS
	RegConsoleCmd("wempty", empty_menu);
	RegConsoleCmd("guns", weapon_menu);
#endif

	
	// disabled
	// command_stuck is push out callback
	// we currently use the noblock toggle callback
	#if defined STUCK
	// workaround for csgo wont support this neatly
	if(SetCollisionGroup == INVALID_HANDLE)
	{
		RegConsoleCmd("stuck", command_stuck);
	}
	#endif		
	RegConsoleCmd("sm_samira", samira_EE);
	
	// admin commands
	RegAdminCmd("sm_rw", fire_warden, ADMFLAG_KICK);
	RegAdminCmd("block", enable_block_admin, ADMFLAG_BAN);
	RegAdminCmd("ublock",disable_block_admin, ADMFLAG_BAN);	
	RegAdminCmd("force_open", force_open_callback, ADMFLAG_UNBAN);

#if defined LASER_DEATH
	// toggle kill and safe laser
	RegAdminCmd("kill_laser", kill_laser, ADMFLAG_CUSTOM6);
	RegAdminCmd("safe_laser", safe_laser, ADMFLAG_CUSTOM6);
	
#endif
	// custom flag required to do draw laser
#if defined DRAW_CUSTOM_FLAGS 
	RegAdminCmd("laser", laser_menu, MEMBER);
#else
	RegConsoleCmd("laser", laser_menu);
#endif

#if defined T_LASER	
	RegConsoleCmd("tlaser", t_laser_menu);
#endif

#if defined LASER_COLOR_CUSTOM_FLAGS
	RegAdminCmd("laser_color", command_laser_color, ADMFLAG_CUSTOM4);
#else
	RegConsoleCmd("laser_color", command_laser_color);
#endif
	
	RegConsoleCmd("color", warden_color);
	RegConsoleCmd("reset_color", warden_reset_color);
	
	RegConsoleCmd("wv", jailbreak_version);
	RegConsoleCmd("is_blocked", is_blocked_cmd);
	
	// hooks
	HookEvent("round_start", round_start); // For the round start
	HookEvent("player_spawn", player_spawn); 
	HookEvent("player_death", player_death); // To check when our warden dies :)
	HookEvent("player_team", player_team);
	
	// create a timer for a the warden text
	CreateTimer(1.0, print_warden_text_all, _, TIMER_REPEAT);
	
	// if no block is default
#if defined NOBLOCK_DEFAULT
		disable_block_all();
#else
		enable_block_all();
#endif
	
	
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
}

public Action force_open_callback (int client, int args)
{
	force_open();
}

// Top Screen Warden Printing
public Action print_warden_text_all(Handle timer)
{

	
	if(sd_current_state() != sd_inactive)
	{
		return Plugin_Continue;
	}
	
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
	PrintToChat(client,"%s!wb         %s- %sturn on block",color1,color2,color3);
	PrintToChat(client,"%s!wub       %s- %sturn off block",color1,color2,color3);
	PrintToChat(client,"%s!laser       %s- %sswitch point/draw laser",color1,color2,color3);
	PrintToChat(client,"%s!laser_color       %s- %schange laser color",color1,color2,color3);
	PrintToChat(client,"%s!marker  %s- %s+marker, use mouse to adjust size, then -marker",color1,color2,color3);
	PrintToChat(client,"%s!wsd           %s- %sstart sd after %d rounds",color1,color2,color3,ROUND_WARDEN_SD);
#if defined T_LASER
	PrintToChat(client,"%s!tlaser           %s- %stoggle laser for t's'",color1,color2,color3);
#endif	
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
#if defined NOBLOCK_DEFAULT
			if(noblock_enabled(client) || force_setting)
			{
				unblock_client(client, SetCollisionGroup);
			}			
#else
			if(!noblock_enabled(client) || force_setting)
			{
				block_client(client, SetCollisionGroup);
			}
#endif
			else
			{
				unblock_client(client, SetCollisionGroup);
			}		
		}
				
		if(GetClientTeam(client) == CS_TEAM_CT)
		{
			#if defined CT_KEVLAR_HELMET
				GivePlayerItem(client, "item_assaultsuit");
			#elseif defined CT_ARMOUR
				GivePlayerItem(client, "item_kevlar");
				SetEntProp(client , Prop_Send, "m_ArmorValue", 50, 1);
			#endif
		}
	}
}


public Action round_start(Handle event, const String:name[], bool dontBroadcast) 
{
	reset_laser_setting();
	
	// if we are running with block on reset the status on round start
	#if defined NOBLOCK_DEFAULT // does sourcemod have #ifndef?
		disable_block_all();
	#else
		enable_block_all();
	#endif
	
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
