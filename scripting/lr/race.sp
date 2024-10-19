
void race_player_init(int id)
{
    int client = slots[id].client;

    if(!is_valid_client(client))
    {
        end_lr_pair(id,slots[id].partner);
        return;
    }

    SetEntityHealth(client,100); 
    strip_all_weapons(client); // remove all the players weapons

    GivePlayerItem(client, "weapon_knife");
    slots[id].weapon_string = "weapon_knife";

    // unstuck the player
    PrintToChat(client,"%s GO!",LR_PREFIX);

    SetEntityMoveType(client, MOVETYPE_WALK);
    unblock_client(client,SetCollisionGroup);
}

void race_player_startup(int slot,float race_start[3], float race_end[3])
{
    if(!is_valid_client(slots[slot].client))
    {
        end_lr_pair(slot,slots[slot].partner);
        return;
    }


    for(int i = 0; i < 3; i++)
    {
        slots[slot].race_start[i] = race_start[i];
        slots[slot].race_end[i] = race_end[i];
    }

    // disable movement
    float zero[3] = {0.0,0.0,0.0};
    set_player_velocity(slots[slot].client,zero);
    SetEntityMoveType(slots[slot].client, MOVETYPE_NONE);

    // teleport player to end
    TeleportEntity(slots[slot].client,slots[slot].race_end,NULL_VECTOR,NULL_VECTOR);
    CreateTimer(3.0,race_tp_start,slot,TIMER_FLAG_NO_MAPCHANGE);
}

public Action race_tp_start(Handle timer, int id)
{
    if(slots[id].state != lr_starting || !is_valid_client(slots[id].client) || slots[id].type != race)
    {
        return Plugin_Stop;
    }


    int partner_slot = slots[id].partner;

    // teleport players to start
    TeleportEntity(slots[id].client,slots[id].race_start,NULL_VECTOR,NULL_VECTOR);
    TeleportEntity(slots[partner_slot].client,slots[partner_slot].race_start,NULL_VECTOR,NULL_VECTOR);

    return Plugin_Continue;
}


void race_startup(int t_slot, int ct_slot)
{
    int t_client = slots[t_slot].client;
    
    race_player_startup(t_slot,lr_choice[t_client].race_start,lr_choice[t_client].race_end);
    race_player_startup(ct_slot,lr_choice[t_client].race_start,lr_choice[t_client].race_end);

    if(is_player_stuck(slots[ct_slot].client))
    {
        CS_RespawnPlayer(slots[ct_slot].client);
        PrintToChatAll("%s CT is stuck, ending LR",LR_PREFIX);
        end_lr_pair(t_slot,ct_slot);
    }
}

float RACE_RADIUS = 215.0;
float RACE_DRAW_TIMER = 0.1;

void draw_race_circle(float pos[3], int colour[4], float timer) 
{
    TE_SetupBeamRingPoint(pos, RACE_RADIUS, RACE_RADIUS + 0.1, g_lbeam, g_lhalo, 0, 5, timer, 5.2, 0.0, colour, 1000, 0);
    TE_SendToAll();
}

void draw_race_player_line(int client, float end[3])
{
    if(!is_valid_client(client))
    {
        return;
    }

    float pos[3];
    GetClientAbsOrigin(client,pos);
    pos[1] += 5.0;

    TE_SetupBeamPoints(pos, end, g_lbeam, 0, 0, 0, RACE_DRAW_TIMER, 0.8, 0.8, 2, 0.0, { 1, 153, 255, 255 }, 0);
    TE_SendToAll();
}

public Action draw_race(Handle timer, int id)
{
    if(slots[id].state == lr_inactive || !is_valid_client(slots[id].client) || slots[id].type != race)
    {
        slots[id].timer = null;
        return Plugin_Stop;
    }

    draw_race_circle(slots[id].race_start,{ 1, 153, 255, 255 },RACE_DRAW_TIMER);
    draw_race_circle(slots[id].race_end,{ 255, 0, 0, 255 },RACE_DRAW_TIMER);

    draw_race_player_line(slots[id].client,slots[id].race_end);
    int partner_id = slots[id].partner;
    draw_race_player_line(slots[partner_id].client,slots[partner_id].race_end);

    return Plugin_Continue;
}

void start_race(int t_slot, int ct_slot)
{
    slots[t_slot].timer = CreateTimer(RACE_DRAW_TIMER,draw_race,t_slot,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    race_player_init(t_slot);
    race_player_init(ct_slot);
}

public int race_end_cord_handler(Menu end_menu, MenuAction action, int client, int choice)
{
    if(action == MenuAction_Select)
    {
        if(choice == 0)
        {
            GetClientAbsOrigin(client,lr_choice[client].race_end);
            draw_race_circle(lr_choice[client].race_end,{ 255, 0, 0, 255 },10.0);

            // If the distance between these is < rad * 2 then they will be overlapping.
            // This check is will give a few false +ve's but any race this close is not worth running anyways.
            if(GetVectorDistance(lr_choice[client].race_end,lr_choice[client].race_start) <= RACE_RADIUS * 2) {
                PrintToChat(client,"%s Start and end point are too close together",LR_PREFIX);
                return 0;
            }

            pick_partner(client);
        }

        else
        {
            delete end_menu;
        }
    }

    else if (action == MenuAction_End)
    {
        delete end_menu;
    }

    return 0;
}

public int race_start_cord_handler(Menu start_menu, MenuAction action, int client, int choice)
{
    if(action == MenuAction_Select)
    {
        if(choice == 0)
        {
            GetClientAbsOrigin(client,lr_choice[client].race_start);
            draw_race_circle(lr_choice[client].race_start,{ 1, 153, 255, 255 },10.0);

            Menu end_menu = new Menu(race_end_cord_handler);
            end_menu.SetTitle("Race option");

            end_menu.AddItem("Set end","Set end");
            end_menu.AddItem("Cancel","Cancel");
            end_menu.ExitButton = false;

            end_menu.Display(client,20);    
        }

        else
        {
            delete start_menu;
        }
    }

    else if (action == MenuAction_End)
    {
        delete start_menu;
    }

    return 0;
}

void race_menu(int client)
{
    Menu start_menu = new Menu(race_start_cord_handler);
    start_menu.SetTitle("Race option");

    start_menu.AddItem("Set start","Set start");
    start_menu.AddItem("Cancel","Cancel");
    start_menu.ExitButton = false;

    start_menu.Display(client,20);        
}