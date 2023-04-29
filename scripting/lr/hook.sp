void purge_state()
{
    rebel_lr_active = false;
    lr_ready = false;

    for(int i = 0; i < LR_SLOTS; i++)
    {
        end_lr(slots[i]);
    
    }

    reset_use_key();        
}

public Action OnRoundStart(Handle event, const String:name[], bool dontBroadcast)
{
    purge_state();
}

public Action OnRoundEnd(Handle event, const String:name[], bool dontBroadcast)
{
    purge_state();
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


    int unused;
    int alive_t = get_alive_team_count(CS_TEAM_T,unused);

    if(alive_t == (LR_SLOTS / 2) && !lr_ready)
    {
        lr_ready = true;
        PrintToChatAll("%s Last request is now ready type !lr",LR_PREFIX);
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
            case mag_for_mag:
            {
                slots[id].bullet_count -= 1;

                if(!slots[id].bullet_count)
                {
                    int partner = slots[id].partner;
                    set_lr_clip(partner);
                }
            }

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
                    return Plugin_Handled;
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

    return Plugin_Continue;
}

public Action PlayerDisconnect_Event(Handle event, const String:name[], bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event,"userid"));

    if(client == console)
    {
        console = -1;
    }

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
    // both not in lr
    if(!in_lr(victim) && !in_lr(attacker))
    {
        return Plugin_Continue;
    }

    // not in the same lr
    else if(!is_pair(attacker,victim))
    {
        return Plugin_Handled;
    }

    int id = get_slot(attacker);
    int partner = slots[id].partner;

    switch(slots[id].type)
    {
        case gun_toss:
        {
            // cant do damange until gun has been dropped
            if(!slots[partner].gun_dropped  && !slots[id].gun_dropped)
            {
                return Plugin_Handled;
            }
        }
    /*
        case race:
        {
            return Plugin_Handled;
        }
    */        
    }
    

    return Plugin_Continue;
}


public Action OnPlayerHurt(Handle event, const String:name[], bool dont_broadcast)
{
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    // both not in lr
    if(!in_lr(victim) && !in_lr(attacker))
    {
        return Plugin_Continue;
    }

    // not in the same lr
    else if(!is_pair(attacker,victim))
    {
        return Plugin_Handled;
    }


    int hitgroup = GetEventInt(event, "hitgroup");

    int id = get_slot(attacker);

    switch(slots[id].type)
    {
        case headshot_only:
        {
            // if not a headshot cancel out damage
            if(hitgroup != HITGROUP_HEAD)
            {
                if(is_valid_client(victim))
                {
                    // why cant i use setentityhealth here?
                    SetEntProp(victim,Prop_Send,"m_iHealth",100,4);
                }
            }
        }
    }


    return Plugin_Continue;
}



// make team damage the same as cross team damage

public Action OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if(!in_lr(victim) && !in_lr(attacker))
    {
        return Plugin_Continue;
    }

    // not in the same lr
    else if(!is_pair(attacker,victim))
    {
        damage = 0.0;
        return Plugin_Changed;
    }


    int id = get_slot(attacker);
    int partner = slots[id].partner;


    // now in the same lr
    switch(slots[id].type)
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
            // cant do damange until a gun has been dropped
            if(!slots[partner].gun_dropped && !slots[id].gun_dropped)
            {
                damage = 0.0;
                return Plugin_Changed;
            }
        }
    /*
        case race:
        {
            damage = 0.0;
            return Plugin_Changed;
        }
    */
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
            if(console != -1)
            {
                PrintToConsole(console,"%s restrict '%s' : '%s'",LR_PREFIX,weapon_string,slots[id].weapon_string);
            }

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
            // only mark the first drop
            if(slots[id].gun_dropped)
            {
                return Plugin_Continue;
            }

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


public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
    bool in_use = (buttons & IN_USE) == IN_USE;

    int id = get_slot(client);

    if(id == INVALID_SLOT)
    {
        return Plugin_Continue;
    }


    switch(slots[id].type)
    {
        case knife_fight:
        {
            if(view_as<knife_choice>(slots[id].option) == knife_fly)
            {
                if(in_use && !use_key[client])
                {
                    if(GetEntityMoveType(client) == MOVETYPE_FLY)
                    {
                        SetEntityMoveType(client, MOVETYPE_WALK);
                    }
                    
                    else
                    {
                        SetEntityMoveType(client, MOVETYPE_FLY);
                    }
                }
            }
        }
    }


    use_key[client] = in_use;

    return Plugin_Continue;
}

public OnMapStart()
{
    lr_menu = build_lr_menu();

    g_lbeam = PrecacheModel("materials/sprites/laserbeam.vmt");

    purge_state();
}

public OnMapEnd()
{
    purge_state();

    delete lr_menu;
}