

Handle mute_timer = null;


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
    if(is_valid_client(client) && !is_admin(client))
    {
        PrintToChat(client,"%s You are muted until the start of the round\n",JB_PREFIX);
        mute_client(client);
    }

    return Plugin_Continue;
}


void unmute_all()
{
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        if(is_valid_client(i) & is_muted(i) && is_on_team(i))
        {
            unmute_client(i);
        }
    }
}

public Action unmute_t(Handle timer)
{
    mute_timer = null;

    unmute_all();

    PrintToChatAll("%s Terrorists may now speak... quietly...",JB_PREFIX);

    return Plugin_Continue;
}    