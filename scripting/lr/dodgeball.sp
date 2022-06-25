


void dodgeball_player_init(int client)
{
	SetEntityHealth(client,1); // set health to 1
	strip_all_weapons(client); // remove all the players weapons
	GivePlayerItem(client, "weapon_flashbang");
	SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);  
	SetEntityGravity(client, 0.6);
}

void start_dodgeball(int t_slot, int ct_slot)
{
    dodgeball_player_init(slots[t_slot].client);
    dodgeball_player_init(slots[ct_slot].client);
}


public Action GiveFlash(Handle timer, int entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
	

	// no longer in active lr
	if(!in_lr(client)) 
	{ 
		return Plugin_Continue; 
	}
	
	

	if(is_valid_client(client) && is_on_team(client) && IsPlayerAlive(client) )
	{
		strip_all_weapons(client);
		GivePlayerItem(client, "weapon_flashbang");
		SetEntityHealth(client,1);
	}

	return Plugin_Continue;		
}