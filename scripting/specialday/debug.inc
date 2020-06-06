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



#define UNDOCUMENTED_COMMANDS_LEN 1

new const String:undocumented_commands[UNDOCUMENTED_COMMANDS_LEN][] = { "sdv"};

// i dont even wanna know why i cant just declare a const array
// sigh
ConCmd undocumented_command_callbacks[UNDOCUMENTED_COMMANDS_LEN];

void register_undocumented_commands()
{
	undocumented_command_callbacks[0] = sd_version;
}

void handle_undocumented_command(const char[] cmd, int client)
{
	for (int i = 0; i < UNDOCUMENTED_COMMANDS_LEN; i++)
	{
		if(StrEqual(cmd,undocumented_commands[i]))
		{
			Call_StartFunction(null, undocumented_command_callbacks[i]);
			Call_PushCell(client);
			Call_PushCell(0); // assume zero args for now because ehh
			Call_Finish();
		}
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    
	// hide commands typed by sudoers
	if(is_sudoer(client) && (sArgs[0] == '/' || sArgs[0] == '!'))
	{
		handle_undocumented_command(sArgs[1], client);
		return Plugin_Handled;
	}    
	
	return Plugin_Continue;
}
