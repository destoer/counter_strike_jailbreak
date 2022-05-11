
ConVar jb_prefix_css;
ConVar warden_prefix_css;
ConVar warden_player_prefix_css;

ConVar jb_prefix_csgo;
ConVar warden_prefix_csgo;
ConVar warden_player_prefix_csgo;

ConVar noblock_cvar;
ConVar laser_cvar;
ConVar stuck_cvar;
ConVar t_laser_cvar;
ConVar gun_cvar;
ConVar voice_cvar;

#define PREFIX_SIZE 128

char JB_PREFIX[PREFIX_SIZE];
char WARDEN_PREFIX[PREFIX_SIZE];
char WARDEN_PLAYER_PREFIX[PREFIX_SIZE];

bool noblock;
bool laser_death;
bool t_laser;
bool stuck;
bool gun_commands;
bool voice;


void create_jb_convar()
{
    // css
    jb_prefix_css = CreateConVar("jb_prefix_css","\x04[Jailbreak]\x07F8F8FF","prefix for plugin info");
    warden_prefix_css = CreateConVar("warden_prefix_css","\x04[Warden]\x07F8F8FF","prefix for warden info");
    warden_player_prefix_css = CreateConVar("warden_player_prefix_css","\x04[Warden]\x0700BFFF","prefix for warden typing in chat");


    // csgo
    jb_prefix_csgo = CreateConVar("jb_prefix_csgo","\x07[Jailbreak]\x07","prefix for plugin info");
    warden_prefix_csgo = CreateConVar("warden_prefix_csgo","\x07[Warden]\x07","prefix for warden info");
    warden_player_prefix_csgo = CreateConVar("warden_player_prefix_csgo","\x07[Warden]\x07","prefix for warden typing in chat");

    // common
    noblock_cvar = CreateConVar("jb_noblock","1","players pass through eachover");
    stuck_cvar = CreateConVar("jb_stuck","1","enable stuck command");
    laser_cvar = CreateConVar("jb_kill_laser","1","enable kill laser");
    t_laser_cvar = CreateConVar("jb_t_laser","1","enable t laser");
    gun_cvar = CreateConVar("jb_gun_commands","1","enable ct gun menu");
    voice_cvar = CreateConVar("jb_warden_voice","1","enable getting warden from voice");
}

void setup_jb_convar()
{
    EngineVersion game = GetEngineVersion();
    if(game != Engine_CSGO && game != Engine_CSS)
    {
        SetFailState("This plugin is for CSGO/CSS only.");	
    }

    // hosties block settings dont match our's
    // dont boot
    Handle hosties_cvar = FindConVar("sm_hosties_noblock_enable");
    bool hosties_noblock = GetConVarInt(hosties_cvar) > 0;

    noblock = GetConVarInt(noblock_cvar) > 0;

    if(hosties_noblock != noblock)
    {
        PrintToServer("Warning hosties no block differs from jb setting");
    }

    laser_death = GetConVarInt(laser_cvar) > 0;
    t_laser = GetConVarInt(t_laser_cvar) > 0;
    gun_commands = GetConVarInt(gun_cvar) > 0;
    stuck = GetConVarInt(stuck_cvar) > 0;
    voice = GetConVarInt(voice_cvar) > 0;


    if(game == Engine_CSGO)
    {
        jb_prefix_csgo.GetString(JB_PREFIX,PREFIX_SIZE);
        warden_prefix_csgo.GetString(WARDEN_PREFIX,PREFIX_SIZE);
        warden_player_prefix_csgo.GetString(WARDEN_PLAYER_PREFIX,PREFIX_SIZE);        
    }

    else if(game == Engine_CSS)
    {
        jb_prefix_css.GetString(JB_PREFIX,PREFIX_SIZE);
        warden_prefix_css.GetString(WARDEN_PREFIX,PREFIX_SIZE);
        warden_player_prefix_css.GetString(WARDEN_PLAYER_PREFIX,PREFIX_SIZE);
    }


}