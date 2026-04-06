void end_lr(LrSlot slot)
{
    int client = slot.player.client;

    if(is_valid_client(client) && IsPlayerAlive(client))
    {
        SetEntityHealth(client,100);
        strip_all_weapons(client);
        SetEntityGravity(client,1.0);
        set_client_speed(client,1.0);

        if(GetEntityMoveType(client) == MOVETYPE_FLY)
        {
            PrintToChatAll("%s LR finished moving %N back to spawn",LR_PREFIX,client);
            CS_RespawnPlayer(client);
        }

        SetEntityMoveType(client, MOVETYPE_WALK);        

        if(GetClientTeam(client) == CS_TEAM_CT)
        {
            GivePlayerItem(client,"weapon_knife");
            GivePlayerItem(client,"weapon_m4a1");
        }

        else
        {
       
            GivePlayerItem(client,"weapon_knife");
        }
    }

    slot.state = lr_inactive;
    slot.failsafe = false;

    slot.player.client = -1;
    slot.player.slot = -1;
    slot.player.hash = -1;

    slot.partner.client = -1;
    slot.partner.slot = -1;
    slot.partner.hash = -1;

    slot.option = 0;

    slot.weapon = -1;
    slot.restrict_drop = false;
    slot.weapon_string = "";

    slot.restrict_damage = false;

    slot.delay = 0;

    kill_handle(slot.start_timer);
    kill_handle(slot.failsafe_timer);
    end_line(slot);
}

int weapon_owner[2048];

void purge_state()
{
    global_ctx.rebel_lr_active = false;
    global_ctx.lr_ready = false;
    global_ctx.lr_ready = false;

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
}


public Action OnRoundStart(Handle event, char[] name, bool dontBroadcast)
{
    purge_state();
    global_ctx.start_timestamp = GetTime();

    return Plugin_Continue;
}

public Action OnRoundEnd(Handle event, const String:name[], bool dontBroadcast)
{
    purge_state();
    return Plugin_Continue;
}

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

    if(slots[id].restrict_damage)
    {
        damage = 0.0;
        return Plugin_Changed;      
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
    // SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip); // block weapon pickups
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}


public Action OnWeaponCanUse(int client, int weapon) 
{
    if(!is_valid_client(client))
    {
        return Plugin_Continue;
    }

    char weapon_string[32];
    GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 

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
            if(global_ctx.console != -1)
            {
                PrintToConsole(global_ctx.console,"%s restrict '%s' : '%s'",
                    LR_PREFIX,weapon_string,slots[id].weapon_string);
            }

            return Plugin_Handled;
        }         
    }

    return Plugin_Continue;
}


//remove damage and aimpunch
public Action HookTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, 
    int &weapon, float damageForce[3], float damagePosition[3]) 
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

    // Prevent damage before LR starts
    if(slots[id].state != lr_active)
    {
        return Plugin_Handled;
    }

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

        if(victim == slot.player.client)
        {

            PrintToConsoleAll("LR OVER");
            PrintToChatAll("%s %N won %s, %N lost\n",LR_PREFIX,slot.partner.client,slot.impl.name,slot.player.client);

            // lr_lose(slot.player,slot.impl.lr_type);
            // lr_win(slot.partner,slot.player,slot.impl.lr_type);

            // int idx = view_as<int>(slot.type);

            // print_lr_stat_all(victim,idx);
            // print_lr_stat_all(partner,idx);
        }
        
        int partner = slots[id].partner.slot;
        end_lr_pair(id,partner);
    }


    int unused;
    int alive_t = get_alive_team_count(CS_TEAM_T,unused);

    if(alive_t == (LR_SLOTS / 2) && !global_ctx.lr_ready && GetClientTeam(victim) == CS_TEAM_T && lr_cvar.IntValue == 1)
    {
        // inform that lr is now enabled
        Call_StartForward(lr_enabled_forward);
        Call_Finish(unused);

        global_ctx.lr_ready = true;
        PrintToChatAll("%s Last request is now ready type !lr",LR_PREFIX);

        if(global_ctx.lr_sound_cached)
        {
            EmitSoundToAll("lr/lr_enabled.mp3");
        }
        
        int clients[MAXPLAYERS + 1];

        int count = filter_team(CS_TEAM_T,clients,true);

        for(int i = 0; i < count; i++)
        {
            // // give a extra chance by here
            // add_db_client(clients[i]);

            command_lr_internal(clients[i]);
        }
    }

    return Plugin_Continue;

}

public OnMapStart()
{
    global_ctx.lbeam = PrecacheModel("materials/sprites/laserbeam.vmt");
    global_ctx.halo = PrecacheModel("materials/sprites/halo01.vmt");

    purge_state();

    AddFileToDownloadsTable("sound/lr/lr_enabled.mp3");
    global_ctx.lr_sound_cached = PrecacheSound("lr/lr_enabled.mp3");
    PrecacheSound("buttons/blip1.wav");

    setup_config();
}

public OnMapEnd()
{
    purge_state();
}