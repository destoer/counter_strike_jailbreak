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

    // this is an invalid entry if we get this we have trouble
    slot_error,
}


native bool is_in_lr(int client);

forward void OnWinLR(int client, lr_type type);
forward void OnLREnabled(int client);
