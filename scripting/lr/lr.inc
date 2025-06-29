// header gaurd
#if defined _INCLUDE_lr_included
 #endinput
#endif
#define _INCLUDE_lr_included


enum lr_type
{
    knife_fight,
    dodgeball,
    grenade,
    race,
    no_scope,
    gun_toss,
    crash,
    shot_for_shot,
    mag_for_mag,
    shotgun_war,
    russian_roulette,
    headshot_only,
    sumo,
    scout_knife,
    custom,
    rebel,
    knife_rebel,
    combo_key,

    // this is an invalid entry if we get this we have trouble
    slot_error,
}


const int LR_SIZE = 19;
#define LR_SIZE_ACTUAL 18
new const String:lr_list[LR_SIZE][] =
{	
    "Knife fight",
    "Dodgeball",
    "Nade war",
    "Race",
    "No scope",
    "Gun toss",
    "Crash",
    "Shot for shot",
    "Mag for Mag",
    "Shotgun war",
    "Russian roulette",
    "Headshot only",
    "Sumo",
    "Scout knife",
    "Custom",
    "Rebel",
    "Knife rebel",
    "Combo key",
    "Error"
/*
    "Race",
    "Rock paper scissors",
*/
};

native bool is_in_lr(int client);

// NOTE: partner may not be valid
forward void OnWinLR(int client,int partner, lr_type type);
forward void OnLREnabled(int client);
