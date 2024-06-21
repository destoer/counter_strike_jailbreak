/*
**
*/
#if defined _GUNGAME_INCLUDE_included
 #endinput
#endif
#define _GUNGAME_INCLUDE_included


// holds indexes into the gun list so we can randomize what guns are on each sd
int gungame_gun_idx[GUNS_SIZE] = {0};

// gun game
void gun_game_player_init(int client)
{
	// color them incase the skin aint set
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
	    SetEntityRenderColor(client, 0, 0, 255, 255);
	}
	
	else 
	{
	    SetEntityRenderColor(client, 255, 0, 0, 255);
	}
	GiveGunGameGun(client);
}

void init_gungame()
{
	
	PrintToChatAll("%s gun game day started", SPECIALDAY_PREFIX);
	
	global_ctx.special_day = gungame_day;
	
	// shuffle the game game indexes to randomize weapons
	for (int i = GUNS_SIZE-1; i >= 0; i--)
	{
		int idx = GetRandomInt(0, GUNS_SIZE - 1);
		
		int tmp = gungame_gun_idx[i];
		gungame_gun_idx[i] = gungame_gun_idx[idx];
		gungame_gun_idx[idx] = tmp;
	}
		
	global_ctx.player_init = gun_game_player_init;
	BalTeams();
}


public void GiveGunGameGun(int client)
{
	strip_all_weapons(client);
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "item_assaultsuit");
	
	EngineVersion game = GetEngineVersion();
	
	if(game == Engine_CSS)
	{
		GivePlayerItem(client, gun_give_list_css[gungame_gun_idx[players[client].gungame_level]]);
	}
	
	else if(game == Engine_CSGO)
	{
		GivePlayerItem(client, gun_give_list_csgo[gungame_gun_idx[players[client].gungame_level]]);
	}
	
	PrintToChat(client, "%s Current level: %s (%d of %d)", 
		SPECIALDAY_PREFIX, gun_list[gungame_gun_idx[players[client].gungame_level]],players[client].gungame_level+1,GUNS_SIZE);
}



public Action ReviveGunGame(Handle timer, int client)
{
	if(global_ctx.special_day != gungame_day)
	{
		return Plugin_Continue;
	}
	
	if(is_valid_client(client) && is_on_team(client))
	{
		CS_RespawnPlayer(client);
		sd_player_init(client);
	}

	return Plugin_Continue;		
}

public void StartGunGame()
{
	PrintCenterTextAll("Gun game active");
	disable_round_end();
	CreateTimer(1.0, RemoveGuns);
}

void gungame_death(int attacker, int victim)
{
	// if they die by some silly means then ignore and resp
	if(!(attacker > 0 && victim <= MaxClients))
	{
		CreateTimer(3.0, ReviveGunGame, victim);
		return;
	}
	
	
	char weapon_name[64];
	GetClientWeapon(attacker, weapon_name, sizeof(weapon_name));
	
	bool kill_gungame_weapon = false;

	EngineVersion game = GetEngineVersion();

	if(game == Engine_CSS)
	{
		kill_gungame_weapon = StrEqual(weapon_name, gun_give_list_css[gungame_gun_idx[players[attacker].gungame_level]]);
	}

	else if(game == Engine_CSGO)
	{
		kill_gungame_weapon = StrEqual(weapon_name, gun_give_list_csgo[gungame_gun_idx[players[attacker].gungame_level]]);
	}

	// kill with current weapon
	if(players[attacker].gungame_level < GUNS_SIZE && kill_gungame_weapon)
	{
		players[attacker].gungame_level++;
		if(players[attacker].gungame_level >= GUNS_SIZE)
		{
			// end the round
			players[attacker].gungame_level = 0;
			
			// renable loss conds
			enable_round_end();
			PrintCenterTextAll("%N won gungame",  attacker);
			PrintToChatAll("%s %N won gungame", SPECIALDAY_PREFIX, attacker);
			
			
			global_ctx.sd_winner = attacker;
			slay_all();
		}
		
		else // still going
		{
			// update gun
			GiveGunGameGun(attacker);
		}
		
	}
	
	// killed with knife dec the enemies weapon
	else if(StrEqual(weapon_name,"weapon_knife"))
	{
		if(players[victim].gungame_level > 0)
		{
			players[victim].gungame_level--;
		}
	}
	
	// start a respawn for the dead player :)
	CreateTimer(3.0, ReviveGunGame, victim);
}		 

public void end_gungame()
{
	enable_round_end();
	RestoreTeams();	
}