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
//#define VOICE_ANNOUNCE_HOOK

#define PLUGIN_AUTHOR "destoer(organ harvester), jordi, ashort"
#define PLUGIN_VERSION "V3.8.2 - Violent Intent Jailbreak"

/*
	onwards to the new era ( ͡° ͜ʖ ͡°)
*/


#define WARDAY_ROUND_COUNT 3


// global vars



// handle for sdkcall
Handle SetCollisionGroup;

// handles for client cookies
Handle client_laser_draw_pref;
Handle client_laser_color_pref;
Handle client_warden_text_pref;


const int WARDEN_INVALID = -1;

enum struct Context
{
	int z_command_count;

	// currernt warden
	int warden_id;
	int tmp_mute_timestamp;
	bool ct_handicap;
	bool spawn_block_override;

	int lenny_rand;
	int lenny_count;

	bool warday_active;
	int warday_round_counter;
	char warday_loc[20];

	bool stuck_timer;

	bool laser_kill;

	bool first_warden;

	Handle warden_to_lr_forward;

	int cell_door_hammer_id;

	int warden_command_countdown;

	// 2048 / 32
	// bitset weapon picked up this round
	int weapon_picked[64];

	Handle command_end_timer;
}

// player configs
enum struct Player
{
	bool rebel;
	bool warden_text;
	
	bool draw_laser;
	bool laser_use;
	int laser_color;
	float prev_pos[3];
	bool t_laser;

	// how many guns has the player picked up
	int pickup_count;
}

Player jb_players[MAXPLAYERS + 1];
Context global_ctx;

void reset_context()
{
	global_ctx.z_command_count = 0;

	global_ctx.warden_id = WARDEN_INVALID;
	global_ctx.ct_handicap = false;

	global_ctx.warday_active = false;

	global_ctx.stuck_timer = false;

	global_ctx.laser_kill = false;

	for(int i = 0; i < 64; i++)
	{
		global_ctx.weapon_picked[i] = 0;
	}

	global_ctx.warden_command_countdown = 0;

	global_ctx.first_warden = true;

	kill_handle(global_ctx.command_end_timer);
}

void init_context()
{
	reset_context();

	global_ctx.warday_round_counter = 0;
	global_ctx.cell_door_hammer_id = -1;

	global_ctx.spawn_block_override = false;
}

void init_player(int client)
{
	reset_player(client);

	jb_players[client].laser_color = 0;
	jb_players[client].warden_text = false;
	jb_players[client].draw_laser = false;
}

void reset_player(int client)
{
	jb_players[client].rebel = false;

	jb_players[client].laser_use = false;
	jb_players[client].t_laser = false;

	for(int i = 0; i < 3 ; i++)
	{
		jb_players[client].prev_pos[i] = 0.0;
	}

	jb_players[client].pickup_count = 0;
}

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <basecomm>
#include "lib.inc"
#include "specialday/specialday.inc"
#include "lr/lr.inc"

// cookies
#include <clientprefs>


// split files for this plugin
#include "jailbreak/config.sp"
#include "jailbreak/block.sp"
#include "jailbreak/stuck.sp"
#include "jailbreak/guns.sp"
#include "jailbreak/laser.sp"
#include "jailbreak/debug.sp"
#include "jailbreak/cookies.sp"
#include "jailbreak/color.sp"
#include "jailbreak/warday.sp"
#include "jailbreak/circle.sp"
#include "jailbreak/mute.sp"
#include "jailbreak/door_control.sp"


int g_ExplosionSprite = -1;

public Plugin:myinfo = 
{
	name = "Private Warden plugin",
	author = PLUGIN_AUTHOR,
	description = "warden for jailbreak",
	version = PLUGIN_VERSION,
	url = "https://github.com/destoer/css_jailbreak_plugins"
};

// todo
// trivia generator (hard)


public int native_get_warden_id(Handle plugin, int num_param)
{
	return global_ctx.warden_id;
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
	MarkNativeAsOptional("in_lr");

	global_ctx.warden_to_lr_forward = CreateGlobalForward("OnWardenToLR",ET_Ignore,Param_Cell);

	return APLRes_Success;
}

native bool IsClientSpeaking(int client);

