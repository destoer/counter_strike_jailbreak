



public Action GiveGrenade(Handle timer, any entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");


	
	if(!in_lr(client))
	{ 
		return Plugin_Continue; 
	}
	
	
	if(is_valid_client(client) && is_on_team(client) && IsPlayerAlive(client))
	{
		strip_all_weapons(client);
		GivePlayerItem(client, "weapon_hegrenade");
	}

	return Plugin_Continue;	
}


void grenade_player_init(int client)
{
	// when coming off ladders and using the reset
	// we dont wanna regive the nades
	strip_all_weapons(client); // remove all the players weapons
	GivePlayerItem(client, "weapon_hegrenade");
	SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);  
	SetEntityGravity(client, 0.6);
	SetEntityHealth(client,250);
}


void start_grenade(LrPair pair)
{
    grenade_player_init(pair.t);
    grenade_player_init(pair.ct);
}
