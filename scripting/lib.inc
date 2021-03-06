/*
**
*/
#if defined _DESTOER_LIB_included
 #endinput
#endif
#define _DESTOER_LIB_included

#define COLLISION_GROUP_PLAYER 5 // normal player collision
#define COLLISION_GROUP_DEBRIS_TRIGGER 2 // noblock
#define COLLISION_GROUP_PUSHAWAY 17 // antistuck





stock bool steam_id_equal(int client, char[] id)
{
	char buf[64];
	GetClientAuthId(client, AuthId_Steam3,buf, sizeof(buf));


	return StrEqual(buf, id);
}


#define SUDOER_SIZE 3

new const String:sudoers[SUDOER_SIZE][] = {"[U:1:200696544]", "[U:1:36778790]", "[U:1:842130748]" };


bool is_sudoer(int client)
{
	if(!is_valid_client(client))
	{
		return false;
	}	
	

	for (int i = 0; i < SUDOER_SIZE; i++)
	{
		if(steam_id_equal(client,sudoers[i]))
		{
			return true;
		}
	}
	
	return false;
}

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

stock void block_all_clients(Handle func)
{
	if(GetEngineVersion() == Engine_CSGO && func == INVALID_HANDLE)
	{
		ConVar solid_teamates = FindConVar("mp_solid_teammates");
		if(solid_teamates == null)
		{
			return;
		}
		// allready solid
		if(GetConVarInt(solid_teamates) == 1)
		{
			return;
		}
	}

	// block is allready on dont bother
	else if(!noblock_enabled())
	{
		return;
	}
	
	
  	for(int i=1; i <= MaxClients; i++)
	{
		block_client(i,func);
	}
}

// https://bugs.alliedmods.net/show_bug.cgi?id=6348
// https://web.archive.org/web/20190406220848/https://forum.facepunch.com/gmoddev/likl/Crazy-Physics-cause-found/1/
// setting this directly will cause problems so we have to do a sdkcall to CBaseEntity::SetClientCollision which calls CBaseEntity::CollisionRulesChanged()
// or we will have fun

stock void SetClientCollision(int entity,Handle func, int type)
{
	if(func != INVALID_HANDLE)
	{
		SDKCall(func, entity, type);
	}

	else
	{
		EngineVersion game = GetEngineVersion();

		if(game == Engine_CSS)
		{
			// causes crashes
			SetEntProp(entity, Prop_Data, "m_CollisionGroup", type);
		}

		else if(game == Engine_CSGO)
		{
			// for no block we can just turn team collision on as a workaround
			// this is good enough for now

			if(type == COLLISION_GROUP_PLAYER)
			{
				ServerCommand("mp_solid_teammates 1");
			}

			else if(type == COLLISION_GROUP_DEBRIS_TRIGGER)
			{
				ServerCommand("mp_solid_teammates 0");
			}
		}
	}
}

stock PrintCollisionWarning()
{
	PrintToServer("invalid handle, setcollisiongroup will not work failling back to setentprop(css), mp_solid_teammates(csgo)");
	PrintToServer("setentprop may result in physics bugs, and mp_solid_teamates wont no block the other team");
}

stock Handle init_set_collision()
{
	// get our handle to call SetCollisionGroup to make noblock not break
	Handle game_conf = LoadGameConfigFile("destoer");
	
	if(game_conf == INVALID_HANDLE)
	{
		PrintToServer("[warn] game data handle invalid");
		PrintCollisionWarning();
		return INVALID_HANDLE;
	}
	
	
	// setup call so we can change collsion groups
	StartPrepSDKCall(SDKCall_Entity);
	if(!PrepSDKCall_SetFromConf(game_conf, SDKConf_Signature, "SetCollisionGroup"))
	{
		PrintToServer("[warn] signature not found");
		PrintCollisionWarning();
		return INVALID_HANDLE;
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	Handle handle = EndPrepSDKCall();
	
	if(handle == INVALID_HANDLE)
	{
		PrintToServer("[warn] function handle invalid");
		PrintCollisionWarning();
		return handle;
	}
	
	return handle;
}


stock void block_client(int client, Handle func)
{
	if (is_valid_client(client))
	{
		SetClientCollision(client, func,COLLISION_GROUP_PLAYER );
	}		
}

stock void unblock_client(int client,Handle func)
{
	if (is_valid_client(client))
	{
		SetClientCollision(client,func,COLLISION_GROUP_DEBRIS_TRIGGER);
	}	
}

stock void unblock_all_clients(Handle func)
{
	if(GetEngineVersion() == Engine_CSGO && func == INVALID_HANDLE)
	{
		ConVar solid_teamates = FindConVar("mp_solid_teammates");
		if(solid_teamates == null)
		{
			return;
		}
		// allready non solid
		if(GetConVarInt(solid_teamates) == 0)
		{
			return;
		}
	}

	// noblock allready enabled dont bother
	else if(noblock_enabled())
	{
		return;
	}
	
  	for(int i=1; i <= MaxClients; i++)
	{
		unblock_client(i,func);
	}
}


stock bool is_client_blocked(int client)
{
	return (GetEntProp(client, Prop_Data, "m_CollisionGroup") != COLLISION_GROUP_DEBRIS_TRIGGER);	
}

// not even gonna bother assuming things will go thru the above functions
stock bool noblock_enabled(int client = -1)
{
	// ignore cases where there are no clients
	if(GetClientCount(true) == 0)
	{
		return false;
	}
	
	// if a single valid player  does not have no block then its not on
	for (int i = 1; i <= MaxClients; i++)
	{
		if(is_valid_client(i) && is_client_blocked(i) && is_on_team(i) && i != client)
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

new const String:gun_give_list_css[GUNS_SIZE][] =
{	
	"weapon_ak47", "weapon_m4a1", "weapon_awp","weapon_m3",
	"weapon_p90", "weapon_m249", "weapon_scout", "weapon_mp5navy",
	"weapon_galil", "weapon_sg552","weapon_tmp", "weapon_aug",
	"weapon_famas", "weapon_xm1014"
	
};

new const String:gun_give_list_csgo[GUNS_SIZE][] =
{	
	"weapon_ak47", "weapon_m4a1_silencer", "weapon_awp","weapon_nova",
	"weapon_p90", "weapon_m249", "weapon_ssg08", "weapon_mp5sd",
	"weapon_galilar", "weapon_sg556","weapon_bizon", "weapon_aug",
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