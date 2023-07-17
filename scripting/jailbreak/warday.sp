#if defined _WARDAY_INCLUDE_included
 #endinput
#endif
#define _WARDAY_INCLUDE_included#


public Action warday_callback(client, args)
{
    if(client != warden_id)
    {
        PrintToChat(client,"%s Only a warden may call a warday!",WARDEN_PREFIX);
        return Plugin_Handled;
    }


    if(warday_round_counter < WARDAY_ROUND_COUNT)
    {
        PrintToChat(client,"%s please wait %d rounds",WARDEN_PREFIX,WARDAY_ROUND_COUNT - warday_round_counter);
        return Plugin_Handled;
    }

    // we have called a warday reset the counter
    warday_round_counter = 0;

    if(args >= 1)
    {
        GetCmdArg(1,warday_loc,sizeof(warday_loc));
    }

    // no loc passed init to nothing
    else
    {
        Format(warday_loc,sizeof(warday_loc),"");
    }

    // start a warday....
    warday_start();

    return Plugin_Continue;
}


void warday_start()
{
    warday_active = true;

    PrintToChatAll("%s war day started doors will auto open in 20 seconds", WARDEN_PREFIX);


    // give every ct a gun
    for(int i = 0; i <= MAXPLAYERS; i++)
    {
        if(is_valid_client(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
        {
            gun_menu.Display(i,20);
        }
    }

    // after 20 seconds jam open every door
    CreateTimer(20.0,start_warday);
}

public Action start_warday(Handle timer)
{
    // give every t a gun
    for(int i = 0; i <= MAXPLAYERS; i++)
    {
        if(is_valid_client(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
        {
            gun_menu.Display(i,20);
        }
    }


    force_open();
    return Plugin_Handled;
}


