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

bool laser_kill = false;



// timer here to draw connected points
public Action laser_draw(Handle timer)
{
	if(warden_id != WARDEN_INVALID && use_draw_laser_settings[warden_id] && laser_use[warden_id])
	{
		float cur_pos[3];
		get_client_sight_end(warden_id, cur_pos);
		
		// check we are not on the first laser shine
		bool initial_draw = prev_pos[warden_id][0] == 0.0 && prev_pos[warden_id][1] == 0.0 
			&& prev_pos[warden_id][2] == 0.0;
		
		if(!initial_draw)
		{
			// draw a line from the last laser end to the current one
			TE_SetupBeamPoints(prev_pos[warden_id], cur_pos, g_lbeam, 0, 0, 0, 25.0, 2.0, 2.0, 10, 0.0, {1,153,255,255}, 0);
			TE_SendToAll();
		}
		prev_pos[warden_id] = cur_pos;
	}
}


// what has the clients picked for laser color
int laser_color[64];

int laser_colors[7][4] =
{
	{ 1, 153, 255, 255 }, // cyan
	{255, 0, 251,255} , // pink
	{255,0,0,255}, // red
	{118, 9, 186, 255}, // purple
	{66, 66, 66, 255}, // grey
	{0,255,0,255}, // green
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

}


public int color_handler(Menu menu, MenuAction action, int client, int choice) 
{
	if(action == MenuAction_Select) 
	{
		laser_color[client] = choice - 1;
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



// laser menu
public Action laser_menu(client,args) {
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

public laser_handler(Menu menu, MenuAction action, int param1, int param2) 
{
	if(action == MenuAction_Select) 
	{
		switch(param2)
		{
			case 1:
				use_draw_laser_settings[param1] = false;
				
			case 2:
				use_draw_laser_settings[param1] = true;
		}
	}
	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d",param1,param2);
	}	
}



public Action kill_laser (int client, int args)
{
	laser_kill = true;
}

public Action safe_laser (int client, int args)
{
	laser_kill = false;
}
