/*
**
*/
#if defined _LASERWARS_INCLUDE_included
 #endinput
#endif
#define _LASERWARS_INCLUDE_included

void laser_player_init(int client)
{
	WeaponMenu(client);
}



public Action ReviveLaser(Handle Timer, int client)
{
	if(is_valid_client(client) && is_on_team(client))
	{
		CS_RespawnPlayer(client);
		sd_player_init(client);
	}

	return Plugin_Continue;
}

void laser_init()
{
	PrintToChatAll("%s laser day started hold e after timer if you are selected", SPECIALDAY_PREFIX);
	global_ctx.special_day = laser_day;

	SaveTeams(true);
	
	if(validclients == 0)
	{
		PrintToChatAll("%s You are all freekillers!", SPECIALDAY_PREFIX);
		global_ctx.sd_init_failure = true;
		return;
	}
	
	PrintToChatAll("%s Laser day started", SPECIALDAY_PREFIX);
}

void make_laser(int client)
{
	SetEntityHealth(client, 25 * validclients);
	CS_SwitchTeam(client,CS_TEAM_CT);
	SetEntityRenderColor(client, 255, 0, 0, 255);

	ServerCommand("sm_beacon %N",client);

	PrintCenterTextAll("%N has the kill laser!", client);
}


public void start_laser()
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
	make_laser(global_ctx.boss);
}


void laser_discon_active(int client)
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
	
	make_laser(global_ctx.boss);		
}

void end_laser()
{
	PrintToChatAll("%s Laser day over", SPECIALDAY_PREFIX);
	RestoreTeams();
	SetEntityRenderColor(global_ctx.boss, 255, 255, 255, 255);	
}

public void laser_death(int victim)
{
	//CreateTimer(3.0, ReviveLaser, victim);
}

SpecialDayImpl laser_impl()
{
	SpecialDayImpl laser;
	laser = make_sd_impl(laser_init,start_laser,end_laser,laser_player_init);
	laser.sd_discon_active = laser_discon_active;
	
	return laser;
}