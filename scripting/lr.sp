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
    bool knife_rebel_active;
    bool lr_ready;
    bool ct_ban;
    int console;
    bool lr_sound_cached;
    int lbeam;
    int halo;
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

    bool restrict_damage;

    Handle start_timer;
    int delay;

    Handle line_timer;
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


Handle lr_win_forward = null;
Handle lr_enabled_forward = null;

#define LINE_TIMER 0.1
#define BEACON_TIMER 1.0

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
#include "lr/hook.sp"
// #include "lr/stats.sp"
#include "jailbreak/jailbreak.inc"

#undef REQUIRE_PLUGIN
#include "thirdparty/ctban.inc"
#define REQUIRE_PLUGIN

public int native_is_in_lr(Handle plugin, int num_param)
{
    int client = GetNativeCell(1);
    return in_lr(client);
}

public void native_add_lr(Handle plugin, int num_param)
{
    LrImpl impl;
    GetNativeArray(1,impl,sizeof(LrImpl));
    PrintToConsoleAll("Adding LR %s",impl.name);
    lr_impl.PushArray(impl);
}

public void native_restrict_weapon(Handle plugin, int num_param)
{
    LrPlayer player;
    GetNativeArray(1,player,sizeof(LrPlayer));
    char weapon[64];
    GetNativeString(2,weapon,sizeof(weapon));

    PrintToConsoleAll("Restricting weapon for %N %s",player.client,weapon);


    int slot = get_slot_from_hash(player.hash);
    if(slot != INVALID_SLOT)
    {
        strip_all_weapons(player.client)
        GivePlayerItem(player.client, weapon);
        strcopy(slots[slot].weapon_string,sizeof(slots[slot].weapon_string),weapon);
    }
}

// register our call
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("vi_lr");

    CreateNative("is_in_lr", native_is_in_lr);
    CreateNative("restrict_weapon", native_restrict_weapon);
    CreateNative("add_lr", native_add_lr);

    lr_win_forward = CreateGlobalForward("OnWinLR",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);
    lr_enabled_forward = CreateGlobalForward("OnLREnabled",ET_Ignore);


    return APLRes_Success;
}


void purge_context()
{
    global_ctx.current_hash = 0;
    global_ctx.lr_ready = false;
    global_ctx.ct_ban = false;
    global_ctx.rebel_lr_active = false;
    global_ctx.knife_rebel_active = false;
    global_ctx.console = -1;
    global_ctx.lr_sound_cached = false;
    global_ctx.lbeam = -1;
    global_ctx.halo = -1;
}

public OnPluginStart()
{
    create_lr_convar();
    setup_config();

    RegConsoleCmd("lr",command_lr);

    lr_impl = new ArrayList(sizeof(LrImpl));

    LoadTranslations("common.phrases"); 

    HookEvent("round_end", OnRoundEnd);
    HookEvent("round_start", OnRoundStart);

    HookEvent("player_death", OnPlayerDeath,EventHookMode_Post);

    for(int i = 1; i <= MaxClients; i++)
    {
        if(is_valid_client(i))
        {
            OnClientPutInServer(i);
        }
    }

    purge_context();
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

bool is_valid_slot(int id)
{
    return id != INVALID_SLOT;
}

bool in_lr(int client) {
    return get_slot(client) != INVALID_SLOT;
}

bool is_pair(int c1, int c2)
{
    int id1 = get_slot(c1);
    int id2 = get_slot(c2);

    // both in lr
    if(is_valid_slot(id1) && is_valid_slot(id2))
    {
        int partner = slots[id1].partner.slot;

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

bool is_valid_t(int client)
{
    if(!is_valid_client(client))
    {
        return false;
    }

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

    PrintToConsoleAll("Starting %s %d",impl.name,view_as<int>(impl.start_lr));
    Call_StartFunction(impl.plugin_handle,impl.start_lr);
    Call_PushArray(slots[t_slot].player,sizeof(LrPlayer));
    Call_PushArray(slots[t_slot].partner,sizeof(LrPlayer));
    Call_PushCell(lr_choice[t].option);
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

    start_beacon(id);
    start_line(id);
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
        Call_StartFunction(impl.plugin_handle,impl.init_lr);
		Call_PushArray(t_player,sizeof(LrPlayer));
        Call_PushArray(ct_player,sizeof(LrPlayer));
        Call_PushCell(lr_choice[t].option);
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

public Action draw_line(Handle timer,int id)
{
    LrSlot slot;
    slot = slots[id];


    if(slots[id].state == lr_inactive || !is_valid_client(slot.player.client))
    {
        return Plugin_Continue;
    }

    float client_cords[3];
    float partner_cords[3];

    GetClientAbsOrigin(slot.player.client,client_cords); client_cords[2] += 10.0;
    GetClientAbsOrigin(slot.partner.client,partner_cords); partner_cords[2] += 10.0;

    // draw line between players
    TE_SetupBeamPoints(client_cords, partner_cords, global_ctx.lbeam, 0, 0, 0, LINE_TIMER, 0.8, 0.8, 2, 0.0, { 1, 153, 255, 255 }, 0);
    TE_SendToAll();


    return Plugin_Continue;
}

public Action beacon_callback(Handle timer, int client)
{
    // if in a knife rebel beacon can stay active as long as it wants
    if(!global_ctx.knife_rebel_active)
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
    TE_SetupBeamRingPoint(pos, 35.0, 250.0, global_ctx.lbeam, global_ctx.halo, 0, 15, (BEACON_TIMER / 2), 2.0, 0.0, {66, 66, 66, 255}, 500, 0);
    TE_SendToAll();   

    // team color
    TE_SetupBeamRingPoint(pos, 35.0, 250.0, global_ctx.lbeam, global_ctx.halo, 0, 5, (BEACON_TIMER / 2) + 0.1, 2.0, 0.0, color, 250, 0);
    TE_SendToAll();    

    EmitAmbientSound("buttons/blip1.wav", pos, client, SNDLEVEL_RAIDSIREN);
    
    return Plugin_Continue;
}

void start_beacon(int id)
{
    // do beacon
    if(is_valid_client(slots[id].player.client))
    {
        CreateTimer(BEACON_TIMER,beacon_callback,slots[id].player.client,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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