// reimpl of sm-hosties2 https://github.com/dataviruset/sm-hosties

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include "lib.inc"

#define PLUGIN_AUTHOR "destoer(organ harvester)"
#define PLUGIN_VERSION "V0.3.7 - Violent Intent Jailbreak"

/*
	onwards to the new era ( ͡° ͜ʖ ͡°)
*/


/*
-Add more gun options in shotgun war, and change name to war

// TODO: later
-Add back button in LR menu
-Add lr leaderboard
-impl more lr's
-remove guns on slay (probs easiest to just hook the comamnds like in the team bal plugin)
*/

public Plugin:myinfo = 
{
	name = "last request",
	author = PLUGIN_AUTHOR,
	description = "sm-hosties2 last request reimpl",
	version = PLUGIN_VERSION,
	url = "https://github.com/destoer/css_jailbreak_plugins"
};

#define LR_PREFIX "\x04[Last Request]\x07F8F8FF"

#include "lr/lr.inc"


new const String:lr_win_field[LR_SIZE_ACTUAL][] =
{	
    "Knife_fight_Win",
    "Dodgeball_Win",
    "Nade_war_Win",
    "Race_Win",
    "No_scope_Win",
    "Gun_toss_Win",
    "Crash_Win",
    "Shot_for_shot_Win",
    "Mag_for_Mag_Win",
    "Shotgun_war_Win",
    "Russian_roulette_Win",
    "Headshot_only_Win",
    "Sumo_Win",
    "Scout_knife_Win",
    "Custom_Win",
    "Rebel_Win",
    "Knife_rebel_Win",
    "Combo_key_Win",
};


new const String:lr_loss_field[LR_SIZE_ACTUAL][] =
{	
    "Knife_fight_Loss",
    "Dodgeball_Loss",
    "Nade_war_Loss",
    "Race_Loss",
    "No_scope_Loss",
    "Gun_toss_Loss",
    "Crash_Loss",
    "Shot_for_shot_Loss",
    "Mag_for_Mag_Loss",
    "Shotgun_war_Loss",
    "Russian_roulette_Loss",
    "Headshot_only_Loss",
    "Sumo_Loss",
    "Scout_knife_Loss",
    "Custom_Loss",
    "Rebel_Loss",
    "Knife_rebel_Loss",
    "Combo_key_Loss",
};

enum lr_state 
{
    lr_inactive,
    lr_starting,
    lr_active,
}

enum struct LrSlot  
{
    lr_state state;
    int client;
    lr_type type;
    int option;

    int weapon;

    int combo_buttons[16];
    int current_button;
    int button_size;
    int buttons_old;

    float pos[3];
    float gun_pos[3];
    Handle timer;
    bool gun_dropped;
    bool dropped_once;

    int bullet_count;
    int bullet_max;

    int delay;

    int chamber;
    int bullet_chamber;

    bool restrict_drop;

    int crash_stop;
    int dropped_last;
    int crash_delay;

    bool failsafe;

    float race_start[3];
    float race_end[3];

    // this is the slot to our partner
    int partner;

    char weapon_string[64];

    Handle line_timer;
}

#define LR_SLOTS 4

#define INVALID_SLOT -1

#define LINE_TIMER 0.1

#define GUNTOSS_TIMER 0.1

#define BEACON_TIMER 1.0

// NOTE: only take a copy for convience
// it only passes as reference when we directly access it
LrSlot slots[LR_SLOTS];

Menu lr_menu;

enum struct Choice
{
    lr_type type;
    
    // basic menu option
    int option;

    float race_start[3];
    float race_end[3];
}

enum struct LrTimer
{
    Timer timer;

    int uniq;

    int slot;
}

Choice lr_choice[MAXPLAYERS + 1]

Menu gun_menu;

int g_lbeam;
int g_lhalo;

bool rebel_lr_active = false;
bool knife_rebel_active = false;

bool lr_ready = false;

bool lr_sound_cached = false;

bool use_key[MAXPLAYERS+1] = {false};

int start_timestamp = 0;

Handle lr_win_forward = null;
Handle lr_enabled_forward = null;

