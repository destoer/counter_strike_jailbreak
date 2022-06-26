// reimpl of sm-hosties2 https://github.com/dataviruset/sm-hosties

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include "lib.inc"

#define PLUGIN_AUTHOR "destoer(organ harvester)"
#define PLUGIN_VERSION "V0.2 - Violent Intent Jailbreak"

/*
	onwards to the new era ( ͡° ͜ʖ ͡°)
*/

// TODO: add options to mag for mag, no scope etc
// TODO: impl more lr's

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
    rebel,
}

const int LR_SIZE = 10;
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
    "Rebel",
/*
    "Sumo",
    "Race",
    "Rock paper scissors",
    "Hot potato",
    "Chicken fight",
*/
};


enum struct LrSlot  
{
    bool active;
    int client;
    lr_type type;

    int weapon;

    float pos[3];
    float gun_pos[3];
    Handle timer;
    bool gun_dropped;

    int bullet_count;
    int bullet_max;

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

lr_type lr_request[64]

int g_lbeam;

// unity build
#include "lr/debug.sp"
#include "lr/hook.sp"
#include "/lr/knife_fight.sp"
#include "lr/dodgeball.sp"
#include "lr/grenade.sp"
#include "lr/no_scope.sp"
#include "lr/gun_toss.sp"
#include "lr/shot_for_shot.sp"
#include "lr/shotgun_war.sp"
#include "lr/russian_roulette.sp"
#include "lr/rebel.sp"
#include "lr/config.sp"

// handle for sdkcall
Handle SetCollisionGroup;

public Action command_cancel_lr(int client , int args)
{
    for(int i = 0; i < LR_SLOTS; i++)
    {
        end_lr(slots[i]);
    }        
}

public OnPluginStart()
{
    create_lr_convar();

    RegConsoleCmd("lr",command_lr);

    RegAdminCmd("cancel_lr",command_cancel_lr,ADMFLAG_KICK);

    HookEvent("player_death", OnPlayerDeath,EventHookMode_Post);
    HookEvent("round_end", OnRoundEnd);

    // hook disonnect incase a vital member leaves
    HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);

    
    HookEvent("weapon_zoom",OnWeaponZoom,EventHookMode_Pre);
    HookEvent("weapon_fire",OnWeaponFire,EventHookMode_Post);

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

bool in_lr(int client)
{
    return get_slot(client) != INVALID_SLOT;
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


    slot.active = false;
    slot.client = -1;

    slot.weapon = -1;

    slot.bullet_count = -1;
    slot.bullet_max = -1;

    slot.partner = -1;

    slot.bullet_chamber = -1;
    slot.chamber = -1;

    slot.restrict_drop = false;

    slot.weapon_string = "";

    kill_handle(slot.timer);

    slot.gun_dropped = false;

    end_line(slot);
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

void init_slot(int id, int client, int partner, lr_type type)
{
    slots[id].client = client;
    slots[id].type = type;
    slots[id].active = true;
    slots[id].partner = partner;

    start_beacon(id);
}

void start_lr(int t, int ct, lr_type type)
{
    if(!is_valid_t(t) || !is_valid_partner(ct))
    {
        return;
    }

    PrintToChat(t,"%s Lr %s vs %N\n",LR_PREFIX,lr_list[type],ct);
    PrintToChat(ct,"%s Lr %s vs %N\n",LR_PREFIX,lr_list[type],t)

    int t_slot = get_inactive_slot();
    int ct_slot = get_inactive_slot();


    init_slot(t_slot,t,ct_slot,type);
    init_slot(ct_slot,ct,t_slot,type);

    // only really need one of these to draw
    start_line(t_slot);

    switch(type)
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
            start_shot_for_shot(t_slot,ct_slot,1);
        }

        case mag_for_mag:
        {
            start_shot_for_shot(t_slot,ct_slot,7);
        }

        case shotgun_war:
        {
            start_shotgun_war(t_slot,ct_slot);
        }

        case russian_roulette:
        {
            start_russian_roulette(t_slot,ct_slot);
        }
    }

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
        int id = get_slot(client);

        print_slot(client,slots[id]);

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

        int partner = FindTarget(t,name);

        lr_type type = lr_request[t];

        start_lr(t,partner,type);
    }

    else if (action == MenuAction_End)
    {
        delete menu;
    }
  
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
        return -1;
    }

    // save what lr the current client is requesting so we can pull it inside the player handler
    lr_request[client] = view_as<lr_type>(lr);

    menu.Display(client,20);

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