bool sd_enabled()
{
	return check_command_exists("sd");
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
/*
	// if on a laser day dont allow lasers
	if(sd_enabled() && sd_current_day() == laser_day && sd_current_state() != sd_inactive)
	{
		return Plugin_Continue;
	}
*/	
	bool in_use = (buttons & IN_USE) != 0;
	jb_players[client].laser_use = in_use;


	if(!in_use)
	{
		// reset laser posistion
		for(int i = 0; i < 3; i++)
		{
			jb_players[client].prev_pos[i] = 0.0;
		}

		return Plugin_Continue;
	}

	
	// allways draw standard laser!
	// only warden or admin can shine laser
	bool is_warden = (client == global_ctx.warden_id);
	
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
	
	else if(CheckCommandAccess(client, "generic_admin", ADMIN, false) && admin_laser)
	{
		type = admin;
	}

	else
	{
		type = none;
	}
	
	if(type != none)
	{
		if(is_valid_client(client))
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
					SetupLaser(client,laser_colors[jb_players[client].laser_color]);
				}
			}
		}
	}

	return Plugin_Continue;
}


void voice_internal(int client)
{
	if(voice && GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client) && global_ctx.warden_id == WARDEN_INVALID)
	{
		set_warden(client);
	}	
}

#if defined VOICE_ANNOUNCE_HOOK

// provided for back compat
public void OnClientSpeakingEx(int client)
{
	voice_internal(client);
}

#else

// NOTE: requires SM 1.11
public void OnClientSpeaking(int client)
{
	voice_internal(client);
}

#endif

public OnMapStart()
{
	// prechache circle sprites
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	

	// precache laser sprites
	g_lbeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_lpoint = PrecacheModel("materials/sprites/glow07.vmt");


	PrecacheSound("bot\\what_have_you_done.wav");
	PrecacheSound("bot\\its_all_up_to_you_sir.wav");
	PrecacheSound("ambient/explosions/explode_8.wav", true);
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	
	// laser draw timer
	CreateTimer(0.01, laser_draw, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	if(warden_ring)
	{
		CreateTimer(RING_LIFTEIME,beacon_callback , _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	CreateTimer(0.3, rainbow_timer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	// clear info
	init_context();

	for (int i = 1; i <= MAXPLAYERS; i++)
	{
		init_player(i);
	}
	
	
	gun_menu = build_gun_menu(WeaponHandler,true);

	if(noblock)
	{
		jb_disable_block_all();
	}

	else
	{
		jb_enable_block_all();
	}

	mute_timer = null;

	database_connect();

	setup_jb_convar();

	// enable a warday on map start
	global_ctx.warday_round_counter = WARDAY_ROUND_COUNT;	
}

public OnMapEnd()
{
	delete gun_menu;
}


// need to use this to be able to call client funcs
// thanks tring
public void OnClientPutInServer(int client)
{
	reset_player(client);

	if(!AreClientCookiesCached(client))
	{
		init_player(client);
	}

	// on any connection player cannot talk, they must be on a team
	if(mute)
	{
		mute_client(client);
	}

	SDKHook(client, SDKHook_OnTakeDamage, take_damage);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip); 
}

// If the Warden leaves
public void OnClientDisconnect(int client)
{
	// clear all player info
	init_player(client);

	if(client == global_ctx.warden_id)
	{
		global_ctx.warden_id  = WARDEN_INVALID;
		PrintToChatAll("%s Warden has left the game!", WARDEN_PREFIX);
	}
}


public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	// hook zombie commands
	if(StrContains(sArgs,"ztele") != -1 || StrContains(sArgs,"zspawn") != -1)
	{
		global_ctx.z_command_count++;
		if(global_ctx.z_command_count >= 3)
		{
			ForcePlayerSuicide(client);
		}

		else
		{
			PrintToChatAll("%s %N just tried to do something very stupid",JB_PREFIX,client);
		}

		return Plugin_Handled;
	}

	// hide commands typed by sudoers
	if(is_sudoer(client) && (sArgs[0] == '/' || sArgs[0] == '!'))
	{
		return Plugin_Handled;
	}    
	
	if(StrContains(command,"( ͡° ͜ʖ ͡°)"))
	{
		global_ctx.lenny_count += 1;

		//PrintToConsole(client,"%d == %d?\n",lenny_rand,global_ctx.lenny_count);
		if(global_ctx.lenny_rand == global_ctx.lenny_count)
		{
			global_ctx.lenny_rand = GetRandomInt(global_ctx.lenny_count,global_ctx.lenny_count + 10000);

			PrintToChat(client,"%s For some reason you feel lucky ( ͡° ͜ʖ ͡°)",JB_PREFIX);
			GivePlayerItem(client,"weapon_flashbang");
			GivePlayerItem(client,"weapon_hegrenade");
			GivePlayerItem(client,"weapon_smokegrenade");
			GivePlayerItem(client,"item_assaultsuit");
		}
	}
	
	if (global_ctx.warden_id == client && is_valid_client(client))
	{
		char color1[] = "\x07000000";
		char color2[] = "\x07FFC0CB";

		if(GetEngineVersion() == Engine_CSGO)
		{
			Format(color1,strlen(color1),"\x06");
			Format(color2,strlen(color2),"\x06");
		}


		if(sArgs[0] == '@')
		{
			return Plugin_Continue;
		}

		else if (!StrEqual(command, "say_team"))
		{    
			PrintToChatAll("%s %N %s: %s%s", WARDEN_PLAYER_PREFIX, client,color1,color2, sArgs);
			LogAction(client, -1, "[Warden] %N : %s", client, sArgs);
			return Plugin_Handled;	
		}

		// ct team chat
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (is_valid_client(i) && GetClientTeam(i) == CS_TEAM_CT && sArgs[0] != '@')
				{
					PrintToChat(i, "%s (Counter-Terrorist) %N %s: %s%s", WARDEN_PLAYER_PREFIX, client,color1,color2, sArgs);
					LogAction(client, -1, "[Warden CT] %N : %s", client, sArgs);
				}
			}
			return Plugin_Handled;
		}
	}
	
	
	
	return Plugin_Continue;
}

