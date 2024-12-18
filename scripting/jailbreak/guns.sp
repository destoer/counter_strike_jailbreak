/*
**
*/
#if defined _GUNS_INCLUDE_included
 #endinput
#endif
#define _GUNS_INCLUDE_included


// how many times we can empty a gun
int empty_uses = 2;

Menu gun_menu;


public int WeaponHandler(Menu menu, MenuAction action, int client, int param2) 
{
	if(action == MenuAction_Select) 
	{
		// if they aernt alive or are not on ct they cant use this
		if(!(IsPlayerAlive(client) && ((GetClientTeam(client) == CS_TEAM_CT) || global_ctx.warday_active)))
		{
			return -1;
		}

		weapon_handler_generic(client,param2);
	}

	
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu was cancelled. Reason: %d", client, param2);
	}
	return 0;
}

public Action weapon_menu(int client, int args)
{
	if(IsClientConnected(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		gun_menu.Display(client,20);
	}

	return Plugin_Continue;
}


// empty weapon handler
public empty_handler(Menu menu, MenuAction action, int client, int menu_option) 
{
	// only warden can quick empty	
	if(client == global_ctx.warden_id && empty_uses > 0 ) 
	{
		if(action == MenuAction_Select) 
		{
			new weapon;
			if(menu_option == 1) // primary
			{
				weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			}
			
			if(menu_option == 2) // secondary
			{
				weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			
			}

		
			PrintToChat(client, "%s emptying gun.", WARDEN_PREFIX);
			empty_weapon(client, weapon);
			
			 // decrement uses
			PrintToChat(client, "%s You have %d uses left.", WARDEN_PREFIX, empty_uses--);
		}
		
		else if (action == MenuAction_Cancel) 
		{
			PrintToServer("%N's menu was cancelled. Reason: %d", client ,menu_option);
		}
	}
	
	
	else if(client != global_ctx.warden_id)
	{
		PrintToChat(client, "%s Only warden is allowed to quick emtpy guns.", WARDEN_PREFIX);
	}
	
	else // uses must be zero 
	{
		PrintToChat(client, "%s You cannot empty any more guns this round.", WARDEN_PREFIX);
	}
}

// menu for emptying guns
public Action empty_menu(client,args)
{
	
	Panel panel = new Panel();
	panel.SetTitle("EmptyGun");
	panel.DrawItem("Primary");
	panel.DrawItem("Secondary"); 
	
	panel.Send(client, empty_handler, 20);

	delete panel;
			
	return Plugin_Handled;	
}

const int PICKUP_LIMIT = 20;

public Action:Command_Drop(int client, const char[] command, int args)
{ 
	// can only minipulate 15 weapons
	if(jb_players[client].pickup_count >= PICKUP_LIMIT)
	{
		// only print this message once
		if(jb_players[client].pickup_count < PICKUP_LIMIT * 2)
		{
			PrintToServer("%N may be gun spamming they are over the limit %d : %d\n",client,jb_players[client].pickup_count,PICKUP_LIMIT);

			PrintToChat(client,"%s Anti gun spam: you cannot pickup more than %d unique guns a round\n",JB_PREFIX,PICKUP_LIMIT);

			jb_players[client].pickup_count = PICKUP_LIMIT * 2;

			// give them plenty of ammo as they wont be able to get any more guns
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			set_reserve_ammo(client, weapon, 999);
			

			// give them plenty of primary ammo
			weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			set_reserve_ammo(client, weapon, 999);	
		}

		// if we have an external LR we will log only
		if(!internal_lr())
		{
			return Plugin_Continue;
		}

		// allow drop in lr
		if(!is_in_lr(client))
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action OnWeaponEquip(int client, int weapon) 
{
	int idx = weapon / 32;
	int bit = weapon % 32;

	int mask = (1 << bit);

	// weapon not picked up
	if((global_ctx.weapon_picked[idx] & mask) == 0)
	{
		//PrintToChatAll("pickup count: %d\n",jb_players[client].pickup_count);

		global_ctx.weapon_picked[idx] |= mask;
		jb_players[client].pickup_count += 1;
	}

	return Plugin_Continue;
}