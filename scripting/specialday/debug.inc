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