public int WeaponHandler(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
        // canot use the menu
        if(!IsPlayerAlive(client) || !rebel_lr_active)
        {
            return -1;
        }

        weapon_handler_generic(client,param2);
        PrintToChatAll("%s %N is a rebel!",LR_PREFIX,client);
	}

	
	else if (action == MenuAction_Cancel) 
    {
        PrintToChatAll("%s %N is a rebel!",LR_PREFIX,client);
        PrintToServer("Client %d's menu was cancelled. Reason: %d", client, param2);
    }
	return 0;
}



// unity build
#include "lr/debug.sp"
#include "lr/knife_fight.sp"
#include "lr/dodgeball.sp"
#include "lr/grenade.sp"
#include "lr/no_scope.sp"
#include "lr/gun_toss.sp"
#include "lr/shot_for_shot.sp"
#include "lr/shotgun_war.sp"
#include "lr/russian_roulette.sp"
#include "lr/headshot_only.sp"
#include "lr/scout_knife.sp"
#include "lr/race.sp"
#include "lr/sumo.sp"
#include "lr/rebel.sp"
#include "lr/combo_key.sp"
#include "lr/crash.sp"
#include "lr/custom.sp"
#include "lr/config.sp"
#include "lr/hook.sp"
#include "lr/stats.sp"
#include "jailbreak/jailbreak.inc"


public Action command_cancel_lr(int client , int args)
{
    if(!(CheckCommandAccess(client, "generic_admin", ADMFLAG_KICK, false) || client == get_warden_id()))
    {
        PrintToChat(client,"%s You must be an admin or warden to cancel a lr\n",LR_PREFIX);
        return Plugin_Handled;
    }

    for(int i = 0; i < LR_SLOTS; i++)
    {
        end_lr(slots[i]);
    }

    return Plugin_Continue;        
}


void reset_use_key()
{
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		use_key[i] = false;
	}
}

public int native_is_in_lr(Handle plugin, int num_param)
{
    int client = GetNativeCell(1);
    return in_lr(client);
}


// register our call
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("is_in_lr", native_is_in_lr);

    lr_win_forward = CreateGlobalForward("OnWinLR",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
    lr_enabled_forward = CreateGlobalForward("OnLREnabled",ET_Ignore);


    return APLRes_Success;
}


public void OnWinLR(int client,int rival, lr_type type) 
{
    if(is_valid_client(rival))
    {
        PrintToConsole(client,"You won the lr against %N!",rival);
    }

    else
    {
        PrintToConsole(client,"You won the lr!");
    }
}

#undef REQUIRE_PLUGIN
#include "thirdparty/ctban.inc"
#define REQUIRE_PLUGIN


public OnPluginStart()
{
    create_lr_convar();
    setup_config();

    RegConsoleCmd("lr",command_lr);
    RegConsoleCmd("lr_stats",lr_stats);

    // debugging
    RegConsoleCmd("register_console",register_console);
    RegConsoleCmd("lrv", lr_version);
    RegConsoleCmd("dump_slots",dump_slots);
    RegAdminCmd("force_lr",force_lr,ADMFLAG_KICK);
    RegAdminCmd("force_drop",force_drop,ADMFLAG_KICK);

    RegConsoleCmd("cancel_lr",command_cancel_lr);
    RegConsoleCmd("cancellr",command_cancel_lr);
    

    HookEvent("player_death", OnPlayerDeath,EventHookMode_Post);
    HookEvent("round_end", OnRoundEnd);
    HookEvent("round_start", OnRoundStart);

    // hook disonnect incase a vital member leaves
    HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);

    
    HookEvent("weapon_zoom",OnWeaponZoom,EventHookMode_Pre);
    HookEvent("weapon_fire",OnWeaponFire,EventHookMode_Post);
    HookEvent("player_hurt", OnPlayerHurt);
    HookEvent("player_team", player_team);

    for(int i = 1; i <= MaxClients; i++)
    {
        if(is_valid_client(i))
        {
            OnClientPutInServer(i);
        }
    }

    database_connect();

    LoadTranslations("common.phrases"); 
}


int get_slot(int client)
{
    if(!is_valid_client(client))
    {
        return INVALID_SLOT;
    }

    // NOTE: this should be fine for a low slot number
    // otherwhise we are gonna need a client to slot lookup
    for(int i = 0; i < LR_SLOTS; i++)
    {
        if(slots[i].client == client)
        {
            return i;
        }
    }

    return INVALID_SLOT;
}

