void scout_knife_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,100); 
    strip_all_weapons(client); // remove all the players weapons

    GivePlayerItem(client, "weapon_scout");
    GivePlayerItem(client, "weapon_knife");
    slots[id].weapon_string = "weapon_scout";   
        
    slots[id].restrict_drop = true;
    SetEntityGravity(client,0.1);
}


void start_scout_knife(int t_slot, int ct_slot)
{
    scout_knife_player_init(t_slot);
    scout_knife_player_init(ct_slot);
}
