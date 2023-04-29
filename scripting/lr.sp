// reimpl of sm-hosties2 https://github.com/dataviruset/sm-hosties

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include "lib.inc"

#define PLUGIN_AUTHOR "destoer(organ harvester)"
#define PLUGIN_VERSION "V0.3.2 - Violent Intent Jailbreak"

/*
	onwards to the new era ( ͡° ͜ʖ ͡°)
*/


/*
-Add more gun options in shotgun war, and change name to war

// TODO: later
-Add back button in LR menu
-Add sumo lr
-Add chicken fight lr
-Add hot potato lr
-Add auto open LR menu to non rebellers when availiable
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


enum lr_type
{
    knife_fight,
    dodgeball,
    grenade,
    no_scope,
    gun_toss,
    shot_for_shot,
    mag_for_mag,
    shotgun_war,
    russian_roulette,
    headshot_only,
    sumo,
    rebel,
    error,
}

const int LR_SIZE = 12;
new const String:lr_list[LR_SIZE][] =
{	
    "Knife fight",
    "Dodgeball",
    "Nade war",
    "No scope",
    "Gun toss",
    "Shot for shot",
    "Mag for Mag",
    "Shotgun war",
    "Russian roulette",
    "Headshot only",
    "Rebel",
    "Error",
/*
    "Sumo",
    "Race",
    "Rock paper scissors",
    "Hot potato",
    "Chicken fight", // (Yeah screw this one)
*/
};


enum struct LrSlot  
{
    bool active;
    int client;
    lr_type type;
    int option;

    int weapon;

    float pos[3];
    float gun_pos[3];
    Handle timer;
    bool gun_dropped;

    int bullet_count;
    int bullet_max;

    int delay;

    int chamber;
    int bullet_chamber;

    bool restrict_drop;

    // this is the slot to our partner
    int partner;

    char weapon_string[64];

    Handle line_timer;
}

#define LR_SLOTS 4

#define INVALID_SLOT -1

#define LINE_TIMER 0.1

#define GUNTOSS_TIMER 0.1

// NOTE: only take a copy for convience
// it only passes as reference when we directly access it
LrSlot slots[LR_SLOTS];

Menu lr_menu;

enum struct Choice
{
    lr_type type;
    
    // basic menu option
    int option;
}

Choice lr_choice[64]

int g_lbeam;

bool rebel_lr_active = false;

bool lr_ready = false;

bool use_key[MAXPLAYERS+1] = {false};

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
//#include "lr/race.sp"
#include "lr/rebel.sp"
#include "lr/config.sp"
#include "lr/hook.sp"

// handle for sdkcall
Handle SetCollisionGroup;

public Action command_cancel_lr(int client , int args)
{
    for(int i = 0; i < LR_SLOTS; i++)
    {
        end_lr(slots[i]);
    }        
}


void reset_use_key()
{
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		use_key[i] = false;
	}
}

public OnPluginStart()
{
    create_lr_convar();

    RegConsoleCmd("lr",command_lr);

    // debugging
    RegConsoleCmd("register_console",register_console);
    RegConsoleCmd("lrv", lr_version);
    RegConsoleCmd("dump_slots",dump_slots);
    RegConsoleCmd("force_lr",force_lr);

    RegAdminCmd("cancel_lr",command_cancel_lr,ADMFLAG_KICK);
    RegAdminCmd("cancellr",command_cancel_lr,ADMFLAG_KICK);
    

    HookEvent("player_death", OnPlayerDeath,EventHookMode_Post);
    HookEvent("round_end", OnRoundEnd);

    // hook disonnect incase a vital member leaves
    HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);

    
    HookEvent("weapon_zoom",OnWeaponZoom,EventHookMode_Pre);
    HookEvent("weapon_fire",OnWeaponFire,EventHookMode_Post);
    HookEvent("player_hurt", OnPlayerHurt);

    for(int i = 0; i < MaxClients;i++)
    {
        if(is_valid_client(i))
        {
            OnClientPutInServer(i);
        }
    }

    SetCollisionGroup = init_set_collision();
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
    end_beacon(slot);

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

    slot.type = error;
    slot.active = false;
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
}


