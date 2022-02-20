/*
**
*/
#if defined _DEBUG_INCLUDE_included
 #endinput
#endif
#define _DEBUG_INCLUDE_included


// because we cant have debugging commands without
// inboxes blowing up sigh...

public Action sd_version(int client, int args)
{
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}
	
	PrintToChat(client, "%s SD VERSION: %s",SPECIALDAY_PREFIX, VERSION);
	
	return Plugin_Continue;
}

#if defined SD_STANDALONE

#else

public Action enable_wsd(int client, int args)
{
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}
	
	warden_sd_available++;
	
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

#endif