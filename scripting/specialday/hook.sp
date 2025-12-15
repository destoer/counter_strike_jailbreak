#if defined _HOOK_INCLUDE_included
 #endinput
#endif
#define _HOOK_INCLUDE_included


public void OnClientPutInServer(int client)
{
	// for sd
	SDKHook(client, SDKHook_TraceAttack, HookTraceAttack); // block damage
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip); // block weapon pickups
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}



//remove damage and aimpunch
public Action HookTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) 
{
	if(global_ctx.no_damage)
	{
		return Plugin_Handled;
	}
	
	
	return Plugin_Continue;
}

public Action PlayerDisconnect_Event(Handle event, const String:name[], bool dontBroadcast)
{

	int client = GetClientOfUserId(GetEventInt(event,"userid"));

	if(global_ctx.sd_state == sd_active)
	{
		bool boss_discon = global_ctx.boss == client;

		if(!boss_discon)
		{
			return Plugin_Continue;
		}

		if(global_ctx.cur_day.sd_discon_active != null)
		{		
			Call_StartFunction(null, global_ctx.cur_day.sd_discon_active);
			Call_PushCell(client);
			Call_Finish();
		}
	}

	return Plugin_Continue;
}


Menu sd_menu;
Menu sd_list_menu;

// Clean up our variables just to be on the safe side
public OnMapStart()
{
	
#if defined STORE
	store_kill_ammount_cvar = FindConVar("sm_store_credit_amount_kill");
	if(store_kill_ammount_cvar != null)
	{
		store_kill_ammount_backup = GetConVarInt(store_kill_ammount_cvar);
	}
#endif
	
	
	g_lbeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_lpoint = PrecacheModel("materials/sprites/glow07.vmt");	
	
	global_ctx.sd_state = sd_inactive;
	global_ctx.special_day = normal_day;
	disable_friendly_fire();

	gun_menu = build_gun_menu(WeaponHandler,false);
	sd_menu = build_sd_menu(SdHandler); // real sd select
	sd_list_menu = build_sd_menu(SdListHandler); // dummy sd menu for people to see sds
	
	#if defined USE_CUSTOM_ZOMBIE_MODEL
		zombie_model_success = CacheCustomZombieModel();
		if (!zombie_model_success)
		{
			PrecacheModel("models/zombie/classic.mdl");
		}
	#else
		PrecacheModel("models/zombie/classic.mdl");
	#endif
	
	PrecacheSound("npc/zombie/zombie_voice_idle1.wav");

#if defined CUSTOM_ZOMBIE_MUSIC
	AddFileToDownloadsTable("sound/music/HLA.mp3");
	PrecacheSound("music/HLA.mp3");
#else
	// dont know if we should loop this
	PrecacheSound("music/ravenholm_1.mp3");
#endif
	
	setup_sd_convar();

	SetupFog();
}

public OnMapEnd()
{
	delete gun_menu;
	delete sd_menu;
	delete sd_list_menu;
}



public Action OnRoundStart(Handle event, const String:name[], bool dontBroadcast)
{
	reset_use_key();
	EndSd();

	return Plugin_Continue;
}



public Action OnRoundEnd(Handle event, const String:name[], bool dontBroadcast)
{
#if defined SD_STANDALONE	

#else
	// if we have the required players and can still add rounds to the stockpile
	if(GetClientCount(true) >= ROUND_PLAYER_REQ && global_ctx.warden_sd_available < ROUND_STACK_LIM)
	{
		global_ctx.rounds_since_warden_sd += 1;
		// inc availiable reset round counter
		if(global_ctx.rounds_since_warden_sd >= ROUND_WARDEN_SD)
		{
			global_ctx.rounds_since_warden_sd = 0;
			global_ctx.warden_sd_available += 1;
		}
	}	


	if(global_ctx.warden_sd_available > 0)
	{
		PrintToChatAll("%s Warden sd available !wsd(%d)",SPECIALDAY_PREFIX,global_ctx.warden_sd_available);
	}
#endif
	
#if defined GANGS	
	if(global_ctx.sd_state == sd_active && check_command_exists("sm_gang"))
	{
		ServerCommand("sm plugins load hl_gangs.smx")
	}
#endif
	
	EndSd();
	return Plugin_Handled;
}



public Action OnPlayerHurt(Handle event, const String:name[], bool dont_broadcast)
{
	int hitgroup = GetEventInt(event, "hitgroup");

	if(global_ctx.sd_state == sd_active && global_ctx.special_day == headshot_day)
	{
		// if not a headshot cancel out damage
		if(hitgroup != HITGROUP_HEAD)
		{
			int victim = GetClientOfUserId(GetEventInt(event, "userid"));
			if(is_valid_client(victim))
			{
				// why cant i use setentityhealth here?
				SetEntProp(victim,Prop_Send,"m_iHealth",100,4);
			}
		}
	}

	return Plugin_Continue;
}

// make team damage the same as cross team damage