bool is_valid_slot(int id)
{
    return id != INVALID_SLOT;
}

bool in_lr(int client)
{
    int slot = get_slot(client);

    return is_valid_slot(slot);
}

bool is_pair(int c1, int c2)
{
    int id1 = get_slot(c1);
    int id2 = get_slot(c2);

    // both in lr
    if(is_valid_slot(id1) && is_valid_slot(id2))
    {
        int partner = slots[id1].partner;

        // if partner matches id then they are a pair
        return partner == id2;
    }

    // one is not in lr they are not a pair
    else
    {
        return false;
    }
}


void end_lr_pair(int id, int partner)
{
    end_lr(slots[id]);
    end_lr(slots[partner]);    
}

void end_lr(LrSlot slot)
{
    if(is_valid_client(slot.client) && IsPlayerAlive(slot.client))
    {
        SetEntityHealth(slot.client,100);
        strip_all_weapons(slot.client);
        SetEntityGravity(slot.client,1.0);
        set_client_speed(slot.client,1.0);

        if(GetEntityMoveType(slot.client) == MOVETYPE_FLY)
        {
            PrintToChatAll("%s LR finished moving %N back to spawn",LR_PREFIX,slot.client);
            CS_RespawnPlayer(slot.client);
        }

        SetEntityMoveType(slot.client, MOVETYPE_WALK);        

        if(GetClientTeam(slot.client) == CS_TEAM_CT)
        {
            GivePlayerItem(slot.client,"weapon_knife");
            GivePlayerItem(slot.client,"weapon_m4a1");
        }

        else
        {
       
            GivePlayerItem(slot.client,"weapon_knife");
        }
    }

    slot.type = slot_error;
    slot.state = lr_inactive;
    slot.failsafe = false;
    slot.client = -1;
    slot.option = 0;

    slot.weapon = -1;

    slot.bullet_count = -1;
    slot.bullet_max = -1;

    slot.partner = -1;

    slot.bullet_chamber = -1;
    slot.chamber = -1;

    slot.delay = 0;

    slot.restrict_drop = false;

    slot.weapon_string = "";

    for(int i = 0; i < 3; i++)
    {
        slot.pos[i] = 0.0;
        slot.gun_pos[i] = 1.0;
    }

    kill_handle(slot.timer);

    slot.gun_dropped = false;
    slot.dropped_once = false;

    slot.crash_stop = -1;
    slot.dropped_last = -1;

    slot.current_button = 0;
    slot.button_size = 0;

    end_line(slot);
}

public int default_choice_handler(Menu menu, MenuAction action, int client, int choice)
{
    if(action == MenuAction_Select)
    {
        lr_choice[client].option = choice;
        pick_partner(client);
    }

    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}


int get_inactive_slot()
{
    for(int i = 0; i < LR_SLOTS; i++)
    {
        if(slots[i].state == lr_inactive)
        {
            slots[i].state = lr_starting;
            return i;
        }
    }

    SetFailState("Could not find an empty lr slot");    

    return -1;
}


public Action draw_line(Handle timer,int id)
{
    LrSlot slot;
    slot = slots[id];


    if(slots[id].state == lr_inactive || !is_valid_client(slot.client))
    {
        return Plugin_Continue;
    }

    float client_cords[3];
    float partner_cords[3];

    GetClientAbsOrigin(slot.client,client_cords); client_cords[2] += 10.0;
    GetClientAbsOrigin(slots[slot.partner].client,partner_cords); partner_cords[2] += 10.0;


    // pulse handled by funcommands for now

    // draw line between players
    TE_SetupBeamPoints(client_cords, partner_cords, g_lbeam, 0, 0, 0, LINE_TIMER, 0.8, 0.8, 2, 0.0, { 1, 153, 255, 255 }, 0);
    TE_SendToAll();


    return Plugin_Continue;
}

