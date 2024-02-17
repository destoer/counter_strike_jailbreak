// this seems overkill put the m_owner members aernt working..
int weapon_owner[2048];

void purge_state()
{
    rebel_lr_active = false;
    knife_rebel_active = false;
    lr_ready = false;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(is_valid_client(i))
        {
            SetEntityGravity(i,1.0);
            set_client_speed(i,1.0);
        }
    }

    for(int i = 0; i < LR_SLOTS; i++)
    {
        end_lr(slots[i]);
    }

    for(int i = 0; i < 2048; i++)
    {
        weapon_owner[i] = 0;
    }

    reset_use_key();        
}


public Action OnRoundStart(Handle event, const String:name[], bool dontBroadcast)
{
    start_timestamp = GetTime();

    purge_state();
    return Plugin_Continue;
}

public Action OnRoundEnd(Handle event, const String:name[], bool dontBroadcast)
{
    if(rebel_lr_active)
    {
        int player;
        int count = get_alive_team_count(CS_TEAM_T,player);

        if(is_valid_client(player))
        {
            // if t is alive then they have won
            bool won = count != 0;

            lr_type type = knife_rebel_active? knife_rebel : rebel;

            if(won)
            {
                lr_win(player,type);
            }

            else
            {
                lr_lose(player,type);
            }
        }
    }

    purge_state();
    return Plugin_Continue;
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

            int partner = slots[slot.partner].client;

            lr_lose(victim,slot.type);
            lr_win(partner,slot.type);

            int idx = view_as<int>(slot.type);

            print_lr_stat_all(victim,idx);
            print_lr_stat_all(partner,idx);
        }
        
        int partner = slots[id].partner;
        end_lr_pair(id,partner);
    }


    int unused;
    int alive_t = get_alive_team_count(CS_TEAM_T,unused);

    if(alive_t == (LR_SLOTS / 2) && !lr_ready && GetClientTeam(victim) == CS_TEAM_T && lr_cvar.IntValue == 1)
    {
        lr_ready = true;
        PrintToChatAll("%s Last request is now ready type !lr",LR_PREFIX);

        if(lr_sound_cached)
        {
            EmitSoundToAll("lr/lr_enabled.mp3");
        }
        
        int clients[MAXPLAYERS + 1];

        int count = filter_team(CS_TEAM_T,clients,true);

        for(int i = 0; i < count; i++)
        {
            // give a extra chance by here
            add_db_client(clients[i]);

            command_lr_internal(clients[i]);
        }
    }

    return Plugin_Continue;

}

public Action kill_delay(Handle timer, int client)
{
    if(is_valid_client(client) && in_lr(client))
    {
        ForcePlayerSuicide(client);
    }

    return Plugin_Continue;
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

                    // delay the player slay to make sure that they die after all bullets have hit
                    CreateTimer(0.5,kill_delay,client,TIMER_FLAG_NO_MAPCHANGE);
                    return Plugin_Handled;
                }

                else
                {
                    PrintToChatAll("%s click!",LR_PREFIX);
                }

                slots[id].chamber = (slots[id].chamber + 1) % 6;

                int partner = slots[id].partner;

                slots[partner].chamber = (slots[partner].chamber + 1) % 6;
                return Plugin_Handled;
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

    clear_stat(client);

    return Plugin_Continue;
}

