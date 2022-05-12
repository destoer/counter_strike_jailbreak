/*
**
*/
#if defined _SPECTRE_INCLUDE_included
 #endinput
#endif
#define _SPECTRE_INCLUDE_included


int spectre = -1;

void spectre_player_init(int client)
{
	WeaponMenu(client);
}

void spectre_init()
{
	PrintToChatAll("%s spectre day started", SPECIALDAY_PREFIX);
	special_day = spectre_day;
	sd_player_init_fptr = spectre_player_init;
	
	
	// save teams so we can swap them back later and select the "spectre"
	SaveTeams(true);
	
	if(validclients == 0)
	{
		PrintToChatAll("%s You are all freekillers!", SPECIALDAY_PREFIX);
		sd_init_failure = true;
		return;
	}

	if(rigged_client == -1)
	{
		int rand = GetRandomInt( 0, (validclients-1) );
		spectre = game_clients[rand]; // select the lucky client
	}

	else
	{
		spectre = rigged_client;
	}
}


public void MakeSpectre(int client)
{
	SetEntityHealth(client, 60 * GetClientCount(true));
	
	
	// ensure player has only a knife
	strip_all_weapons(client);
	
	GivePlayerItem(client, "weapon_knife"); 
	
	CS_SwitchTeam(client,CS_TEAM_CT);
	// spectre is invis
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 0, 0, 0, 0);
	set_client_speed(client, 2.0);
	PrintCenterTextAll("%N is the SPECTRE!", client);		
}

public void StartSpectre()
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
	
	MakeSpectre(spectre);
}

void end_spectre()
{
	RestoreTeams();
	SetEntityRenderColor(spectre,255,255,255, 255)
	spectre = -1;
}

public void spectre_discon_started(int client)
{
	SaveTeams(true);

	int rand = GetRandomInt( 0, validclients - 1 );
	spectre = game_clients[rand]; // select the lucky client
}


void spectre_discon_active(int client)
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
	while(spectre == client)
	{
		int rand = GetRandomInt( 0, (validclients-1) );
		spectre = game_clients[rand]; // select the lucky client
	}
	
	MakeSpectre(spectre);
}