public Action beacon_callback(Handle timer, int client)
{
    // if in a knife rebel beacon can stay active as long as it wants
    if(!knife_rebel_active)
    {
        int slot = get_slot(client);

        if(slot == INVALID_SLOT)
        {
            return Plugin_Stop;
        }
    }

    int color[4]; 
    
    if(!is_valid_client(client))
    {
        return Plugin_Stop;
    }

    if(GetClientTeam(client) == CS_TEAM_T)
    { 
        color = {230,10,10,255};
    }
    
    else 
    {
        color = { 1, 153, 255, 255};
    }


    float pos[3];
    GetClientAbsOrigin(client,pos);
    pos[2] += 5.0;

    // highlight
    TE_SetupBeamRingPoint(pos, 35.0, 250.0, g_lbeam, g_lhalo, 0, 15, (BEACON_TIMER / 2), 2.0, 0.0, {66, 66, 66, 255}, 500, 0);
    TE_SendToAll();   

    // team color
    TE_SetupBeamRingPoint(pos, 35.0, 250.0, g_lbeam, g_lhalo, 0, 5, (BEACON_TIMER / 2) + 0.1, 2.0, 0.0, color, 250, 0);
    TE_SendToAll();    

    EmitAmbientSound("buttons/blip1.wav", pos, client, SNDLEVEL_RAIDSIREN);
    
    return Plugin_Continue;
}

