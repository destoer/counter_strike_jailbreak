public Action OnRoundEnd(Handle event, const String:name[], bool dontBroadcast)
{
    for(int i = 0; i < LR_SLOTS; i++)
    {
        end_lr(slots[i]);
    }    
}

public Action OnPlayerDeath(Handle event, const String:name[], bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    int id = get_slot(victim);

    if(id != INVALID_SLOT)
    {
        LrSlot slot;

        slot = slots[id];

        if(victim == slot.client)
        {
            PrintToChatAll("%s %N won %s, %N lost\n",LR_PREFIX,slots[slot.partner].client,lr_list[slot.type],slot.client);
        }
        
        int partner = slots[id].partner;
        end_lr_pair(id,partner);
    }

}

public Action OnWeaponFire(Handle event, const String:name[], bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event,"userid"));
    int id = get_slot(client);

    if(id != INVALID_SLOT)
    {
        switch(slots[id].type)
        {
            case shot_for_shot:
            {
                slots[id].bullet_count -= 1;

                if(!slots[id].bullet_count)
                {
                    int partner = slots[id].partner;
                    set_lr_clip(partner);
                }
            }

            case russian_roulette:
            {
                slots[id].bullet_count -= 1;

                if(!slots[id].bullet_count)
                {
                    int partner = slots[id].partner;
                    set_lr_clip(partner);
                }

                if(slots[id].chamber == slots[id].bullet_chamber)
                {
                    PrintToChatAll("%s BANG!",LR_PREFIX);
                    ForcePlayerSuicide(client);
                }

                else
                {
                    PrintToChatAll("%s click!",LR_PREFIX);
                }

                slots[id].chamber = (slots[id].chamber + 1) % 6;

                int partner = slots[id].partner;

                slots[partner].chamber = (slots[partner].chamber + 1) % 6;
            }
        }
    }

}

public Action PlayerDisconnect_Event(Handle event, const String:name[], bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event,"userid"));

    int id = get_slot(client);

    if(id != INVALID_SLOT)
    {
        PrintToChat(client,"%s %s disconnected during LR",LR_PREFIX,client);

        int partner = slots[id].partner;
        end_lr_pair(id,partner);
    }
}

//remove damage and aimpunch
public Action HookTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) 
{
    // if player is in a lr only allow damage to partner
    int id = get_slot(victim);

    if(id == INVALID_SLOT)
    {
        return Plugin_Continue;
    }


    LrSlot slot;
    slot = slots[id];

    // rebel etc, attack anyone
    if(slot.partner == INVALID_SLOT)
    {
        return Plugin_Continue;
    }

    // attack is not other partner, there is no damage
    if(attacker != slots[slot.partner].client)
    {
        return Plugin_Handled;
    }
    
    switch(slot.type)
    {
        case gun_toss:
        {
            int partner = slots[id].partner;

            // cant do damange until gun has been dropped
            if(!slots[partner].gun_dropped  && !slots[id].gun_dropped)
            {
                return Plugin_Handled;
            }
        }        
    }

    return Plugin_Continue;
}

// make team damage the same as cross team damage

public Action OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    // if player is in a lr only allow damage to partner
    int id = get_slot(victim);

    if(id == INVALID_SLOT)
    {
        return Plugin_Continue;
    }


    LrSlot slot;
    slot = slots[id];

    // rebel etc, attack anyone
    if(slot.partner == INVALID_SLOT)
    {
        return Plugin_Continue;
    }


    // attack is not other partner, there is no damage
    if(attacker != slots[slot.partner].client)
    {
        damage = 0.0;
        return Plugin_Changed;
    }
    

    switch(slot.type)
    {
    
        case dodgeball:
        {
            // any damage kills 
            // prevents cheaters from healing 
            damage = 500.0;

            return Plugin_Changed;
        }

        case russian_roulette:
        {
            damage = 0.0;
            return Plugin_Changed;
        }

        case gun_toss:
        {
            int partner = slots[id].partner;

            // cant do damange until a gun has been dropped
            if(!slots[partner].gun_dropped && !slots[id].gun_dropped)
            {
                damage = 0.0;
                return Plugin_Changed;
            }
        }
    }

    return Plugin_Continue;
}

public Action OnWeaponEquip(int client, int weapon) 
{
    int id = get_slot(client);

    if(id == INVALID_SLOT)
    {
        return Plugin_Continue;
    }

    LrSlot slot;
    slot = slots[id];

    //print_slot(client,slot);

    char weapon_string[32];
    GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 

    // if we have a string
    if(slots[id].weapon_string[0])
    {
        if(!StrEqual(weapon_string,slots[id].weapon_string))
        {
            return Plugin_Handled;
        }         
    }

    return Plugin_Continue;
}

public Action OnEntitySpawn(int entity)
{
    char classname[64];
    GetEntityClassname(entity,classname,sizeof(classname) - 1);

    int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
    int id = get_slot(client);

    if(id == INVALID_SLOT)
    {
        return;
    }

    switch(slots[id].type)
    {
        case dodgeball:
        {
            if (StrEqual(classname, "flashbang_projectile"))
            {
                CreateTimer(1.4, GiveFlash, entity);
            }
        }

		case grenade:
		{
			if (StrEqual(classname, "hegrenade_projectile"))
            {
			    CreateTimer(1.4, GiveGrenade, entity);
            }
		}
    }
}

public OnEntityCreated(int entity, const String:classname[])
{
    SDKHook(entity, SDKHook_Spawn, OnEntitySpawn); 
}
		

public Action OnWeaponZoom(Handle event, const String:weaponName[], bool dontBroadcast)
{

    int client = GetClientOfUserId(GetEventInt(event,"userid"));

    int id = get_slot(client);

    if(id == INVALID_SLOT)
    {
        return Plugin_Continue;
    }


    switch(slots[id].type)
    {
        case no_scope:
        {
            strip_all_weapons(client);
            CreateTimer(0.1,give_no_scope,client);
        }
    }

    return Plugin_Continue;
}


public Action OnWeaponDrop(int client, int weapon) 
{
    int id = get_slot(client);

    if(id == INVALID_SLOT)
    {
        return Plugin_Continue;
    }

    if(slots[id].restrict_drop)
    {
        return Plugin_Handled;
    }

    switch(slots[id].type)
    {
        case gun_toss:
        {
            if(weapon == slots[id].weapon)
            {
                slots[id].gun_dropped = true;
                GetClientAbsOrigin(slots[id].client, slots[id].pos);
                CreateTimer(0.1, get_gun_end, id ,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_TraceAttack, HookTraceAttack); // block damage
    SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip); // block weapon pickups
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public OnMapStart()
{
    lr_menu = build_lr_menu();

    g_lbeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnMapEnd()
{
    delete lr_menu;
}