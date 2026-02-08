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


enum lr_state 
{
    lr_inactive,
    lr_starting,
    lr_active,
}

enum struct Context
{
    int start_timestamp;
    int current_hash;
    bool rebel_lr_active;
}

Context global_ctx;

enum struct LrSlot  
{
    lr_state state;

    LrPlayer player;
    LrPlayer partner;

    LrImpl impl;
    int option;

    int weapon;
    char weapon_string[64];
    bool restrict_drop;

    bool failsafe;

    Handle start_timer;
    int delay;
}

enum struct Choice
{
    int lr_type;
    
    // basic menu option
    int option;
}

LrSlot slots[LR_SLOTS];


ArrayList lr_impl;


Choice lr_choice[MAXPLAYERS + 1]

// unity build
// #include "lr/debug.sp"
// #include "lr/knife_fight.sp"
// #include "lr/dodgeball.sp"
// #include "lr/grenade.sp"
// #include "lr/no_scope.sp"
// #include "lr/gun_toss.sp"
// #include "lr/shot_for_shot.sp"
// #include "lr/shotgun_war.sp"
// #include "lr/russian_roulette.sp"
// #include "lr/headshot_only.sp"
// #include "lr/scout_knife.sp"
// #include "lr/race.sp"
// #include "lr/sumo.sp"
// #include "lr/rebel.sp"
// #include "lr/combo_key.sp"
// #include "lr/crash.sp"
// #include "lr/custom.sp"
#include "lr/config.sp"
// #include "lr/hook.sp"
// #include "lr/stats.sp"
#include "jailbreak/jailbreak.inc"

#undef REQUIRE_PLUGIN
#include "thirdparty/ctban.inc"
#define REQUIRE_PLUGIN


public OnPluginStart()
{
    create_lr_convar();
    setup_config();

    RegConsoleCmd("lr",command_lr);

    lr_impl = new ArrayList(sizeof(LrImpl));

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
        if(slots[i].player.client == client)
        {
            return i;
        }
    }

    return INVALID_SLOT;
}

int get_slot_from_hash(int hash) {

    // NOTE: this should be fine for a low slot number
    // otherwise we are gonna need a client to slot lookup
    for(int i = 0; i < LR_SLOTS; i++)
    {
        if(slots[i].player.hash == hash)
        {
            return i;
        }
    }

    return INVALID_SLOT;

}


bool in_lr(int client) {
    return get_slot(client) != INVALID_SLOT;
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
        PrintToChat(client,"%s You are already in a lr\n",LR_PREFIX);
        return false;
    }

    if(GetClientTeam(client) != CS_TEAM_T)
    {
        PrintToChat(client,"%s You must be on t to start a lr\n",LR_PREFIX);
        return false;        
    }

    return true;    
}


LrPlayer get_inactive_slot(int client)
{
    LrPlayer player;
    player.client = client;
    player.hash = global_ctx.current_hash;
    global_ctx.current_hash += 1;


    for(int i = 0; i < LR_SLOTS; i++)
    {
        if(slots[i].state == lr_inactive)
        {
            player.slot = i;
            slots[i].state = lr_starting;
            return player;
        }
    }

    SetFailState("Could not find an empty lr slot");
    return player;
}


public Action start_lr_callback(Handle timer, int hash)
{
    // By convention the passed hash is for the T
    int t_slot = get_slot_from_hash(hash);
    if(t_slot == INVALID_SLOT) 
    {
        return Plugin_Handled;
    }

    int t = slots[t_slot].player.client;
    int ct = slots[t_slot].partner.client;

    LrImpl impl;
    impl = slots[t_slot].impl;

    if(slots[t_slot].delay)
    {
        slots[t_slot].delay -= 1;
        int delay = slots[t_slot].delay;

        // Suggestion: fearless print lr in countdown
        PrintCenterText(t,"lr %s starting in %d seconds against %N!",impl.name,delay,ct);
        PrintCenterText(ct,"lr %s starting in %d seconds against %N!",impl.name,delay,t);

        if(slots[t_slot].delay)
        {
            slots[t_slot].start_timer = CreateTimer(1.0,start_lr_callback,hash,TIMER_FLAG_NO_MAPCHANGE);
            return Plugin_Handled;
        }

        slots[t_slot].start_timer = null;
    }

    PrintCenterText(t,"Go!");
    PrintCenterText(ct,"Go!");

    Call_StartFunction(null,impl.start_lr);
    Call_PushArray(slots[t_slot].player,sizeof(LrPlayer));
    Call_PushArray(slots[t_slot].partner,sizeof(LrPlayer));
    Call_Finish();

    int partner = slots[t_slot].partner.slot;

    slots[t_slot].state = lr_active;
    slots[partner].state = lr_active;

    return Plugin_Continue;
}

