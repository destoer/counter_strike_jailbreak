void sumo_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,100); 
    strip_all_weapons(client); // remove all the players weapons
    GivePlayerItem(client, "weapon_knife");

    slots[id].weapon_string = "weapon_knife";
    
    // unstuck the player
    PrintToChat(client,"%s Fight!",LR_PREFIX);
    SetEntityMoveType(client, MOVETYPE_WALK);
    unblock_client(client);
}

float SUMO_CIRCLE_TIMER = 0.1;

float SUMO_RADIUS = 215.0;

public Action draw_circle(Handle timer, int id)
{

    if(slots[id].state == lr_inactive || !is_valid_client(slots[id].client) || slots[id].type != sumo)
    {
        slots[id].timer = null;
        return Plugin_Stop;
    }

    TE_SetupBeamRingPoint(slots[id].pos, SUMO_RADIUS, SUMO_RADIUS + 0.1, g_lbeam, g_lhalo, 0, 5, SUMO_CIRCLE_TIMER, 5.2, 0.0, { 1, 153, 255, 255 }, 1000, 0);
    TE_SendToAll();

    return Plugin_Continue;
}

public Action enable_sumo_damage(Handle timer,int ct_slot)
{
    if(slots[ct_slot].state == lr_inactive || !is_valid_client(slots[ct_slot].client))
    {
        return Plugin_Continue;
    }

    slots[ct_slot].timer = null;


    slots[ct_slot].failsafe = true;
    int t_slot = slots[ct_slot].partner;
    slots[t_slot].failsafe = true;

    PrintToChat(slots[t_slot].client,"%s DAMAGE ENABLED! Hurry up",LR_PREFIX);
    PrintToChat(slots[ct_slot].client,"%s DAMAGE ENABLED! Hurry up",LR_PREFIX);

    return Plugin_Continue;
}

void sumo_startup(int t_slot, int ct_slot)
{
    GetClientAbsOrigin(slots[t_slot].client,slots[t_slot].pos);

    // make sure both clients have a pos!
    for(int i = 0; i < 3; i++)
    {
        slots[ct_slot].pos[i] = slots[t_slot].pos[i];
    }

    slots[t_slot].timer = CreateTimer(SUMO_CIRCLE_TIMER,draw_circle,t_slot,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    slots[ct_slot].timer = CreateTimer(28.0,enable_sumo_damage,ct_slot,TIMER_FLAG_NO_MAPCHANGE);

    float zero[3] = {0.0,0.0,0.0};

    set_player_velocity(slots[t_slot].client,zero);
    SetEntityMoveType(slots[t_slot].client, MOVETYPE_NONE);

    set_player_velocity(slots[ct_slot].client,zero);
    SetEntityMoveType(slots[ct_slot].client, MOVETYPE_NONE);


    // teleport ct
    TeleportEntity(slots[ct_slot].client,slots[t_slot].pos,NULL_VECTOR,NULL_VECTOR);

    if(is_player_stuck(slots[ct_slot].client))
    {
        CS_RespawnPlayer(slots[ct_slot].client);
        PrintToChatAll("%s CT is stuck, ending LR",LR_PREFIX);
        end_lr_pair(t_slot,ct_slot);
    }

}

void start_sumo(int t_slot, int ct_slot)
{
    sumo_player_init(t_slot);
    sumo_player_init(ct_slot);
}