// init the plugin
public OnPluginStart()
{
	global_ctx.lenny_count = 0;
	global_ctx.lenny_rand = GetRandomInt(global_ctx.lenny_count,global_ctx.lenny_count + 10000);

	create_jb_convar();
	setup_jb_convar();
	
	SetCollisionGroup = init_set_collision();


	// user commands
	RegConsoleCmd("wd", warday_callback);
	RegConsoleCmd("warday", warday_callback);

	RegConsoleCmd("lenny_count",lenny_count_cmd);


	if(warden_block)
	{
		RegConsoleCmd("wub", disable_block_warden_callback);
		RegConsoleCmd("wb", enable_block_warden_callback);
	}

	RegConsoleCmd("w", become_warden);
	RegConsoleCmd("uw", leave_warden);

	RegConsoleCmd("wm",tmp_warden_mute);

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
		if(SetCollisionGroup != INVALID_HANDLE)
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
	RegConsoleCmd("warden_text",warden_text_menu);


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
	RegConsoleCmd("is_muted", is_muted_cmd);
	RegConsoleCmd("is_rebel", is_rebel_cmd);
	RegConsoleCmd("wd_rounds",wd_rounds);
	RegAdminCmd("enable_wd",enable_wd,ADMFLAG_CUSTOM6);
	RegConsoleCmd("spawn_count",spawn_count_cmd);
	RegConsoleCmd("ent_count",ent_count);
	RegConsoleCmd("is_stuck",is_stuck_cmd);

	RegConsoleCmd("wcommands",warden_commands);
	
	RegConsoleCmd("open_cell",force_cell_doors_cmd);
	RegAdminCmd("set_cell_button",set_cell_button_cmd,ADMFLAG_KICK);

	// hooks
	HookEvent("round_start", round_start); // For the round start
	HookEvent("round_end", round_end); // For the round start
	HookEvent("player_spawn", player_spawn); 
	HookEvent("player_death", player_death); // To check when our warden dies :)
	HookEvent("player_team", player_team);
	HookEvent("weapon_fire",OnWeaponFire,EventHookMode_Post);
	
	HookEntityOutput("func_button", "OnPressed", OnButtonPressed);

	AddCommandListener(Command_Drop, "drop");

	// create a timer for a the warden text
	CreateTimer(1.0, print_warden_text_all, _, TIMER_REPEAT);
	
	// if no block is default
	if(noblock)
	{
		jb_disable_block_all();
	}

	else
	{
		jb_enable_block_all();
	}
	
	for(int i = 1; i <= MaxClients;i++)
	{
		if(is_valid_client(i))
		{
			OnClientPutInServer(i);
		}
	}

	if(explode_kill_enable)
	{
		AddCommandListener(kill_command,"explode");
		AddCommandListener(kill_command,"kill");
	}

	register_cookies();
}



