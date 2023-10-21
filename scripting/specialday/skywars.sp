/*
**
*/
#if defined _SKYWARS_INCLUDE_included
 #endinput
#endif
#define _SKYWARS_INCLUDE_included


void client_fly(int client)
{
	set_client_speed(client,2.5);
	SetEntityMoveType(client, MOVETYPE_FLY);
}

// flying day
void flying_player_init(int client)
{
	// give player guns if we are just starting
	if(global_ctx.sd_state == sd_started)
	{
		WeaponMenu(client);
	}
	
	client_fly(client);
}


void init_skywars()
{
	global_ctx.special_day = fly_day;
	PrintToChatAll("%s Sky wars started, press e to toggle flying", SPECIALDAY_PREFIX);
	global_ctx.player_init = flying_player_init;
}

public void StartFly()
{

}