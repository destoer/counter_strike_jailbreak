/*
**
*/
#if defined _SCOUTKNIFE_INCLUDE_included
 #endinput
#endif
#define _SCOUTKNIFE_INCLUDE_included


void scout_player_init(int client)
{
	strip_all_weapons(client);
	GivePlayerItem(client, "weapon_scout");
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "item_assaultsuit");
	SetEntityGravity(client, 0.1)
}

public Action ReviveScout(Handle Timer, int client)
{
	CS_RespawnPlayer(client);
	sd_player_init(client);
}


void scoutknife_init()
{
	PrintToChatAll("%s scout knife day started", SPECIALDAY_PREFIX);
	special_day = scoutknife_day;
	sd_player_init_fptr = scout_player_init;
	
	// reset player kill
	for (int i = 0; i < 64; i++)
	{
		player_kills[i] = 0;
	}
}

public void StartScout()
{
	start_round_delay(90);
	CreateTimer(1.0, RemoveGuns);
	enable_friendly_fire();
}

void end_scout()
{
	int cli = get_client_max_kills();
	
	if(IsClientConnected(cli) && IsClientInGame(cli) && is_on_team(cli))
	{
		PrintToChatAll("%s %N won scoutknifes", SPECIALDAY_PREFIX, cli);
	}
	sd_winner = cli;
}

void scoutknife_death(int attacker,int victim)
{
	CreateTimer(3.0, ReviveScout, victim);
	player_kills[attacker]++;
}