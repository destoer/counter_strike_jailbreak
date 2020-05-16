/*
**
*/
#if defined _DESTOER_LIB_included
 #endinput
#endif
#define _DESTOER_LIB_included

#define COLLISION_GROUP_PLAYER 5 // normal player collision
#define COLLISION_GROUP_DEBRIS_TRIGGER 2 // noblock

stock bool is_on_team(int i)
{
	return GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T;
}

stock void set_client_speed(int client,float speed)
{ 
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed)
}

// open all doors
new const String:entity_list[][] = { "func_door", "func_movelinear","func_door_rotating","prop_door_rotating" };
stock void force_open()
{
	int entity;
	// open all doors
	for(new i = 0; i < sizeof(entity_list); i++)
	{
		while((entity = FindEntityByClassname(entity, entity_list[i])) != -1)
		
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Open");
		}	
	}
	
	// destroy all breakables
	while((entity = FindEntityByClassname(entity, "func_breakable")) != -1)
		
	if(IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Break");
	}	
}

stock void slay_all()
{
	// slay everyone
	for (int i=1; i<=MaxClients; i++)
	{
		if (is_valid_client(i) && IsPlayerAlive(i)) 
		{
			ForcePlayerSuicide(i);
		}
	}	
}

stock bool check_command_exists(const String:command[])
{
	return GetCommandFlags(command) != INVALID_FCVAR_FLAGS;
}

stock void block_all_clients()
{
	// block is allready on dont bother
	if(!noblock_enabled())
	{
		return;
	}
	
	
  	for(int i=1; i <= MaxClients; i++)
	{
		block_client(i);
	}
}

stock void block_client(int client)
{
	if (is_valid_client(client) && !is_client_blocked(client))
	{
		SetEntProp(client, Prop_Data,"m_CollisionGroup", COLLISION_GROUP_PLAYER, 4);
	}		
}

stock void unblock_client(int client)
{
	if (is_valid_client(client) && is_client_blocked(client))
	{
		SetEntProp(client, Prop_Data,"m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER, 4);
	}	
}

stock void unblock_all_clients()
{
	// noblock allready enabled dont bother
	if(noblock_enabled())
	{
		return;
	}
	
  	for(int i=1; i <= MaxClients; i++)
	{
		unblock_client(i);
	}
}


stock bool is_client_blocked(int client)
{
	return (GetEntProp(client, Prop_Data, "m_CollisionGroup") != COLLISION_GROUP_DEBRIS_TRIGGER);	
}

// not even gonna bother assuming things will go thru the above functions
stock bool noblock_enabled()
{
	// ignore cases where there are no clients
	if(GetClientCount(true) == 0)
	{
		return false;
	}
	
	// if a single valid player  does not have no block then its not on
	for (int i = 1; i <= MaxClients; i++)
	{
		if(is_valid_client(i) && is_client_blocked(i) && is_on_team(i))
		{
			return false;
		}
	}
	
	// if everyone has it then its on
	return true;
}


stock void set_clip_ammo(int client, int weapon, int ammo)
{
	if(weapon != -1)
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);
		SetEntProp(weapon, Prop_Send, "m_iClip2", ammo);
	}
}


stock void set_reserve_ammo(int client, int weapon, int ammo)
{
	if(weapon != -1)
	{
		int g_offset_ammo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
		int ammo_type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		SetEntData(client, g_offset_ammo+(ammo_type*4), ammo, _, true);
	}
}


// filter to ignore a ray hitting a player
// kill settings if > max players is on
// client is kill_settings - max players
stock bool trace_ignore_players(int entity, int contents_mask, int kill_settings)
{
	if(entity > 0 && entity < MAXPLAYERS)
	{
		if(is_valid_client(entity))
		{
			// kill players (if toggled)
			// ugly hack i know
			bool kill = kill_settings > MAXPLAYERS;
			int cli_ignore = kill_settings - MAXPLAYERS;
			if (kill && entity != cli_ignore)
			{
				ForcePlayerSuicide(entity);
			}
			return false;

		}
		
	}
	
	return true;
}


