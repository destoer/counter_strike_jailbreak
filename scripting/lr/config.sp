


ConVar lr_cvar;
ConVar ct_ban_cvar;

bool ct_ban = false;


new const String:lr_enable_name[LR_SIZE_ACTUAL][] =
{	
    "lr_knife_fight_enable",
    "lr_dodgeball_enable",
    "lr_nade_war_enable",
    "lr_race_enable",
    "lr_no_scope_enable",
    "lr_gun_toss_enable",
    "lr_crash_enable",
    "lr_shot_for_shot_enable",
    "lr_mag_for_mag_enable",
    "lr_shotgun_war_enable",
    "lr_russian_roulette_enable",
    "lr_headshot_only_enable",
    "lr_sumo_enable",
    "lr_scout_knife_enable",
    "lr_custom_enable",
    "lr_rebel_enable",
    "lr_knife_rebel_enable",
}

ConVar lr_enable_cvar[LR_SIZE_ACTUAL];
bool lr_enable[LR_SIZE];


void create_lr_convar()
{
    lr_cvar = CreateConVar("destoer_lr","1","enable lr",FCVAR_NONE);
    ct_ban_cvar = CreateConVar("jb_ct_ban","1","auto ban cts");

    for(int i = 0; i < LR_SIZE_ACTUAL; i++)
    {
        lr_enable_cvar[i] = CreateConVar(lr_enable_name[i],"1","enable the last request");
    }

    AutoExecConfig(true,"lr","jail");
}

void setup_config()
{
    ct_ban = GetConVarInt(ct_ban_cvar) > 0;

    for(int i = 0; i < LR_SIZE_ACTUAL; i++)
    {
	    lr_enable[i] = GetConVarInt(lr_enable_cvar[i]) > 0;
    }

    lr_enable[LR_SIZE - 1] = false;
}