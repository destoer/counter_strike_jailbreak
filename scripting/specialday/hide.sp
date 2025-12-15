/*
**
*/
#if defined _HIDE_INCLUDE_included
 #endinput
#endif
#define _HIDE_INCLUDE_included

// hide and seek
void hide_player_init(int client)
{
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		// make players invis
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 0, 0, 0, 0);
	}
	
	else if(GetClientTeam(client) == CS_TEAM_CT)
	{
		CS_RespawnPlayer(client);
		WeaponMenu(client);
		set_client_speed(client, 0.0);
		SetEntityHealth(client,500); // set health to 500
	}
}

void init_hide()
{
	PrintToChatAll("%s Hide and seek day started", SPECIALDAY_PREFIX);
	PrintToChatAll("%s Ts must hide while CTs seek",SPECIALDAY_PREFIX);
	global_ctx.special_day = hide_day;
	
	CreateTimer(1.0,MoreTimers);
}


public void start_hide()
{
	// renable movement
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT) // check the client is in the game
		{
			set_client_speed(i, 1.0);
			SetEntityHealth(i,500); // set health to 500
		}
	}
	
	// hide everyone again just incase
	make_invis_t(); 
}


public void make_invis_t()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(is_valid_client(i) && IsPlayerAlive(i))
		{
			if(GetClientTeam(i) == CS_TEAM_T)
			{
				// make players invis
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, 0, 0, 0, 0);
			}
		}
	}	
}

void add_hide_impl()
{
	add_special_day(make_sd_impl(init_hide,start_hide,callback_dummy,hide_player_init,"Hide and Seek"));
}