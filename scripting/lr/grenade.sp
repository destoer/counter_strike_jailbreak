

enum grenade_choice
{
	grenade_vanilla,
	grenade_low_grav,
}


public Action GiveGrenade(Handle timer, any entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");


	
	if(!in_lr(client))
	{ 
		return Plugin_Continue; 
	}
	
	
	if(is_valid_client(client) && is_on_team(client) && IsPlayerAlive(client))
	{
		strip_all_weapons(client);
		GivePlayerItem(client, "weapon_hegrenade");
	}

	return Plugin_Continue;	
}


void grenade_player_init(int id)
{
	int client = slots[id].client;

	strip_all_weapons(client); // remove all the players weapons
	GivePlayerItem(client, "weapon_hegrenade");
	SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);  
	SetEntityHealth(client,125);

	grenade_choice choice = view_as<grenade_choice>(slots[id].option);

	switch(choice)
	{
		case grenade_vanilla:
		{

		}

		case grenade_low_grav: 
		{
			SetEntityGravity(client,0.6);
		}
	}

	slots[id].weapon_string = "weapon_hegrenade";
}

void grenade_sudden_death(int slot)
{
	int client = slots[slot].client;

	slots[slot].failsafe = true;

	PrintCenterText(client,"Sudden death!");
	PrintToChat(client,"%s Sudden death!",LR_PREFIX);
}

public Action grenade_failsafe(Handle timer,int t_slot)
{
	LrSlot slot;
	slot = slots[t_slot];

	if(!is_valid_client(slot.client) || !slot.active || slots[t_slot].type != grenade)
	{
		return Plugin_Continue;
	}

	slots[t_slot].timer = null

	int ct_slot = slot.partner;

	grenade_sudden_death(t_slot);
	grenade_sudden_death(ct_slot);

	return Plugin_Continue;
}

void start_grenade(int t_slot, int ct_slot)
{
	grenade_player_init(t_slot);
	grenade_player_init(ct_slot);

	slots[t_slot].timer = CreateTimer(35.0,grenade_failsafe,t_slot,TIMER_FLAG_NO_MAPCHANGE);
}


void grenade_menu(int client)
{
    Menu menu = new Menu(default_choice_handler);
    menu.SetTitle("Nade option");

    menu.AddItem("vanilla","vanilla");
    menu.AddItem("low grav","low grav");

    menu.ExitButton = false;


    menu.Display(client,20);        
}