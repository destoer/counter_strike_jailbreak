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
}

public void start_scout()
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

bool scoutknife_restrict_weapon(int client, char[] weapon_string)
{
	return StrEqual(weapon_string,"weapon_scout") || StrEqual(weapon_string,"weapon_knife") || StrEqual(weapon_string,"weapon_ssg08");
}

void scoutknife_fix_ladder(int client)
{
	scout_player_init(client);
}

void add_scoutknife_impl()
{
	SpecialDayImpl scout_knife
	scout_knife = make_sd_impl(scoutknife_init,start_scout,end_scout,scout_player_init,"Scout Knives");
	scout_knife.sd_player_death = scoutknife_death;
	scout_knife.sd_restrict_weapon = scoutknife_restrict_weapon;
	scout_knife.sd_fix_ladder = scoutknife_fix_ladder;

	add_special_day(scout_knife);
}