#if defined _WARDAY_INCLUDE_included
 #endinput
#endif
#define _WARDAY_INCLUDE_included


void format_warday(int args)
{
    // no loc passed init to nothing
    if(args == 0)
    {
        Format(global_ctx.warday_loc,sizeof(global_ctx.warday_loc),"");
    }

    else
    {
        GetCmdArgString(global_ctx.warday_loc,sizeof(global_ctx.warday_loc));
    }

}

public Action warday_callback(int client, int args)
{
    if(!warday_enable)
    {	
        PrintToChat(client,"%s Warday is disabled",WARDEN_PREFIX);
        return Plugin_Handled;
    }

    if(client != global_ctx.warden_id)
    {
        PrintToChat(client,"%s Only a warden may call a warday!",WARDEN_PREFIX);
        return Plugin_Handled;
    }

    if(!global_ctx.warday_active)
    {
        if(global_ctx.warday_round_counter < WARDAY_ROUND_COUNT)
        {
            PrintToChat(client,"%s please wait %d rounds",WARDEN_PREFIX,WARDAY_ROUND_COUNT - global_ctx.warday_round_counter);
            return Plugin_Handled;
        }

        // we have called a warday reset the counter
        global_ctx.warday_round_counter = 0;

        format_warday(args);

        // start a warday....
        warday_start();
    }

    // recalled when active let them re format the name
    else
    {
        format_warday(args);
    }

    return Plugin_Continue;
}


void warday_start()
{
    global_ctx.warday_active = true;

    disable_lr();

    PrintToChatAll("%s war day started doors will auto open in 20 seconds", WARDEN_PREFIX);

    if(warday_gun_enable)
    {
        // give every ct a gun
        for(int i = 0; i <= MAXPLAYERS; i++)
        {
            if(is_valid_client(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
            {
                gun_menu.Display(i,20);
            }
        }
    }

    // after 20 seconds jam open every door
    CreateTimer(20.0,start_warday);
}

public Action start_warday(Handle timer)
{
    if(warday_gun_enable)
    {
        // give every t a gun
        for(int i = 0; i <= MAXPLAYERS; i++)
        {
            if(is_valid_client(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
            {
                gun_menu.Display(i,20);
            }
        }
    }

    force_open();
    return Plugin_Handled;
}


