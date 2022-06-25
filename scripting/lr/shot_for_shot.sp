

void shot_for_shot_player_init(int id)
{
    int client = slots[id].client;

    strip_all_weapons(client); // remove all the players weapons
    int weapon = GivePlayerItem(client, "weapon_deagle");
    SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);

    slots[id].bullet_max = 1;
    slots[id].weapon = weapon;

    empty_weapon(client,weapon);
}

void start_shot_for_shot(int t_slot, int ct_slot)
{
    shot_for_shot_player_init(t_slot);
    shot_for_shot_player_init(ct_slot);


    if(GetRandomInt(0,1) == 0)
    {
        PrintToChatAll("%s Randomly chose %N to shoot first",LR_PREFIX,slots[t_slot].client);
        set_lr_clip(t_slot);
    }

    else
    {
        PrintToChatAll("%s Randomly chose %N to shoot first",LR_PREFIX,slots[ct_slot].client);
        set_lr_clip(ct_slot);
    }
}
