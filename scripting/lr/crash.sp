
void crash_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,1000);
    strip_all_weapons(client); // remove all the players weapons
    int weapon =  GivePlayerItem(client, "weapon_deagle");
    GivePlayerItem(client,"weapon_knife");

    set_clip_ammo(client,weapon,999);
    set_reserve_ammo(client,weapon,999);

    slots[id].weapon = weapon;
    slots[id].weapon_string = "deagle";

    PrintToChat(client,"%s Drop your weapon when you are ready",LR_PREFIX);
}

void start_crash(int t_slot, int ct_slot)
{
    crash_player_init(t_slot);
    crash_player_init(ct_slot);

    // Use a ms timer for the actual triggers
    int start = GetSysTickCount();
    slots[t_slot].ticks_start = start;
    slots[ct_slot].ticks_start = start;

    slots[t_slot].crash_delay = GetRandomInt(5,20);

    // countdown is here
    slots[t_slot].delay = slots[t_slot].crash_delay;

    // use a seperate int timer for showing progress
    slots[ct_slot].delay = 0;

    slots[t_slot].timer = CreateTimer(1.0,crash_end,t_slot,TIMER_FLAG_NO_MAPCHANGE);
}

void print_time(int slot)
{
    if(slots[slot].dropped_once)
    {
        PrintToChatAll("%s %N dropped at %f",LR_PREFIX,slots[slot].client,float(slots[slot].ticks - slots[slot].ticks_start) / 1000.0);
    }
}

public Action crash_end(Handle timer, int t_slot)
{
    int id = t_slot;
    int ct_slot = slots[t_slot].partner;

    if(!slots[t_slot].delay)
    {
        slots[id].timer = null;
        return Plugin_Stop;
    }

    // is valid?
    int t = slots[t_slot].client;
    int ct = slots[ct_slot].client;

    if(slots[t_slot].delay)
    {
        slots[t_slot].delay -= 1;
        slots[ct_slot].delay += 1;

        PrintCenterText(t,"crash timer %d",slots[ct_slot].delay);
        PrintCenterText(ct,"crash timer %d",slots[ct_slot].delay);

        slots[t_slot].timer = CreateTimer(1.0,crash_end,t_slot,TIMER_FLAG_NO_MAPCHANGE);

        // more to go
        if(slots[t_slot].delay)
        {
            return Plugin_Handled;
        }
    }

    // timer is done
    slots[id].timer = null;


    PrintToChatAll("%s Actual crash delay %d",LR_PREFIX,slots[t_slot].crash_delay);
    print_time(t_slot);
    print_time(ct_slot);


    bool t_dropped = slots[t_slot].dropped_once;
    bool ct_dropped = slots[ct_slot].dropped_once;

    // both players have picked
    if(t_dropped && ct_dropped)
    {
        // As we cannot go over whoever has the HIGHEST timer is the winner
        if(slots[t_slot].ticks > slots[ct_slot].ticks)
        {   
            ForcePlayerSuicide(ct);
        }

        // ct won
        else
        {
            ForcePlayerSuicide(t);
        }
    }

    // neither player dropped
    else if(!t_dropped && !ct_dropped)
    {
        PrintToChatAll("%s %N and %N did not drop their weapon in time, tossing coin...",LR_PREFIX,t,ct);
        
        int toss = GetRandomInt(0,1);

        if(toss == 0)
        {
            PrintToChatAll("%s %N won the coin toss\n",LR_PREFIX,ct);
            ForcePlayerSuicide(t);
        }

        else
        {
            PrintToChatAll("%s %N won the coin toss\n",LR_PREFIX,t);
            ForcePlayerSuicide(ct);
        }
    }

    // if a player has not picked they lose automatically
    else
    {
        if(!t_dropped)
        {
            PrintToChatAll("%s %N did not drop their weapon in time",LR_PREFIX,t);
            ForcePlayerSuicide(t);
        }

        if(!ct_dropped)
        {
            PrintToChatAll("%s %N did not drop their weapon in time",LR_PREFIX,ct);
            ForcePlayerSuicide(ct);
        }
    }

    return Plugin_Continue;
}