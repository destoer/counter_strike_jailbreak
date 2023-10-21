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
	
	global_ctx.special_day = knife_day;
	global_ctx.player_init = knife_player_init;
	global_ctx.weapon_restrict = "weapon_knife";
}

public void StartKnife()
{
	PrintCenterTextAll("Knife day active");
	CreateTimer(1.0, RemoveGuns);
}