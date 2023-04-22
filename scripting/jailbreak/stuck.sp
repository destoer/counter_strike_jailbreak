/*
**
*/
#if defined _STUCK_INCLUDE_included
 #endinput
#endif
#define _STUCK_INCLUDE_included

bool timer_active = false;

int old_group;

public Action command_stuck(int client, int args)
{
	static int next = 0;
	
	if(GetTime() < next)
	{
		PrintToChat(client, "%s stuck is on cooldown!", JB_PREFIX);
		return Plugin_Handled;
	}	
	
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && !timer_active && !noblock_enabled())
	{
		old_group = GetEntProp(client, Prop_Data, "m_CollisionGroup");
		// 5 second usage delay
		next = GetTime() + 5;
		
		PrintToChatAll("%s %N unstuck all players", JB_PREFIX, client);    
		timer_active = true;
		CreateTimer(1.0, timer_unblock_player, client);
		
		for (int i = 1; i <= MaxClients; i++)
		{    
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				enable_anti_stuck(i);
			}
		}
	}
	else if (timer_active)
	{
		PrintToChat(client, "%s Command is already in use", JB_PREFIX);
	}
	else
	{
		PrintToChat(client, "%s You must be alive to use this command", JB_PREFIX);
	}
	
	return Plugin_Handled;

}



public Action timer_unblock_player(Handle timer, int client)
{
  	timer_active = false;
    
	for (int i = 1; i <= MaxClients; i++)
    {    
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            disable_anti_stuck(i);
        }
    }
    
	return Plugin_Continue;
    
}

void disable_anti_stuck(int client)
{
	// should be unrequired to save teh group at this point but ya know
    SetClientCollision(client, SetCollisionGroup, old_group);
}

void enable_anti_stuck(int client)
{
    SetClientCollision(client, SetCollisionGroup, COLLISION_GROUP_DEBRIS_TRIGGER);
}
