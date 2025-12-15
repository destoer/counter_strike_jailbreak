/*
**
*/
#if defined _GRENADE_INCLUDE_included
 #endinput
#endif
#define _GRENADE_INCLUDE_included


// grenade day
void grenade_player_init(int client)
{
	// when coming off ladders and using the reset
	// we dont wanna regive the nades
	strip_all_weapons(client); // remove all the players weapons
	GivePlayerItem(client, "weapon_hegrenade");
	SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);  
	SetEntityGravity(client, 0.6);

	if(global_ctx.sd_state != sd_active)
	{
		SetEntityHealth(client,250);
	}
}


void grenade_init()
{
	PrintToChatAll("%s grenade day started", SPECIALDAY_PREFIX);
	CreateTimer(1.0, RemoveGuns);
	global_ctx.special_day = grenade_day;

	global_ctx.weapon_restrict = "weapon_hegrenade";
}

public void start_grenade()
{
	// set everyones hp to 250
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) // check the client is in the game
		{
			if(IsPlayerAlive(i))  // check player is dead
			{
				if(is_on_team(i)) // check not in spec
				{
					SetEntityHealth(i,250);
				}
			}
		}	
	}	
}

public Action GiveGrenade(Handle timer, any entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");



	// giver person who threw a flash after a second +  set hp to one
	
	if(global_ctx.special_day != grenade_day) 
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

SpecialDayImpl grenade_impl()
{
	return make_sd_impl(grenade_init,start_grenade,callback_dummy,grenade_player_init);
}