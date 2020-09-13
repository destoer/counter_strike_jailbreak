/*
**
*/
#if defined _DEATHMATCH_INCLUDE_included
 #endinput
#endif
#define _DEATHMATCH_INCLUDE_included


void deathmatch_player_init(int client)
{
	WeaponMenu(client);
}

public Action ReviveDeathMatch(Handle Timer, int client)
{
	CS_RespawnPlayer(client);
	sd_player_init(client);
}

void deathmatch_init()
{
	PrintToChatAll("%s deathmatch day started", SPECIALDAY_PREFIX);
	special_day = deathmatch_day;
	sd_player_init_fptr = deathmatch_player_init;
	
	// reset player kill
	for (int i = 0; i < 64; i++)
	{
		player_kills[i] = 0;
	}
}	


public void StartDeathMatch()
{
	start_round_delay(90);
	CreateTimer(1.0, RemoveGuns);
	enable_friendly_fire();
}

void end_deathmatch()
{
	int cli = get_client_max_kills();
	
	if(IsClientConnected(cli) && IsClientInGame(cli) && is_on_team(cli))
	{
		PrintToChatAll("%s %N won deathmatch", SPECIALDAY_PREFIX, cli);
	}
	sd_winner = cli;
}

void deathmatch_death(int attacker, int victim)
{
	CreateTimer(3.0, ReviveDeathMatch, victim);
	player_kills[attacker]++;
}