

int console = -1;

void print_slot(int id)
{
    if(console == -1)
    {
        return;
    }

    PrintToConsole(console,"--- slot : %d --- ",id);
    PrintToConsole(console,"LR: %s",lr_list[slots[id].type]);
    PrintToConsole(console,"state: %d",slots[id].state);

    int partner = slots[id].partner;

    if(is_valid_slot(partner) && is_valid_client(slots[partner].client))
    {
        PrintToConsole(console,"partner: %N",slots[partner].client);
    }

    else
    {
        PrintToConsole(console,"Invalid partner %d",partner);
    }

    int client = slots[id].client

    if(is_valid_client(client))
    {
        PrintToConsole(console,"client: %N",client);
    }

    PrintToConsole(console,"bullet max: %d\n",slots[id].bullet_max);
    PrintToConsole(console,"bullet count: %d\n", slots[id].bullet_count)

    PrintToConsole(console,"weapon: %s : %d",slots[id].weapon_string,slots[id].weapon);

    PrintToConsole(console,"--------------");
}

public Action dump_slots(int client, int args)
{
    if(is_sudoer(client))
    {
        for(int i = 0; i < LR_SLOTS; i++)
        {
            print_slot(i);
        }
    }

    return Plugin_Continue;    
}

public Action force_drop(int client, int args)
{
    if(!is_sudoer(client))
    {
        return Plugin_Handled;
    } 

    for(int i = 1; i <= MaxClients; i++)
    {
        if(is_valid_client(i))
        {
            int wep_idx;
            for (int j = 0; j < 6; j++)
            {
                if ((wep_idx = GetPlayerWeaponSlot(i, j)) != -1)
                {
                    CS_DropWeapon(i,wep_idx,true,false);
                }
            }            
        }
    }

    return Plugin_Continue;   
}

public Action force_lr(int client, int args)
{
    if(!is_sudoer(client))
    {
        return Plugin_Handled;
    }

    if(GetCmdArgs() != 3)
    {
        PrintToChat(client,"%s Not enough args",LR_PREFIX);
        return Plugin_Handled;
    }

    new String:arg[64];

    GetCmdArg(1,arg,sizeof(arg));

    int cli1 = FindTarget(client,arg,false,false);

    if(cli1 == -1)
    {
        PrintToChat(client,"%s invalid client %s\n",LR_PREFIX,arg);
        return Plugin_Handled;
    }

    GetCmdArg(2,arg,sizeof(arg));

    int cli2 = FindTarget(client,arg,false,false);

    if(cli2 == -1)
    {
        PrintToChat(client,"%s invalid client %s\n",LR_PREFIX,arg);
        return Plugin_Handled;
    }

    GetCmdArg(3,arg,sizeof(arg));

    int lr = StringToInt(arg);
    lr_type type = view_as<lr_type>(lr);

    if(!(lr >= 0 && lr < LR_SIZE))
    {
        PrintToChat(client,"%s invalid lr %s\n",LR_PREFIX,arg);
        return Plugin_Handled;
    }


    if(GetClientTeam(cli1) != CS_TEAM_CT && GetClientTeam(cli2) != CS_TEAM_T)
    {
        PrintToChat(client,"%s invalid teams",LR_PREFIX);
        return Plugin_Handled;
    }

    start_lr_internal(cli1, cli2, type);

    return Plugin_Continue;
}

public Action register_console(int client, int args)
{
    if(is_sudoer(client))
    {
        console = client;
        PrintToChat(client,"%s Debugging enabled for client",LR_PREFIX);
    }


    return Plugin_Continue
}

public Action lr_version(int client, int args)
{
	// undocumented command
	if(!is_sudoer(client))
	{
		return Plugin_Handled;
	}	
	
	
	PrintToChat(console, "%s LR VERSION: %s",LR_PREFIX, PLUGIN_VERSION);
	
	return Plugin_Continue;
}