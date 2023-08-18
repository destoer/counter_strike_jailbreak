void rebel_player_init(int client)
{
    rebel_lr_active = true;

    int unused;
    int alive_ct = get_alive_team_count(CS_TEAM_CT,unused);

    SetEntityHealth(client,alive_ct * 100);
    strip_all_weapons(client); // remove all the players weapons
    
    gun_menu.Display(client,20);

    GivePlayerItem(client,"weapon_knife");
    GivePlayerItem(client,"weapon_deagle");

    PrintToChatAll("%s %N is a rebel!",LR_PREFIX,client);
}

void knife_rebel_player_init(int client)
{
    rebel_lr_active = true;
    knife_rebel_active = true;

    int unused;
    int alive_ct = get_alive_team_count(CS_TEAM_CT,unused);

    SetEntityHealth(client,alive_ct * 100);

    for(int i = 0; i < MAXPLAYERS + 1; i++)
    {
        if(is_valid_client(i) && IsPlayerAlive(i))
        {
            strip_all_weapons(i); 
            GivePlayerItem(i,"weapon_knife");
        }
    }

    PrintToChatAll("%s %N is a knife rebel!",LR_PREFIX,client);

    CreateTimer(BEACON_TIMER,beacon_callback,client,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
