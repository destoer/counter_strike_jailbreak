/*
**
*/
#if defined HEADSHOT_INCLUDE_included
 #endinput
#endif
#define HEADSHOT_INCLUDE_included

#define HITGROUP_HEAD 1

void StartHeadshot()
{
	enable_friendly_fire();
}

void headshot_init()
{
	special_day = headshot_day;
	PrintToChatAll("%s headshot day started.", SPECIALDAY_PREFIX);
	
	sd_player_init_fptr = headshot_player_init;
}

// ffd do a gun menu
void headshot_player_init(int client)
{
	// ensure player has only a knife
	strip_all_weapons(client);
	GivePlayerItem(client, "weapon_deagle"); 
	
	// give them plenty of deagle ammo
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	set_reserve_ammo(client, weapon, 999);
}