enum no_scope_choice
{
    no_scope_awp,
    no_scope_scout,
}



void noscope_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,100); 
    strip_all_weapons(client); // remove all the players weapons

    no_scope_choice choice = view_as<no_scope_choice>(slots[id].option);

    switch(choice)
    {
        case no_scope_awp:
        {
            GivePlayerItem(client, "weapon_awp");
            slots[id].weapon_string = "weapon_awp";
        }

        case no_scope_scout: 
        {
            GivePlayerItem(client, "weapon_scout");
            slots[id].weapon_string = "weapon_scout";            
        }
    }

    slots[id].restrict_drop = true;
}


void start_no_scope(int t_slot, int ct_slot)
{
    noscope_player_init(t_slot);
    noscope_player_init(ct_slot);
}


public Action give_no_scope(Handle Timer, int client)
{
    int id = get_slot(client);

    if(id == INVALID_SLOT)
    {
        return Plugin_Continue;
    }

    GivePlayerItem(client, slots[id].weapon_string);

    return Plugin_Continue;
}


public int no_scope_handler(Menu menu, MenuAction action, int client, int choice)
{
    if(action == MenuAction_Select)
    {
        lr_choice[client].option = choice;
        pick_partner(client);
    }

    else if (action == MenuAction_End)
    {
        delete menu;
    }
}


void no_scope_menu(int client)
{
    Menu menu = new Menu(no_scope_handler);
    menu.SetTitle("Pick Gun");

    menu.AddItem("Awp","Awp");
    menu.AddItem("scout","scout");

    menu.ExitButton = false;


    menu.Display(client,20);        
}