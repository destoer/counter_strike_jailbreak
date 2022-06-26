void knife_fight_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,100); 
    strip_all_weapons(client); // remove all the players weapons
    GivePlayerItem(client, "weapon_knife");

    slots[id].weapon_string = "weapon_knife";
}

void start_knife_fight(int t_slot, int ct_slot)
{
    knife_fight_player_init(t_slot);
    knife_fight_player_init(ct_slot);
}