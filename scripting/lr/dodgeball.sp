#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#include "lr.inc"
#include "../lib.inc"

enum dodgeball_choice
{
	dodgeball_vanilla,
	dodgeball_low_grav
}

void dodgeball_player_init(LrPlayer player,int option)
{
	int client = player.client;

	SetEntityHealth(client,1); // set health to 1
    restrict_weapon(client,"weapon_flashbang");
	SetEntProp(client, Prop_Data, "m_ArmorValue", 0.0);  

	dodgeball_choice choice = view_as<dodgeball_choice>(option);

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
}

void dodgeball_sudden_death(int client)
{
    if(!is_valid_client(client))
    {
        return;
    }

	restrict_weapon(client,"weapon_hegrenade");

	PrintCenterText(client,"Sudden death!");
	PrintToChat(client,"%s Sudden death!",LR_PREFIX);
}

public void dodgeball_failsafe(LrPlayer t_player, LrPlayer ct_player)
{
	dodgeball_sudden_death(t_player.client);
	dodgeball_sudden_death(t_player.client);
}

void start_dodgeball(int t_slot, int ct_slot)
{
	dodgeball_player_init(t_slot);
	dodgeball_player_init(ct_slot);
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

public OnEntityCreated(int entity,  char classname[])
{
    SDKHook(entity, SDKHook_Spawn, OnEntitySpawn); 
}

public Action OnEntitySpawn(int entity)
{
    char classname[64];
    GetEntityClassname(entity,classname,sizeof(classname) - 1);

    int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

    int slot = get_slot(client);

    if(id == INVALID_SLOT)
    {
        return Plugin_Continue;
    }

    if (StrEqual(classname, slots[id].entity_spawn))
    {
        if (StrEqual(classname, "flashbang_projectile") || (slots[id].failsafe && StrEqual(classname, "hegrenade_projectile")))
        {
            CreateTimer(1.4, GiveFlash, entity);
        }        
    }    

    return Plugin_Continue;
}


void dodgeball_menu(int client)
{
    Menu menu = new Menu(pick_partner_callback);
    menu.SetTitle("Nade option");

    menu.AddItem("vanilla","vanilla");
    menu.AddItem("low grav","low grav");

    menu.ExitButton = false;


    menu.Display(client,20);        
}

public OnAllPluginsLoaded()
{
    add_lr(make_lr_impl_menu_failsafe(start_dodgeball,dodgeball_menu,dodgeball_failsafe,43.0,"Dodgeball"));
}