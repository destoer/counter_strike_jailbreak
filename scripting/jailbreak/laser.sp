/*
**
*/
#if defined _LASER_INCLUDE_included
 #endinput
#endif
#define _LASER_INCLUDE_included


// laser stuff
// laser globals
bool laser_use[MAXPLAYERS+1];
float prev_pos[MAXPLAYERS+1][3];
int g_lbeam;
int g_lpoint;

bool use_draw_laser_settings[MAXPLAYERS + 1];
bool t_use_draw_laser[MAXPLAYERS + 1];
bool laser_kill = false;


// what has the clients picked for laser color
int laser_color[MAXPLAYERS+1];

#define LASER_COLOR_SIZE 7
int laser_colors[LASER_COLOR_SIZE][4] =
{
	{ 1, 153, 255, 255 }, // cyan
	{255, 0, 251,255} , // pink
	{255,0,0,255}, // red
	{118, 9, 186, 255}, // purple
	{66, 66, 66, 255}, // grey
	{0, 191, 0, 255}, // green
	{ 255, 255, 0, 255 } // yellow
};

int rainbow_color = 0;

int laser_rainbow[7][4] = 
{
	{255,0,0,255}, // red
	{255,165,0,255}, // orange
	{ 255, 255, 0, 255 }, // yellow
	{0,255,0,255}, // green
	{0,0,255,255}, // blue
	{75,0,130,255}, //indigo
	{138,43,226,255} // violet
};


public Action rainbow_timer(Handle timer)
{
	rainbow_color = (rainbow_color + 1) % 7;

	return Plugin_Continue;
}

public Action command_laser_color(int client, int args)
{
	Panel lasers = new Panel();
	lasers.SetTitle("Laser Color Selection");
	lasers.DrawItem("cyan");
	lasers.DrawItem("pink");
	lasers.DrawItem("red");
	lasers.DrawItem("purple");
	lasers.DrawItem("grey");
	lasers.DrawItem("green");
	lasers.DrawItem("yellow");
	lasers.Send(client,color_handler,20);

	return Plugin_Continue;
}


public int color_handler(Menu menu, MenuAction action, int client, int choice) 
{
	if(action == MenuAction_Select) 
	{
		laser_color[client] = choice - 1;
		
		set_cookie_int(client,laser_color[client],client_laser_color_pref);
	}

	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d", client, choice);
	}
	
	
	return 0;
}

enum laser_type
{
	warden,
	admin,
	donator,
	none	
};



public void SetupLaser(int client,int color[4])
{
	setup_laser(client, color, g_lbeam, g_lpoint, laser_kill);
}

int t_client_list[64] = {0};


public Action t_laser_menu(int client,int args)
{

	if(client != warden_id)
	{
		return Plugin_Handled;
	}

	Menu menu = new Menu(t_laser_handler);
	
	int idx = 0;
	for (int i = 1; i < MaxClients; i++)
	{
		if(is_valid_client(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			t_client_list[idx++] = i;
		}
	}
	
	char buf[64];

	for (int i = 0; i < idx; i++)
	{
		Format(buf, sizeof(buf), "%N", t_client_list[i]);
		menu.AddItem(buf,buf);
	}
	menu.SetTitle("t draw laser");
	menu.Display(client, 20);
	
	return Plugin_Continue;
}

public t_laser_handler(Menu menu, MenuAction action, int param1, int param2) 
{

    if (action == MenuAction_Select)
    {
		t_use_draw_laser[t_client_list[param2]] = !t_use_draw_laser[t_client_list[param2]];
    }

    else if (action == MenuAction_Cancel)
    {
        PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
    }
    

    else if (action == MenuAction_End)
    {
        delete menu;
    }
}

// laser menu
public Action laser_menu(int client,int args) 
{
	Panel options = new Panel();
	options.SetTitle("Laser selection");
	options.DrawItem("normal laser");
	options.DrawItem("draw laser");
	
	if(IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT || GetClientTeam(client) == CS_TEAM_T )
	{
		options.Send(client, laser_handler, 20);
	}
	
	delete options;
	return Plugin_Handled;
}

public laser_handler(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		switch(param2)
		{
			case 1:
				use_draw_laser_settings[client] = false;
				
			case 2:
				use_draw_laser_settings[client] = true;
		}
		
		set_cookie_int(client,use_draw_laser_settings[client],client_laser_draw_pref);
	}
	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d",client,param2);
	}	
}


// reset the laser draw for t's
void reset_laser_setting()
{
	for (int i = 1; i < MaxClients; i++)
	{
		t_use_draw_laser[i] = false;	
	}
}

// timer here to draw connected points
public Action laser_draw(Handle timer)
{
	if(warden_id != WARDEN_INVALID && use_draw_laser_settings[warden_id] && laser_use[warden_id])
	{
		do_draw(warden_id, {0,191,0,255} );
	}
	
	// now check if any of our t's happen to be drawing
	for (int i = 1; i < MaxClients; i++)
	{
		if(!is_valid_client(i) || GetClientTeam(i) != CS_TEAM_T)
		{
			continue;
		}
		
		if(t_use_draw_laser[i])
		{
			do_draw(i, {255,0,0,255} );
		}
	}

	return Plugin_Handled;
}


void do_draw(int client, int color[4])
{
	float cur_pos[3];
	get_client_sight_end(client, cur_pos);
	
	// check we are not on the first laser shine
	bool initial_draw = prev_pos[client][0] == 0.0 && prev_pos[client][1] == 0.0 
		&& prev_pos[client][2] == 0.0;
	

	// we only want to allow drawing on a wall or floor not lines between
	// i.e on a 2d plane, as we are in a 3d space all we have to do is simply check
	// that less than 3 cordinates changed
	// change is set reasonably high to allow a smooth transistion onto a different plane
	// if drawing is not happening too quickly i.e when drawing up ramps or slopes
	const float CHANGE_LIM = 20.0;

	int change_count = 0;

	for(int i = 0; i < 3; i++)
	{
		float change = FloatAbs(cur_pos[i] - prev_pos[client][i]);

		//PrintToChatAll("change %d : %f",i,change);

		if(change >= CHANGE_LIM)
		{
			change_count++;
		}
	}

	if(!initial_draw && change_count < 3)
	{
		// draw a line from the last laser end to the current one
		TE_SetupBeamPoints(prev_pos[client], cur_pos, g_lbeam, 0, 0, 0, 25.0, 2.0, 2.0, 10, 0.0, color, 0);
		TE_SendToAll();
	}
	prev_pos[client] = cur_pos;		
}



public Action kill_laser (int client, int args)
{
	laser_kill = true;

	return Plugin_Handled;
}

public Action safe_laser (int client, int args)
{
	laser_kill = false;

	return Plugin_Handled;
}
