/*
**
*/
#if defined _DODGEBALL_INCLUDE_included
 #endinput
#endif
#define _DODGEBALL_INCLUDE_included


// dodgeball day
void dodgeball_player_init(int client)
{
	SetEntityHealth(client,1); // set health to 1
	strip_all_weapons(client); // remove all the players weapons
	GivePlayerItem(client, "weapon_flashbang");
	SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);  
	SetEntityGravity(client, 0.6);
}

void dodgeball_init()
{
	PrintToChatAll("%s Dodgeball day started", SPECIALDAY_PREFIX);
	CreateTimer(1.0, RemoveGuns);
	special_day = dodgeball_day;

	sd_player_init_fptr = dodgeball_player_init;
}


public void StartDodgeball()
{

	PrintCenterTextAll("Dodgeball active!");
	enable_friendly_fire();
	
	// right now we need to enable all our callback required
	// 1. give new flashbangs every second (needs a timer callback like moreTimers) (done)
	// 2. block all flashes (done)
	// 3. hook hp changes so we can prevent heals (done (kinda just cheats and instant kills on any damage))
	// 4. disable gun pickups (done )
	
	
	
	// give an initial flashbang
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i)) // check the client is in the game
		{
			if(IsPlayerAlive(i))  // check player is dead
			{
				if(is_on_team(i)) // check not in spec
				{
					SetEntityHealth(i,1);
					SetEntProp(i, Prop_Data, "m_ArmorValue", 0.0);  // remove armor 
				}
			}
		}	
	}
}


public Action GiveFlash(Handle timer, any entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
	

	// give person who threw a flash after a second +  set hp to one
	if(special_day != dodgeball_day) 
	{ 
		return; 
	}
	
	

	if(is_valid_client(client) && is_on_team(client) && IsPlayerAlive(client) )
	{
		strip_all_weapons(client);
		GivePlayerItem(client, "weapon_flashbang");
		SetEntityHealth(client,1);
	}		
}