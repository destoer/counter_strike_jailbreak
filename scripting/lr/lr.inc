// header gaurd
#if defined _INCLUDE_lr_included
 #endinput
#endif
#define _INCLUDE_lr_included

#define LR_SLOTS 4
#define INVALID_SLOT -1

#define LR_PREFIX "\x04[Last Request]\x07F8F8FF"

enum struct LrPlayer
{
    // Client associated with this player for.
    int client;
    // Slot for LR player for storing LR specific info about the player
    int slot;
    // Hash of the LR they are in. Use this when passing information about the LR
    // Across a time boundary as it will prevent TOUTOC bugs.
    // Use get_player_by_hash
    int hash;
}

typedef LR_INIT  = function void(LrPlayer player_t, LrPlayer player_ct, int option);
typedef LR_START  = function void(LrPlayer player_t, LrPlayer player_ct, int option);
typedef LR_FAILSAFE_TRIGGERED  = function void(LrPlayer player_t, LrPlayer player_ct);
typedef LR_SELECTION_MENU = function void(int client);

enum struct LrImpl
{
    int lr_type;

    char name[64]

    // Called when lr invoked (not required)
    LR_INIT init_lr;

    // Called when LR timer up (required)
    LR_START start_lr;

    // Called when LR failsafe triggered (not required)
    LR_FAILSAFE_TRIGGERED failsafe;

    float failsafe_time;

    // LR selection menu (not required) defaults to pick_partner
    LR_SELECTION_MENU selection_menu;

    // Calling plugin handle do not tamper with
    Handle plugin_handle;
}



native void add_lr(LrImpl impl);
native void restrict_weapon(LrPlayer player, char[] weapon);
native void default_menu_option();
native void pick_partner(int client, int option);

stock LrImpl make_lr_impl(LR_START lr_start, char[] name)
{
	LrImpl out;
	out.init_lr = null;
	out.start_lr = lr_start;
    strcopy(out.name,sizeof(out.name) - 1, name);
	
    out.failsafe = null;
    out.selection_menu = null;

    out.plugin_handle = GetMyHandle();

	return out;
}

stock LrImpl make_lr_impl_menu(LR_START lr_start, LR_SELECTION_MENU lr_menu, char[] name)
{
	LrImpl out;
    out = make_lr_impl(lr_start,name);
    out.selection_menu = lr_menu;

    return out;
}

stock LrImpl make_lr_impl_menu_failsafe(LR_START lr_start, LR_SELECTION_MENU lr_menu, 
    LR_FAILSAFE_TRIGGERED failsafe, float failsafe_time, char[] name)
{
	LrImpl out;
    out = make_lr_impl_menu(lr_start,lr_menu,name);
    out.failsafe_time = failsafe_time;
    out.failsafe = failsafe;

    return out;
}



stock int pick_partner_callback(Menu menu, MenuAction action, int client, int choice)
{
    if(action == MenuAction_Select)
    {
        pick_partner(client,choice);
    }

    else if (action == MenuAction_End)
    {
        delete menu;
    }

    return 0;
}