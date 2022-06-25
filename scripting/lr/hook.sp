

public Action OnRoundEnd(Handle event, const String:name[], bool dontBroadcast)
{
    for(int i = 0; i < LR_PAIRS; i++)
    {
        end_lr(pairs[i]);
    }    
}

public Action OnPlayerDeath(Handle event, const String:name[], bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    int id = get_pair(victim);

    if(id != INVALID_PAIR)
    {
        LrPair pair;

        pair = pairs[id];

        if(victim == pair.ct)
        {
            PrintToChatAll("%s %N won %s, %N lost\n",LR_PREFIX,pair.t,lr_list[pair.type],pair.ct);
        }

        else
        {
            PrintToChatAll("%s %N won %s, %N lost\n",LR_PREFIX,pair.ct,lr_list[pair.type],pair.t);
        }

        end_lr(pairs[id]);
    }
}

public Action PlayerDisconnect_Event(Handle event, const String:name[], bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event,"userid"));

    int id = get_pair(client);

    if(id != INVALID_PAIR)
    {
        PrintToChat(client,"%s %s disconnected during LR",LR_PREFIX,client);
        end_lr(pairs[id]);
    }
}

//remove damage and aimpunch
public Action HookTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) 
{
    // if player is in a lr only allow damage to partner
    int id = get_pair(attacker);

    if(id == INVALID_PAIR)
    {
        return Plugin_Continue;
    }


    LrPair pair;
    pair = pairs[id];

    if(victim == pair.ct)
    {
        if(attacker != pair.t)
        {
            return Plugin_Handled;
        }
    }


    else if(victim == pair.t)
    {
        if(attacker != pair.ct)
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
    int id = get_pair(attacker);

    if(id == INVALID_PAIR)
    {
        return Plugin_Continue;
    }


    LrPair pair;
    pair = pairs[id];

    if(victim == pair.ct)
    {
        // attack is not other partner, there is no damage
        if(attacker != pair.t)
        {
            damage = 0.0;
            return Plugin_Handled;
        }
    }


    else if(victim == pair.t)
    {
        // attacker is not other partner there is no damage
        if(attacker != pair.ct)
        {
            damage = 0.0;
            return Plugin_Handled;            
        }
    }


    switch(pair.type)
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
    int id = get_pair(client);

    if(id == INVALID_PAIR)
    {
        return Plugin_Continue;
    }

    LrPair pair;
    pair = pairs[id];

    //print_pair(client,pair);

    char weapon_string[32];
    GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 


    switch(pair.type)
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
    }

    return Plugin_Continue;
}

public Action OnEntitySpawn(int entity)
{
    char classname[64];
    GetEntityClassname(entity,classname,sizeof(classname) - 1);

    int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
    int id = get_pair(client);

    if(id == INVALID_PAIR)
    {
        return;
    }

    switch(pairs[id].type)
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

    int id = get_pair(client);

    if(id == INVALID_PAIR)
    {
        return Plugin_Continue;
    }


    switch(pairs[id].type)
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
    int id = get_pair(client);

    if(id == INVALID_PAIR)
    {
        return Plugin_Continue;
    }

    switch(pairs[id].type)
    {
        case gun_toss:
        {
            if(weapon == pairs[id].ct_weapon)
            {


            }

            else if(weapon == pairs[id].t_weapon)
            {
               GetClientAbsOrigin(pairs[id].t, pairs[id].t_pos);
               CreateTimer(0.1, get_gun_end, pack_int(id,pairs[id].t) ,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }

    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    // for sd
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