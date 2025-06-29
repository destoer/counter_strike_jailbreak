/*
**
*/
#if defined _SPECTRE_INCLUDE_included
 #endinput
#endif
#define _SPECTRE_INCLUDE_included


void spectre_player_init(int client)
{
	WeaponMenu(client);
}

void spectre_init()
{
	PrintToChatAll("%s spectre day started", SPECIALDAY_PREFIX);
	global_ctx.special_day = spectre_day;
	global_ctx.player_init = spectre_player_init;
	
	
	// save teams so we can swap them back later and select the "spectre"
	SaveTeams(true);
	
	if(validclients == 0)
	{
		PrintToChatAll("%s You are all freekillers!", SPECIALDAY_PREFIX);
		global_ctx.sd_init_failure = true;
		return;
	}
}


public void MakeSpectre(int client)
{
	SetEntityHealth(client, 60 * validclients);
	
	
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
	MakeSpectre(global_ctx.boss);
}

void end_spectre()
{
	RestoreTeams();
	if(is_valid_client(global_ctx.boss))
	{
		SetEntityRenderColor(global_ctx.boss,255,255,255, 255);
	}
}

void spectre_discon_active(int client)
{
	// restore the hp
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntityHealth(i, 100);
		}
	}		

	pick_boss_discon(client)
	
	MakeSpectre(global_ctx.boss);
}