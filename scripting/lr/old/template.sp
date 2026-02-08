enum boop_choice
{
    boop_vanilla
}

void boop_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,100); 
    strip_all_weapons(client); // remove all the players weapons


    boop_choice choice = view_as<boop_choice>(slots[id].option);

}

void start_boop(int t_slot, int ct_slot)
{
    boop_player_init(t_slot);
    boop_player_init(ct_slot);
}

void boop_menu(int client)
{
    Menu menu = new Menu(default_choice_handler);
    menu.SetTitle("Boop option");

    menu.AddItem("vanilla","vanilla");


    menu.ExitButton = false;


    menu.Display(client,20);        
}