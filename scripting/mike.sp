/* Headers */
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <basecomm>
#include "lib.inc"

#define ADMIN_FLAG		ADMFLAG_BAN

// Screen fade flags.
#define FFADE_IN		0x0001 // Just here so we don't pass 0 into the function
#define FFADE_OUT		0x0002 // Fade out (not in)
#define FFADE_MODULATE	0x0004 // Modulate (don't blend)
#define FFADE_STAYOUT	0x0008 // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE		0x0010 // Purges all other fades, replacing them with this one

#define CHAT_PREFIX "\x01\x07ffffff[ \x07ff1affMike Myers \x07ffffff]"

// Notify me if I miss a semicolon from now on.
#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Mike Myers",
	author = "ici, Myles",
	description = "Sponsored by Nomy for GamePunch",
	version = "1.12",
	url = "http://steamcommunity.com/id/1ci"
};

/* Enums */
enum MMGameEndReason
{
	MMGameEnd_Default,
	MMGameEnd_MikeMyersWin,
	MMGameEnd_SurvivorsWin
}

/* Variables */
new g_iMike;
new Handle:g_hMinions = INVALID_HANDLE;
new Handle:g_hSurvivors = INVALID_HANDLE;
new Handle:g_hLastCTs = INVALID_HANDLE;

new g_iCountdownTimer;
new Handle:g_hCountdownTimer = INVALID_HANDLE;

new g_iSurvivalTimer;
new Handle:g_hSurvivalTimer = INVALID_HANDLE;

new g_iMikeTrailRef = -1;
new Handle:g_hSurvivorTrails = INVALID_HANDLE;

new g_iExplosionSprite = -1;
new g_iSmokeSprite = -1;
new g_iLaserSprite = -1;
new g_iLaserHalo = -1;
new g_iBeamSprite = -1;

new m_bDrawViewmodel = -1;
//new m_hPlayer = -1;

new bool:g_bRunning = false;
new bool:g_bSurvival = false;

/* Constants */
new const String:k_sTypesOfDoors[][] = {"func_door", "func_movelinear", "func_door_rotating"};

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
	findOffsets();
	initCvars();
	initCmds();
	HookEvent("player_spawn", NoBlock_PlayerSpawn);
}

public NoBlock_PlayerSpawn(Handle: event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bRunning)
	{
		unblock_client(client);
	}
}

findOffsets()
{
	m_bDrawViewmodel = FindSendPropInfo("CCSPlayer", "m_bDrawViewmodel");
	if (m_bDrawViewmodel == -1)
		LogError("CCSPlayer::m_bDrawViewmodel was not found.");
	
	// m_hPlayer = FindSendPropInfo("CCSRagdoll", "m_hPlayer");
	// if (m_hPlayer == -1)
		// LogError("CCSRagdoll::m_hPlayer was not found.");
}

