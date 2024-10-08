void gun_toss_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,100); // set health to 1
    strip_all_weapons(client); // remove all the players weapons
    int weapon =  GivePlayerItem(client, "weapon_deagle");
    GivePlayerItem(client,"weapon_knife");


    slots[id].weapon = weapon;
    slots[id].weapon_string = "weapon_deagle"
}

void start_gun_toss(int t_slot, int ct_slot)
{
    gun_toss_player_init(t_slot);
    gun_toss_player_init(ct_slot);
}

void draw_toss(float start[3], float end[3], int line_color[4])
{
    TE_SetupBeamPoints(start, end, g_lbeam, 0, 0, 0, GUNTOSS_TIMER, 0.8, 0.8, 2, 0.0, line_color, 0);
    TE_SendToAll();    
}

public Action draw_toss_timer(Handle timer, int id)
{
    LrSlot slot;
    slot = slots[id];

    if(!is_valid_client(slot.client) || slots[id].state == lr_inactive || slots[id].type != gun_toss)
    {
        slots[id].timer = null;
        return Plugin_Stop;
    }

    if(GetClientTeam(slot.client) == CS_TEAM_T)
    {
        draw_toss(slot.pos,slot.gun_pos,{255,0,0,255});
    }

    else 
    {
        draw_toss(slot.pos,slot.gun_pos,{0,0,255,255});
    }  

    return Plugin_Continue;  
}

public Action get_gun_end(Handle timer, int id)
{
    if(slots[id].state == lr_inactive)
    {
        return Plugin_Stop;
    }

    if(!slots[id].gun_dropped)
    {
        return Plugin_Stop;
    }


    float pos[3]
    GetEntPropVector(slots[id].weapon, Prop_Send, "m_vecOrigin", pos);

    // vel has hit zero (draw the line and print the display result)
    if(cmp_vec(pos,slots[id].gun_pos))
    {
        float start[3]; 
        float end[3];

        start = slots[id].pos;
        end = pos;
    
        start[2] = 0.0;
        end[2] = 0.0;

        float distance = GetVectorDistance(start,end);
        PrintToChatAll("%s %N distance %f",LR_PREFIX,slots[id].client,distance);
        KillTimer(timer);

        // same z cord
        slots[id].pos[2] = pos[2] + 8.0;

        slots[id].timer = CreateTimer(GUNTOSS_TIMER,draw_toss_timer,id,TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
    }

    slots[id].gun_pos = pos;
    
    return Plugin_Continue;
}