
ConVar sd_prefix_css_cvar;
ConVar sd_prefix_csgo_cvar;

// common
ConVar ctban_cvar;
ConVar gangs_cvar;
ConVar store_cvar;
ConVar standalone_cvar;
ConVar freeze_cvar;
ConVar lr_cvar;


bool ct_ban;
bool store;
bool gangs;
bool standalone;
bool freeze;
bool lr;

#define PREFIX_SIZE 128

char SPECIALDAY_PREFIX[PREFIX_SIZE];


void create_sd_convar()
{
    sd_prefix_css_cvar = CreateConVar("sd_prefix_css","\x04[Special Day]\x07F8F8FF","sd prefix for css");
    sd_prefix_csgo_cvar = CreateConVar("sd_prefix_csgo","\x04[Special Day]\x02","sd prefix for csgo");

    // common
    ctban_cvar = CreateConVar("sd_ctban","1","enable ctban support");
    gangs_cvar = CreateConVar("sd_gangs","0","enable gangs support");
    store_cvar = CreateConVar("sd_store","1","enable store support");
    standalone_cvar = CreateConVar("sd_standalone","0","make plugin operate without jailbreak");
    freeze_cvar = CreateConVar("sd_freeze","0","enable freeze commands");
    lr_cvar = CreateConVar("sd_lr","1","disable lr on sd");
}

void setup_sd_convar()
{
    EngineVersion game = GetEngineVersion();
    if(game != Engine_CSGO && game != Engine_CSS)
    {
        SetFailState("This plugin is for CSGO/CSS only.");	
    }


    if(game == Engine_CSGO)
    {
        sd_prefix_csgo_cvar.GetString(SPECIALDAY_PREFIX,PREFIX_SIZE);
    }

    else if(game == Engine_CSS)
    {
        sd_prefix_css_cvar.GetString(SPECIALDAY_PREFIX,PREFIX_SIZE);
    }


    // commmon
    ct_ban = GetConVarInt(ctban_cvar) > 0;
    gangs = GetConVarInt(gangs_cvar) > 0;
    store = GetConVarInt(store_cvar) > 0;
    standalone = GetConVarInt(standalone_cvar) > 0;
    freeze = GetConVarInt(freeze_cvar) > 0;  
    lr = GetConVarInt(lr_cvar) > 0;  
}