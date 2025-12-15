/*
**
*/
#if defined _TANK_INCLUDE_included
 #endinput
#endif
#define _TANK_INCLUDE_included

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
		global_ctx.sd_init_failure = true;
		return;
	}
	
	global_ctx.special_day = tank_day;
	PrintToChatAll("%s Tank day started", SPECIALDAY_PREFIX);	
}

void end_tank()
{
	PrintToChatAll("%s Tank day over", SPECIALDAY_PREFIX);
	RestoreTeams();
	if(is_valid_client(global_ctx.boss))
	{
		SetEntityRenderColor(global_ctx.boss, 255, 255, 255, 255);
	}
}


public void MakeTank(int client)
{
	SetEntityHealth(client, 200 * validclients);
	CS_SwitchTeam(client,CS_TEAM_CT);

	// beacon the tank
	ServerCommand("sm_beacon %N",client);

	SetEntityRenderColor(client, 255, 0, 0, 255);
	PrintCenterTextAll("%N is the TANK!", client);
}


public void start_tank()
{	
	// swap everyone other than the tank to the t side
	// if they were allready in ct or t
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(is_on_team(i))
			{
				CS_SwitchTeam(i,CS_TEAM_T);
			}
		}
	}
	
	pick_boss();

	MakeTank(global_ctx.boss);
}


void tank_discon_active(int client)
{
	// restore the hp
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntityHealth(i, 100);	
		}
	}


	pick_boss_discon(client);
	
	MakeTank(global_ctx.boss);		
}

SpecialDayImpl tank_impl()
{
	return make_sd_impl(init_tank,start_tank,end_tank,tank_player_init);
}