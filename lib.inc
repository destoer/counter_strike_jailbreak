/*
**
*/
#if defined _DESTOER_LIB_included
 #endinput
#endif
#define _DESTOER_LIB_included


stock bool is_on_team(int i)
{
	return GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T;
}

stock void set_client_speed(int client,float speed)
{ 
      SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed)
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
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntProp(i, Prop_Data,"m_CollisionGroup", 5, 4, true);
		}
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
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntProp(i, Prop_Data,"m_CollisionGroup", 2, 4, true);
		}
	}
}

// not even gonna bother assuming things will go thru the above functions
stock bool noblock_enabled()
{
	for (int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			return GetEntProp(i, Prop_Data,"m_CollisionGroup") == 2;
		}
	}
	ThrowError("could not pull collision data from a client");
	return false; // keep compilier happy
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
stock bool trace_ignore_players(int entity, int contents_mask)
{
	if(entity > 0 && entity < MAXPLAYERS)
	{
		return false;
	}
	
	return true;
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



//get players alive on a team
// 2nd param has last matching player found
stock int get_alive_team_count(int team, int &client)
{
	int number = 0;
	for (int i= 1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team) 
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