initCvars()
{
	g_hCountdownTimer = CreateConVar("sm_mikemyers_countdown_timer", "10", "", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	g_hSurvivalTimer = CreateConVar("sm_mikemyers_survival_timer", "60", "", FCVAR_PLUGIN, true, 10.0);
}

initCmds()
{
	RegAdminCmd("sm_mm", Command_MikeMyers, ADMIN_FLAG, "Command to start/stop the game.");
}

/**
 * The map is starting.
 */
public OnMapStart()
{
	g_iExplosionSprite = PrecacheModel("sprites/blueglow2.vmt");
	g_iSmokeSprite = PrecacheModel("sprites/steam1.vmt");
	g_iLaserSprite = PrecacheModel("materials/sprites/lgtning.vmt");
	g_iLaserHalo = PrecacheModel("materials/sprites/plasmahalo.vmt");
	g_iBeamSprite = PrecacheModel("sprites/laserbeam.vmt");
	
	PrecacheSound("ambient/explosions/explode_8.wav");
	PrecacheSound("buttons/blip1.wav");
	PrecacheSound("hitmarker.wav");
	AddFileToDownloadsTable("sound/hitmarker.wav");
}

/**
 * The map is ending.
 */
public OnMapEnd()
{
	if ( g_bRunning )
		stop( 0 );
}

public Action:Command_MikeMyers(client, args)
{
	// Don't care if command was sent from the server console
	if ( !client )
		return Plugin_Handled;
	
	sendPanel( client );
	return Plugin_Handled;
}

sendPanel(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Mike Myers");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "Enable", (g_bRunning) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	DrawPanelItem(panel, "Disable", (!g_bRunning) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	DrawPanelText(panel, " ");
	SetPanelCurrentKey(panel, 10);
	DrawPanelItem(panel, "Exit", ITEMDRAW_CONTROL);
	SendPanelToClient(panel, client, Panel_Handler, 0);
	CloseHandle(panel);
}

public Panel_Handler(Handle:panel, MenuAction:action, client, choice)
{
	if (action != MenuAction_Select)
		return;
	
	switch (choice)
	{
		case 1: // Enable
		{
			
			start( client );
			
		}
		case 2: // Disable
		{
			// Skip action if game has already been stopped
			if ( !g_bRunning )
			{
				SayText2(client, "%s The game is not running.", CHAT_PREFIX);
				return;
			}
			
			stop( client );
		}
	}
}

start(client, Float:interval = 1.0)
{
	g_iMike = 0;
	createPlayerContainers();
	g_iCountdownTimer = GetConVarInt(g_hCountdownTimer);
	
	// Hook events
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Suicide_Check, "kill");
	AddCommandListener(Suicide_Check, "explode");
	AddCommandListener(Suicide_Check, "spectate");
	
	openCells();
	breakCells();
	setHostiesMuteCvar( 0 );
	unmuteAlive();
	enableLR(false);
	setHostiesRebelAnnouncement( 0 );
	
	if ( !client )
		SayText2All("%s The game has restarted on its own.", CHAT_PREFIX);
	else
		SayText2All("%s \x04%N \x07ffffffhas started the game.", CHAT_PREFIX, client);
	
	// Start countdowning
	g_bRunning = true;
	unblock_all_clients();
	CreateTimer(interval, Timer_Countdown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Countdown(Handle:timer)
{
	if ( !g_bRunning )
		return Plugin_Stop;
	
	if ( g_iCountdownTimer > 0 )
	{
		// Keep checking if someone needs a respawn
		for (new i = 1; i <= MaxClients; ++i)
		{
			if ( !IsClientInGame(i) || GetClientTeam(i) < 2 )
				continue;
			
			if ( !IsPlayerAlive(i) )
				CS_RespawnPlayer( i );
		}
		
		--g_iCountdownTimer;
		PrintCenterTextAll("Mike Myers will begin in %02i seconds", g_iCountdownTimer);
		return Plugin_Continue;
	}
	
	// Get a random player to be Mike
	g_iMike = getRandomPlayer();
	
	if ( g_iMike == -1 )
	{
		// Couldn't find a player to be Mike
		SayText2All("%s Couldn't find a player to be \x07ff3333Mike\x07ffffff. Ending the game.", CHAT_PREFIX);
		stop( 0 );
		return Plugin_Stop;
	}
	
	mikePicked();
	
	// Swap everybody else to CT
	decl team;
	for (new i = 1; i <= MaxClients; ++i)
	{
		if ( i == g_iMike || !IsClientInGame(i) || (team = GetClientTeam(i)) < 2 )
			continue;
		
		if ( team == CS_TEAM_CT )
		{
			PushArrayCell(g_hLastCTs, GetClientUserId( i ));
		}
		else // CS_TEAM_T
		{
			CS_SwitchTeam(i, CS_TEAM_CT);
			SayText2(i, "%s You were moved to \x0799CCFFCT\x07ffffff. You'll be swapped back to \x07FF4040T \x07ffffffat the end of the round.", CHAT_PREFIX);
		}
		
		// Make them blue
		SetEntityRenderColor(i, 0, 0, 255, 255);
	}
	
	stripWeaponsAll();
	allowPickup(false);
	stripWorldWeapons();
	giveKnives();
	detourOnTakeDamage(true);
	
	// Set Mike's health
	new health = GetRandomInt(300, 400);
	SetEntityHealth(g_iMike, health);
	
	SayText2All("%s \x04%N \x07ffffffis \x07ff3333Mike\x07ffffff! Setting his HP to \x07ffff4d%i\x07ffffff.", CHAT_PREFIX, g_iMike, health);
	//PrintToChatAll("\x04%N is Mike Myers! Setting his health to \x03%i", g_iMike, health);
	PrintCenterTextAll("%N is Mike Myers!", g_iMike);
	--g_iCountdownTimer;
	return Plugin_Stop;
}

stop(client, MMGameEndReason:reason = MMGameEnd_Default)
{
	// Doing this first prevents the "X has decided to turn into a minion." message.
	//g_bRunning = false;
	
	// Destroy hooks
	UnhookEvent("player_hurt", Event_PlayerHurt);
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("player_spawn", Event_PlayerSpawn);
	UnhookEvent("weapon_fire", Event_WeaponFire);
	RemoveCommandListener(Command_JoinTeam, "jointeam");
	RemoveCommandListener(Suicide_Check, "kill");
	RemoveCommandListener(Suicide_Check, "explode");
	RemoveCommandListener(Suicide_Check, "spectate");
	
	// Stopped mid-game or game ended
	if (g_iCountdownTimer == -1)
	{
		performSwaps();
		allowPickup(true);
		detourOnTakeDamage(false);
		stripWeaponsAll();
		giveKnives();
		defaultRenderColourAll();
		detachTrail(g_iMikeTrailRef);
		resetSpeedAll();
	}
	
	// Unhooking this event after team swaps
	UnhookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	
	// If a survival had taken place
	if ( g_bSurvival )
	{
		new size = GetArraySize(g_hSurvivorTrails);
		while ( size > 0 )
		{
			detachTrail( GetArrayCell(g_hSurvivorTrails, size-1) );
			--size;
		}
		CloseHandle(g_hSurvivorTrails);
	}
	
	destroyPlayerContainers();
	
	if ( client == 0 )
		SayText2All("%s The game has ended.", CHAT_PREFIX);
	else
		SayText2All("%s \x04%N \x07ffffffhas stopped the game.", CHAT_PREFIX, client);
	
	switch ( reason )
	{
		case MMGameEnd_MikeMyersWin:
		{
			CS_TerminateRound(5.0, CSRoundEndReason:CSRoundEnd_TerroristWin, true);
		}
		case MMGameEnd_SurvivorsWin:
		{
			CS_TerminateRound(5.0, CSRoundEndReason:CSRoundEnd_CTWin, true);
		}
	}
	
	enableLR(true);
	setHostiesMuteCvar( 3 );
	setHostiesRebelAnnouncement( 1 );
	
	g_bSurvival = false;
	g_bRunning = false;
}

public stopOnNextFrame(MMGameEndReason:reason)
{
	stop(0, reason);
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	if ( g_bRunning )
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/**
 * Client is leaving the server.
 * 
 * @param client    The client index.
 */
public OnClientDisconnect(client)
{
	if ( !g_bRunning )
		return;
	
	if (client == g_iMike)
	{
		// Mike Myers left the server in the middle of the game
		if ( g_bSurvival )
		{
			// Mike Myers decided to leave during Survival.
			SayText2All("%s \x07ff3333Mike \x07ffffff(\x04%N\x07ffffff) left the server during Survival.", CHAT_PREFIX, g_iMike);
			detachTrail(g_iMikeTrailRef);
			
			// Let's pick one of his minions as the new Mike Myers.
			if ( GetArraySize(g_hMinions) != 0 )
			{
				new numOfTries = 0;
				new minion, index;
				do {
					if ( numOfTries >= GetArraySize(g_hMinions) )
					{
						// We tried to get a random alive minion but we couldn't.
						// Let's just respawn the last one we've encountered then.
						CS_RespawnPlayer(minion);
						break;
					}
					index = GetRandomInt(0, GetArraySize(g_hMinions)-1);
					minion = GetClientOfUserId( GetArrayCell(g_hMinions, index) );
					++numOfTries;
				} while ( !minion || !IsPlayerAlive(minion) );
				
				// Turn the minion into Mike Myers
				RemoveFromArray(g_hMinions, index); // No longer a minion
				g_iMike = minion;
				
				mikePicked();
				
				// Set the new Mike's health to the old one's (preserve it)
				SetEntityHealth(g_iMike, GetClientHealth(client));
				
				SayText2All("%s The \x0700e600minion \x04%N \x07ffffffis the new \x07ff3333Mike\x07ffffff.", CHAT_PREFIX, g_iMike);
				PrintCenterTextAll("The minion (%N) has replaced Mike Myers.", g_iMike);
			}
			else // No minions were available. Let's just end the game then...
			{
				SayText2All("%s There were no \x0700e600minions \x07ffffffavailable to replace \x07ff3333Mike\x07ffffff. Ending the game.", CHAT_PREFIX);
				//PrintToChatAll("\x04There were no minions available to replace Mike Myers. Ending the game.");
				stop( 0, MMGameEnd_SurvivorsWin );
				return;
			}
			attemptSurvival();
			return;
		}
		// else - survival has not yet begun
		SayText2All("%s \x07ff3333Mike \x07ffffff(\x04%N\x07ffffff) left the server.", CHAT_PREFIX, g_iMike);
		detachTrail(g_iMikeTrailRef);
		
		// Let's pick one of his minions as the new Mike Myers.
		if ( GetArraySize(g_hMinions) != 0 )
		{
			new numOfTries = 0;
			new minion, index;
			do {
				if ( numOfTries >= GetArraySize(g_hMinions) )
				{
					// We tried to get a random alive minion but we couldn't.
					// Let's just respawn the last one we've encountered then.
					CS_RespawnPlayer(minion);
					break;
				}
				index = GetRandomInt(0, GetArraySize(g_hMinions)-1);
				minion = GetClientOfUserId( GetArrayCell(g_hMinions, index) );
				++numOfTries;
			} while ( !minion || !IsPlayerAlive(minion) );
			
			// Turn the minion into Mike Myers
			RemoveFromArray(g_hMinions, index); // No longer a minion
			g_iMike = minion;
			
			mikePicked();
			
			// Set the new Mike's health to the old one's (preserve it)
			SetEntityHealth(g_iMike, GetClientHealth(client));
			
			SayText2All("%s The \x0700e600minion \x04%N \x07ffffffis the new \x07ff3333Mike\x07ffffff.", CHAT_PREFIX, g_iMike);
			PrintCenterTextAll("The minion (%N) has replaced Mike Myers.", g_iMike);
		}
		else // No minions were available. Let's restart.
		{
			SayText2All("%s There were no \x0700e600minions \x07ffffffavailable to replace \x07ff3333Mike\x07ffffff. Restarting the game.", CHAT_PREFIX);
			
			// Restart
			stop( 0 );
			PrintCenterTextAll("Restarting Mike Myers.");
			start( 0, 0.3 );
			return;
		}
		attemptSurvival();
		return;
	}
	
	new userid = GetClientUserId(client);
	new index = FindValueInArray(g_hLastCTs, userid);
	
	if ( index != -1 )
	{
		// A player that was on the CT team before swaps left the server
		RemoveFromArray(g_hLastCTs, index);
	}
	
	if ( (index = FindValueInArray(g_hMinions, userid)) != -1 )
	{
		// A minion left the server
		RemoveFromArray(g_hMinions, index);
	}
	
	if ( (index = FindValueInArray(g_hSurvivors, userid)) != -1 )
	{
		// A survivor left the server
		RemoveFromArray(g_hSurvivors, index);
	}
	
	// If all survivors left the server
	if ( g_bSurvival && GetArraySize(g_hSurvivors) == 0 )
	{
		//PrintToChatAll("\x04The last survivor (%N) has left the server so therefore Mike Myers wins.", client);
		//PrintToChatAll("\x04Mike Myers (%N) won! Remaining HP: \x03%i", g_iMike, GetClientHealth(g_iMike));
		SayText2All("%s The last \x0733adffsurvivor \x07ffffff(\x04%N\x07ffffff) has left the server so therefore \x07ff3333Mike\x07ffffff wins.", CHAT_PREFIX, client);
		SayText2All("%s \x07ff3333Mike\x07ffffff (\x04%N\x07ffffff) wins! Remaining HP: \x07ffff4d%i\x07ffffff.", CHAT_PREFIX, g_iMike, GetClientHealth(g_iMike));
		stop( 0, MMGameEnd_MikeMyersWin );
		return;
	}
	
	attemptSurvival();
}

mikePicked()
{
	PrintHintText(g_iMike, "You are Mike Myers! Get yourself some minions.");
	performFade(g_iMike, 1000, {255, 0, 0, 50}, FFADE_IN);
	
	// Swap Mike to T
	if ( GetClientTeam(g_iMike) == CS_TEAM_CT )
	{
		PushArrayCell(g_hLastCTs, GetClientUserId( g_iMike ));
		CS_SwitchTeam(g_iMike, CS_TEAM_T);
		SayText2(g_iMike, "%s You were moved to \x07FF4040T\x07ffffff. You'll be swapped back to \x0799CCFFCT\x07ffffff at the end of the round.", CHAT_PREFIX);
		//PrintToChat(g_iMike, "\x04You were moved to T. You'll be swapped back to CT at the end of the round.");
	}
	
	// Make Mike red
	SetEntityRenderColor(g_iMike, 255, 0, 0, 255);
	
	// Beacon him once
	beaconMike();
	
	// Attach a red trail to his body
	new trail = attachTrail(g_iMike, {255, 0, 0, 255});
	if ( trail != -1 )
		g_iMikeTrailRef = EntIndexToEntRef(trail);
}

attemptSurvival()
{
	if ( !g_bRunning )
	{
		return;
	}
	
	if ( g_bSurvival )
	{
		return;
	}
	
	new numOfMinions = GetArraySize(g_hMinions);
	new numOfAliveSurvivors = getPlayersCount(CS_TEAM_CT, true);
	new totalPlayers = numOfMinions + numOfAliveSurvivors + 1; // Including Mike Myers
	
	// Last 15% alive players get turned into survivors.
	if ( numOfAliveSurvivors <= RoundToNearest( float(totalPlayers) * 0.15 ) )
	{
		initSurvival();
	}
}

initSurvival()
{
	SayText2All("%s It's Survival time! \x0733adffSurvivors \x07ffffffhave to find \x07ff3333Mike\x07ffffff and kill him in order to win the game.", CHAT_PREFIX);
	//PrintToChatAll("\x04IT'S SURVIVAL TIME! Survivors have to find Mike Myers and kill him to win the game.");
	PrintCenterTextAll("IT'S SURVIVAL TIME!");
	
	// Create an array to hold survivors' trails
	g_hSurvivorTrails = CreateArray();
	
	for (new i = 1; i <= MaxClients; ++i)
		if ( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT )
			turnSurvivor( i );
	
	g_bSurvival = true;
	
	// Might beacon survivors and Mike Myers every 5 seconds
	// Might let survivors have x amount of time to find and kill Mike Myers.
	g_iSurvivalTimer = GetConVarInt(g_hSurvivalTimer);
	CreateTimer(1.0, Timer_Survival, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	// Inform them about their mission
	alertSurvivorsMission(1.0);
}

turnSurvivor(client)
{
	PushArrayCell(g_hSurvivors, GetClientUserId(client));
	
	// Make survivors blue
	SetEntityRenderColor(client, 0, 0, 255, 255);
	
	// Give them weapons
	GivePlayerItem(client, "weapon_ak47");
	
	// Attach a blue trail
	new trail = attachTrail(client, {0, 0, 255, 255});
	if ( trail != -1 )
		PushArrayCell(g_hSurvivorTrails, EntIndexToEntRef(trail));
	
	PrintHintText(client, "Kill Mike Myers (%N) to win!", g_iMike);
	performFade(client, 1000, {0, 0, 255, 50}, FFADE_IN);
}

public Action:Timer_Survival(Handle:timer)
{
	if ( !g_bRunning )
		return Plugin_Stop;
	
	if ( g_iSurvivalTimer > 0 )
	{
		if ( g_iSurvivalTimer % 5 == 0 )
		{
			// Beacon survivors and Mike every 5 seconds
			beaconMike();
			beaconSurvivors();
		}
		// This doesn't work because the synchronizer gets overidden
		// else if ( g_iSurvivalTimer % 15 == 0 )
		// {
		//	Remind them what they have to do.
		//  alertSurvivorsMission(5.0);
		// }
		--g_iSurvivalTimer;
		PrintCenterTextAll("%i:%02i", g_iSurvivalTimer / 60, g_iSurvivalTimer % 60);
		return Plugin_Continue;
	}
	
	// Survivors failed to kill Mike within the time given
	//killSurvivors();
	//PrintToChatAll("Survivors no longer have unlimited ammo!");
	SayText2All("%s \x0733adffSurvivors \x07ffffffno longer have unlimited ammo.", CHAT_PREFIX);
	CreateTimer(1.0, Timer_PostSurvival, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	--g_iSurvivalTimer;
	return Plugin_Stop;
}

alertSurvivorsMission(Float:holdtime)
{
	new size = GetArraySize(g_hSurvivors);
	new player;
	while ( size > 0 )
	{
		if ( (player = GetClientOfUserId( GetArrayCell(g_hSurvivors, size-1) )) && 
			IsPlayerAlive( player ) )
		{
			new Handle:sync = CreateHudSynchronizer();
			if (sync != INVALID_HANDLE)
			{
				SetHudTextParams(-1.0, -0.87, holdtime, 255, 0, 0, 255, 0, 5.0, 0.1, 0.2);
				ShowSyncHudText(player, sync, "KILL MIKE MYERS");
				CloseHandle(sync);
			}
		}
		--size;
	}
}

public Action:Timer_PostSurvival(Handle:timer)
{
	if ( !g_bRunning )
		return Plugin_Stop;
	
	beaconMike();
	beaconSurvivors();
	connectSurvivorsWithMike( 1.0 );
	alertSurvivorsMission(1.0);
	
	return Plugin_Continue;
}

connectSurvivorsWithMike(Float:life)
{
	new size = GetArraySize(g_hSurvivors);
	new survivor;
	while (size > 0)
	{
		if ( (survivor = GetClientOfUserId( GetArrayCell(g_hSurvivors, size-1))) && 
			g_iMike )
		{
			performConnectingBeam(survivor, g_iMike, life, {255, 0, 0, 255});
			//performConnectingBeam(g_iMike, survivor, life, {255, 0, 0, 255});
		}
		--size;
	}
}

performConnectingBeam(fromClient, toClient, Float:life, colour[4])
{
	decl Float:vFromOrigin[3];
	decl Float:vToOrigin[3];
	
	GetClientEyePosition(fromClient, vFromOrigin);
	vFromOrigin[2] -= 40.0;
	
	GetClientEyePosition(toClient, vToOrigin);
	vToOrigin[2] -= 40.0;
	
	new clients[2];
	clients[0] = fromClient;
	clients[1] = toClient;
	
	TE_SetupBeamPoints(vFromOrigin, vToOrigin, g_iBeamSprite, 0, 1, 1, life, 3.0, 3.0, 10, 2.0, colour, 10);
	TE_Send(clients, 2);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	// While still counting down before the game actually begins
	if (g_iCountdownTimer >= 0)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		//new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		// Restore victim's health if he gets knifed
		SetEntityHealth(victim, GetClientHealth(victim) + GetEventInt(event, "dmg_health"));
		return Plugin_Continue;
	}
	
	// If the player hurt is a survivor
	new userid = GetEventInt(event, "userid");
	if ( FindValueInArray(g_hSurvivors, userid) != -1 )
	{
		new victim = GetClientOfUserId(userid);
		checkForSpeedUpgrade(victim);
	}
	return Plugin_Continue;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimUserID = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(victimUserID);
	new attackerUserID = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attackerUserID);
	
	// If Mike managed to kill himself
	// Might want to disallow Mike from typing "kill" in console
	if ( (g_iMike == attacker && g_iMike == victim) || (g_iMike == victim && attacker == 0) )
	{
		SayText2All("%s \x07ff3333Mike\x07ffffff (\x04%N\x07ffffff) managed to kill himself. What a dummy.", CHAT_PREFIX, g_iMike);
		//PrintToChatAll("\x04Mike Myers (%N) managed to kill himself. What a dummy.", g_iMike);
		explosionEffect(g_iMike);
		killMinions();
		stop( 0, MMGameEnd_SurvivorsWin );
		return;
	}
	
	// If Mike was killed by a survivor
	if (g_iMike == victim)
	{
		SayText2All("%s \x0733adffSurvivors \x07ffffffwin. \x07ff3333Mike\x07ffffff (\x04%N\x07ffffff) was killed by: \x04%N\x07ffffff.", CHAT_PREFIX, g_iMike, attacker);
		//PrintToChatAll("\x04Mike Myers (%N) was killed by: \x03%N", g_iMike, attacker);
		explosionEffect(g_iMike);
		killMinions();
		//stop( 0, MMGameEnd_SurvivorsWin );
		RequestFrame( stopOnNextFrame, MMGameEnd_SurvivorsWin );
		return;
	}
	
	// if a survivor died
	new index = -1;
	if ( (index = FindValueInArray(g_hSurvivors, victimUserID)) != -1 )
	{
		// No longer has speed boost
		SetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue", 1.0);
		
		RemoveFromArray(g_hSurvivors, index);
		// Might want to detach and kill his trail here
		detachSurvivorTrail(victim);
	}
	
	// If the attacker was a survivor
	if ( FindValueInArray(g_hSurvivors, attackerUserID) != -1 )
	{
		// The survivor gets a 5 HP award
		SetEntityHealth(attacker, GetClientHealth(attacker) + 5);
		
		// Make him faster by a tiny bit
		checkForSpeedUpgrade(attacker);
	}
	
	// Mike got himself a new minion
	explosionEffect(victim);
	CreateTimer(0.0, Timer_RespawnMinion, victimUserID, TIMER_FLAG_NO_MAPCHANGE);
	performShake(g_iMike, 20.0, 1.0, 1.5);
}

checkForSpeedUpgrade(client)
{
	new health = GetClientHealth(client);
	
	if ( health > 100 )
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0 + (float(health) / 1000.0));
	else
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
}

resetSpeedAll()
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if ( !IsClientInGame(i) )
			continue;
		
		SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}

detachSurvivorTrail(client)
{
	decl String:sTargetName[MAX_NAME_LENGTH];
	GetEntPropString(client, Prop_Data, "m_iName", sTargetName, MAX_NAME_LENGTH);
	
	decl String:sParentName[MAX_NAME_LENGTH];
	new size = GetArraySize(g_hSurvivorTrails);
	new trail;
	while (size > 0)
	{
		if ( (trail = EntRefToEntIndex( GetArrayCell(g_hSurvivorTrails, size-1) )) == INVALID_ENT_REFERENCE || 
			!IsValidEntity(trail) )
			continue;
		
		GetEntPropString(trail, Prop_Data, "m_iParent", sParentName, MAX_NAME_LENGTH);
		if ( StrEqual(sTargetName, sParentName) )
		{
			detachTrail(trail);
			RemoveFromArray(g_hSurvivorTrails, size-1);
			break;
		}
		--size;
	}
}

public Action:Timer_RespawnMinion(Handle:timer, any:userid)
{
	// Prevent respawns after the game ends
	if ( !g_bRunning )
		return Plugin_Stop;
	
	new client = GetClientOfUserId(userid);
	new team;
	if ( !client || !IsClientInGame(client) || (team = GetClientTeam(client)) < 2 )
		return Plugin_Stop;
	
	if ( FindValueInArray(g_hMinions, userid) == -1 )
		PushArrayCell(g_hMinions, userid);
	
	if ( team != CS_TEAM_T )
		CS_SwitchTeam(client, CS_TEAM_T);
	
	CS_RespawnPlayer(client);
	
	// If no survivors are left
	if ( getPlayersCount(CS_TEAM_CT, true) == 0 )
	{
		//PrintToChatAll("\x04Mike Myers (%N) won! Remaining HP: \x03%i", g_iMike, GetClientHealth(g_iMike));
		SayText2All("%s \x07ff3333Mike\x07ffffff (\x04%N\x07ffffff) wins! Remaining HP: \x07ffff4d%i\x07ffffff.", CHAT_PREFIX, g_iMike, GetClientHealth(g_iMike));
		stop( 0, MMGameEnd_MikeMyersWin );
		return Plugin_Stop;
	}
	
	attemptSurvival();
	return Plugin_Stop;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	stripWeapons(client);
	GivePlayerItem(client, "weapon_knife");
	updateViewModel(client);
	unmutePlayer(client);
	
	if ( g_iCountdownTimer >= 0 )
		return;
	
	// From now on every person who spawns becomes a minion.
	
	// First time being a minion (admin respawned someone)
	if ( FindValueInArray(g_hMinions, userid) == -1 )
	{
		// If the admin respawned a survivor
		new index = -1;
		if ( (index = FindValueInArray(g_hSurvivors, userid)) != -1 )
		{
			RemoveFromArray(g_hSurvivors, index);
		}
		PushArrayCell(g_hMinions, userid);
	}
	
	SetEntityHealth(client, 10);
	SetEntityRenderColor(client, 0, 255, 0, 255);
	
	decl Float:vOrigin[3], Float:vAngles[3], Float:vVelocity[3];
	getRandomMinionSpawnLocation(client, vOrigin, vAngles, vVelocity);
	TeleportEntity(client, vOrigin, vAngles, vVelocity);
	
	// Laser beam going upwards
	decl Float:vEndPoint[3];
	arrayCopy(vOrigin, vEndPoint, 3);
	vEndPoint[2] += 8192.0;
	
	TE_SetupBeamPoints(vOrigin, vEndPoint, g_iLaserSprite, g_iLaserHalo, 1, 1, 1.2, 10.0, 15.0, 2, 10.0, {0, 255, 0, 255}, 10);
	TE_SendToAll();
	
	PrintHintText(client, "You are a minion! Your job is to help and protect Mike Myers.");
	performFade(client, 1000, {0, 255, 0, 50}, FFADE_IN);
	
	attemptSurvival();
}

getRandomMinionSpawnLocation(client, Float:vOrigin[3], Float:vAngles[3], Float:vVelocity[3])
{
	new location;
	if ( GetArraySize(g_hMinions) <= 1 )
	{
		// Spawn the first 3 minions at Mike
		location = g_iMike;
	}
	else
	{
		// Otherwise spawn at a random minion that's alive and is not ducking (prevents ppl from getting stuck)
		new numOfTries = 0;
		do {
			// This will hopefully prevent crashes
			if ( numOfTries >= GetArraySize(g_hMinions) )
			{
				if ( g_iMike )
				{
					location = g_iMike;
					break;
				}
				else return; // If Mike is no longer on the server
			}
			location = GetClientOfUserId( GetArrayCell(g_hMinions, GetRandomInt(0, GetArraySize(g_hMinions)-1)) );
			++numOfTries;
		} while ( !location || location == client || !IsPlayerAlive(location) || (GetEntityFlags(location) & FL_DUCKING) );
	}
	
	GetClientAbsOrigin(location, vOrigin);
	GetClientEyeAngles(location, vAngles);
	GetEntPropVector(location, Prop_Data, "m_vecAbsVelocity", vVelocity);
	
	// Spawn on the ground (avoid mid-air spawning)
	new Float:flGroundDistance = getGroundDistance(location);
	if ( flGroundDistance > 0.0 )
	{
		vOrigin[2] -= flGroundDistance;
	}
	
	// Opposite eye view
	if (vAngles[1] > 0.0)
		vAngles[1] -= 180.0;
	else if (vAngles[1] < 0.0)
		vAngles[1] += 180.0;
	
	// Opposite speed direction
	vVelocity[0] *= -1.0;
	vVelocity[1] *= -1.0;
}

Float:getGroundDistance(client)
{
	decl Float:vClientAbsOrigin[3];
	GetClientAbsOrigin(client, vClientAbsOrigin);
	
	decl Float:vTemp[3];
	vTemp = vClientAbsOrigin;
	vTemp[2] -= 8192.0;
	
	decl Float:vClientMins[3];
	GetClientMins(client, vClientMins);
	
	decl Float:vClientMaxs[3];
	GetClientMaxs(client, vClientMaxs);
	
	decl Handle:hTrace;
	hTrace = TR_TraceHullFilterEx(vClientAbsOrigin, vTemp, vClientMins, vClientMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceRayBrushOnly, client);
	
	new Float:flTimeFraction = TR_GetFraction(hTrace);
	CloseHandle(hTrace);
	
	return ((vTemp[2] - vClientAbsOrigin[2]) * -flTimeFraction);
}

public bool:TraceRayBrushOnly(entity, mask, any:data)
{
	return entity != data && !(0 < entity <= MaxClients);
}

detourOnTakeDamage(bool:detour)
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if ( !IsClientInGame(i) )
			continue;
		
		if ( detour == true )
			SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
		else
			SDKUnhook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	}
}

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if ( !isClientValid(victim) || !isClientValid(attacker) )
		return Plugin_Continue;
	
	// If Mike knives someone
	if ( attacker == g_iMike )
	{
		// Instant kill. Mike got himself a new minion.
		if ( GetClientHealth(victim) > 100 )
			SetEntityHealth(victim, 100);
		
		damage = 100.0;
		
		new victimTeam = GetClientTeam(victim);
		if ( victimTeam == CS_TEAM_CT )
		{
			performHitMarker(attacker, 0, 0, 255, 25);
		}
		else if ( victimTeam == CS_TEAM_T )
		{
			performHitMarker(attacker, 0, 255, 0, 25);
		}
		
		return Plugin_Changed;
	}
	
	// Make Mike invulnerable while there are no survivors
	if ( victim == g_iMike && GetArraySize(g_hSurvivors) == 0 )
	{
		damage = 0.0;
		if ( attacker == 0 || attacker == g_iMike )
		{
			SlapPlayer(victim, 0, true);
		}
		return Plugin_Handled;
	}
	
	// Is the attacker a minion?
	if ( FindValueInArray(g_hMinions, GetClientUserId(attacker)) != -1 )
	{
		// How can a minion damage Mike.. gr8 friendly fire m8
		if ( victim == g_iMike )
		{
			damage = 0.0;
			return Plugin_Handled;
		}
		
		new victimTeam = GetClientTeam(victim);
		if ( victimTeam == CS_TEAM_CT )
		{
			performHitMarker(attacker, 0, 0, 255, 25);
		}
		else if ( victimTeam == CS_TEAM_T )
		{
			performHitMarker(attacker, 0, 255, 0, 25);
		}
		return Plugin_Continue;
	}
	
	// Is the attacker on CT team? (non-infected)
	if ( GetClientTeam(attacker) == CS_TEAM_CT )
	{
		// If he's damaging a minion
		if ( FindValueInArray(g_hMinions, GetClientUserId(victim)) != -1 )
		{
			if ( GetClientHealth(victim) > 100 )
				SetEntityHealth(victim, 100);
			
			// Instant kill
			damage = 100.0;
			
			performHitMarker(attacker, 0, 255, 0, 25);
			return Plugin_Changed;
		}
	}
	
	// Is the attacker a survivor?
	if ( FindValueInArray(g_hSurvivors, GetClientUserId(attacker)) != -1 )
	{
		if ( victim == g_iMike ) // it's Mike who we're damaging
		{
			performHitMarker(attacker, 255, 0, 0, 25);
			return Plugin_Continue;
		}
		else if ( FindValueInArray(g_hMinions, GetClientUserId(victim)) != -1 ) // Is the victim a minion?
		{
			if ( GetClientHealth(victim) > 100 )
				SetEntityHealth(victim, 100);
			
			// Instant kill
			damage = 100.0;
			
			performHitMarker(attacker, 0, 255, 0, 25);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	// Is it a survivor?
	if ( FindValueInArray(g_hSurvivors, userid) == -1 )
		return; // No, it isn't. Skip action.
	
	// Has survival taken place and time ran out?
	if ( g_bSurvival && g_iSurvivalTimer == -1 )
		return; // don't give survivors unlimited ammo anymore
	
	// Unlimited clip
	new Slot1 = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	new Slot2 = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	
	if ( IsValidEntity(Slot1) )
		if (GetEntProp(Slot1, Prop_Data, "m_iState") == 2)
			SetEntProp(Slot1, Prop_Data, "m_iClip1", GetEntProp(Slot1, Prop_Data, "m_iClip1") + 1);
	
	if ( IsValidEntity(Slot2) )
		if (GetEntProp(Slot2, Prop_Data, "m_iState") == 2)
			SetEntProp(Slot2, Prop_Data, "m_iClip1", GetEntProp(Slot2, Prop_Data, "m_iClip1") + 1);
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!dontBroadcast && !GetEventBool(event, "silent"))
	{
		new team = GetEventInt(event, "team");
		if (team != 1) // if not switching to spectators
		{
			// Don't broadcast team swap messages
			SetEventBroadcast(event, true);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:Command_JoinTeam(client, const String:command[], argc)
{
	if ( !IsClientInGame(client) )
		return Plugin_Continue;
	
	// Disallow Mike from suiciding by joining another team.
	if ( client == g_iMike )
		return Plugin_Handled;
	
	decl String:sArg[4];
	GetCmdArg(1, sArg, sizeof(sArg));
	
	// Check if minion wants to join survivors team and vice versa
	if (sArg[0] == '3') // CS_TEAM_CT
	{
		//PrintToChat(client, "\x04You cannot join this team during Mike Myers.");
		SayText2(client, "%s You cannot join this team during the game.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	else
	{
		new index = FindValueInArray(g_hLastCTs, GetClientUserId(client));
		if (index != -1)
		{
			// This person swapped to T but was CT previously. Don't care about him anymore.
			RemoveFromArray(g_hLastCTs, index);
		}
	}
	return Plugin_Continue;
}

public Action:Suicide_Check(client, const String:command[], args)
{
	if (client && IsClientInGame(client) && client == g_iMike)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Hook_WeaponCanUse(client, weapon)
{
	if ( !isClientValid(client) )
		return Plugin_Continue;
	
	new userid = GetClientUserId(client);
	
	// Only survivors can use weapons other than knife
	if ( //client == g_iMike || FindValueInArray(g_hMinions, userid) != -1 || 
		FindValueInArray(g_hSurvivors, userid) == -1 )
	{
		decl String:sClassname[64];
		GetEdictClassname(weapon, sClassname, sizeof(sClassname));
		
		if (StrContains(sClassname, "knife", false) == -1)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

createPlayerContainers()
{
	g_hMinions = CreateArray();
	g_hSurvivors = CreateArray();
	g_hLastCTs = CreateArray();
}

destroyPlayerContainers()
{
	CloseHandle(g_hMinions);
	CloseHandle(g_hSurvivors);
	CloseHandle(g_hLastCTs);
}

defaultRenderColourAll()
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if ( !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) < 2 )
			continue;
		
		SetEntityRenderColor(i, 255, 255, 255, 255);
	}
}

killMinions()
{
	new size = GetArraySize(g_hMinions);
	new player;
	while ( size > 0 )
	{
		if ( (player = GetClientOfUserId( GetArrayCell(g_hMinions, size-1) )) && 
			IsPlayerAlive( player ) )
		{
			performShake(player, 40.0, 1.0, 1.5);
			ForcePlayerSuicide(player);
		}
		--size;
	}
	// Might kill all Ts too just in case
	for (new i = 1; i <= MaxClients; ++i)
	{
		if ( !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_T )
			continue;
		
		performShake(i, 40.0, 1.0, 1.5);
		ForcePlayerSuicide(i);
	}
}

stock killSurvivors()
{
	new size = GetArraySize(g_hSurvivors);
	new player;
	while ( size > 0 )
	{
		if ( (player = GetClientOfUserId( GetArrayCell(g_hSurvivors, size-1) )) && 
			IsPlayerAlive( player ) )
		{
			performShake(player, 40.0, 1.0, 1.5);
			ForcePlayerSuicide(player);
		}
		--size;
	}
	// Might kill all CTs too just in case
	for (new i = 1; i <= MaxClients; ++i)
	{
		if ( !IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CS_TEAM_CT )
			continue;
		
		performShake(i, 40.0, 1.0, 1.5);
		ForcePlayerSuicide(i);
	}
}

allowPickup(bool:allow)
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if ( !IsClientInGame(i) )
			continue;
		
		if ( allow == false )
			SDKHook(i, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
		else
			SDKUnhook(i, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
	}
}

performSwaps()
{
	new size = GetArraySize(g_hLastCTs);
	new player;
	while ( size > 0 )
	{
		if ( (player = GetClientOfUserId( GetArrayCell(g_hLastCTs, size-1) )) && 
			GetClientTeam( player ) == CS_TEAM_T )
		{
			CS_SwitchTeam(player, CS_TEAM_CT);
		}
		--size;
	}
	for (new i = 1; i <= MaxClients; ++i)
	{
		if ( !IsClientInGame( i ) || GetClientTeam( i ) != CS_TEAM_CT )
			continue;
		
		if ( FindValueInArray(g_hLastCTs, GetClientUserId(i)) == -1 )
		{
			CS_SwitchTeam(i, CS_TEAM_T);
		}
	}
}

unmutePlayer(client)
{
	if ( !BaseComm_IsClientMuted(client) )
		SetClientListeningFlags(client, VOICE_NORMAL);
}

unmuteAlive()
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if ( !IsClientInGame(i) || !IsPlayerAlive(i) )
			continue;
		
		unmutePlayer(i);
	}
}

openCells()
{
	new entity = -1;
	for (new i = 0; i < sizeof(k_sTypesOfDoors); ++i)
		while ( ( entity = FindEntityByClassname(entity, k_sTypesOfDoors[i]) ) != -1 )
			AcceptEntityInput(entity, "Open");
}

breakCells() // for breakable cells like on jb_minecraft
{
	new entity = -1;
	while ( ( entity = FindEntityByClassname(entity, "func_breakable") ) != -1 )
		AcceptEntityInput(entity, "Break");
}

giveKnives()
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if ( !IsClientInGame(i) || !IsPlayerAlive(i) )
			continue;
		
		GivePlayerItem(i, "weapon_knife");
		updateViewModel(i);
	}
}

updateViewModel(client)
{
	RequestFrame(updateViewModelCallback, GetClientUserId(client));
}

public updateViewModelCallback(any:userid)
{
	new client;
	if ( !(client = GetClientOfUserId(userid)) || !IsPlayerAlive(client) )
		return;
	
	SetEntData(client, m_bDrawViewmodel, 1, 4, true);
}

stripWeapons(client)
{
	if ( !IsClientInGame(client) || !IsPlayerAlive(client) )
		return;
	
	new wepIdx;
	for (new i; i < 4; i++)
	{
		if ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, wepIdx);
			AcceptEntityInput(wepIdx, "Kill");
		}
	}
}

