/*
**
*/
#if defined _FFDG_INCLUDE_included
 #endinput
#endif
#define _FFDG_INCLUDE_included


// ffdg
void ffdg_player_init(int client)
{
	WeaponMenu(client);
}


void init_ffdg()
{
	global_ctx.hp_steal = true; 
	global_ctx.special_day = juggernaut_day;
	PrintToChatAll("%s Friendly fire juggernaut day  started.", SPECIALDAY_PREFIX);
	
	global_ctx.player_init = ffdg_player_init;
	
	
	// allow player to pick for 20 seconds
	PrintToChatAll("%s Please wait 20 seconds for friendly fire to be enabled", SPECIALDAY_PREFIX);
	
}

StartJuggernaut()
{
	PrintToChatAll("%s Friendly fire enabled",SPECIALDAY_PREFIX);
	
	enable_friendly_fire();
}

public void end_juggernaut()
{

}