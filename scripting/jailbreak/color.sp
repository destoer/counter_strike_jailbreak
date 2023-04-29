/*
**
*/
#if defined _WCOLOR_INCLUDE_included
 #endinput
#endif
#define _WCOLOR_INCLUDE_included


int client_sight = -1;


#define PLAYER_COLOR_SIZE 7
int player_color[PLAYER_COLOR_SIZE][4] =
{
	{ 1, 153, 255, 255 }, // cyan
	{255, 0, 251,255} , // pink
	{255,0,0,255}, // red
	{118, 9, 186, 255}, // purple
	{66, 66, 66, 255}, // grey
	{0,255,0,255}, // green
	{ 255, 255, 0, 255 } // yellow
};


// filter to ignore a ray hitting a player
// kill settings if > max players is on
// client is kill_settings - max players
stock bool trace_find_client(int entity, int contents_mask, int caller)
{
	if(entity != caller && is_valid_client(entity))
	{
		client_sight = entity;
	}
	
	return true;
}


stock int get_client_at_sight(int client)
{
	client_sight = -1;
	
	float m_fEyes[3];
	float m_fAngles[3];
	GetClientEyePosition(client, m_fEyes);
	GetClientEyeAngles(client, m_fAngles);
	TR_TraceRayFilter(m_fEyes, m_fAngles, MASK_PLAYERSOLID, RayType_Infinite, trace_find_client,client);

	return client_sight;
}

public Action warden_reset_color(int client, int args)
{
	if(client != warden_id)
	{
		return Plugin_Handled;
	}	
	
	for(int i = 1; i < MaxClients; i++)
	{
		if(is_valid_client(i) && IsPlayerAlive(i))
		{
			if(i != warden_id)
			{
				// make players invis
				SetEntityRenderColor(i, 255, 255, 255, 255);
			}
		}
	}

	return Plugin_Continue;
}

public Action warden_color(int client, int args)
{
	if(client != warden_id)
	{
		return Plugin_Handled;
	}
	int found = get_client_at_sight(client);
	if(found != -1)
	{
		PrintToChat(client, "client color for %N", found);
		Panel lasers = new Panel();
		lasers.SetTitle("Laser Color Selection");
		lasers.DrawItem("cyan");
		lasers.DrawItem("pink");
		lasers.DrawItem("red");
		lasers.DrawItem("purple");
		lasers.DrawItem("grey");
		lasers.DrawItem("green");
		lasers.DrawItem("yellow");
		lasers.Send(client,player_color_handler,20);
	}
	
	return Plugin_Continue;
}

// ideally we would pass the client sight through
public int player_color_handler(Menu menu, MenuAction action, int client, int choice) 
{
	if(action == MenuAction_Select) 
	{
		int color[4];
		// dont know why we have to copy this...
		for (int i = 0; i < 4; i++)
		{
			color[i] = player_color[choice - 1][i];
		}
		SetEntityRenderColor(client_sight, color[0],color[1],color[2],color[3]);
	}

	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d", client, choice);
	}
	
	
	return 0;
}

/*
int team_count = 0;

// ideally we would pass the client sight through
public int player_color_team_handler(Menu menu, MenuAction action, int client, int choice)
{
	if(action == MenuAction_Select) 
	{
		int teams = choice + 1;

		// Get all players on T into a list
		
		// Split into each team
		int count = 

		int each = count / teams;

		// Color each team

	
		// Color the odd player in Yellow if any
	}

	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d", client, choice);
	}	
} 

public Action make_teams(int client, int args)
{
	if(client != warden_id)
	{
		return Plugin_Handled;
	}

	
	// ask how many teams
	Panel lasers = new Panel();
	lasers.SetTitle("Number of teams");
	lasers.DrawItem("2");
	lasers.DrawItem("3");
	lasers.DrawItem("4");
	lasers.DrawItem("5");

	lasers.Send(client,player_color_team_handler,20);

}
*/