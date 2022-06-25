

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
        
        // end both peoples lr
        end_lr(slots[id]);
        end_lr(slots[slots[id].partner]);
    }

}

public Action PlayerDisconnect_Event(Handle event, const String:name[], bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event,"userid"));

    int id = get_slot(client);

    if(id != INVALID_SLOT)
    {
        PrintToChat(client,"%s %s disconnected during LR",LR_PREFIX,client);
        end_lr(slots[id]);
    }
}

//remove damage and aimpunch
public Action HookTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) 
{
    // if player is in a lr only allow damage to partner
    int id = get_slot(attacker);

    if(id == INVALID_SLOT)
    {
        return Plugin_Continue;
    }


    LrSlot slot;
    slot = slots[id];

    if(victim == slot.client)
    {
        // attack is not other partner, there is no damage
        if(attacker != slots[slot.partner].client)
        {
            return Plugin_Handled;
        }
    }


    return Plugin_Continue;
}

// make team damage the same as cross team damage

public Action OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    // if player is in a lr only allow damage to partner
    int id = get_slot(attacker);

    if(id == INVALID_SLOT)
    {
        return Plugin_Continue;
    }


    LrSlot slot;
    slot = slots[id];

    if(victim == slot.client)
    {
        // attack is not other partner, there is no damage
        if(attacker != slots[slot.partner].client)
        {
            damage = 0.0;
            return Plugin_Handled;
        }
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


    switch(slot.type)
    {
        case knife_fight:
        {
            if(!StrEqual(weapon_string,"weapon_knife"))
            {
                return Plugin_Handled;
            }      
        }

        case dodgeball:
        {
            if(!StrEqual(weapon_string,"weapon_flashbang"))
            {
                return Plugin_Handled;
            }            
        }

        case no_scope:
        {
            if(!StrEqual(weapon_string,"weapon_awp"))
            {
                return Plugin_Handled;
            }               
        }

        case shot_for_shot:
        {
            if(!StrEqual(weapon_string,"weapon_deagle"))
            {
                return Plugin_Handled;
            }                           
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

    switch(slots[id].type)
    {
        case gun_toss:
        {
            if(weapon == slots[id].weapon)
            {
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