stripWeaponsAll()
{
	for (new i = 1; i <= MaxClients; ++i)
		stripWeapons( i );
}

stripWorldWeapons()
{
	new lastEdictInUse = GetEntityCount();
	for (new entity = MaxClients+1; entity <= lastEdictInUse; ++entity)
	{
		if ( !IsValidEdict(entity) )
			continue;
		
		decl String:sClassname[64];
		GetEdictClassname(entity, sClassname, sizeof(sClassname));
		
		if (StrContains(sClassname, "weapon_", false) != -1)
			AcceptEntityInput(entity, "Kill");
	}
}

getRandomPlayer()
{
	new clients[MaxClients+1], clientCount;
	
	for (new i = 1; i <= MaxClients; ++i)
		if (IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) > 1))
			clients[clientCount++] = i;
	
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

getPlayersCount(team, bool:aliveonly = false)
{
	new count;
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
		{
			if (aliveonly && IsPlayerAlive(i))
				++count;
			else
				++count;
		}
	}
	return count;
}

attachTrail(client, colour[4])
{
	new trail = CreateEntityByName("env_spritetrail");

	if ( !IsValidEntity(trail) )
		return -1;

	decl String:strTargetName[MAX_NAME_LENGTH];
	GetClientName(client, strTargetName, sizeof(strTargetName));

	DispatchKeyValue(client, "targetname", strTargetName);
	DispatchKeyValue(trail, "parentname", strTargetName);
	DispatchKeyValueFloat(trail, "lifetime", 1.0);
	DispatchKeyValueFloat(trail, "endwidth", 3.0);
	DispatchKeyValueFloat(trail, "startwidth", 3.0);
	DispatchKeyValue(trail, "spritename", "sprites/laserbeam.vmt");
	DispatchKeyValue(trail, "renderamt", "255");
	
	decl String:sColours[4][8];
	decl String:sRenderColour[32];
	
	for (new i = 0; i < 4; ++i)
		IntToString(colour[i], sColours[i], 8);
	Format(sRenderColour, sizeof(sRenderColour), "%s %s %s %s", sColours[0], sColours[1], sColours[2], sColours[3]);
	
	DispatchKeyValue(trail, "rendercolor", sRenderColour);
	DispatchKeyValue(trail, "rendermode", "1");
	DispatchSpawn(trail);

	new Float:flOrigin[3];
	GetClientAbsOrigin(client, flOrigin);
	flOrigin[2] += 10.0; //Beam clips into the floor without this
	TeleportEntity(trail, flOrigin, NULL_VECTOR, NULL_VECTOR);

	SetVariantString(strTargetName);
	AcceptEntityInput(trail, "SetParent");
	SetEntPropFloat(trail, Prop_Send, "m_flTextureRes", 0.05);
	SetEntPropFloat(trail, Prop_Data, "m_flMinFadeLength", 0.0);
	
	return trail;
}

