/*
**
*/
#if defined _TANK_INCLUDE_included
 #endinput
#endif
#define _TANK_INCLUDE_included



int tank = -1; // hold client id of the tank

// tank give a gun menu
void tank_player_init(int client)
{
	WeaponMenu(client);
}

void init_tank()
{
	SaveTeams(true);
	
	if(validclients == 0)
	{
		PrintToChatAll("%s You are all freekillers!", SPECIALDAY_PREFIX);
		sd_init_failure = true;
		return;
	}
	
	special_day = tank_day;
	PrintToChatAll("%s Tank day started", SPECIALDAY_PREFIX);
	
	sd_player_init_fptr = tank_player_init;

	if(rigged_client == -1)
	{
		int rand = GetRandomInt( 0, (validclients-1) );
		tank = game_clients[rand]; // select the lucky client
	}

	else
	{
		tank = rigged_client;
	}
}

void end_tank()
{
	PrintToChatAll("%s Tank day over", SPECIALDAY_PREFIX);
	RestoreTeams();
	SetEntityRenderColor(tank, 255, 255, 255, 255);
	tank = -1;	
}


public void MakeTank(int client)
{
	SetEntityHealth(client, 250 * GetClientCount(true));
	CS_SwitchTeam(client,CS_TEAM_CT);
	SetEntityRenderColor(client, 255, 0, 0, 255);
	PrintCenterTextAll("%N is the TANK!", client);
}


public void StartTank()
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
	
	MakeTank(tank);
}


void tank_discon_active(int client)
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
	while(tank == client)
	{
		int rand = GetRandomInt( 0, (validclients-1) );
		tank = game_clients[rand]; // select the lucky client
	}
	
	
	MakeTank(tank);		
}

void tank_discon_started(int client)
{
	client += 0; // ignore unused warning
	SaveTeams(true);

	int rand = GetRandomInt( 0, validclients - 1 );
	tank = game_clients[rand]; // select the lucky client
}