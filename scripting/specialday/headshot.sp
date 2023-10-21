/*
**
*/
#if defined HEADSHOT_INCLUDE_included
 #endinput
#endif
#define HEADSHOT_INCLUDE_included

void StartHeadshot()
{
	
}

void headshot_init()
{
	global_ctx.special_day = headshot_day;
	PrintToChatAll("%s headshot day started.", SPECIALDAY_PREFIX);
	
	global_ctx.player_init = headshot_player_init;
	global_ctx.weapon_restrict = "weapon_deagle";
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