detachTrail(trailRef)
{
	new trail = EntRefToEntIndex(trailRef);
	if ( trail == INVALID_ENT_REFERENCE )
		return;
	
	if ( !IsValidEntity(trail) )
		return;
	
	AcceptEntityInput(trail, "ClearParent");
	AcceptEntityInput(trail, "Kill");
}

performBeacon(client, colour[4])
{
	decl Float:vOrigin[3];
	GetClientAbsOrigin(client, vOrigin);
	vOrigin[2] += 7.0;
	
	TE_SetupBeamRingPoint(vOrigin, 10.0, 360.0, g_iBeamSprite, g_iLaserHalo, 0, 30, 0.5, 7.0, 0.5, colour, 10, 0);
	TE_SendToAll();
	
	GetClientEyePosition(client, vOrigin);
	EmitAmbientSound("buttons/blip1.wav", vOrigin, client, SNDLEVEL_RAIDSIREN);
}

beaconMike()
{
	if ( g_iMike )
		performBeacon(g_iMike, {255, 0, 0, 255});
}

beaconSurvivors()
{
	new size = GetArraySize(g_hSurvivors);
	new player;
	while ( size > 0 )
	{
		if ( (player = GetClientOfUserId( GetArrayCell(g_hSurvivors, size-1) )) && 
			IsPlayerAlive( player ) )
		{
			performBeacon(player, {0, 0, 255, 255});
		}
		--size;
	}
}

