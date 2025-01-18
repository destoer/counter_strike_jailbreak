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
	//vip_day,
	custom_day, // Must be after the last real sd
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
native void sd_start_custom_day();

forward void OnWinSD(int client, SpecialDay type);


#define ROUND_WARDEN_SD 50
#define ROUND_STACK_LIM 1
#define ROUND_PLAYER_REQ 3