enum knife_choice
{
    knife_vanilla,
    knife_low_grav,
    knife_high_speed,
    knife_one_hit,
    knife_fly,
}

void client_fly(int client)
{
	set_client_speed(client,1.5);
	SetEntityMoveType(client, MOVETYPE_FLY);
}

void knife_fight_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,100); 
    strip_all_weapons(client); // remove all the players weapons
    GivePlayerItem(client, "weapon_knife");

    slots[id].weapon_string = "weapon_knife";


    knife_choice choice = view_as<knife_choice>(slots[id].option);

    switch(choice)
    {
        case knife_vanilla:
        {
            
        }

        case knife_low_grav: 
        {
            SetEntityGravity(client,0.6);
        }

        case knife_high_speed:
        {
            set_client_speed(client,2.5);
        }

        case knife_one_hit:
        {
            SetEntityHealth(client,50); 
        }

        case knife_fly:
        {
            PrintToChat(client,"%s Press e to toggle flying",LR_PREFIX)
            client_fly(client);
        }
    }

}

void start_knife_fight(int t_slot, int ct_slot)
{
    knife_fight_player_init(t_slot);
    knife_fight_player_init(ct_slot);
}

void knife_fight_menu(int client)
{
    Menu menu = new Menu(default_choice_handler);
    menu.SetTitle("Knife option");

    menu.AddItem("vanilla","vanilla");
    menu.AddItem("low grav","low grav");
    menu.AddItem("high speed","high speed");
    menu.AddItem("one hit","one hit");
    menu.AddItem("fly", "fly");

    menu.ExitButton = false;


    menu.Display(client,20);        
}