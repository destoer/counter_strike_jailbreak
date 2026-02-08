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
    LR_FAILSAFE_TRIGGERED failsafe_triggered

    // LR selection menu (not required) defaults to pick_partner
    LR_SELECTION_MENU selection_menu;
}



native void add_lr(LrImpl impl);
native void restrict_weapon(LrPlayer player, char[] weapon);

stock LrImpl make_lr_impl(LR_START lr_start, char[] name)
{
	LrImpl out;
	out.init_lr = null;
	out.start_lr = lr_start;
    strcopy(out.name,sizeof(out.name) - 1, name);
	
    out.failsafe_triggered = null;
    out.selection_menu = null;

	return out;
}

