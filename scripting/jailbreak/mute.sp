

Handle mute_timer = null;


void mute_t()
{
    for(int i = 1; i < 64; i++)
    {
        if(is_valid_client(i) && GetClientTeam(i) != CS_TEAM_CT && !is_muted(i) && !is_admin(i))
        {
            mute_client(i);
        }
    }

    PrintToChatAll("%s T's are muted for the first 30 seconds",JB_PREFIX);

    mute_timer = CreateTimer(30.0,unmute_t);
}



void unmute_all()
{
    for(int i = 1; i < 64; i++)
    {
        if(is_valid_client(i) & is_muted(i))
        {
            unmute_client(i);
        }
    }
}

public Action unmute_t(Handle timer)
{
    mute_timer = null;

    unmute_all();

    PrintToChatAll("%s T's can now speak",JB_PREFIX);
}    