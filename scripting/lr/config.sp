


ConVar lr_cvar;
ConVar ct_ban_cvar;

bool ct_ban = false;


void create_lr_convar()
{
    lr_cvar = CreateConVar("destoer_lr","1","enable lr",FCVAR_NONE);
    ct_ban_cvar = CreateConVar("jb_ct_ban","1","auto ban cts");
}

void setup_config()
{
    ct_ban = GetConVarInt(ct_ban_cvar) > 0;
}