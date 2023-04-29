int headshot_only_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,100);
    strip_all_weapons(client); // remove all the players weapons
    int weapon =  GivePlayerItem(client, "weapon_deagle");
    GivePlayerItem(client,"weapon_knife");

    slots[id].weapon = weapon;
    slots[id].weapon_string = "weapon_deagle";

    slots[id].restrict_drop = true;
}

void start_headshot_only(int t_slot, int ct_slot)
{
    headshot_only_player_init(t_slot);
    headshot_only_player_init(ct_slot);
}