int get_inactive_slot()
{
    for(int i = 0; i < LR_SLOTS; i++)
    {
        if(!slots[i].active)
        {
            slots[i].active = true;
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


    if(!slot.active || !is_valid_client(slot.client))
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

void end_beacon(LrSlot slot)
{
    // stop beacon
    if(is_valid_client(slot.client))
    {
        ServerCommand("sm_beacon %N",slot.client);
    }
}

void start_beacon(int id)
{
    // do beacon
    if(is_valid_client(slots[id].client))
    {
        ServerCommand("sm_beacon %N",slots[id].client);
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
    slots[id].active = true;
    slots[id].partner = partner;
    slots[id].option = option;

    print_slot(id);

    start_beacon(id);
}

public Action start_lr_callback(Handle timer, int id)
{

    // by convention the t triggers the lr
    int t_slot = id;
    int ct_slot = slots[id].partner;

    int t = slots[t_slot].client;
    int ct = slots[ct_slot].client;

    if(slots[t_slot].delay)
    {
        PrintCenterText(t,"Lr starting in %d seconds against %N!",slots[id].delay,ct);
        PrintCenterText(ct,"Lr starting in %d seconds against %N!",slots[id].delay,t);

        slots[id].timer = CreateTimer(1.0,start_lr_callback,id,TIMER_FLAG_NO_MAPCHANGE);
        slots[id].delay -= 1;

        return Plugin_Handled;
    }

    else
    {
        slots[id].timer = null;
    }


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
/*
        case race:
        {
            start_race(t_slot,ct_slot);
        }
*/
        case error:
        {
            PrintToConsole(console,"%s An error has occured in picking an lr");
        }
    }

    return Plugin_Continue;
}

void start_lr_internal(int t, int ct, lr_type type)
{
    PrintToChat(t,"%s Lr %s vs %N\n",LR_PREFIX,lr_list[type],ct);
    PrintToChat(ct,"%s Lr %s vs %N\n",LR_PREFIX,lr_list[type],t)

    int t_slot = get_inactive_slot();
    int ct_slot = get_inactive_slot();


    init_slot(t_slot,t,ct_slot,type, lr_choice[t].option);
    init_slot(ct_slot,ct,t_slot,type, lr_choice[t].option);


    // only really need one of these to draw
    start_line(t_slot);

    strip_all_weapons(t);
    strip_all_weapons(ct);



    slots[t_slot].timer = CreateTimer(1.0,start_lr_callback,t_slot,TIMER_FLAG_NO_MAPCHANGE);
    slots[t_slot].delay = 3;    
}

void start_lr(int t, int ct, lr_type type)
{
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

Action command_lr (int client, int args)
{
    if(rebel_lr_active)
    {
        return Plugin_Continue;
    }

    SetCollisionGroup = init_set_collision();


    // lr is not enabled
    if(lr_cvar.IntValue == 0)
    {
        return Plugin_Continue;
    }

    if(!is_valid_t(client))
    {
        return Plugin_Handled;
    }


    int unused;
    int alive_t = get_alive_team_count(CS_TEAM_T,unused);
    if(alive_t > LR_SLOTS / 2)
    {
        PrintToChat(client,"%s Too many players left alive %d : %d\n",LR_PREFIX,alive_t,LR_SLOTS / 2);
        return Plugin_Handled;
    }

    // open a selection menu for 20 seconds
    lr_menu.Display(client,20);

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
        char name[64]
        menu.GetItem(param2,name,sizeof(name) - 1);

        int partner = FindTarget(t,name,false,false);

        if(partner == -1)
        {
            PrintToChat(t,"%s No such player: %s\n",LR_PREFIX,name)
        }

        lr_type type = lr_choice[t].type;

        start_lr(t,partner,type);
    }

    else if (action == MenuAction_End)
    {
        delete menu;
    }
  
}

void pick_partner(int client)
{
    Menu menu = new Menu(partner_handler);
    menu.SetTitle("Pick partner");

    int valid_players = 0;

    // Build a list of valid players
    for(int i = 0; i < MaxClients; i++)
    {
        if(is_valid_partner(i))
        {
            char name[64];
            GetClientName(i,name,sizeof(name) - 1)

            menu.AddItem(name,name);
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
        int unused;
        int alive_t = get_alive_team_count(CS_TEAM_T,unused);
        if(alive_t == 1)
        {
            rebel_player_init(client);
            return 0;
        }

        else
        {
            PrintToChat(client,"%s You must be last t alive to rebel",LR_PREFIX);
            return -1;
        }
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
/*
        case race:
        {
            race_menu(client);
        }
*/
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
		return lr_select(client,param2);
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

	for (int i = 0; i < LR_SIZE; i++)
	{
		menu.AddItem(lr_list[i], lr_list[i]);
	}

	menu.SetTitle("Last Request");
	return menu;
}
