/*
**
*/
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
		if(no_damage)
		{
			return Plugin_Handled;
		}
		
		
		return Plugin_Continue;
}

public Action PlayerDisconnect_Event(Handle event, const String:name[], bool dontBroadcast)
{

	int client = GetClientOfUserId(GetEventInt(event,"userid"));


	if(sd_state == sd_started)
	{
		switch(special_day)
		{
			case tank_day:
			{
				if(client == tank)
				{
					tank_discon_started(client);
				}
			}
			
			case spectre_day:
			{
				if(client == spectre)
				{
					spectre_discon_started(client);
				}
			}
			
			
			case zombie_day:
			{
				if(client == patient_zero)
				{
					zombie_discon_started(client);
				}
			}


			case laser_day:
			{
				if(client == laser_tank)
				{
					laser_discon_started(client);
				}
			}
			
			default: {}
		}
	}
	
	else if(sd_state == sd_active)
	{
		switch(special_day)
		{
			case tank_day:
			{	
				if(client == tank)
				{
					tank_discon_active(client);
				}
			}
			
			case spectre_day:
			{
				if(client == spectre)
				{
					spectre_discon_active(client);
				}
			}
			
			
			case zombie_day:
			{
				if(client == patient_zero)
				{
					zombie_discon_active(client);
				}
			}

			case laser_day:
			{
				if(client == laser_tank)
				{
					laser_discon_active(client);
				}
			}

			
			default: {}
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
	
	sd_state = sd_inactive;
	special_day = normal_day;
	disable_friendly_fire();
	tank = -1;
	patient_zero = -1;
	
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

	
	// create fog controller
	int ent;

	ent = FindEntityByClassname(-1, "env_fog_controller");

	if(ent == -1)
	{
		ent = CreateEntityByName("env_fog_controller");
		DispatchSpawn(ent); 
	}	
	
	fog_ent = ent;
	SetupFog();
	AcceptEntityInput(fog_ent, "TurnOff");
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
	if(GetClientCount(true) >= ROUND_PLAYER_REQ && warden_sd_available < ROUND_STACK_LIM)
	{
		rounds_since_warden_sd += 1;
		// inc availiable reset round counter
		if(rounds_since_warden_sd >= ROUND_WARDEN_SD)
		{
			rounds_since_warden_sd = 0;
			warden_sd_available += 1;
		}
	}	


	if(warden_sd_available > 0)
	{
		PrintToChatAll("%s Warden sd available !wsd(%d)",SPECIALDAY_PREFIX,warden_sd_available);
	}
#endif
	
#if defined GANGS	
	if(sd_state == sd_active && check_command_exists("sm_gang"))
	{
		ServerCommand("sm plugins load hl_gangs.smx")
	}
#endif
	fr = false;
	no_damage = false;
	EndSd();
	return Plugin_Handled;
}



public Action OnPlayerHurt(Handle event, const String:name[], bool dont_broadcast)
{
	int hitgroup = GetEventInt(event, "hitgroup");

	if(sd_state == sd_active && special_day == headshot_day)
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

	if(no_damage)
	{
		damage = 0.0;
		return Plugin_Changed;
	}

	// scale ff damage so its the same as standard dmg
	else if(ff)
	{
		if (is_ffa(victim, attacker) && inflictor == attacker)
		{
			damage /= 0.35;
		}	
	}

	// hook any sd damage modifications here
	if(sd_state != sd_inactive)
	{
		switch(special_day)
		{
		
			case dodgeball_day:
			{
				// any damage kills 
				// prevents cheaters from healing 
				damage = 500.0;
			}
			
			
			case zombie_day:
			{
				if (!is_valid_client(attacker)) { return Plugin_Continue; }
				
				// knockback is way to overkill on csgo
				if(GetClientTeam(victim) == CS_TEAM_T && GetEngineVersion() == Engine_CSS)
				{
					CreateKnockBack(victim, attacker, damage);
				}
				

				// patient zero instantly kills
				else if(attacker == patient_zero)
				{
					damage = 120.0;
				}
				
			}
			
			// spectre instant kills everyone
			case spectre_day:
			{
				if(attacker == spectre)
				{
					damage = 120.0;
				}	
			}

			default: {}
		}
		return Plugin_Changed;
	}

	return Plugin_Continue;
}


//float death_cords[MAXPLAYERS+1][3];
// int player_kills[MAXPLAYERS+1] =  { 0 }; ^ defined above
public Action OnPlayerDeath(Handle event, const String:name[], bool dontBroadcast)
{

	if(hp_steal)
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		// give the killer +100 hp
		int health = GetClientHealth(attacker);
		health += 100;
		SetEntityHealth(attacker, health);
	}
	
	if(sd_state == sd_inactive)
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

	switch(special_day)
	{
		case zombie_day:
		{
			zombie_death(victim);
		}
		
		case scoutknife_day:
		{	
			scoutknife_death(attacker, victim);
		}
		
		case deathmatch_day:
		{
			deathmatch_death(attacker, victim);
		}	
		
		case gungame_day:
		{
			gungame_death(attacker, victim);
		}
	
		case laser_day:
		{
			laser_death(victim);
		}
	
		default: {}
	
	}
	
	return Plugin_Continue;
}


// handle nade projectiles for a sd create timers to remove them :)
public OnEntityCreated(int entity, const String:classname[])
{
	
	if(sd_state == sd_inactive)
	{
		return;
	}	
	
	switch(special_day)
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

	if(sd_state == sd_inactive)
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

	switch(special_day)
	{
		
	
		case dodgeball_day:
		{
			if(!StrEqual(weapon_string,"weapon_flashbang"))
			{
				return Plugin_Handled;
			}
		}
		
		case grenade_day:
		{
			if(!StrEqual(weapon_string,"weapon_hegrenade"))
			{
				return Plugin_Handled;
			}
		}
		
		case knife_day:
		{
			if(!StrEqual(weapon_string,"weapon_knife"))
			{
				return Plugin_Handled;
			}
		}
	
		case scoutknife_day:
		{
			// need to check for ssg08 incase we are oncsgo
			if(!(StrEqual(weapon_string,"weapon_scout") || StrEqual(weapon_string,"weapon_knife") || StrEqual(weapon_string,"weapon_ssg08")))
			{
				return Plugin_Handled;
			}
		}
	
		case zombie_day:
		{
			if(sd_state == sd_active)
			{
				if(GetClientTeam(client) == CS_TEAM_T)
				{
					if(!StrEqual(weapon_string,"weapon_knife"))
					{
						return Plugin_Handled;
					}
				}
			}
		}

		// spectre can only use knife
		case spectre_day:
		{
			if(sd_state == sd_active)
			{
				if(client == spectre)
				{
					if(!StrEqual(weapon_string,"weapon_knife"))
					{
						return Plugin_Handled;
					}					
				}				
			}
		}
		
		
		case headshot_day:
		{
			if(sd_state != sd_inactive)
			{
				if(!StrEqual(weapon_string,"weapon_deagle"))
				{
					return Plugin_Handled;
				}					
									
			}
		}

		default: {}
	
	}
	return Plugin_Continue;
}



// handles movement changes off a ladder so they are what they should be for an sd

MoveType player_last_movement_type[MAXPLAYERS+1] = {MOVETYPE_WALK};


public Action check_movement(Handle Timer)
{
	// no sd running dont care
	if(sd_state == sd_inactive)
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
				switch(special_day)
				{
					
					case zombie_day:
					{
						if(GetClientTeam(client) == CS_TEAM_T && sd_state == sd_active)
						{
							set_zombie_speed(client);
						}
					}
					
					// we use a button toggle i dont think we need this anymore
					case fly_day:
					{
						//client_fly(client);
					}


					case dodgeball_day: 
					{
						sd_player_init(client);
					}
					
					case grenade_day: 
					{
						sd_player_init(client);
					}					

					case scoutknife_day: 
					{
						sd_player_init(client);
					}
					
					default: {}
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
	if(sd_state == sd_inactive)	
	{
		return Plugin_Continue;
	}
	
	bool in_use = (buttons & IN_USE) == IN_USE;
	
	// kill laser
	if(in_use && special_day == laser_day && sd_state == sd_active && client == laser_tank)
	{
		setup_laser(client,{ 1, 153, 255, 255 },g_lbeam,g_lpoint,true);
	}	

	// use key press toggle fly day move type
	else if(in_use && !use_key[client] && special_day == fly_day)
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
