
ConVar sd_prefix_cvar;

// common
ConVar ctban_cvar;
ConVar gangs_cvar;
ConVar store_cvar;
ConVar standalone_cvar;
ConVar freeze_cvar;
ConVar lr_cvar;
ConVar sd_delay_cvar;
ConVar map_time_minute_restrict_cvar;

ConVar sd_enable_cvar[SD_SIZE];

new const String:sd_enable_name[SD_SIZE][] =
{	
	"sd_ffd_enable", 
	"sd_tank_enable",
	"sd_juggernaut_enable",
	"sd_sky_wars_enable",
	"sd_hide_and_seek_enable",
	"sd_dodgeball_enable",
	"sd_grenade_enable",
	"sd_zombie_enable",
	"sd_gun_game_enable",
	"sd_knife_enable",
	"sd_scout_knife_enable",
	"sd_death_match_enable",
	"sd_laser_wars",
	"sd_spectre",
	"sd_headshot",
	//"VIP",
}



bool ct_ban;
bool store;
bool gangs;
bool standalone;
bool freeze;
bool lr;
int map_time_minute_restrict = 4;

bool sd_enable[SD_SIZE];

int SD_DELAY = 15;

#define PREFIX_SIZE 128

char SPECIALDAY_PREFIX[PREFIX_SIZE];


void create_sd_convar()
{
    sd_prefix_cvar = CreateConVar("sd_prefix_css","[Special Day]","sd prefix for");

    // common
    ctban_cvar = CreateConVar("sd_ctban","1","enable ctban support");
    gangs_cvar = CreateConVar("sd_gangs","0","enable gangs support");
    store_cvar = CreateConVar("sd_store","1","enable store support");
    sd_delay_cvar = CreateConVar("sd_delay","15","How long before an sd starts");
    standalone_cvar = CreateConVar("sd_standalone","0","make plugin operate without jailbreak");
    freeze_cvar = CreateConVar("sd_freeze","0","enable freeze commands");
    map_time_minute_restrict_cvar = CreateConVar("sd_map_minute_restrict","4","How many minutes left in map before sd is enabled (0 allways enabled)");
    lr_cvar = CreateConVar("sd_lr","1","disable lr on sd");

    for(int i = 0; i < SD_SIZE; i++)
    {
        sd_enable_cvar[i] = CreateConVar(sd_enable_name[i],"1","enable the special day");
    }

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
    ct_ban = GetConVarInt(ctban_cvar) > 0 && check_command_exists("ct_ban");
    gangs = GetConVarInt(gangs_cvar) > 0;
    store = GetConVarInt(store_cvar) > 0;
    standalone = GetConVarInt(standalone_cvar) > 0;
    freeze = GetConVarInt(freeze_cvar) > 0;  
    lr = GetConVarInt(lr_cvar) > 0;  
    SD_DELAY = GetConVarInt(sd_delay_cvar);
    map_time_minute_restrict = GetConVarInt(map_time_minute_restrict_cvar);


    for(int i = 0; i < SD_SIZE; i++)
    {
	    sd_enable[i] = GetConVarInt(sd_enable_cvar[i]) > 0;
    }
}