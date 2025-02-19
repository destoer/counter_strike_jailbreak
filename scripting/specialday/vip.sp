void vip_player_init(int client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
	    SetEntityRenderColor(client, 0, 0, 255, 255);
	}
	
	else 
	{
	    SetEntityRenderColor(client, 255, 0, 0, 255);
	}
	WeaponMenu(client);
}


public Action ReviveVip(Handle Timer, int client)
{
    // dont reviive if not active
	if(global_ctx.sd_state != sd_active || global_ctx.special_day != vip_day)
	{
		return Plugin_Continue;
	}

	if(is_valid_client(client) && is_on_team(client))
	{
		CS_RespawnPlayer(client);
		sd_player_init(client);
	}

	return Plugin_Continue;
}


void vip_init()
{
	PrintToChatAll("%s vip day started", SPECIALDAY_PREFIX);
    PrintToChatAll("%s Protect the vip for your team!",SPECIALDAY_PREFIX);
	global_ctx.special_day = vip_day;
	global_ctx.player_init = vip_player_init;
	
	BalTeams();
}

int t_vip = 0;
int ct_vip = 0;

void give_vip(int client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);

    // VIP is yellow
	SetEntityRenderColor(client, 255, 255, 0, 255);
 
    PrintToChatAll("%s %N is the vip for %s",SPECIALDAY_PREFIX,client,GetClientTeam(client) == CS_TEAM_T? "T" : "CT");

    SetEntityHealth(client,250);
}

int pick_vip_internal(int team)
{
    // Get List of each team that is alive
    int clients[MAXPLAYERS + 1];

    int count = filter_team(team,clients,true);

    // pick one at random...
    int idx = GetRandomInt(0,count - 1);

    return clients[idx];
}

void pick_t_vip()
{
    t_vip = pick_vip_internal(CS_TEAM_T);
    give_vip(t_vip);
}

void pick_ct_vip()
{
    ct_vip = pick_vip_internal(CS_TEAM_CT);
    give_vip(ct_vip);
}

public void StartVip()
{
	start_round_delay(240);
	CreateTimer(1.0, RemoveGuns);

    // Select T randomly
    pick_t_vip();

    // Select CT randomly
    pick_ct_vip();
}

int winner = -1;

void end_vip()
{
    // renable loss conds
    enable_round_end();
    slay_team(winner == CS_TEAM_CT? CS_TEAM_T : CS_TEAM_CT);    
	
    if(winner != -1)
    {
        PrintToChatAll("%s %s won VIP day",SPECIALDAY_PREFIX,winner == CS_TEAM_CT? "Counter terrorists" : "Terrorists");
    }
}


void vip_death(int attacker,int victim)
{
    if(is_valid_client(attacker) && is_valid_client(victim))
    {
        PrintToChatAll("%s %N killed the the VIP %N",SPECIALDAY_PREFIX,attacker,victim);
    }

    if(t_vip == victim)
    {
        winner = CS_TEAM_CT;
        end_vip();
    }

    else if(ct_vip == victim)
    {
        winner = CS_TEAM_T;
        end_vip();
    }

    // normal player - respawn is fine
    else
    {
        PrintToChat(victim,"%s You will respawn in 20 seconds\n",SPECIALDAY_PREFIX);
        CreateTimer(10.0, ReviveVip, victim);
    }
}