performFade(client, duration, const color[4], flags)
{
	new Handle:fade = StartMessageOne("Fade", client);
	if (fade == INVALID_HANDLE)
		return;
	
	BfWriteShort(fade, duration);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration
	BfWriteShort(fade, 0);			// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration until reset (fade & hold)
	BfWriteShort(fade, flags);		// fade type (in / out)
	BfWriteByte(fade, color[0]);	// fade red
	BfWriteByte(fade, color[1]);	// fade green
	BfWriteByte(fade, color[2]);	// fade blue
	BfWriteByte(fade, color[3]);	// fade alpha
	EndMessage();
}

performShake(client, Float:flAmplitude, Float:flFrequency, Float:flDuration)
{
	new Handle:shake = StartMessageOne("Shake", client);
	if (shake == INVALID_HANDLE)
		return;
	
	BfWriteByte(shake,  0);
	BfWriteFloat(shake, flAmplitude);
	BfWriteFloat(shake, flFrequency);
	BfWriteFloat(shake, flDuration);
	EndMessage();
}

explosionEffect(client)
{
	static const Float:s_flNormal[3] = {0.0, 0.0, 1.0};
	
	decl Float:vOrigin[3];
	GetClientAbsOrigin(client, vOrigin);
	
	TE_SetupExplosion(vOrigin, g_iExplosionSprite, 5.0, 1, 0, 50, 40, s_flNormal);
	TE_SendToAll();
	
	TE_SetupSmoke(vOrigin, g_iSmokeSprite, 10.0, 3);
	TE_SendToAll();
	
	EmitAmbientSound("ambient/explosions/explode_8.wav", vOrigin, client, SNDLEVEL_NORMAL);
}

