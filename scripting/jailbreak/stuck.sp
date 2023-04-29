/*
**
*/
#if defined _STUCK_INCLUDE_included
 #endinput
#endif
#define _STUCK_INCLUDE_included

bool timer_active = false;

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
		// 5 second usage delay
		next = GetTime() + 5;
		
		PrintToChatAll("%s %N unstuck all players", JB_PREFIX, client);    
		timer_active = true;
		CreateTimer(2.0, timer_end_stuck, client);
		
		// NOTE: we use the internal function as we want to use the others for state tracking of what block is meant to be
		unblock_all_clients(SetCollisionGroup);
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



public Action timer_end_stuck(Handle timer, int client)
{
	PrintToChatAll("%S unstuck over", JB_PREFIX);    

  	timer_active = false;
    
	// restore to correct state
	// NOTE: this may not be the state before stuck was triggered
	// as wub can change it while active...
	if(block_state)
	{
		block_all_clients(SetCollisionGroup);
	}

	else
	{
		unblock_all_clients(SetCollisionGroup);
	}
    
	return Plugin_Continue;
    
}