stock void get_client_sight_end(int client, float out[3],bool use_kill_laser=false)
{
	float m_fEyes[3];
	float m_fAngles[3];
	int kill_settings = use_kill_laser? client + MAXPLAYERS : client;
	GetClientEyePosition(client, m_fEyes);
	GetClientEyeAngles(client, m_fAngles);
	TR_TraceRayFilter(m_fEyes, m_fAngles, MASK_PLAYERSOLID, RayType_Infinite, trace_ignore_players,kill_settings);
	if(TR_DidHit())
	{
		TR_GetEndPosition(out);
	}
}


stock setup_laser(int client,int color[4],int beam_model, int point_model, bool use_kill_laser=false)
{
	// setup laser
	float m_fOrigin[3];
	float m_fImpact[3];
	GetClientEyePosition(client, m_fOrigin);
	get_client_sight_end(client, m_fImpact,use_kill_laser);	
	TE_SetupBeamPoints(m_fOrigin, m_fImpact, beam_model, 0, 0, 0, 0.1, 0.8, 0.8, 2, 0.0,color , 0);
	TE_SendToAll();
	
	
	
	// setup laser end "glow"
	TE_SetupGlowSprite(m_fImpact, point_model, 0.1, 0.2, 255);
	TE_SendToAll();
}

stock bool is_valid_client(int client)
{
	if(client <= 0) 
	{
		return false;
	}
	
	if(client > MaxClients)
	{	
		return false;
	}
	
	if(!IsClientConnected(client)) 
	{
		return false;
	}
	return IsClientInGame(client);
}


stock void get_player_velocity(int client, float vec[3])
{
	if(is_valid_client(client) && is_on_team(client))
	{
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);
	}
}

stock void set_player_velocity(int client, const float vec[3])
{
	if(is_valid_client(client) && is_on_team(client))
	{
		SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vec);
	}
}

//get players alive on a team
// 2nd param has last matching player found
stock int get_alive_team_count(int team, int &client)
{
	int number = 0;
	for (int i= 1; i<=MaxClients; i++)
	{
		if (is_valid_client(i) && IsPlayerAlive(i) && GetClientTeam(i) == team) 
		{
			number += 1;
			client = i;
		}
	}
	return number;
}  



// remove all client weapons
stock void strip_all_weapons(int client)
{
	
	// first we need to loop through all the weapons
	int wep_idx;
	for (int i = 0; i < 6; i++)
	{
		if ((wep_idx = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, wep_idx);
			AcceptEntityInput(wep_idx, "Kill");
		}
	}

	// remove any nades left (as it will only remove first from nade slot)
	// so we need to remove it from every slot
	wep_idx = GetPlayerWeaponSlot(client, 3); // 3 is the nade slot 
	while(wep_idx  != -1)
	{
			RemovePlayerItem(client, wep_idx);
			AcceptEntityInput(wep_idx, "Kill");
			wep_idx = GetPlayerWeaponSlot(client, 3);
	}

	// finally we need to set all of the nade ammo to zero
	for (int i = 0; i < 4; i++)
	{
		// nade offsets start at 11 in css
		SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, 11 + i);
	}
}


const int GUNS_SIZE = 14;

new const String:gun_list[GUNS_SIZE][] =
{	
	"AK47", "M4A1", "AWP","M3",
	"P90", "M249", "SCOUT", "MP5", 
	"GALIL","SG", "TMP", "AUG",
	"FAMAS", "XM"
};

new const String:gun_give_list[GUNS_SIZE][] =
{	
	"weapon_ak47", "weapon_m4a1", "weapon_awp","weapon_m3",
	"weapon_p90", "weapon_m249", "weapon_scout", "weapon_mp5navy",
	"weapon_galil", "weapon_sg552","weapon_tmp", "weapon_aug",
	"weapon_famas", "weapon_xm1014"
	
};

stock Menu build_gun_menu(MenuHandler menu_handler)
{
	Menu menu = new Menu(menu_handler);
	for (int i = 0; i < GUNS_SIZE; i++)
	{
		menu.AddItem(gun_list[i], gun_list[i]);
	}
	menu.SetTitle("Weapon Selection");
	return menu;
}