void start_beacon(int id)
{
    // do beacon
    if(is_valid_client(slots[id].client))
    {
        CreateTimer(BEACON_TIMER,beacon_callback,slots[id].client,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

void start_line(int id)
{
    slots[id].line_timer = CreateTimer(LINE_TIMER,draw_line,id,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void end_line(LrSlot slot)
{
    kill_handle(slot.line_timer);
}

void init_slot(int id, int client, int partner, lr_type type, int option)
{
    
    slots[id].client = client;
    slots[id].type = type;
    slots[id].state = lr_starting;
    slots[id].partner = partner;
    slots[id].option = option;

    print_slot(id);

    if(type != sumo)
    {
        start_beacon(id);
    }
}

public Action start_lr_callback(Handle timer, int id)
{
    if(slots[id].state == lr_inactive)
    {
        slots[id].timer = null;
        return Plugin_Handled;
    }

    // by convention the t triggers the lr
    int t_slot = id;
    int ct_slot = slots[id].partner;

    int t = slots[t_slot].client;
    int ct = slots[ct_slot].client;

    int type = slots[t_slot].type;

    if(slots[t_slot].delay)
    {
        slots[id].delay -= 1;

        // Suggestion: fearless print lr in countdown
        PrintCenterText(t,"lr %s starting in %d seconds against %N!",lr_list[type],slots[id].delay,ct);
        PrintCenterText(ct,"lr %s starting in %d seconds against %N!",lr_list[type],slots[id].delay,t);

        if(slots[id].delay)
        {
            slots[id].timer = CreateTimer(1.0,start_lr_callback,id,TIMER_FLAG_NO_MAPCHANGE);
            return Plugin_Handled;
        }

        slots[id].timer = null;
    }

    slots[t_slot].state = lr_active;
    slots[ct_slot].state = lr_active;


    PrintCenterText(t,"Go!");
    PrintCenterText(ct,"Go!");

    switch(slots[id].type)
    {
        case knife_fight: 
        {
            start_knife_fight(t_slot,ct_slot);
        }

        case dodgeball:
        {
            start_dodgeball(t_slot,ct_slot);
        }

        case grenade:
        {
            start_grenade(t_slot,ct_slot)
        }

        case no_scope:
        {
            start_no_scope(t_slot,ct_slot);
        }

        case gun_toss:
        {
            start_gun_toss(t_slot,ct_slot);
        }

        case shot_for_shot:
        {
            start_shot_for_shot(t_slot,ct_slot,false);
        }

        case mag_for_mag:
        {
            start_shot_for_shot(t_slot,ct_slot,true);
        }

        case shotgun_war:
        {
            start_shotgun_war(t_slot,ct_slot);
        }

        case headshot_only:
        {
            start_headshot_only(t_slot,ct_slot);
        }

        case russian_roulette:
        {
            start_russian_roulette(t_slot,ct_slot);
        }

        case custom:
        {
            start_custom(t_slot,ct_slot);
        }

        case sumo:
        {
            start_sumo(t_slot,ct_slot);
        }

        case scout_knife:
        {
            start_scout_knife(t_slot,ct_slot);
        }

        case crash:
        {
            start_crash(t_slot,ct_slot);
        }

        case race:
        {
            start_race(t_slot,ct_slot);
        }

        case combo_key:
        {
            start_combo_key(t_slot,ct_slot);
        }

        case slot_error:
        {
            PrintToConsole(console,"%s An error has occured in picking an lr");
        }
    }

    return Plugin_Continue;
}

void print_crash_info(int client)
{
    PrintToChat(client,"%s drop your weapon as close to the timer as possible (between 5 - 20 seconds)",LR_PREFIX);
    PrintToChat(client,"%s however, dont go over the selected time or you may die",LR_PREFIX);
}

void start_lr_internal(int t, int ct, lr_type type)
{
    PrintToChat(t,"%s Lr %s vs %N\n",LR_PREFIX,lr_list[type],ct);
    PrintToChat(ct,"%s Lr %s vs %N\n",LR_PREFIX,lr_list[type],t)

    int t_slot = get_inactive_slot();
    int ct_slot = get_inactive_slot();


    init_slot(t_slot,t,ct_slot,type, lr_choice[t].option);
    init_slot(ct_slot,ct,t_slot,type, lr_choice[t].option);


    // only really need one of these to draw, but don't do it on race its distracting
    if(type != race)
    {
        start_line(t_slot);
    }

    strip_all_weapons(t);
    strip_all_weapons(ct);

    slots[t_slot].delay = 3; 

    // do some initial setup before the timer starts
    switch(type)
    {
        case sumo:
        {
            sumo_startup(t_slot,ct_slot);
        }

        case race:
        {
            race_startup(t_slot,ct_slot);
            slots[t_slot].delay = 6;
        }

        case crash:
        {
            print_crash_info(t);
            print_crash_info(ct);
        }        
    }

    // Suggestion: fearless print lr in countdown
    PrintCenterText(t,"lr %s starting in %d seconds against %N!",lr_list[type],slots[t_slot].delay,ct);
    PrintCenterText(ct,"lr %s starting in %d seconds against %N!",lr_list[type],slots[t_slot].delay,t);
    slots[t_slot].timer = CreateTimer(1.0,start_lr_callback,t_slot,TIMER_FLAG_NO_MAPCHANGE);   
}

void start_lr(int t, int ct, lr_type type)
{
    int unused;
    int alive_t = get_alive_team_count(CS_TEAM_T,unused);
    if(alive_t > LR_SLOTS / 2)
    {
        return;
    }

    if(!is_valid_t(t) || !is_valid_partner(ct))
    {
        return;
    }

    start_lr_internal(t,ct,type);
}

void set_lr_clip(int id)
{
    PrintToChat(slots[id].client,"%s Take your shots",LR_PREFIX);
    set_clip_ammo(slots[id].client,slots[id].weapon,slots[id].bullet_max);
    slots[id].bullet_count = slots[id].bullet_max;
}

bool is_valid_t(int client)
{
    if(!IsPlayerAlive(client))
    {
        PrintToChat(client,"%s You must be alive to start a lr\n",LR_PREFIX);
        return false;     
    }

    if(in_lr(client))
    {
        PrintToChat(client,"%s You are allready in a lr\n",LR_PREFIX);
        return false;
    }

    if(GetClientTeam(client) != CS_TEAM_T)
    {
        PrintToChat(client,"%s You must be on t to start a lr\n",LR_PREFIX);
        return false;        
    }

    return true;    
}

// error when true
bool command_lr_internal(int client)
{
    if(rebel_lr_active)
    {
        return true;
    }

    // lr is not enabled
    if(lr_cvar.IntValue == 0)
    {
        PrintToChat(client,"%s Lr is currently disabled!",LR_PREFIX);
        return true;
    }

    if(GetTime() - start_timestamp < 15 && !is_sudoer(client))
    {
        int remain = 15 - (GetTime() - start_timestamp);

        PrintToChat(client,"%s Round has just started, please wait %d seconds to start an lr!",LR_PREFIX,remain);
        return true;       
    }

    if(!is_valid_t(client))
    {
        return true;
    }


    int unused;
    int alive_t = get_alive_team_count(CS_TEAM_T,unused);
    if(alive_t > LR_SLOTS / 2)
    {
        PrintToChat(client,"%s Too many players left alive %d : %d\n",LR_PREFIX,alive_t,LR_SLOTS / 2);
        return true;
    }

    // open a selection menu for 20 seconds
    lr_menu.Display(client,20);  

    return false;  
}

Action command_lr (int client, int args)
{
    if(command_lr_internal(client))
    {
        return Plugin_Continue;
    }

    return Plugin_Handled;
}

bool is_valid_partner(int client)
{
    if(!is_valid_client(client))
    {
        return false;
    }

    if(!IsPlayerAlive(client))
    {
        return false;
    }


    if(in_lr(client))
    {
        return false;
    }

    if(GetClientTeam(client) != CS_TEAM_CT)
    {
        return false;
    }

    return true;
}

public int partner_handler(Menu menu, MenuAction action, int t, int param2)
{
    // Get the selected parter and start the LR
    if(action == MenuAction_Select)
    {
        char id[64];
        menu.GetItem(param2,id,sizeof(id) - 1);

        int partner = StringToInt(id);

        if(!is_valid_partner(partner))
        {
            PrintToChat(t,"%s invalid lr partner\n",LR_PREFIX);
            return 0;
        }

        lr_type type = lr_choice[t].type;

        start_lr(t,partner,type);
    }

    else if (action == MenuAction_End)
    {
        delete menu;
    }
  
    return 0;
}

void pick_partner(int client)
{
    Menu menu = new Menu(partner_handler);
    menu.SetTitle("Pick partner");

    int valid_players = 0;

    // Build a list of valid players
    for(int i = 1; i <= MaxClients; i++)
    {
        if(is_valid_partner(i))
        {
            char name[64];
            GetClientName(i,name,sizeof(name) - 1)

            char id[64];
            Format(id,sizeof(id) - 1,"%d",i);

            menu.AddItem(id,name);
            valid_players++;
        }
    }
    
    menu.ExitButton = false;

    if(!valid_players)
    {
        PrintToChat(client,"%s There are no players alive to lr with\n",LR_PREFIX);
        return;
    }

    menu.Display(client,20);    
}

bool check_last_rebel(int client)
{
    int unused;
    int alive_t = get_alive_team_count(CS_TEAM_T,unused); 

    bool res = alive_t == 1;   

    if(!res)
    {
        PrintToChat(client,"%s You must be last t alive to rebel",LR_PREFIX);
    }

    return res;
}

public int lr_select(int client, int lr)
{
    PrintToChat(client,"%s Selected %s\n",LR_PREFIX,lr_list[lr]);

    if(!is_valid_t(client))
    {
        return -1;
    }


    lr_type type = view_as<lr_type>(lr);

    // rebel has only one user
    if(type == rebel)
    {
        if(check_last_rebel(client))
        {
            rebel_player_init(client);
            return 0;
        }

        return -1;  
    }

    if(type == knife_rebel)
    {
        if(check_last_rebel(client))
        {
            knife_rebel_player_init(client);
            return 0;
        }

        return -1;  
    }    

    // save what lr the current client is requesting so we can pull it inside the player handler
    lr_choice[client].type = view_as<lr_type>(lr);
    lr_choice[client].option = 0;

    switch(lr_choice[client].type)
    {
        case no_scope:
        {
            no_scope_menu(client);
        }

        case shot_for_shot:
        {
            shot_for_shot_menu(client);
        }

        case mag_for_mag:
        {
            shot_for_shot_menu(client);
        }

        case grenade:
        {
            grenade_menu(client);
        }

        case dodgeball:
        {
            dodgeball_menu(client);
        }

        case knife_fight:
        {
            knife_fight_menu(client);
        }

        case race:
        {
            race_menu(client);
        }

        default:
        {
            pick_partner(client);            
        }
    }


    return 0;
}

public int lr_handler(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		char item[64];
		menu.GetItem(param2, item, sizeof(item));

		// scan for the right LR
		for(int i = 0; i < LR_SIZE; i++)
		{
			if(StrEqual(lr_list[i],item))
			{
				return lr_select(client,i);
			}
		}

		PrintToChat(client,"%s Invalid sd selected",LR_PREFIX);
	}
	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d",client,param2);
	}
	
	return -1;
}

public Menu build_lr_menu()
{
	Menu menu = new Menu(lr_handler);

    // Ignore the error choice
	for (int i = 0; i < LR_SIZE - 1; i++)
	{
		if(lr_enable[i])
        {
		    menu.AddItem(lr_list[i], lr_list[i]);
        }
	}

	menu.SetTitle("Last Request");
	return menu;
}
