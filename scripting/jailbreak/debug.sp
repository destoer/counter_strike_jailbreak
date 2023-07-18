/*
**
*/
#if defined _DEBUG_INCLUDE_included
 #endinput
#endif
#define _DEBUG_INCLUDE_included


public Action jailbreak_version(int client, int args)
{
	// debugging command
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}	
	
	
	PrintToChat(client, "%s WARDEN VERSION: %s",WARDEN_PREFIX, PLUGIN_VERSION);
	
	return Plugin_Continue;
}

public Action is_blocked_cmd(int client, int args)
{
	// debugging command
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}
	
	Handle hosties_cvar = FindConVar("sm_hosties_noblock_enable");

	if(hosties_cvar)
	{
		bool hosties_noblock = GetConVarInt(hosties_cvar) > 0;
		PrintToChat(client, "%s hosties block setting %s\n", WARDEN_PREFIX, hosties_noblock ? "no block" : "block");
	}

	
	PrintToChat(client, "%s blocked state: %s",WARDEN_PREFIX, noblock_enabled() ? "no block" : "block");
	PrintToChat(client, "%s internal blocked state: %s",WARDEN_PREFIX, noblock_enabled() ? "no block" : "block");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(is_valid_client(i))
		{
			PrintToConsole(client, "block state: %N %s", i, is_client_blocked(i) ? "block" : "no block");
		}
	}
	
	return Plugin_Continue;
}

public Action is_rebel_cmd(int client, int args)
{
	// debugging command
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if(is_valid_client(i))
		{
			PrintToConsole(client, "rebel: %N %s", i, rebel[i] ? "true" : "false");
		}
	}

	return Plugin_Continue;
}


public Action ent_count(int client, int args)
{
	// debugging command
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}

	PrintToChat(client,"%s Entity count %d",JB_PREFIX,GetEntityCount());

	return Plugin_Continue;	
}

public Action is_muted_cmd(int client, int args)
{
	// undocumented command
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if(is_valid_client(i))
		{
			PrintToConsole(client, "muted: %N %s", i, is_muted(i) ? "true" : "false");
		}
	}

	return Plugin_Continue;	
}

public Action wd_rounds(int client, int args)
{
	// debugging command
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}

	PrintToChat(client,"%s warday round counter %d:%d",WARDEN_PREFIX,warday_round_counter,WARDAY_ROUND_COUNT);

	return Plugin_Continue;
}

public Action spawn_count_cmd(int client, int args)
{
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client,"%s spawn count %d : %d\n",JB_PREFIX,spawn_count(CS_TEAM_T),spawn_count(CS_TEAM_CT));
	
	return Plugin_Continue;	
}


public Action enable_wd(int client, int args)
{
	// debugging command
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}

	warday_round_counter = WARDAY_ROUND_COUNT;	

	return Plugin_Continue;
}