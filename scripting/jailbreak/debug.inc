/*
**
*/
#if defined _DEBUG_INCLUDE_included
 #endinput
#endif
#define _DEBUG_INCLUDE_included


public Action jailbreak_version(int client, int args)
{
	// undocumented command
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}	
	
	
	PrintToChat(client, "%s WARDEN VERSION: %s",WARDEN_PREFIX, PLUGIN_VERSION);
	
	return Plugin_Continue;
}

public Action is_blocked_cmd(int client, int args)
{
	// undocumented command
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client, "%s blocked state: %s",WARDEN_PREFIX, noblock_enabled() ? "no block" : "block");
	for (int i = 0; i < MaxClients; i++)
	{
		if(is_valid_client(i))
		{
			PrintToConsole(client, "block state: %N %s", i, is_client_blocked(i) ? "block" : "no block");
		}
	}
	
	return Plugin_Continue;
}