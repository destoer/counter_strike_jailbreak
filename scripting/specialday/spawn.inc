/*
**
*/
#if defined _SPAWN_included
 #endinput
#endif
#define _SPAWN_included

#define SPAWN_SIZE 15

float spawn_cords[SPAWN_SIZE][3];
int cord_size = 0;


void sample_cords()
{
	for (int i = 0; i < 64; i++)
	{
		if(is_on_team(i) && is_valid_client(i))
		{
			sample_cord(i);
		}
	}
}

bool is_player_stuck(int client)
{
	float min[3];
	float max[3];
	float origin[3];
	
	GetClientMins(client, min);
	GetClientMaxs(client, max);
	
	GetClientAbsOrigin(client, origin);
	
	TR_TraceHullFilter(origin, origin, min, max, MASK_PLAYERSOLID, trace_stuck, client);
}

bool trace_stuck(int entity, int client)
{
	return entity != client;
}


// if there aernt enough sampled respawn points
// (less than 5)
// then do a tradional spawn or we are just gonna
// get players bunching up on eachover

// select a random spawn and unblock the player
// if we spawn in stuck remove the spawn point
// and move them somewhere else
// if there are no points fallback to a slay and 
// traditional respawn

void sample_cord(int client)
{
	// valid on t or ct and alive
	if(!( is_valid_client(client) && is_on_team(client)  && IsPlayerAlive(client)))
	{
		return;
	}
	
	// okay now test if the player is on the ground and not stuck
	// if they are not then sample the cord
	if((GetEntityFlags(client) & FL_ONGROUND) != 0 && is_player_stuck(client))
	{
		float cords[3];
		GetClientAbsOrigin(client, cords);
		
		// check cords are sufficiently away from others
		for (int i = 0; i < SPAWN_SIZE; i++)
		{
			if (GetVectorDistance(cords, spawn_cords[i]) <= 10.0)
			{
				return;
			}
		}
		
		if(cord_size < SPAWN_SIZE)
		{
			spawn_cords[cord_size++] = cords;
		}
	}
}