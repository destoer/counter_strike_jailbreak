
enum dodgeball_choice
{
	dodgeball_vanilla,
	dodgeball_low_grav
}

void dodgeball_player_init(int id)
{
	int client = slots[id].client;

	SetEntityHealth(client,1); // set health to 1
	strip_all_weapons(client); // remove all the players weapons
	GivePlayerItem(client, "weapon_flashbang");
	SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);  

	dodgeball_choice choice = view_as<dodgeball_choice>(slots[id].option);

	switch(choice)
	{
		case dodgeball_vanilla:
		{

		}

		case dodgeball_low_grav: 
		{
			SetEntityGravity(client,0.6);
		}
	}

	slots[id].weapon_string = "weapon_flashbang";
}

void dodgeball_sudden_death(int slot)
{
	int client = slots[slot].client;

	slots[slot].failsafe = true;

	slots[slot].weapon_string = "weapon_hegrenade";

	PrintCenterText(client,"Sudden death!");

	strip_all_weapons(client);

	GivePlayerItem(client, slots[slot].weapon_string);
}

public Action dodgeball_failsafe(Handle timer,int t_slot)
{
	LrSlot slot;
	slot = slots[t_slot];

	if(!is_valid_client(slot.client) || !slot.active || slots[t_slot].type != dodgeball)
	{
		return Plugin_Continue;
	}

	slots[t_slot].timer = null

	// make players get he nades instead of flashbangs if this is taking too long
	int ct_slot = slot.partner;

	dodgeball_sudden_death(t_slot);
	dodgeball_sudden_death(ct_slot);

	return Plugin_Continue;
}

void start_dodgeball(int t_slot, int ct_slot)
{
	dodgeball_player_init(t_slot);
	dodgeball_player_init(ct_slot);

	slots[t_slot].timer = CreateTimer(28.0,dodgeball_failsafe,t_slot,TIMER_FLAG_NO_MAPCHANGE);
}


public Action GiveFlash(Handle timer, int entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	// only kill ent if its a flashbang
	char classname[64];
	GetEntityClassname(entity,classname,sizeof(classname) - 1);

	if (IsValidEntity(entity) && StrEqual(classname, "flashbang_projectile"))
	{
		AcceptEntityInput(entity, "Kill");
	}

	// no longer in active lr
	if(!in_lr(client)) 
	{ 
		return Plugin_Continue; 
	}
	

	if(is_valid_client(client) && is_on_team(client) && IsPlayerAlive(client) )
	{
		int slot = get_slot(client);

		strip_all_weapons(client);

		// NOTE: this might be a he nade
		GivePlayerItem(client, slots[slot].weapon_string);
		SetEntityHealth(client,1);
	}

	return Plugin_Continue;		
}

void dodgeball_menu(int client)
{
    Menu menu = new Menu(default_choice_handler);
    menu.SetTitle("Nade option");

    menu.AddItem("vanilla","vanilla");
    menu.AddItem("low grav","low grav");

    menu.ExitButton = false;


    menu.Display(client,20);        
}