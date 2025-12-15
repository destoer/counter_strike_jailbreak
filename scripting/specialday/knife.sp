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
	global_ctx.weapon_restrict = "weapon_knife";
}

public void start_knife()
{
	PrintCenterTextAll("Knife day active");
	CreateTimer(1.0, RemoveGuns);
}

void add_knife_impl()
{
	add_special_day(make_sd_impl(knife_init,start_knife,callback_dummy,knife_player_init,"Knife"));
}