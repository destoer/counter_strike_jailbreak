
ConVar sd_prefix_cvar;

// common
ConVar ctban_cvar;
ConVar ctban_override_cvar;
ConVar gangs_cvar;
ConVar store_cvar;
ConVar standalone_cvar;
ConVar freeze_cvar;
ConVar lr_cvar;
ConVar sd_delay_cvar;


bool ct_ban;
bool ct_ban_override;
bool store;
bool gangs;
bool standalone;
bool freeze;
bool lr;

int SD_DELAY = 15;

#define PREFIX_SIZE 128

char SPECIALDAY_PREFIX[PREFIX_SIZE];


void create_sd_convar()
{
    sd_prefix_cvar = CreateConVar("sd_prefix_css","[Special Day]","sd prefix for");

    // common
    ctban_cvar = CreateConVar("sd_ctban","1","enable ctban support");
    ctban_override_cvar = CreateConVar("sd_ctban_override","0","enable ctban override");
    gangs_cvar = CreateConVar("sd_gangs","0","enable gangs support");
    store_cvar = CreateConVar("sd_store","1","enable store support");
    sd_delay_cvar = CreateConVar("sd_delay","15","How long before an sd starts");
    standalone_cvar = CreateConVar("sd_standalone","0","make plugin operate without jailbreak");
    freeze_cvar = CreateConVar("sd_freeze","0","enable freeze commands");
    lr_cvar = CreateConVar("sd_lr","1","disable lr on sd");

    AutoExecConfig(true,"specialday","jail");
}

void setup_sd_convar()
{
    EngineVersion game = GetEngineVersion();
    if(game != Engine_CSGO && game != Engine_CSS)
    {
        SetFailState("This plugin is for CSGO/CSS only.");	
    }

    sd_prefix_cvar.GetString(SPECIALDAY_PREFIX,PREFIX_SIZE);

    if(game == Engine_CSGO)
    {
        Format(SPECIALDAY_PREFIX,PREFIX_SIZE,"\x04%s\x02",SPECIALDAY_PREFIX);
    }

    else if(game == Engine_CSS)
    {
        Format(SPECIALDAY_PREFIX,PREFIX_SIZE,"\x04%s\x07F8F8FF",SPECIALDAY_PREFIX);
    }


    // commmon
    ct_ban = GetConVarInt(ctban_cvar) > 0;
    ct_ban_override = GetConVarInt(ctban_override_cvar) > 0;
    gangs = GetConVarInt(gangs_cvar) > 0;
    store = GetConVarInt(store_cvar) > 0;
    standalone = GetConVarInt(standalone_cvar) > 0;
    freeze = GetConVarInt(freeze_cvar) > 0;  
    lr = GetConVarInt(lr_cvar) > 0;  
    SD_DELAY = GetConVarInt(sd_delay_cvar);
}