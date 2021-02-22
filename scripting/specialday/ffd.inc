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
	special_day = friendly_fire_day;
	PrintToChatAll("%s Friendly fire day started.", SPECIALDAY_PREFIX);
	
	sd_player_init_fptr = ffd_player_init;
	
	
	// allow player to pick for 20 seconds
	PrintToChatAll("%s Please wait 20 seconds for friendly fire to be enabled", SPECIALDAY_PREFIX);
}

public void StartFFD()
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
	disable_friendly_fire();
}