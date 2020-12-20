/*
**
*/
#if defined _ZOMBIE_INCLUDE_included
 #endinput
#endif
#define _ZOMBIE_INCLUDE_included


int patient_zero = -1;

// zombie day
void zombie_player_init(int client)
{
	// not active give guns
	if(sd_state == sd_started)
	{
		WeaponMenu(client);
	}
	
	// just make a zombie
	else
	{
		MakeZombie(client);
	}
}


#if defined USE_CUSTOM_ZOMBIE_MODEL
bool zombie_model_success = false;
const int ZOMBIE_MODEL_LIST_SIZE = 33;
new const String:zombie_model_list[ZOMBIE_MODEL_LIST_SIZE][] = {
"models/player/slow/aliendrone/slow_alien.dx80.vtx",
"models/player/slow/aliendrone/slow_alien.dx90.vtx",
"models/player/slow/aliendrone/slow_alien.mdl",
"models/player/slow/aliendrone/slow_alien.phy",
"models/player/slow/aliendrone/slow_alien.sw.vtx",
"models/player/slow/aliendrone/slow_alien.vvd",
"models/player/slow/aliendrone/slow_alien.xbox.vtx",
"models/player/slow/aliendrone/slow_alien_head.dx80.vtx",
"models/player/slow/aliendrone/slow_alien_head.dx90.vtx",
"models/player/slow/aliendrone/slow_alien_head.mdl",
"models/player/slow/aliendrone/slow_alien_head.phy",
"models/player/slow/aliendrone/slow_alien_head.sw.vtx",
"models/player/slow/aliendrone/slow_alien_head.vvd",
"models/player/slow/aliendrone/slow_alien_head.xbox.vtx",
"models/player/slow/aliendrone/slow_alien_hs.dx80.vtx",
"models/player/slow/aliendrone/slow_alien_hs.dx90.vtx",
"models/player/slow/aliendrone/slow_alien_hs.mdl",
"models/player/slow/aliendrone/slow_alien_hs.phy",
"models/player/slow/aliendrone/slow_alien_hs.sw.vtx",
"models/player/slow/aliendrone/slow_alien_hs.vvd",
"models/player/slow/aliendrone/slow_alien_hs.xbox.vtx",
"materials/models/player/slow/aliendrone/drone_arms.vmt",
"materials/models/player/slow/aliendrone/drone_arms.vtf",
"materials/models/player/slow/aliendrone/drone_arms_normal.vtf",
"materials/models/player/slow/aliendrone/drone_head.vmt",
"materials/models/player/slow/aliendrone/drone_head.vtf",
"materials/models/player/slow/aliendrone/drone_head_normal.vtf",
"materials/models/player/slow/aliendrone/drone_legs.vmt",
"materials/models/player/slow/aliendrone/drone_legs.vtf",
"materials/models/player/slow/aliendrone/drone_legs_normal.vtf",
"materials/models/player/slow/aliendrone/drone_torso.vmt",
"materials/models/player/slow/aliendrone/drone_torso.vtf",
"materials/models/player/slow/aliendrone/drone_torso_normal.vtf"
};

// custom alien zombie model 
bool CacheCustomZombieModel()
{
	// these apparently just fail silently...
	for (int i = 0; i < ZOMBIE_MODEL_LIST_SIZE; i++)
	{
		AddFileToDownloadsTable(zombie_model_list[i]);
	}


	for (int i = 0; i < ZOMBIE_MODEL_LIST_SIZE; i++)
	{
		if(!PrecacheModel(zombie_model_list[i]))
		{
			return false;
		}
	}

	return true;
}
#endif


void end_zombie()
{
	RestoreTeams();
	patient_zero = -1;
	AcceptEntityInput(fog_ent, "TurnOff");
}


public Action NewZombie(Handle timer, int client)
{
	if(special_day != zombie_day || !IsClientInGame(client))
	{
		return;
	}

	
	CS_RespawnPlayer(client);
	TeleportEntity(client, death_cords[client], NULL_VECTOR, NULL_VECTOR);
	CS_SwitchTeam(client, CS_TEAM_T);
	MakeZombie(client);
	EmitSoundToAll("npc/zombie/zombie_voice_idle1.wav");
}

public Action ReviveZombie(Handle timer, int client)
{
	if(special_day != zombie_day || !IsClientInGame(client) || IsPlayerAlive(client))
	{
		return;
	}
	
	if(IsPlayerAlive(patient_zero))
	{	
		// pull cords so we can tele player to patient zero
		float cords[3];
		GetClientAbsOrigin(patient_zero, cords);
		CS_RespawnPlayer(client);
		TeleportEntity(client, cords, NULL_VECTOR, NULL_VECTOR);
		CS_SwitchTeam(client, CS_TEAM_T);
		MakeZombie(client);
	}				
}

