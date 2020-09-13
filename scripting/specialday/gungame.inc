/*
**
*/
#if defined _GUNGAME_INCLUDE_included
 #endinput
#endif
#define _GUNGAME_INCLUDE_included


// holds indexes into the gun list so we can randomize what guns are on each sd
int gungame_gun_idx[GUNS_SIZE] = {0};

// level of progression the player is on
int gungame_level[64] =  { 0 };


// gun game
void gun_game_player_init(int client)
{
	GiveGunGameGun(client);
}

void init_gungame()
{
	PrintToChatAll("%s gun game day started", SPECIALDAY_PREFIX);
	
	special_day = gungame_day;
	
	// reset the gun counter
	for (int i = 0; i < MaxClients; i++)
	{
		gungame_level[i] = 0;
	}
	
	// shuffle the game game indexes to randomize weapons
	for (int i = 0; i < GUNS_SIZE; i++)
	{
		int p1 = GetRandomInt(0, GUNS_SIZE - 1);
		int p2 = GetRandomInt(0, GUNS_SIZE - 1);
		
		int tmp = gungame_gun_idx[p1];
		gungame_gun_idx[p1] = gungame_gun_idx[p2];
		gungame_gun_idx[p2] = tmp;
	}
		
	sd_player_init_fptr = gun_game_player_init;
}


public void GiveGunGameGun(int client)
{
	strip_all_weapons(client);
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "item_assaultsuit");

	EngineVersion game = GetEngineVersion();

	if(game == Engine_CSS)
	{
		GivePlayerItem(client, gun_give_list_css[gungame_gun_idx[gungame_level[client]]]);
	}

	if(game == Engine_CSGO)
	{
		GivePlayerItem(client, gun_give_list_csgo[gungame_gun_idx[gungame_level[client]]]);
	}

	PrintToChat(client, "%s Current level: %s (%d of %d)", 
		SPECIALDAY_PREFIX, gun_list[gungame_gun_idx[gungame_level[client]]],gungame_level[client]+1,GUNS_SIZE);
}



public Action ReviveGunGame(Handle timer, int client)
{
	if(special_day != gungame_day)
	{
		return;
	}
	
	if(IsClientInGame(client))
	{
		CS_RespawnPlayer(client);
		GiveGunGameGun(client);
	}		
}

public void StartGunGame()
{
	enable_friendly_fire();
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
		kill_gungame_weapon = StrEqual(weapon_name, gun_give_list_css[gungame_gun_idx[gungame_level[attacker]]]);
	}

	else if(game == Engine_CSGO)
	{
		kill_gungame_weapon = StrEqual(weapon_name, gun_give_list_csgo[gungame_gun_idx[gungame_level[attacker]]]);
	}

	// kill with current weapon
	if(gungame_level[attacker] < GUNS_SIZE && kill_gungame_weapon)
	{
		gungame_level[attacker]++;
		if(gungame_level[attacker] >= GUNS_SIZE)
		{
			// end the round
			gungame_level[attacker] = 0;
			
			// renable loss conds
			enable_round_end();
			PrintToChatAll("%s %N won gungame", SPECIALDAY_PREFIX, attacker);
			
			
			sd_winner = attacker;
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
		gungame_level[victim]--;
		if(gungame_level[victim] < 0)
		{
			gungame_level[victim] = 0;
		}
	}
	
	
	
	
	// start a respawn for the dead player :)
	CreateTimer(3.0, ReviveGunGame, victim);
}		 