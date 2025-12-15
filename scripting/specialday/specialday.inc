/*
**
*/
#if defined SPECIALDAY_INCLUDE_included
 #endinput
#endif
#define SPECIALDAY_INCLUDE_included

// sadly we cant scope these
enum SpecialDay
{
	friendly_fire_day,
	tank_day,
	juggernaut_day,
	fly_day,
	hide_day,
	dodgeball_day,
	grenade_day,
	zombie_day,
	gungame_day,
	knife_day,
	scoutknife_day,
	deathmatch_day,
	laser_day,
	spectre_day,
	headshot_day,
	vip_day,
	custom_day, // Must be after the last real sd
	normal_day,
};


const int SD_SIZE = 16;
new const String:sd_list[SD_SIZE][] =
{	
	"Friendly Fire Day", 
	"Tank Day",
	"Friendly Fire Juggernaut Day",
	"Sky Wars",
	"Hide and Seek",
	"Dodgeball",
	"Grenade",
	"Zombie",
	"Gun Game",
	"Knife",
	"Scout Knives",
	"Death Match",
	"Laser Wars",
	"Spectre",
	"Headshot",
	"VIP",
};


enum SdState
{
	sd_started,
	sd_active,
	sd_inactive
};


typedef SD_START = function void();
typedef SD_END = function void();
typedef SD_INIT = function void();
typedef SD_PLAYER_INIT = function void(int client);
typedef SD_BOSS_DISCON_ACTIVE = function void(int client);
typedef SD_PLAYER_DEATH = function void(int attacker, int victim);
typedef SD_ON_TAKE_DAMAGE = function void(int attacker, int victim, float &damage)

enum struct SpecialDayImpl
{
	// called on sd start (required)
	SD_START sd_start;
	// called on sd init (required)
	SD_INIT sd_init;
	// called on special day end (required)
	SD_END sd_end;

	// function pointer set to tell us how to handle initialize players on sds
	// (required)
	SD_PLAYER_INIT sd_player_init;

	// Called on dc active during active SD (not required)
	SD_BOSS_DISCON_ACTIVE sd_discon_active;

	// Called on player death during active SD (not required)
	SD_PLAYER_DEATH sd_player_death;

	// Called when a player takes damage during SD (not required)
	SD_ON_TAKE_DAMAGE sd_take_damage;
}

native SdState sd_current_state();
native SpecialDay sd_current_day();
native void sd_start_custom_day();

forward void OnWinSD(int client, SpecialDay type);
forward void OnStartSD(SpecialDay type);
forward void OnEndSD(SpecialDay type, bool forced);

#define ROUND_WARDEN_SD 50
#define ROUND_STACK_LIM 1
#define ROUND_PLAYER_REQ 3