void init_zombie()
{
	SaveTeams(false);

	PrintToChatAll("%s zombie day started", SPECIALDAY_PREFIX);
	CreateTimer(1.0, RemoveGuns); 
	special_day = zombie_day;

	int rand = GetRandomInt( 0, (validclients-1) );
	
	// select the first zombie
	patient_zero = game_clients[rand]; 

	sd_player_init_fptr = zombie_player_init;
}



public void set_zombie_speed(int client)
{
	set_client_speed(client, 1.2);
	SetEntityGravity(client, 0.4);
}

public void MakeZombie(int client)
{
	strip_all_weapons(client);
	set_zombie_speed(client)
	SetEntityHealth(client, 250);
	GivePlayerItem(client, "weapon_knife");
	
	// cant use custom builtin models on csgo
	EngineVersion game = GetEngineVersion();

	#if defined USE_CUSTOM_ZOMBIE_MODEL
		if (zombie_model_success)
		{
			SetEntityModel(client, "models/player/slow/aliendrone/slow_alien.mdl");
		}
		
		else if(game == Engine_CSS)
		{
			SetEntityModel(client, "models/zombie/classic.mdl");
		}
	#else
	if(game == Engine_CSS)
	{
		SetEntityModel(client, "models/zombie/classic.mdl");
	}
	#endif
	
	// fix no block issues on respawn
	// really did not want to resort to this sigh...
	unblock_client(client,SetCollisionGroup);
}

public void MakePatientZero(int client)
{
	CS_SwitchTeam(client, CS_TEAM_T);
	MakeZombie(client);
	SetEntityHealth(client, 1000 * (validclients+1) );
	SetEntityRenderColor(client, 255, 0, 0, 255);	
	PrintCenterTextAll("%N is patient zero!", client);
}

public void StartZombie()
{

	// swap everyone other than the patient zero to the t side
	// if they were allready in ct or t
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(is_on_team(i))
			{
				CS_SwitchTeam(i,CS_TEAM_CT);
			}
		}
	}

	MakePatientZero(patient_zero);

	AcceptEntityInput(fog_ent, "TurnOn");
	
#if defined CUSTOM_ZOMBIE_MUSIC
	EmitSoundToAll("music/HLA.mp3");
#else
	// dont know if we should loop this
	EmitSoundToAll("music/ravenholm_1.mp3");
#endif
	
}


void zombie_discon_started(int client)
{
	// supress unused warning
	client += 0;
	SaveTeams(false);

	int rand = GetRandomInt( 0, validclients - 1 );
	patient_zero = game_clients[rand]; // select the lucky client
}


void zombie_discon_active(int client)
{
	// restore the hp
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT) // check the client is in the game
		{
			SetEntityHealth(i, 100);	
		}
	}


	// while the current disconnecter
	while(patient_zero == client)
	{
		int rand = GetRandomInt( 0, (validclients-1) );
		patient_zero = game_clients[rand]; // select the lucky client
	}
	
	MakePatientZero(patient_zero);
}

void zombie_death(int victim)
{
	static int ct_count = 0;
	
	// test that first time hitting one ct
	int last_man;
	int cur_count = get_alive_team_count(CS_TEAM_CT, last_man);
	bool last_man_triggered  = (cur_count == 1) && (cur_count != ct_count)
	ct_count = cur_count;
	if(last_man_triggered)
	{
		// LAST MAN STANDING
		PrintCenterTextAll("%N IS LAST MAN STANDING!", last_man);
		SetEntityHealth(last_man, 350);
		int weapon = GetPlayerWeaponSlot(last_man, CS_SLOT_SECONDARY);
		set_clip_ammo(last_man,weapon, 999);
		weapon =  GetPlayerWeaponSlot(last_man, CS_SLOT_PRIMARY);
		set_clip_ammo(last_man,weapon, 999);
	}
	
	
	
	
	int team = GetClientTeam(victim);
	// if victim is a ct -> become a zombie
	if(team == CS_TEAM_CT)
	{
		float cords[3];
		GetClientAbsOrigin(victim, cords);
		
		death_cords[victim] = cords;
		death_cords[victim][2] -= 45.0; // account for player eyesight height
		CreateTimer(0.5,NewZombie, victim)
	}
	
	// if victim is a t -> respawn on 'patient zero' if alive
	else if(team == CS_TEAM_T)
	{
		if(IsPlayerAlive(patient_zero))
		{
			CreateTimer(3.0, ReviveZombie, victim);
		}			
	}
}