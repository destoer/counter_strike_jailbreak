void custom_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,100); // set health to 1
    strip_all_weapons(client); // remove all the players weapons
    
    GivePlayerItem(client, "weapon_deagle");
    GivePlayerItem(client,"weapon_knife");
}

void start_custom(int t_slot, int ct_slot)
{
    custom_player_init(t_slot);
    custom_player_init(ct_slot);
}