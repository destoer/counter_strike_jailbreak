void noscope_player_init(int client)
{
	SetEntityHealth(client,100); // set health to 1
	strip_all_weapons(client); // remove all the players weapons
	GivePlayerItem(client, "weapon_awp");
}

void start_no_scope(int t_slot, int ct_slot)
{
    noscope_player_init(slots[t_slot].client);
    noscope_player_init(slots[ct_slot].client);
}

public Action give_no_scope(Handle Timer, int client)
{
    GivePlayerItem(client, "weapon_awp");
}
