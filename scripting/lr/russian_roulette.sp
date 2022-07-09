void russian_roulette_player_init(int id, int starting_chamber, int bullet)
{
    int client = slots[id].client;

    SetEntityHealth(client,100);
    strip_all_weapons(client); // remove all the players weapons
    int weapon =  GivePlayerItem(client, "weapon_deagle");
    empty_weapon(client,weapon);

    
    slots[id].bullet_max = 1;

    slots[id].weapon = weapon;
    slots[id].weapon_string = "weapon_deagle"

    slots[id].bullet_chamber = bullet;
    slots[id].chamber = starting_chamber;

    slots[id].restrict_drop = true;
}

void start_russian_roulette(int t_slot, int ct_slot)
{
    int starting_chamber = GetRandomInt(0,5); 
    int bullet = GetRandomInt(0,5);

    russian_roulette_player_init(t_slot,starting_chamber,bullet);
    russian_roulette_player_init(ct_slot,starting_chamber,bullet);


    if(GetRandomInt(0,1) == 0)
    {
        PrintToChatAll("%s Randomly chose %N to go first",LR_PREFIX,slots[t_slot].client);
        set_lr_clip(t_slot);
    }

    else
    {
        PrintToChatAll("%s Randomly chose %N to go first",LR_PREFIX,slots[ct_slot].client);
        set_lr_clip(ct_slot);
    }
}