stock removeRagdoll(client, bool:dissolve)
{
	// Apparently CS_RespawnPlayer removes the ragdoll
	// There's a way to detach the ragdoll from the player and then dissolve
	// it though if we're looking for this kind of effect
	
	new entity = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if ( entity == -1 || !IsValidEdict(entity) )
		return;
	
	if (dissolve)
	{
		new dissolver = CreateEntityByName("env_entity_dissolver");
		if (dissolver > MaxClients)
		{
			decl String:sName[32];
			Format(sName, sizeof(sName), "MM_Ref_%i", EntIndexToEntRef(entity));

			DispatchKeyValue(entity, "targetname", sName);
			DispatchKeyValue(dissolve, "target", sName);
			DispatchKeyValue(dissolver, "dissolvetype", "3");
			DispatchKeyValue(dissolver, "magnitude", "15.0");
			AcceptEntityInput(dissolver, "Dissolve");
			AcceptEntityInput(dissolver, "Kill");
			return;
		}
	}
	AcceptEntityInput(entity, "Kill");
}

performHitMarker(attacker, red, green, blue, alpha)
{
	new Handle:sync = CreateHudSynchronizer();
	if (sync == INVALID_HANDLE)
		return;
	
	SetHudTextParams(-1.0, -1.0, 0.3, red, green, blue, alpha, 0, 0.3, 0.1, 0.2);
	ShowSyncHudText(attacker, sync, "x");
	EmitSoundToClient(attacker, "hitmarker.wav", _, _, SNDLEVEL_GUNFIRE);
	CloseHandle(sync);
}

