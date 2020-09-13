/*
**
*/
#if defined _CIRCLE_INCLUDE_included
 #endinput
#endif
#define _CIRCLE_INCLUDE_included


// circle stuff

// circle globals
new g_BeamSprite;
new g_HaloSprite;

public Action Repetidor(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && i == warden_id)
		{
			SetupBeacon(i);
		}
	}
}

public void SetupBeacon(client)
{
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	TE_SetupBeamRingPoint(vec, 35.0, 35.1, g_BeamSprite, g_HaloSprite, 0, 5, 0.1, 5.2, 0.0, {1, 153, 255, 255}, 1000, 0);
	TE_SendToAll();
}