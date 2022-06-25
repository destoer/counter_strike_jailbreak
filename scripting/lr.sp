// reimpl of sm-hosties2 https://github.com/dataviruset/sm-hosties

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include "lib.inc"

#define PLUGIN_AUTHOR "destoer(organ harvester)"
#define PLUGIN_VERSION "V0.1 - Violent Intent Jailbreak"

/*
	onwards to the new era ( ͡° ͜ʖ ͡°)
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
}

const int LR_SIZE = 5;
new const String:lr_list[LR_SIZE][] =
{	
    "Knife fight",
    "Dodgeball",
    "Nade war",
    "No scope",
    "Gun toss",
/*
    "Russian roulette",
    "Shot for shot",
    "Shotgun War",
    "Mag for mag",
    "Sumo",
    "Race",
    "Rock paper scissors",
    "Hot potato",
    "Chicken fight",
    "Rebel"
*/
};


enum struct LrPair  
{
    bool active;
    int ct;
    int t;
    lr_type type;

    
    int t_weapon;
    int ct_weapon;

    float t_pos[3];
    float t_gun_pos[3];
    Handle t_timer;
    bool t_gun_dropped;

    float ct_pos[3];
    float ct_gun_pos[3];
    Handle ct_timer;
    bool ct_gun_dropped;

    Handle beacon_timer;
}

#define LR_PAIRS 2

#define INVALID_PAIR -1

#define BEACON_TIMER 0.1

#define GUNTOSS_TIMER 0.1

// NOTE: only take a copy for convience
// it only passes as reference when we directly access it
LrPair pairs[LR_PAIRS];

Menu lr_menu;

lr_type lr_request[64]

int g_lbeam;

// unity build
#include "lr/debug.sp"
#include "lr/hook.sp"
#include "lr/dodgeball.sp"
#include "lr/grenade.sp"
#include "lr/no_scope.sp"
#include "lr/gun_toss.sp"


// handle for sdkcall
Handle SetCollisionGroup;

public OnPluginStart()
{
    RegConsoleCmd("lr",command_lr);

    HookEvent("player_death", OnPlayerDeath,EventHookMode_Post);
    HookEvent("round_end", OnRoundEnd);

    // hook disonnect incase a vital member leaves
    HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);

    
    HookEvent("weapon_zoom",OnWeaponZoom,EventHookMode_Pre);

    for(int i = 0; i < MaxClients;i++)
    {
        if(is_valid_client(i))
        {
            OnClientPutInServer(i);
        }
    }

    SetCollisionGroup = init_set_collision();
}


int get_pair(int client)
{
    if(!is_valid_client(client))
    {
        return INVALID_PAIR;
    }

    // NOTE: this should be fine for a low pair number
    // otherwhise we are gonna need a client to pair lookup
    for(int i = 0; i < LR_PAIRS; i++)
    {
        if(pairs[i].ct == client || pairs[i].t == client)
        {
            return i;
        }
    }

    return INVALID_PAIR;
}

bool in_lr(int client)
{
    return get_pair(client) != INVALID_PAIR;
}


void end_lr(LrPair pair)
{
    end_beacon(pair);

    if(is_valid_client(pair.ct) && IsPlayerAlive(pair.ct))
    {
        GivePlayerItem(pair.ct,"weapon_knife");
        GivePlayerItem(pair.ct,"weapon_m4a1");
    }

    if(is_valid_client(pair.t) && IsPlayerAlive(pair.t))
    {
        GivePlayerItem(pair.t,"weapon_knife");
    }

    pair.active = false;
    pair.ct = -1;
    pair.t = -1;

    pair.t_weapon = -1;
    pair.ct_weapon = -1;

    kill_handle(pair.t_timer);
    kill_handle(pair.ct_timer);

    pair.t_gun_dropped = false;
    pair.ct_gun_dropped = false;
}

int get_inactive_pair()
{
    for(int i = 0; i < LR_PAIRS; i++)
    {
        if(!pairs[i].active)
        {
            return i;
        }
    }

    SetFailState("Could not find an empty lr pair");    

    return -1;
}


public Action draw_beacon(Handle timer,int id)
{
    LrPair pair;
    pair = pairs[id];


    if(!pair.active || !is_valid_client(pair.t) || !is_valid_client(pair.ct))
    {
        return Plugin_Handled;
    }

    float ct_cords[3];
    float t_cords[3];

    GetClientAbsOrigin(pair.ct,ct_cords); ct_cords[2] += 10.0;
    GetClientAbsOrigin(pair.t,t_cords); t_cords[2] += 10.0;


    // pulse handled by funcommands for now

    // draw line between players
    TE_SetupBeamPoints(ct_cords, t_cords, g_lbeam, 0, 0, 0, BEACON_TIMER, 0.8, 0.8, 2, 0.0, { 1, 153, 255, 255 }, 0);
    TE_SendToAll();


    return Plugin_Continue;
}

void end_beacon(LrPair pair)
{
    if(pair.beacon_timer != INVALID_HANDLE)
    {
        KillTimer(pair.beacon_timer);
        pair.beacon_timer = INVALID_HANDLE;
    }

    // stop beacon
    if(is_valid_client(pair.ct))
    {
        ServerCommand("sm_beacon %N",pair.ct);
    }

    if(is_valid_client(pair.t))
    {
        ServerCommand("sm_beacon %N",pair.t);
    }
}

void start_beacon(int id)
{
    // do beacon
    if(is_valid_client(pairs[id].ct))
    {
        ServerCommand("sm_beacon %N",pairs[id].ct);
    }

    if(is_valid_client(pairs[id].t))
    {
        ServerCommand("sm_beacon %N",pairs[id].t);
    }

    pairs[id].beacon_timer = CreateTimer(BEACON_TIMER,draw_beacon,id,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void start_lr(int id, int t, int ct, lr_type type)
{
    if(!is_valid_t(t) || !is_valid_partner(ct))
    {
        return;
    }

    PrintToChat(t,"%s Lr %s vs %N\n",LR_PREFIX,lr_list[type],ct);
    PrintToChat(ct,"%s Lr %s vs %N\n",LR_PREFIX,lr_list[type],t)

    pairs[id].t = t;
    pairs[id].ct = ct;
    pairs[id].active = true;

    pairs[id].type = type;

    start_beacon(id);

    switch(type)
    {
        case knife_fight: {}

        case dodgeball:
        {
            start_dodgeball(pairs[id]);
        }

        case grenade:
        {
            start_grenade(pairs[id]);
        }

        case no_scope:
        {
            start_no_scope(pairs[id]);
        }

        case gun_toss:
        {
            start_gun_toss(pairs[id]);
        }
    }

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
        int id = get_pair(client);

        print_pair(client,pairs[id]);

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

    if(!is_valid_t(client))
    {
        return Plugin_Handled;
    }


    int unused;
    int alive_t = get_alive_team_count(CS_TEAM_T,unused);
    if(alive_t > LR_PAIRS)
    {
        PrintToChat(client,"%s Too many players left alive %d : %d\n",LR_PREFIX,alive_t,LR_PAIRS);
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

        int idx = get_inactive_pair();

        start_lr(idx,t,partner,type);
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
