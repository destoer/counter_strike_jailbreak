int shotgun_war_player_init(int id)
{
    int client = slots[id].client;

    SetEntityHealth(client,1000);
    strip_all_weapons(client); // remove all the players weapons
    int weapon =  GivePlayerItem(client, "weapon_xm1014");
    GivePlayerItem(client,"weapon_knife");

    set_clip_ammo(client,weapon,999);
    set_reserve_ammo(client,weapon,999);

    slots[id].weapon = weapon;
    slots[id].weapon_string = "weapon_xm1014";
}

void start_shotgun_war(int t_slot, int ct_slot)
{
    shotgun_war_player_init(t_slot);
    shotgun_war_player_init(ct_slot);
}