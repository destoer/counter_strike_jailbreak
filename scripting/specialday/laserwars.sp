/*
**
*/
#if defined _LASERWARS_INCLUDE_included
 #endinput
#endif
#define _LASERWARS_INCLUDE_included


int laser_tank = -1;

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

	return Plugin_Continue;
}

void laser_init()
{
	PrintToChatAll("%s laser day started hold e after timer if you are selected", SPECIALDAY_PREFIX);
	special_day = laser_day;
	sd_player_init_fptr = laser_player_init;

	SaveTeams(true);
	
	if(validclients == 0)
	{
		PrintToChatAll("%s You are all freekillers!", SPECIALDAY_PREFIX);
		sd_init_failure = true;
		return;
	}
	
	PrintToChatAll("%s Laser day started", SPECIALDAY_PREFIX);

	if(rigged_client == -1)
	{
		int rand = GetRandomInt( 0, (validclients-1) );
		laser_tank = game_clients[rand]; // select the lucky client
	}

	else
	{
		laser_tank = rigged_client;
	}
}

void make_laser(int client)
{
	SetEntityHealth(client, 15 * GetClientCount(true));
	CS_SwitchTeam(client,CS_TEAM_CT);
	SetEntityRenderColor(client, 255, 0, 0, 255);
	PrintCenterTextAll("%N has the kill laser!", client);
}


public void StartLaser()
{
	// swap everyone other than the tank to the t side
	// if they were allready in ct or t
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(is_on_team(i))
			{
				CS_SwitchTeam(i,CS_TEAM_T);
			}
		}
	}
	

	make_laser(laser_tank);
}


void laser_discon_active(int client)
{
	// restore the hp
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntityHealth(i, 100);	
		}
	}


	// while the current disconnecter
	while(laser_tank == client)
	{
		int rand = GetRandomInt( 0, (validclients-1) );
		laser_tank = game_clients[rand]; // select the lucky client
	}
	
	make_laser(laser_tank);		
}

public void laser_discon_started(int client)
{
	SaveTeams(true);

	int rand = GetRandomInt( 0, validclients - 1 );
	laser_tank = game_clients[rand]; // select the lucky client
}



void end_laser()
{
	PrintToChatAll("%s Laser day over", SPECIALDAY_PREFIX);
	RestoreTeams();
	SetEntityRenderColor(tank, 255, 255, 255, 255);
	laser_tank = -1;	
}

public void laser_death(int victim)
{
	//CreateTimer(3.0, ReviveLaser, victim);
}