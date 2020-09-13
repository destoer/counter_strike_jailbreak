/*
**
*/
#if defined _KNIFE_INCLUDE_included
 #endinput
#endif
#define _KNIFE_INCLUDE_included


void knife_player_init(int client)
{
	strip_all_weapons(client);
	GivePlayerItem(client,"weapon_knife");
}


void knife_init()
{
	PrintToChatAll("%s knife day started", SPECIALDAY_PREFIX);
	
	special_day = knife_day;
	sd_player_init_fptr = knife_player_init;
}

public void StartKnife()
{
	enable_friendly_fire();
	PrintCenterTextAll("Knife day active");
	CreateTimer(1.0, RemoveGuns);
}