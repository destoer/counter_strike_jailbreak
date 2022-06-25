void noscope_player_init(int client)
{
	SetEntityHealth(client,100); // set health to 1
	strip_all_weapons(client); // remove all the players weapons
	GivePlayerItem(client, "weapon_awp");
}

void start_no_scope(LrPair pair)
{
    noscope_player_init(pair.t);
    noscope_player_init(pair.ct);
}

public Action give_no_scope(Handle Timer, int client)
{
    GivePlayerItem(client, "weapon_awp");
}
