/*
**
*/
#if defined _FFDG_INCLUDE_included
 #endinput
#endif
#define _FFDG_INCLUDE_included


// ffdg
void juggernaut_player_init(int client)
{
	WeaponMenu(client);
}


void init_juggernaut()
{
	global_ctx.hp_steal = true; 
	global_ctx.special_day = juggernaut_day;
	PrintToChatAll("%s Friendly fire juggernaut day  started.", SPECIALDAY_PREFIX);
	
	
	// allow player to pick for 20 seconds
	PrintToChatAll("%s Please %d seconds for friendly fire to be enabled", SPECIALDAY_PREFIX,SD_DELAY);
	
}

void start_juggernaut()
{
	PrintToChatAll("%s Friendly fire enabled",SPECIALDAY_PREFIX);
	
	enable_friendly_fire();
}

public void end_juggernaut()
{

}

void add_juggernaut_impl() 
{
	add_special_day(make_sd_impl(init_juggernaut,start_juggernaut,end_juggernaut,juggernaut_player_init,"Juggernaut"));
}