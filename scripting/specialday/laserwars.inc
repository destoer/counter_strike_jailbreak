/*
**
*/
#if defined _LASERWARS_INCLUDE_included
 #endinput
#endif
#define _LASERWARS_INCLUDE_included


void laser_player_init(int client)
{
	WeaponMenu(client);
}



public Action ReviveLaser(Handle Timer, int client)
{
	if(is_valid_client(client) && is_on_team(client))
	{
		CS_RespawnPlayer(client);
		sd_player_init(client);
	}
}

void laser_init()
{
	PrintToChatAll("%s laser day started hold e after timer", SPECIALDAY_PREFIX);
	special_day = laser_day;
	sd_player_init_fptr = laser_player_init;
}

public void StartLaser()
{
	start_round_delay(90);
	CreateTimer(1.0, RemoveGuns);
	enable_friendly_fire();
}

void laser_death(int victim)
{
	CreateTimer(3.0, ReviveLaser, victim);
}