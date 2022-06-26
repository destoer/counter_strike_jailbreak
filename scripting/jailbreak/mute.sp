

Handle mute_timer;

void mute_all()
{
    for(int i = 0; i < 64; i++)
    {
        if(is_valid_client(i) && GetClientTeam(i) != CS_TEAM_CT && !is_muted(i) && !is_admin(i))
        {
            mute_client(i);
        }
    }
   
}

void mute_t()
{
    mute_all();

    PrintToChatAll("%s T's are muted for the first 30 seconds",JB_PREFIX);

    mute_timer = CreateTimer(30.0,unmute_t);
}



void unmute_all()
{
    for(int i = 0; i < 64; i++)
    {
        if(is_valid_client(i) && GetClientTeam(i) != CS_TEAM_CT && is_muted(i))
        {
            unmute_client(i);
        }
    }
}

public Action unmute_t(Handle timer)
{
    unmute_all();

    PrintToChatAll("%s T's can now speak",JB_PREFIX);
}    