/*
**
*/
#if defined _DEATHMATCH_INCLUDE_included
 #endinput
#endif
#define _DEATHMATCH_INCLUDE_included


void deathmatch_player_init(int client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
	    SetEntityRenderColor(client, 0, 0, 255, 255);
	}
	
	else 
	{
	    SetEntityRenderColor(client, 255, 0, 0, 255);
	}
	WeaponMenu(client);
}

public Action ReviveDeathMatch(Handle Timer, int client)
{
	if(is_valid_client(client) && is_on_team(client))
	{
		CS_RespawnPlayer(client);
		sd_player_init(client);
	}

	return Plugin_Continue;
}

void deathmatch_init()
{
	PrintToChatAll("%s deathmatch day started", SPECIALDAY_PREFIX);
	global_ctx.special_day = deathmatch_day;
	
	BalTeams();
}	


public void start_deathmatch()
{
	start_round_delay(90);
	CreateTimer(1.0, RemoveGuns);
}

void end_deathmatch()
{
	int cli = get_client_max_kills();
	
	if(IsClientConnected(cli) && IsClientInGame(cli) && is_on_team(cli))
	{
		PrintCenterTextAll("%N won deathmatch",  cli);
		PrintToChatAll("%s %N won deathmatch", SPECIALDAY_PREFIX, cli);
	}
	global_ctx.sd_winner = cli;
	RestoreTeams();
}

void deathmatch_death(int attacker, int victim)
{
	CreateTimer(3.0, ReviveDeathMatch, victim);
	sd_players[attacker].kills++;
}

SpecialDayImpl deathmatch_impl()
{
	return make_sd_impl(deathmatch_init,start_deathmatch,end_deathmatch,deathmatch_player_init);
}