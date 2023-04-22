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
	normal_day,
};


enum SdState
{
	sd_started,
	sd_active,
	sd_inactive
};

native SdState sd_current_state();
native SpecialDay sd_current_day();


#define ROUND_WARDEN_SD 50
#define ROUND_STACK_LIM 2
#define ROUND_PLAYER_REQ 3