void explode(int client)
{
	if(!is_valid_client(client))
	{
		return;
	}

	float origin[3];
	GetClientAbsOrigin(client, origin);

	EmitSoundToAll("ambient/explosions/explode_8.wav",SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,origin,NULL_VECTOR,true,0.0);
	TE_SetupExplosion(origin, g_ExplosionSprite, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
	ForcePlayerSuicide(client);
}

public Action kill_command(int client, const char[] command, int args) 
{
	if(!is_valid_client(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}

	PrintToChatAll("%s %N exit(1);",JB_PREFIX,client);
	explode(client);

	return Plugin_Handled;
}


// if warden drops into spec remove them
public Action player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid")); 

	if(!is_valid_client(client))
	{
		return Plugin_Continue;
	}

	int team = GetEventInt(event, "team");


	if(mute)
	{
		if(!IsPlayerAlive(client))
		{
			mute_client(client);
		}

		// player is alive
		else
		{
			if(team == CS_TEAM_CT)
			{
				unmute_client(client);
			}

			// mute timer active, mute the client
			else if(mute_timer)
			{
				mute_client(client);
			}
		}
	}

	if(client == global_ctx.warden_id)
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


public Action lenny_count_cmd(int client,int args) 
{
	PrintToChat(client,"%s ( ͡° ͜ʖ ͡°) count = %d\n",JB_PREFIX,global_ctx.lenny_count);

	return Plugin_Continue;
}

public Action warden_text_menu(int client,int args) 
{
	Panel options = new Panel();
	options.SetTitle("Text selection");
	options.DrawItem("disabled");
	options.DrawItem("enabled");
	
	if(IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT || GetClientTeam(client) == CS_TEAM_T )
	{
		options.Send(client, warden_text_handler, 20);
	}
	
	delete options;
	return Plugin_Handled;
}

public warden_text_handler(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		jb_players[client].warden_text = param2 == 2;

		set_cookie_int(client,jb_players[client].warden_text,client_warden_text_pref);
	}
	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d",client,param2);
	}	
}

// Top Screen Warden Printing
public Action print_warden_text_all(Handle timer)
{
	if(sd_enabled() && sd_current_state() != sd_inactive)
	{
		return Plugin_Continue;
	}
	
	char buf[256];
	

	
	if(!global_ctx.warday_active)
	{
		if(global_ctx.warden_id != WARDEN_INVALID)
		{
			
			Format(buf, sizeof(buf), "Current Warden:  %N  ", global_ctx.warden_id);
		}


		else
		{
			Format(buf, sizeof(buf), "Current Warden:  N/A  ");
		}
	}

	else
	{
		Format(buf, sizeof(buf), "Warday %s",global_ctx.warday_loc);
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
		if (IsClientInGame(i) && !IsFakeClient(i) && jb_players[i].warden_text)
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
	if(global_ctx.warden_id == client)
	{
		remove_warden();
	}
	
	return Plugin_Handled;
}

public Action become_warden(int client, int args) 
{
	if(BaseComm_IsClientMuted(client))
	{
		PrintToChat(client,"%s You are muted and cannot take warden",WARDEN_PREFIX);
		return Plugin_Handled;
	}

	// warden does not exist
	if(global_ctx.warden_id == WARDEN_INVALID)
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
		PrintToChat(client, "%s %N is already a warden.", WARDEN_PREFIX,global_ctx.warden_id);
	}
	
	return Plugin_Handled;
}

public Action warden_commands(int client, int args) 
{
	print_warden_commands(client);

	return Plugin_Continue;
}

