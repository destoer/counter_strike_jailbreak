/*
**
*/
#if defined _DEBUG_INCLUDE_included
 #endinput
#endif
#define _DEBUG_INCLUDE_included

// because we cant have debugging commands without
// inboxes blowing up sigh...



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


#define UNDOCUMENTED_COMMANDS_LEN 2

static const char undocumented_commands[UNDOCUMENTED_COMMANDS_LEN][] = { "wv","is_blocked"};

// i dont even wanna know why i cant just declare a const array
// sigh
ConCmd undocumented_command_callbacks[UNDOCUMENTED_COMMANDS_LEN];

void register_undocumented_commands()
{

	undocumented_command_callbacks[0] = jailbreak_version;
	undocumented_command_callbacks[1] = is_blocked_cmd;
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