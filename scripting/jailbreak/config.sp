
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
ConVar armor_cvar;
ConVar warden_block_cvar;
ConVar mute_cvar;
ConVar print_rebel_cvar;
ConVar guns_cvar;
ConVar helmet_cvar;
ConVar admin_laser_cvar;

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
bool armor;
bool warden_block;
bool mute;
bool print_rebel;
bool guns;
bool helmet;
bool admin_laser;

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
    noblock_cvar = CreateConVar("jb_noblock","0","players pass through eachover");
    stuck_cvar = CreateConVar("jb_stuck","0","enable stuck command");
    laser_cvar = CreateConVar("jb_kill_laser","0","enable kill laser");
    t_laser_cvar = CreateConVar("jb_t_laser","0","enable t laser");
    gun_cvar = CreateConVar("jb_gun_commands","0","enable ct gun menu");
    voice_cvar = CreateConVar("jb_warden_voice","1","enable getting warden from voice");
    armor_cvar = CreateConVar("jb_armor","1","give ct armor on spawn");
    helmet_cvar = CreateConVar("jb_helmet","1","give ct helmet+kevlar on spawn");
    warden_block_cvar = CreateConVar("jb_warden_block","1","enable warden block commands");

    // used for hosties replacment
    mute_cvar = CreateConVar("jb_mute","1","mute t's at round start");
    print_rebel_cvar = CreateConVar("jb_rebel","1","print rebels being killed");

    guns_cvar = CreateConVar("jb_guns","1","give ct's guns at round start");

    admin_laser_cvar = CreateConVar("jb_admin_laser","0","enable admin laser");
}

void setup_jb_convar()
{
    EngineVersion game = GetEngineVersion();
    if(game != Engine_CSGO && game != Engine_CSS)
    {
        SetFailState("This plugin is for CSGO/CSS only.");	
    }


    noblock = GetConVarInt(noblock_cvar) > 0;


    // hosties block settings dont match our's
    // dont boot

    Handle hosties_cvar = FindConVar("sm_hosties_noblock_enable");
    if(hosties_cvar)
    {
        bool hosties_noblock = GetConVarInt(hosties_cvar) > 0;

        if(hosties_noblock != noblock)
        {
            PrintToServer("Warning hosties no block differs from jb setting");
        }
    }

    laser_death = GetConVarInt(laser_cvar) > 0;
    t_laser = GetConVarInt(t_laser_cvar) > 0;
    gun_commands = GetConVarInt(gun_cvar) > 0;
    stuck = GetConVarInt(stuck_cvar) > 0;
    voice = GetConVarInt(voice_cvar) > 0;
    armor = GetConVarInt(armor_cvar) > 0;
    helmet = GetConVarInt(helmet_cvar) > 0;
    warden_block = GetConVarInt(warden_block_cvar) > 0;
    mute = GetConVarInt(mute_cvar) > 0;
    print_rebel = GetConVarInt(print_rebel_cvar) > 0;
    guns = guns_cvar.IntValue > 0;
    admin_laser = GetConVarInt(admin_laser_cvar) > 0;


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