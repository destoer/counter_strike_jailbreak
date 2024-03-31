
ConVar jb_prefix;
ConVar warden_prefix;
ConVar warden_player_prefix;

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
ConVar warday_cvar;
ConVar warday_gun_cvar;
ConVar auto_warden_cvar;
ConVar handicap_enable_cvar;
ConVar warden_ring_cvar;
ConVar ct_primary_cvar;
ConVar ct_secondary_cvar;
ConVar warden_command_end_delay_cvar;

#define PREFIX_SIZE 128

char JB_PREFIX[PREFIX_SIZE];
char WARDEN_PREFIX[PREFIX_SIZE];
char WARDEN_PLAYER_PREFIX[PREFIX_SIZE];

#define WEAPON_SIZE 128
char CT_PRIMARY[WEAPON_SIZE] = "weapon_m4a1";
char CT_SECONDARY[WEAPON_SIZE] = "weapon_deagle";

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

bool warday_enable;
bool warday_gun_enable;

bool auto_warden;

bool handicap_enable;

bool warden_ring;

int warden_command_end_delay = 0;


void create_jb_convar()
{
    // css
    jb_prefix = CreateConVar("jb_prefix_css","[Jailbreak]","prefix for plugin info");
    warden_prefix = CreateConVar("warden_prefix_css","[Warden]","prefix for warden info");
    warden_player_prefix = CreateConVar("warden_player_prefix_css","[Warden]","prefix for warden typing in chat");

    // common
    noblock_cvar = CreateConVar("jb_noblock","0","players pass through eachover");
    stuck_cvar = CreateConVar("jb_stuck","0","enable stuck command");
    laser_cvar = CreateConVar("jb_kill_laser","0","enable kill laser");
    t_laser_cvar = CreateConVar("jb_t_laser","0","enable t laser");
    gun_cvar = CreateConVar("jb_gun_commands","0","enable ct gun menu");
    voice_cvar = CreateConVar("jb_warden_voice","0","enable getting warden from voice");
    armor_cvar = CreateConVar("jb_armor","1","give ct armor on spawn");
    helmet_cvar = CreateConVar("jb_helmet","1","give ct helmet+kevlar on spawn");
    warden_block_cvar = CreateConVar("jb_warden_block","1","enable warden block commands");
    auto_warden_cvar = CreateConVar("jb_auto_warden","1","enable auto warden on last alive");
    handicap_enable_cvar = CreateConVar("jb_handicap","1","enable handicap on bad ct ratio");
    warden_ring_cvar = CreateConVar("jb_warden_ring","1","enable warden ring");

    ct_secondary_cvar = CreateConVar("jb_ct_secondary","weapon_deagle","default ct secondary");
    ct_primary_cvar = CreateConVar("jb_ct_primary","weapon_m4a1","default ct primary");

    // used for hosties replacment
    mute_cvar = CreateConVar("jb_mute","1","mute t's at round start");
    print_rebel_cvar = CreateConVar("jb_rebel","1","print rebels being killed");

    guns_cvar = CreateConVar("jb_guns","1","give ct's guns at round start");
    warday_cvar = CreateConVar("jb_warday","1","enable the warday command");
    warday_gun_cvar = CreateConVar("jb_warday_guns","1","enable the warday guns");

    admin_laser_cvar = CreateConVar("jb_admin_laser","0","enable admin laser");

    warden_command_end_delay_cvar = CreateConVar("warden_command_end_delay","0","delay for print to say orders are no longer active");

    AutoExecConfig(true,"jail","jail");
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
    auto_warden = GetConVarInt(auto_warden_cvar) > 0;
    handicap_enable = GetConVarInt(handicap_enable_cvar) > 0;
    warden_ring = GetConVarInt(warden_ring_cvar) > 0;

    warday_enable = warday_cvar.IntValue > 0;
    warday_gun_enable = warday_gun_cvar.IntValue > 0;

    jb_prefix.GetString(JB_PREFIX,PREFIX_SIZE);
    warden_prefix.GetString(WARDEN_PREFIX,PREFIX_SIZE);
    warden_player_prefix.GetString(WARDEN_PLAYER_PREFIX,PREFIX_SIZE);

    if(game == Engine_CSGO)
    {
        Format(JB_PREFIX,PREFIX_SIZE,"\x04%s\x07",JB_PREFIX);
        Format(WARDEN_PREFIX,PREFIX_SIZE,"\x04%s\x07",WARDEN_PREFIX);
        Format(WARDEN_PLAYER_PREFIX,PREFIX_SIZE,"\x04%s\x07",WARDEN_PLAYER_PREFIX);
    }

    else if(game == Engine_CSS)
    {
        Format(JB_PREFIX,PREFIX_SIZE,"\x04%s\x07F8F8FF",JB_PREFIX);
        Format(WARDEN_PREFIX,PREFIX_SIZE,"\x04%s\x07F8F8FF",WARDEN_PREFIX);
        Format(WARDEN_PLAYER_PREFIX,PREFIX_SIZE,"\x04%s\x0700BFFF",WARDEN_PLAYER_PREFIX);
    }

    ct_primary_cvar.GetString(CT_PRIMARY,WEAPON_SIZE);
    ct_secondary_cvar.GetString(CT_SECONDARY,WEAPON_SIZE);
    
    warden_command_end_delay = GetConVarInt(warden_command_end_delay_cvar);
}