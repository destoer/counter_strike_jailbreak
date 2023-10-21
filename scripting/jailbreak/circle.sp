/*
**
*/
#if defined _CIRCLE_INCLUDE_included
 #endinput
#endif
#define _CIRCLE_INCLUDE_included


#define RING_LIFTEIME 0.1

// circle stuff

// circle globals
int g_BeamSprite;
int g_HaloSprite;

public Action beacon_callback(Handle timer)
{
	if(global_ctx.warden_id != WARDEN_INVALID && is_valid_client(global_ctx.warden_id) && IsPlayerAlive(global_ctx.warden_id))
	{
		float vec[3];
		GetClientAbsOrigin(global_ctx.warden_id, vec);
		vec[2] += 10.0;
		TE_SetupBeamRingPoint(vec, 35.0, 35.1, g_BeamSprite, g_HaloSprite, 0, 5, RING_LIFTEIME, 5.2, 0.0, player_color[0], 1000, 0);
		TE_SendToAll();
	}

	return Plugin_Continue;
}