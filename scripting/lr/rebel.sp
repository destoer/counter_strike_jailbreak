int rebel_player_init(int client)
{
    int id = get_inactive_slot();

    init_slot(id,client,INVALID_SLOT,rebel);

    int unused;
    int alive_ct = get_alive_team_count(CS_TEAM_CT,unused);

    SetEntityHealth(client,alive_ct * 100);
    strip_all_weapons(client); // remove all the players weapons
    int weapon =  GivePlayerItem(client, "weapon_m249");
    GivePlayerItem(client,"weapon_knife");
    GivePlayerItem(client,"weapon_deagle");

    set_clip_ammo(client,weapon,999);
    set_reserve_ammo(client,weapon,999);



    slots[id].weapon = weapon;
    slots[id].weapon_string = "";

    slots[id].restrict_drop = false;

    PrintToChatAll("%s %N is a rebel!",LR_PREFIX,client);
}
