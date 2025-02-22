/*
**
*/
#if defined _STUCK_INCLUDE_included
 #endinput
#endif
#define _STUCK_INCLUDE_included

public Action command_stuck(int client, int args)
{
	static int next = 0;
	
	if(GetTime() < next)
	{
		PrintToChat(client, "%s stuck is on cooldown!", JB_PREFIX);
		return Plugin_Handled;
	}	
	
	
	if (IsClientInGame(client) && IsPlayerAlive(client) && !global_ctx.stuck_timer && !noblock_enabled())
	{
		// 5 second usage delay
		next = GetTime() + 5;
		
		PrintToChatAll("%s %N unstuck all players", JB_PREFIX, client);    
		global_ctx.stuck_timer = true;
		CreateTimer(2.0, timer_end_stuck, client);
		
		// NOTE: we use the internal function as we want to use the others for state tracking of what block is meant to be
		unblock_all_clients();
	}
	else if (global_ctx.stuck_timer)
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
	PrintToChatAll("%s unstuck over", JB_PREFIX);    

  	global_ctx.stuck_timer = false;
    
	// restore to correct state
	// NOTE: this may not be the state before stuck was triggered
	// as wub can change it while active...
	if(block_state)
	{
		block_all_clients();
	}

	else
	{
		unblock_all_clients();
	}
    
	return Plugin_Continue;
    
}