void init_slot(LrPlayer player, LrPlayer partner, LrImpl impl, int option)
{
    int id = player.slot;

    slots[id].player = player;
    slots[id].partner = partner;
    slots[id].impl = impl;
    slots[id].state = lr_starting;
    slots[id].option = option;
}

void start_lr_internal(int t, int ct, int lr_type)
{
    LrImpl impl;
    impl = get_lr_impl(lr_type);

    PrintToChat(t,"%s Lr %s vs %N\n",LR_PREFIX,impl.name,ct);
    PrintToChat(ct,"%s Lr %s vs %N\n",LR_PREFIX,impl.name,t)

    LrPlayer t_player;
    t_player = get_inactive_slot(t);
    LrPlayer ct_player;
    ct_player = get_inactive_slot(ct);

    init_slot(t_player,ct_player, impl, lr_choice[t].option);
    init_slot(ct_player,t_player,  impl, lr_choice[t].option);

    if(impl.init_lr != null)
    {
        Call_StartFunction(null,impl.init_lr);
		Call_PushArray(t_player,sizeof(LrPlayer));
        Call_PushArray(ct_player,sizeof(LrPlayer));
		Call_Finish();
    }

    strip_all_weapons(t);
    strip_all_weapons(ct);

    int delay = 3;
    slots[t_player.slot].delay = delay; 

    // Suggestion: fearless print lr in countdown
    PrintCenterText(t,"lr %s starting in %d seconds against %N!",impl.name,delay,ct);
    PrintCenterText(ct,"lr %s starting in %d seconds against %N!",impl.name,delay,t);
    slots[t_player.slot].start_timer = CreateTimer(1.0,start_lr_callback,t_player.hash,TIMER_FLAG_NO_MAPCHANGE);   
}

bool is_valid_partner(int client)
{
    return is_valid_client(client) && IsPlayerAlive(client) && !in_lr(client) && GetClientTeam(client) == CS_TEAM_CT;
}


void start_lr(int t, int ct, int lr_type)
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

    start_lr_internal(t,ct,lr_type);
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


        start_lr(t,partner,lr_choice[t].lr_type);
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


public int lr_select(int client, LrImpl impl)
{
    PrintToChat(client,"%s Selected %s\n",LR_PREFIX,impl.name);

    if(!is_valid_t(client))
    {
        return -1;
    }

    // save what lr the current client is requesting so we can pull it inside the player handler
    lr_choice[client].lr_type = impl.lr_type;
    lr_choice[client].option = 0;
    pick_partner(client);            

    return 0;
}

public int lr_handler(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		char item[64];
		menu.GetItem(param2, item, sizeof(item));

        // Ignore the error choice
        for (int i = 0; i < lr_impl.Length; i++)
        {
            LrImpl impl;
            impl = get_lr_impl(i);
            if(StrEqual(impl.name,item)) 
            {
                return lr_select(client,impl);
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

LrImpl get_lr_impl(int index)
{
	LrImpl impl;
	lr_impl.GetArray(index,impl);
	return impl;
}

void show_lr_menu(int client)
{
	Menu menu = new Menu(lr_handler);

    // Ignore the error choice
	for (int i = 0; i < lr_impl.Length; i++)
	{
        LrImpl impl;
        impl = get_lr_impl(i);
		menu.AddItem(impl.name, impl.name);
	}

	menu.SetTitle("Last Request");

    // open a selection menu for 20 seconds
    menu.Display(client,20);  
}

// error when true
bool command_lr_internal(int client)
{
    if(global_ctx.rebel_lr_active)
    {
        return true;
    }

    // lr is not enabled
    if(lr_cvar.IntValue == 0)
    {
        PrintToChat(client,"%s Lr is currently disabled!",LR_PREFIX);
        return true;
    }

    if(GetTime() - global_ctx.start_timestamp < 15 && !is_sudoer(client))
    {
        int remain = 15 - (GetTime() - global_ctx.start_timestamp);

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

    show_lr_menu(client);
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