// \n doesent work apparently...
// \n doesent work apparently...
public print_warden_commands(int client)
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

	PrintToChat(client,"%s!wm        %s- %smute everyone else for 10 seconds (60 second cooldown)",color1,color2,color3);

	if(warden_block)
	{
		PrintToChat(client,"%s!wb         %s- %sturn on block",color1,color2,color3);
		PrintToChat(client,"%s!wub       %s- %sturn off block",color1,color2,color3);
	}

	PrintToChat(client,"%s!laser       %s- %sswitch point/draw laser",color1,color2,color3);
	PrintToChat(client,"%s!laser_color       %s- %schange laser color",color1,color2,color3);
	PrintToChat(client,"%s!marker  %s- %s+marker, use mouse to adjust size, then -marker",color1,color2,color3);


	if(sd_enabled())
	{
		PrintToChat(client,"%s!wsd           %s- %sstart sd after %d rounds",color1,color2,color3,ROUND_WARDEN_SD);
		PrintToChat(client,"%s!wsd_ff           %s- %sstart ff sd after %d rounds",color1,color2,color3,ROUND_WARDEN_SD);
	}
	PrintToChat(client,"%s!wd %s- %scall a warday %s",color1,color2,color3, global_ctx.warday_round_counter >= WARDAY_ROUND_COUNT? "ready" : "not ready");


	if(t_laser)
	{
		PrintToChat(client,"%s!tlaser           %s- %stoggle laser for t's'",color1,color2,color3);
	}	

	PrintToChat(client,"%s!color           %s- %scolor players'",color1,color2,color3);	
	PrintToChat(client,"%s!reset_color           %s- %sreset player colors'",color1,color2,color3);	
	PrintToChat(client,"%s!open_cell           %s- %sopen cell doors'",color1,color2,color3);	
	

}

public set_warden(int client)
{
	// dont bother doing this on sds
	if(sd_enabled() && sd_current_state() == sd_active)
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
	global_ctx.warden_id = client;

	// warden has been taken old orders stand!
	kill_handle(global_ctx.command_end_timer);

	if(BaseComm_IsClientMuted(client))
	{
		PrintToChatAll("%s Warden %N is muted\n",WARDEN_PREFIX,client);
	}

	// make sure warden is not muted!
	unmute_client(client);

	PrintToChat(client,"%s Type !wcommands for a full list of commands",JB_PREFIX);
	
	// set the warden with special color
	SetEntityRenderColor(global_ctx.warden_id, 0, 191, 0, 255);

}

public Action warden_command_end(Handle timer)
{
	global_ctx.warden_command_countdown -= 1;
	if(global_ctx.warden_command_countdown <= 0)
	{
		global_ctx.command_end_timer = null;

		PrintToChatAll("%s %d seconds have passed! Previous orders are no longer valid...",WARDEN_PREFIX,warden_command_end_delay);
	}

	else
	{
		PrintCenterTextAll("Wardens orders are no longer valid in %d seconds",global_ctx.warden_command_countdown);
		global_ctx.command_end_timer = CreateTimer(1.0,warden_command_end);
	}


	return Plugin_Continue;
}

public Action player_death(Handle event, const String:name[], bool dontBroadcast) 
{
	// we don't care about this on SD
	if(sd_enabled() && sd_current_state() != sd_inactive)
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid")); // Get the dead clients id
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker")); // Get the dead clients id


	if(jb_players[client].rebel && is_valid_client(attacker) && print_rebel && attacker != client && 
		(!sd_enabled() || (sd_enabled() && sd_current_state() == sd_inactive)))
	{
		PrintToChatAll("%s %N killed the rebel %N",JB_PREFIX,attacker,client);
	}

	// if its the warden we need to remove him
	if(client == global_ctx.warden_id)
	{
		if(warden_command_end_delay > 0)
		{
			global_ctx.warden_command_countdown = warden_command_end_delay;
			PrintCenterTextAll("Wardens orders are no longer valid in %d seconds",global_ctx.warden_command_countdown);
			global_ctx.command_end_timer = CreateTimer(1.0,warden_command_end);
		}

		remove_warden();
	}

	// Let them whine for a bit when they die
	CreateTimer(3.0,mute_death,client);

	
	int new_warden = 0;
	// if there is only one ct left alive automatically warden him
	if(get_alive_team_count(CS_TEAM_CT,new_warden) == 1 && GetClientTeam(client) == CS_TEAM_CT && new_warden != 0)
	{
		if(global_ctx.warden_id == WARDEN_INVALID && auto_warden)
		{
			if(!is_sudoer(new_warden))
			{
				EmitSoundToAll("bot\\its_all_up_to_you_sir.wav");
			}

			// restore hp
			SetEntityHealth(new_warden,global_ctx.ct_handicap? 130 : 100);
			set_warden(new_warden);
		}
	}

	return Plugin_Continue;
}

