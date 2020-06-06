/*
**
*/
#if defined _FFD_INCLUDE_included
 #endinput
#endif
#define _FFD_INCLUDE_included


#define FFA_CONDITION(%1,%2) (1 <= %1 <= MaxClients && 1 <= %2 <= MaxClients && %1 != %2 && GetClientTeam(%1) == GetClientTeam(%2))

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
