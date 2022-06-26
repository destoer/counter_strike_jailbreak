void noscope_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,100); 
    strip_all_weapons(client); // remove all the players weapons
    GivePlayerItem(client, "weapon_awp");

    slots[id].weapon_string = "weapon_awp";
}

void start_no_scope(int t_slot, int ct_slot)
{
    noscope_player_init(t_slot);
    noscope_player_init(ct_slot);
}

public Action give_no_scope(Handle Timer, int client)
{
    GivePlayerItem(client, "weapon_awp");
}
