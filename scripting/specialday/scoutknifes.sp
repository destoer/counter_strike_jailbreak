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
	if(GetEngineVersion() == Engine_CSS)
	{
		GivePlayerItem(client, "weapon_scout");
	}

	else if(GetEngineVersion() == Engine_CSGO)
	{
		GivePlayerItem(client,"weapon_ssg08");
	}

	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "item_assaultsuit");
	SetEntityGravity(client, 0.1)
}

public Action ReviveScout(Handle Timer, int client)
{
	if(is_valid_client(client) && is_on_team(client))
	{
		CS_RespawnPlayer(client);
		sd_player_init(client);
	}

	return Plugin_Continue;
}


void scoutknife_init()
{
	PrintToChatAll("%s scout knife day started", SPECIALDAY_PREFIX);
	global_ctx.special_day = scoutknife_day;
	global_ctx.player_init = scout_player_init;
}

public void StartScout()
{
	start_round_delay(90);
	CreateTimer(1.0, RemoveGuns);
}

void end_scout()
{
	int cli = get_client_max_kills();
	
	if(IsClientConnected(cli) && IsClientInGame(cli) && is_on_team(cli))
	{
		PrintCenterTextAll("%N won scoutknifes", cli);
		PrintToChatAll("%s %N won scoutknifes", SPECIALDAY_PREFIX, cli);
	}
	global_ctx.sd_winner = cli;
}

void scoutknife_death(int attacker,int victim)
{
	CreateTimer(3.0, ReviveScout, victim);
	sd_players[attacker].kills++;
}