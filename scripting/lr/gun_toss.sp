int gun_toss_player_init(int client)
{
    SetEntityHealth(client,100); // set health to 1
    strip_all_weapons(client); // remove all the players weapons
    int weapon =  GivePlayerItem(client, "weapon_deagle");
    GivePlayerItem(client,"weapon_knife");


    return weapon;
}

void start_gun_toss(LrPair pair)
{
    pair.t_weapon = gun_toss_player_init(pair.t);
    pair.ct_weapon = gun_toss_player_init(pair.ct);
}

void draw_toss(float start[3], float end[3], int line_color[4])
{
    TE_SetupBeamPoints(start, end, g_lbeam, 0, 0, 0, GUNTOSS_TIMER, 0.8, 0.8, 2, 0.0, line_color, 0);
    TE_SendToAll();    
}

public Action draw_toss_timer(Handle timer, int pack)
{
    int id; int client;
    unpack_int(pack,id,client);

    if(pairs[id].t == client)
    {
        draw_toss(pairs[id].t_pos,pairs[id].t_gun_pos,{255,0,0,255});
    }

    else if(pairs[id].ct == client)
    {
        draw_toss(pairs[id].ct_pos,pairs[id].ct_gun_pos,{0,0,255,255});
    }    
}

public Action get_gun_end(Handle timer, int pack)
{

    int id; int client;
    unpack_int(pack,id,client);


    if(!pairs[id].active)
    {
        return Plugin_Stop;
    }


    // TODO: its code like this , that means we should probably have the pair be stored seperately from eachover
    // if we dont want to lose our minds LOL

    // TODO: kill the timer if we drop the gun again....

    if(pairs[id].t == client)
    {
        float pos[3]
        GetEntPropVector(pairs[id].t_weapon, Prop_Send, "m_vecOrigin", pos);

        // vel has hit zero (draw the line and print the display result)
        if(cmp_vec(pos,pairs[id].t_gun_pos))
        {
            float distance = GetVectorDistance(pairs[id].t_pos,pos);
            PrintToChatAll("%s %N distance %f",LR_PREFIX,client,distance);
            KillTimer(timer);

            pairs[id].t_timer = CreateTimer(GUNTOSS_TIMER,draw_toss_timer,pack_int(id,client),TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
        }

        pairs[id].t_gun_pos = pos;
    }

    else 
    {
        float pos[3]
        GetEntPropVector(pairs[id].ct_weapon, Prop_Send, "m_vecOrigin", pos);

        // vel has hit zero (draw the line and print the display result)
        if(cmp_vec(pos,pairs[id].ct_gun_pos))
        {
            float distance = GetVectorDistance(pairs[id].ct_pos,pos);
            PrintToChatAll("%s %N distance %f",LR_PREFIX,client,distance);
            KillTimer(timer);

            pairs[id].ct_timer = CreateTimer(GUNTOSS_TIMER,draw_toss_timer,pack_int(id,client),TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
        }

        pairs[id].ct_gun_pos = pos;
    }
    
    return Plugin_Continue;
}