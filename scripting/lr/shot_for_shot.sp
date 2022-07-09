enum shot_for_shot_choice
{
    shot_for_shot_deagle,
    shot_for_shot_usp,
    shot_for_shot_glock,
    shot_for_shot_five_seven,
    shot_for_shot_dual_elite,
}

#define SHOT_FOR_SHOT_WEAPON_SIZE 5

new const SHOT_FOR_SHOT_MAG_SIZE[SHOT_FOR_SHOT_WEAPON_SIZE] = 
{
    7,
    12,
    20,
    20,
    30,
};


void shot_for_shot_player_init(int id, bool mag)
{
    int client = slots[id].client;

    strip_all_weapons(client); // remove all the players weapons
    
    SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);

    shot_for_shot_choice choice = view_as<shot_for_shot_choice>(slots[id].option)

    switch(choice)
    {
        case shot_for_shot_usp:
        {
            slots[id].weapon_string = "weapon_usp";
        }

        case shot_for_shot_glock:
        {
            slots[id].weapon_string = "weapon_glock";
        }

        case shot_for_shot_five_seven:
        {
            slots[id].weapon_string = "weapon_fiveseven";
        }

        case shot_for_shot_dual_elite:
        {
            slots[id].weapon_string = "weapon_elite";
        }

        case shot_for_shot_deagle:
        {
            slots[id].weapon_string = "weapon_deagle";
        }
    }

    int weapon = GivePlayerItem(client, slots[id].weapon_string);

    if(mag)
    {
        slots[id].bullet_max = SHOT_FOR_SHOT_MAG_SIZE[slots[id].option];
    }

    else
    {
        slots[id].bullet_max = 1;
    }

    slots[id].weapon = weapon;

    empty_weapon(client,weapon);


    slots[id].restrict_drop = true;
}

void start_shot_for_shot(int t_slot, int ct_slot, bool mag)
{
    shot_for_shot_player_init(t_slot,mag);
    shot_for_shot_player_init(ct_slot,mag);


    if(GetRandomInt(0,1) == 0)
    {
        PrintToChatAll("%s Randomly chose %N to shoot first",LR_PREFIX,slots[t_slot].client);
        set_lr_clip(t_slot);
    }

    else
    {
        PrintToChatAll("%s Randomly chose %N to shoot first",LR_PREFIX,slots[ct_slot].client);
        set_lr_clip(ct_slot);
    }
}



public int shot_for_shot_handler(Menu menu, MenuAction action, int client, int choice)
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


void shot_for_shot_menu(int client)
{
    Menu menu = new Menu(no_scope_handler);
    menu.SetTitle("Pick Gun");

    menu.AddItem("Deagle","Deagle");
    menu.AddItem("Usp","Usp");
    menu.AddItem("Glock","Glock");
    menu.AddItem("Five seven","Five seven");
    menu.AddItem("Dual Elite","Dual Elite");

    menu.ExitButton = false;


    menu.Display(client,20);        
}