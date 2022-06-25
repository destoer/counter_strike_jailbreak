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
		if(!(IsPlayerAlive(client) && ((GetClientTeam(client) == CS_TEAM_CT) || warday_active)))
		{
			return -1;
		}

		strip_all_weapons(client);
		
	
		GivePlayerItem(client, "weapon_knife"); // give back a knife
		GivePlayerItem(client, "weapon_deagle"); // all ways give a deagle
		
		
		// give them plenty of deagle ammo
		int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		set_reserve_ammo(client, weapon, 999);
		
		// finally give them there item
		EngineVersion game = GetEngineVersion();

		if(game == Engine_CSS)
		{
			GivePlayerItem(client, gun_give_list_css[param2]);
		}

		else if(game == Engine_CSGO)
		{
			GivePlayerItem(client, gun_give_list_csgo[param2]);
		}
		
		// give them plenty of primary ammo
		weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		set_reserve_ammo(client, weapon, 999);
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
	if(client == warden_id && empty_uses > 0 ) 
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
	
	
	else if(client != warden_id)
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