enableLR(bool:enable)
{
	new Handle:hLastRequestCvar = FindConVar("sm_hosties_lr");
	if ( hLastRequestCvar != INVALID_HANDLE )
		SetConVarInt( hLastRequestCvar, _:enable );
}

setHostiesMuteCvar(value)
{
	new Handle:hMuteCvar = FindConVar("sm_hosties_mute");
	if ( hMuteCvar != INVALID_HANDLE )
		SetConVarInt( hMuteCvar, value );
}

setHostiesRebelAnnouncement(value)
{
	new Handle:hRebelAnnouncementCvar = FindConVar("sm_hosties_announce_rebel_down");
	if ( hRebelAnnouncementCvar != INVALID_HANDLE )
		SetConVarInt( hRebelAnnouncementCvar, value );
}

stock bool:isClientValid(client)
{
	return (0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client));
}

stock arrayCopy(const any:source[], any:dest[], size)
{
	for (new i; i < size; ++i)
		dest[i] = source[i];
}

stock SayText2(to, const String:message[], any:...)
{
	new Handle:hBf = StartMessageOne("SayText2", to);
	if (!hBf) return;
	decl String:buffer[1024];
	VFormat(buffer, sizeof(buffer), message, 3);
	BfWriteByte(hBf, to);
	BfWriteByte(hBf, true);
	BfWriteString(hBf, buffer);
	EndMessage();
}

stock SayText2All(const String:message[], any:...)
{
	for (new to = 1; to <= MaxClients; ++to)
	{
		if (!IsClientInGame(to) || IsFakeClient(to)) continue;
		new Handle:hBf = StartMessageOne("SayText2", to);
		if (!hBf) return;
		decl String:buffer[1024];
		VFormat(buffer, sizeof(buffer), message, 2);
		BfWriteByte(hBf, to);
		BfWriteByte(hBf, true);
		BfWriteString(hBf, buffer);
		EndMessage();
	}
}