public Action OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(global_ctx.no_damage)
	{
		damage = 0.0;
		return Plugin_Changed;
	}

	// scale ff damage so its the same as standard dmg
	else if(global_ctx.ff)
	{
		if (is_ffa(victim, attacker) && inflictor == attacker)
		{
			damage /= 0.35;
		}	
	}

	// hook any sd damage modifications here
	if(global_ctx.sd_state != sd_inactive)
	{
		if(global_ctx.cur_day.sd_take_damage != null)
		{
			Call_StartFunction(null, global_ctx.cur_day.sd_take_damage);
			Call_PushCell(victim);
			Call_PushCell(attacker)
			Call_PushFloatRef(damage);
			Call_Finish();
			
			
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

public Action OnPlayerDeath(Handle event, const String:name[], bool dontBroadcast)
{

	if(global_ctx.hp_steal)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		if(is_valid_client(attacker))
		{
			// give the killer +100 hp
			int health = GetClientHealth(attacker);
			health += 100;
			SetEntityHealth(attacker, health);
		}
	}
	
	if(global_ctx.sd_state == sd_inactive)
	{
		return Plugin_Continue;
	}


	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	// if the kill is from friendly fire
	// set the score so it goes up instead of down
	if(is_ffa(victim, attacker) && is_valid_client(attacker))
	{
		int frags = GetEntProp(attacker,Prop_Data, "m_iFrags");
		SetEntProp(attacker, Prop_Data, "m_iFrags", frags + 2);
	}


	if(global_ctx.cur_day.sd_player_death != null)
	{
		Call_StartFunction(null, global_ctx.cur_day.sd_player_death);
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_Finish();
	}
	
	return Plugin_Continue;
}


// handle nade projectiles for a sd create timers to remove them :)
public OnEntityCreated(int entity, const String:classname[])
{
	
	if(global_ctx.sd_state == sd_inactive)
	{
		return;
	}	
	
	switch(global_ctx.special_day)
	{
	
		case dodgeball_day:
		{
			if (StrEqual(classname, "flashbang_projectile"))
			CreateTimer(1.4, GiveFlash, entity);
		}
		
		case grenade_day:
		{
			if (StrEqual(classname, "hegrenade_projectile"))
			CreateTimer(1.4, GiveGrenade, entity);
		}
		
		default: {}
	
	}
}

// prevent additional weapon pickups
// factor this out into each sd file
public Action OnWeaponEquip(int client, int weapon) 
{

	if(global_ctx.sd_state == sd_inactive)
	{
		return Plugin_Continue;
	}


	char weapon_string[32];
	GetEdictClassname(weapon, weapon_string, sizeof(weapon_string)); 


#if defined SD_STANDALONE

	// all sds
	if(StrEqual(weapon_string,"weapon_c4"))
	{
		return Plugin_Handled;
	}
#endif


	if(global_ctx.cur_day.sd_restrict_weapon != null)
	{
		Call_StartFunction(null, global_ctx.cur_day.sd_restrict_weapon);
		Call_PushCell(client);
		Call_PushString(weapon_string);
		bool allowed = false;
		Call_Finish(allowed);

		if(!allowed)
		{
			return Plugin_Handled;
		}
	}

	else
	{
		// no restrict
		if(StrEqual(global_ctx.weapon_restrict,""))
		{
			return Plugin_Continue;
		}

		if(!StrEqual(weapon_string,global_ctx.weapon_restrict))
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}



// handles movement changes off a ladder so they are what they should be for an sd

MoveType player_last_movement_type[MAXPLAYERS+1] = {MOVETYPE_WALK};


public Action check_movement(Handle Timer)
{
	// no sd running dont care
	if(global_ctx.sd_state == sd_inactive)
	{
		return Plugin_Continue;
	}
	

	for (int client = 1; client < MaxClients; client++)
	{
		// not interested is they are dead or not here
		if(is_valid_client(client) && is_on_team(client) && IsPlayerAlive(client))
		{
			
			// if it is different from the old one
			// and the old one is a ladder and we are on a sd
			// with different movement settings
			// reset the players move type
			MoveType cur_type = GetEntityMoveType(client);
			MoveType old_type = player_last_movement_type[client];
			if(cur_type != old_type && old_type == MOVETYPE_LADDER)
			{
				if(global_ctx.cur_day.sd_fix_ladder)
				{
					Call_StartFunction(null, global_ctx.cur_day.sd_fix_ladder);
					Call_PushCell(client);
					Call_Finish();
				}
			}
			
			//cache the last movement type
			player_last_movement_type[client] = cur_type
		}
	}	

		
	return Plugin_Continue;
}

bool use_key[MAXPLAYERS+1] = {false};

void reset_use_key()
{
	for (int i = 0; i <= MAXPLAYERS; i++)
	{
		use_key[i] = false;
	}
}


// hook for laser day :)
// add callbacks if other sds do need to use this
public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
	// cant use while dead	
	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	// if not an sd we dont care
	if(global_ctx.sd_state == sd_inactive)	
	{
		return Plugin_Continue;
	}
	
	bool in_use = (buttons & IN_USE) == IN_USE;
	
	// kill laser
	if(in_use && global_ctx.special_day == laser_day && global_ctx.sd_state == sd_active && client == global_ctx.boss)
	{
		setup_laser(client,{ 1, 153, 255, 255 },g_lbeam,g_lpoint,true);
	}	

	// use key press toggle fly day move type
	else if(in_use && !use_key[client] && global_ctx.special_day == fly_day)
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

	use_key[client] = in_use;
	
	return Plugin_Continue;
}
