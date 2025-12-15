/*
**
*/
#if defined _FFD_INCLUDE_included
 #endinput
#endif
#define _FFD_INCLUDE_included


bool is_ffa(int attacker,int victim)
{
	if(is_valid_client(attacker) && is_valid_client(victim))
	{
		return GetClientTeam(attacker) == GetClientTeam(victim);
	}
	
	return false;
}


// ffd do a gun menu
void ffd_player_init(int client)
{
	WeaponMenu(client);
}

void init_ffd()
{
	global_ctx.special_day = friendly_fire_day;
	PrintToChatAll("%s Friendly fire day started.", SPECIALDAY_PREFIX);	
	
	// allow player to pick for 15 seconds
	PrintToChatAll("%s Please 15 seconds for friendly fire to be enabled", SPECIALDAY_PREFIX);
}

public void start_ffd()
{
	PrintToChatAll("%s Friendly fire enabled",SPECIALDAY_PREFIX);
	
	//implement a proper printing function lol
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	PrintCenterTextAll("Friendly fire day has begun"); 
	
	enable_friendly_fire();
}

public void end_ffd()
{

}

SpecialDayImpl ffd_impl()
{
	return make_sd_impl(init_ffd,start_ffd,end_ffd,ffd_player_init);
}