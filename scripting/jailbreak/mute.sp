

Handle mute_timer = null;
Handle tmp_mute_timer = null;


void mute_t()
{
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        if(is_valid_client(i) && GetClientTeam(i) != CS_TEAM_CT && !is_muted(i) && !is_admin(i))
        {
            mute_client(i);
        }
    }

    PrintToChatAll("%s Terrorists are muted for the first 30 seconds of the round!",JB_PREFIX);

    mute_timer = CreateTimer(30.0,unmute_t);
}

public Action mute_death(Handle timer, int client)
{
    // Ignore mute during SD
    if(sd_enabled() && sd_current_state() != sd_inactive)
    {
        return Plugin_Continue;
    }

    if(is_valid_client(client))
    {
        PrintToChat(client,"%s You are muted until the start of the round\n",JB_PREFIX);
        mute_client(client);
    }

    return Plugin_Continue;
}

public Action unmute_tmp(Handle timer)
{
    PrintToChatAll("%s warden mute is now over!",JB_PREFIX);
    unmute_all(false);
    tmp_mute_timer = null;

    // re grab the timestamp for the cooldown
    global_ctx.tmp_mute_timestamp = GetTime();

    return Plugin_Continue;
}

public Action tmp_warden_mute(int client, int args)
{
    if(tmp_mute_timer != null)
    {
        PrintToChat(client,"%s mute is already active",WARDEN_PREFIX);
        return Plugin_Continue;
    }

    bool client_admin = is_admin(client);

    // make sure we are actually the warden
    if(client != global_ctx.warden_id && !client_admin)
    {
        PrintToChat(client,"%s You must be the warden or admin to use !wm",WARDEN_PREFIX);
        return Plugin_Continue;
    }

    int remain = 60 - (GetTime() - global_ctx.tmp_mute_timestamp);

    // make sure we cant spam this unless we are admin
    if(remain > 0 && !client_admin)
    {
        PrintToChat(client,"%s Warden mute cannot be used for another %d seconds",WARDEN_PREFIX,remain);
        return Plugin_Continue;
    }

    // mute everyone that isnt the warden
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        if(is_valid_client(i) && i != global_ctx.warden_id)
        {
            mute_client(i);
        }
    }

    PrintToChatAll("%s everyone apart from the warden is muted for 10 seconds!",JB_PREFIX);

    tmp_mute_timer = CreateTimer(10.0,unmute_tmp);  
    
    return Plugin_Continue;
}


void unmute_all(bool round_end)
{
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        // note: we need a extra dead check here to handle late joins
        if(is_valid_client(i) && is_muted(i) && is_on_team(i) && (round_end || IsPlayerAlive(i)))
        {
            // make sure this doesn't unmute t's if the mute timer is still active
            // due to a tmp mute
            if(mute_timer != null && GetClientTeam(i) == CS_TEAM_T)
            {
                continue;
            }

            unmute_client(i); 
        }
    }
}

public Action unmute_t(Handle timer)
{
    // make sure this happens before unmute_all
    // as it wont unmute t's while the timers are still active
    mute_timer = null;

    unmute_all(false);

    PrintToChatAll("%s Terrorists may now speak... quietly...",JB_PREFIX);

    return Plugin_Continue;
}    