void override_spawn_block(int client)
{
	// if player numbers exceed spawns in block trip no block
	if(!noblock && !global_ctx.spawn_block_override)
	{
		if(is_stuck_in_player(client))
		{
			jb_disable_block_all();
			global_ctx.spawn_block_override = true;
			PrintToChatAll("%s Player stuck on spawn unblocking",JB_PREFIX);
		}
	}
}

// give ct equitment on spawn & set block
public Action player_spawn(Handle event, const String:name[], bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	

	if(is_valid_client(client))
	{
		int team = GetClientTeam(client);

		override_spawn_block(client);

		// spawned in and there is not a current mute
		if(!mute_timer || team == CS_TEAM_CT)
		{
			unmute_client(client);
		}

		if(!sd_enabled() || sd_enabled() && sd_current_state() == sd_inactive)
		{
		
			//taking this information off clients is not functioning reliably
		
			// ignore clients setting as its unreliable
			// the first round we cant rely on it to be set as there are no players
			// apparently hoping a empty team join will force a round reset aint good enough
			
			if(block_state)
			{
				block_client(client,SetCollisionGroup);
			}

			else
			{
				unblock_client(client, SetCollisionGroup);
			}		
		}
				
		if(team == CS_TEAM_CT)
		{
			if(global_ctx.ct_handicap)
			{
				SetEntityHealth(client,130);
			}

			if(helmet)
			{
				GivePlayerItem(client, "item_assaultsuit");
			}

			else if(armor)
			{
				GivePlayerItem(client, "item_kevlar");
			}

			// give night vision
			GivePlayerItem(client,"item_nvgs");
		}

		else if(team == CS_TEAM_T)
		{
			strip_all_weapons(client);
			GivePlayerItem(client,"weapon_knife");
		}
	}

	return Plugin_Continue;
}

public Action round_end(Handle event, const String:name[], bool dontBroadcast) 
{
	if(mute)
	{
		kill_handle(mute_timer);
		unmute_all(true);
	}

	kill_handle(cell_auto_timer);
	kill_handle(tmp_mute_timer);

	// only reset this here and not in round start
	// otherwhise it will clobber it, as spawns happen before
	// the start
	global_ctx.spawn_block_override = false;

	// reset the mute cooldown for new round
	global_ctx.tmp_mute_timestamp = 0;

	reset_context();

	for(int i = 1; i <= MAXPLAYERS; i++)
	{
		reset_player(i);
	}

	return Plugin_Continue;
}

public Action round_start(Handle event, const String:name[], bool dontBroadcast) 
{
	// setup auto open
	if(global_ctx.cell_door_hammer_id != -1)
	{
		PrintToChatAll("%s Auto opening cell doors in 45 seconds",JB_PREFIX);
		PrintCenterTextAll("Auto opening cell doors in 45 seconds");
		cell_auto_timer = CreateTimer(45.0,auto_open_cell_callback);
	}

	enable_lr();

	reset_context();

	if(mute)
	{
		mute_t();
	}

	if(!global_ctx.spawn_block_override)
	{
		// if we are running with block on reset the status on round start
		if(noblock)
		{
			jb_disable_block_all();
		}

		else
		{
			jb_enable_block_all();
		}
	}

	else
	{
		jb_disable_block_all();
	}

	int ct_count = GetTeamClientCount(CS_TEAM_CT);
	int t_count = GetTeamClientCount(CS_TEAM_T);

	global_ctx.ct_handicap = (ct_count * 3) <= t_count;

	// next round
	global_ctx.warday_round_counter += 1;

	if(global_ctx.ct_handicap && handicap_enable)
	{
		for(int i = 1; i <= MAXPLAYERS; i++)
		{
			if(is_valid_client(i) && GetClientTeam(i) == CS_TEAM_CT)
			{
				SetEntityHealth(i,130);
			}
		}

		PrintToChatAll("%s CT's are outnumbered 3 to 1 increasing health to 130",JB_PREFIX);
		PrintCenterTextAll("CT's are outnumbered 3 to 1 increasing health to 130");
	}

	// 1 ct only on team auto warden them at start of round
	int client = 0;
	if(get_alive_team_count(CS_TEAM_CT, client) == 1 && client != 0)
	{
		if(auto_warden)
		{
			set_warden(client);
		}
	}
	
	for(int i = 0; i <= MAXPLAYERS; i++)
	{
		reset_player(i);

		if(!is_valid_client(i))
		{
			continue;
		}

		// give ct's guns
		if(guns && GetClientTeam(i) == CS_TEAM_CT)
		{
			GivePlayerItem(i,CT_SECONDARY);
			GivePlayerItem(i,CT_PRIMARY);
		}
	}

	return Plugin_Continue;
}


