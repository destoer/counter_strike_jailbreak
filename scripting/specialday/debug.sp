/*
**
*/
#if defined _DEBUG_INCLUDE_included
 #endinput
#endif
#define _DEBUG_INCLUDE_included


// because we cant have debugging commands without
// inboxes blowing up sigh...

public Action sd_info_cmd(int client, int args)
{
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client, "%s SD VERSION: %s",SPECIALDAY_PREFIX, VERSION);
	PrintToChat(client, "%s SD STATE: %d\n",SPECIALDAY_PREFIX, view_as<int>(sd_state));
	PrintToChat(client, "%s SD CURRENT: %d\n",SPECIALDAY_PREFIX, view_as<int>(special_day));
	
	return Plugin_Continue;
}

public Action rig_client(int client, int args)
{
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}	

	new String:arg[64];

	GetCmdArg(1,arg,sizeof(arg));

	PrintToChat(client,"%s Rigging next sd for client %s\n",SPECIALDAY_PREFIX,arg);

	rigged_client = FindTarget(client,arg);

	PrintToChat(client,"%s Rigged to client %d:%N\n",SPECIALDAY_PREFIX,rigged_client,rigged_client);


	return Plugin_Continue;
}

public Action enable_wsd(int client, int args)
{
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}
	
	warden_sd_available++;
	
	return Plugin_Continue;	
}