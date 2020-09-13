/*
**
*/
#if defined _STUCK_INCLUDE_included
 #endinput
#endif
#define _STUCK_INCLUDE_included


// uses the push out method
#if defined STUCK

bool timer_active = false;


public Action command_stuck(int client, int args)
{
    if (IsClientInGame(client) && IsPlayerAlive(client) && !timer_active)
    {
        PrintToChatAll("%s %N unstuck all players", ANTISTUCK_PREFIX, client);    
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
        PrintToChat(client, "%s Command is already in use", ANTISTUCK_PREFIX);
    }
    else
    {
        PrintToChat(client, "%s You must be alive to use this command", ANTISTUCK_PREFIX);
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
    SetClientCollision(client, SetCollisionGroup, COLLISION_GROUP_PLAYER);
}

void enable_anti_stuck(int client)
{
    SetClientCollision(client, SetCollisionGroup, COLLISION_GROUP_PUSHAWAY);
}


// enable and disables no block temp
// needs to be updated to use newer collision setting if we roll with this

/*
// no block
#if defined STUCK
public Action stuck_callback(client,args)
{	
	static int next = 0;
	
	if(GetTime() < next)
	{
		PrintToChat(client, "%s stuck is on cooldown!", ANTISTUCK_PREFIX);
		return Plugin_Handled;
	}
	
	if(!noblock_enabled() && IsPlayerAlive(client))
	{
		// 3 second usage delay
		next = GetTime() + 5;
		
		
		PrintToChatAll("%s Player %N unstuck everyone!", ANTISTUCK_PREFIX, client);
		disable_block_all();
		
		CreateTimer(3.0, block_timer_callback);
	}
	return Plugin_Handled;
}

public Action block_timer_callback(Handle timer)
{
	enable_block_all();
}
#endif
*/



#endif