public Action fire_warden(client, args)
{
	if(global_ctx.warden_id == WARDEN_INVALID)
	{
		PrintToChat(client,"%s There is no warden.", WARDEN_PREFIX);
	}
	
	else 
	{
		remove_warden();
	}
	
	return Plugin_Handled;
}

public void remove_warden()
{
	// no warden do nothing
	if(global_ctx.warden_id == WARDEN_INVALID)
	{
		return;
	}
	
	global_ctx.first_warden = false;

	// make sure any tmp mutes get cleared
	unmute_all(false);

	// inform players of his death
	PrintCenterTextAll("%N is no longer warden.", global_ctx.warden_id);
	PrintToChatAll("%s %N is no longer warden.", WARDEN_PREFIX, global_ctx.warden_id);
		
	// remove warden color
	SetEntityRenderColor(global_ctx.warden_id, 255, 255, 255, 255); 
	
	// deregister the warden
	global_ctx.warden_id = WARDEN_INVALID;
}

public void OnLREnabled() 
{
	if(is_valid_client(global_ctx.warden_id) && global_ctx.first_warden)
	{
		// inform that lr is now enabled
		Call_StartForward(global_ctx.warden_to_lr_forward);
		Call_PushCell(global_ctx.warden_id);
		int unused;
		Call_Finish(unused);
	}
}

public void OnWardenToLR(int client)
{
	PrintToChatAll("%s %N Was warden till LR!",WARDEN_PREFIX,client);
}

void set_rebel(int client)
{
	if(!global_ctx.warday_active && !is_in_lr(client))
	{
		jb_players[client].rebel = true;
	}
}

public Action take_damage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(is_valid_client(attacker) && GetClientTeam(attacker) == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_CT)
	{
		set_rebel(attacker);

		char weapon[64];
		GetClientWeapon(attacker, weapon, sizeof(weapon) - 1);

		if(global_ctx.ct_handicap && !is_in_lr(attacker) && (StrEqual(weapon,"weapon_knife") || StrEqual(weapon,"weapon_awp")))
		{
			// up damage to account for ct handicap
			damage = damage * 1.3;
			return Plugin_Changed;
		}
	}

	// print ct damage to console
	if(is_valid_client(attacker) && GetClientTeam(attacker) == CS_TEAM_CT)
	{
		for(int i = 0; i <= MAXPLAYERS; i++)
		{
			if(is_valid_client(i))
			{
				PrintToConsole(i,"CT %N hit %N for %f",attacker,victim,damage);
			}
		}
	}

	return Plugin_Continue;
}

public Action OnWeaponFire(Handle event, const String:name[], bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));

	char weapon_string[32];
	GetEventString(event,"weapon",weapon_string,sizeof(weapon_string) - 1);

	bool valid_weapon = !StrEqual(weapon_string,"knife") && !StrEqual(weapon_string,"hegrenade") 
		&& !StrEqual(weapon_string,"flashbang") && !StrEqual(weapon_string,"c4");

	if(GetClientTeam(client) == CS_TEAM_T && valid_weapon)
	{
		set_rebel(client);
	}

	return Plugin_Continue;
}