// TODO: this requires finding out a way to reliably manage 

void race_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,100); 
    strip_all_weapons(client); // remove all the players weapons

    GivePlayerItem(client, "weapon_knife");

    slots[id].weapon_string = "weapon_knife";
}

void start_race(int t_slot, int ct_slot)
{
    race_player_init(t_slot);
    race_player_init(ct_slot);
}

public int race_start_cord_handler(Menu menu, MenuAction action, int client, int choice)
{
    if(action == MenuAction_Select)
    {
        if(choice == 0)
        {
            
        }

        else
        {
            delete menu;
        }
    }

    else if (action == MenuAction_End)
    {
        delete menu;
    }
}


void race_menu(int client)
{
    Menu menu = new Menu(race_start_cord_handler);
    menu.SetTitle("Race option");

    menu.AddItem("Set start","Set start");
    menu.AddItem("Cancel","Cancel");

    menu.ExitButton = false;


    menu.Display(client,20);        
}