public void OnClientAuthorized(int client, const char[] auth)
{
    clear_stat(client);

    CreateTimer(10.0,load_from_db_callback,client,TIMER_FLAG_NO_MAPCHANGE);
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
            if(!slots[partner].dropped_once  && !slots[id].dropped_once)
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

        case grenade:
        {
            if(slots[id].failsafe)
            {
                damage = damage * 5.0;
                return Plugin_Changed;
            }
        }

        case russian_roulette:
        {
            damage = 0.0;
            return Plugin_Changed;
        }

        case gun_toss:
        {
            // cant do damange until a gun has been dropped
            if(!slots[partner].dropped_once && !slots[id].dropped_once)
            {
                damage = 0.0;
                return Plugin_Changed;
            }
        }

        case crash:
        {
            damage = 0.0;
            return Plugin_Changed;
        }

        case sumo:
        {
            if(!slots[id].failsafe)
            {
                SlapPlayer(victim,0,true);
                damage = 0.0;
                return Plugin_Changed
            }

            // this has gone on too long start inflicting damage
            else
            {
                SlapPlayer(victim,15,true);
            }

            return Plugin_Continue;
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


// prevent lr team swaps
public Action player_team(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid")); 

    // extra load
    load_from_db(client);

    int id = get_slot(client);

    if(id != INVALID_SLOT)
    {
        end_lr_pair(id,slots[id].partner);
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

    switch(slots[id].type)
    {
        case gun_toss:
        {
            slots[id].gun_dropped = false;    
        }
    }

    return Plugin_Continue;    
}

public Action OnWeaponCanUse(int client, int weapon) 
{

    if(!is_valid_client(client))
    {
        return Plugin_Continue;
    }

    char weapon_string[32];
    GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 

    if(knife_rebel_active)
    {
        if(!StrEqual(weapon_string,"weapon_knife"))
        {
            return Plugin_Handled;
        }
    }

    int id = get_slot(client);

    int prev_owner = -1;

    if(is_valid_ent(weapon))
    {
        prev_owner = weapon_owner[weapon]; 
    }

    int owner_slot = get_slot(prev_owner);

    // if prev owner aint in lr this is fine
    if(owner_slot != INVALID_SLOT)
    {
        switch(slots[owner_slot].type)
        {
            case gun_toss:
            {
                // only prev owner can pick up dropped gun if alive
                // unless its map spawned
                if(prev_owner != client && prev_owner != 0 && IsPlayerAlive(prev_owner))
                {
                    return Plugin_Handled;
                }
            }
        }

        return Plugin_Continue;
    }

    if(id == INVALID_SLOT)
    {
        return Plugin_Continue;
    }

    //print_slot(client,slot[id]);

    // if we have a string
    if(slots[id].weapon_string[0])
    {
        if(!StrEqual(weapon_string,slots[id].weapon_string))
        {
            // two weapons fine in scout  knife
            if(StrEqual(weapon_string,"weapon_knife") && slots[id].type == scout_knife)
            {
                return Plugin_Continue;
            }

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
        return Plugin_Continue;
    }

    switch(slots[id].type)
    {
        case dodgeball:
        {
            if (StrEqual(classname, "flashbang_projectile") || (slots[id].failsafe && StrEqual(classname, "hegrenade_projectile")))
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

    return Plugin_Continue;
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
        if(is_valid_ent(weapon))
        {
            weapon_owner[weapon] = client;
        }

        return Plugin_Continue;
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
                slots[id].dropped_once = true;

                // no drawing if dropped once
                if(slots[id].timer == null)
                {
                    GetClientAbsOrigin(slots[id].client, slots[id].pos);
                    CreateTimer(0.3, get_gun_end, id ,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
                }
            }
        }

        case crash:
        {
            // only mark the first drop
            if(slots[id].dropped_once)
            {
                return Plugin_Handled;
            }

            slots[id].dropped_once = true;

            int ct_slot = GetClientTeam(client) == CS_TEAM_CT? id : slots[id].partner;

            slots[id].crash_stop = slots[ct_slot].delay;

            slots[id].dropped_last = client;
            slots[slots[id].partner].dropped_last = client;

            PrintToChat(client,"%s dropped at %d",LR_PREFIX,slots[id].crash_stop);

            // dont actually drop the gun so the other player cant see what time was picked
            return Plugin_Handled;
        }
    }

    if(slots[id].restrict_drop)
    {
        return Plugin_Handled;
    }

    if(is_valid_ent(weapon))
    {
        weapon_owner[weapon] = client;
    }

    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_TraceAttack, HookTraceAttack); // block damage
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse); // block weapon pickups
    SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip); // block weapon pickups
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}


bool intersects_circle_origin(float origin[3], float radius, float pos[3])
{
    float v2[3]
    float v1[3]

    for(int i = 0; i < 2 ;i++)
    {
        v1[i] = origin[i];
        v2[i] = pos[i];
    }

    // ignore z
    v2[2] = 0.0;
    v1[2] = 0.0;

    // why is this / 2!?
    return GetVectorDistance(v1, v2,false) <= radius / 2;
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

        case sumo:
        {
            float vec[3];
            GetClientAbsOrigin(slots[id].client,vec);

            // player is outside of ring kill them
            if(!intersects_circle_origin(slots[id].pos,SUMO_RADIUS,vec))
            {
                ForcePlayerSuicide(slots[id].client);
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
    g_lhalo = PrecacheModel("materials/sprites/halo01.vmt");

    gun_menu = build_gun_menu(WeaponHandler,false);

    purge_state();

    AddFileToDownloadsTable("sound/lr/lr_enabled.mp3");
    lr_sound_cached = PrecacheSound("lr/lr_enabled.mp3");
    PrecacheSound("buttons/blip1.wav");
}

public OnMapEnd()
{
    purge_state();

    delete gun_menu;
    delete lr_menu;
}