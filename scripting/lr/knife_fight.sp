#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#include "lr.inc"
#include "../lib.inc"

enum knife_choice
{
    knife_vanilla,
    knife_low_grav,
    knife_high_speed,
    knife_one_hit,
    knife_fly,
}

void client_fly(int client)
{
	set_client_speed(client,1.5);
	SetEntityMoveType(client, MOVETYPE_FLY);
}

void knife_fight_player_init(LrPlayer player,int option)
{
    SetEntityHealth(player.client,100); 
    restrict_weapon(player,"weapon_knife");

    knife_choice choice = view_as<knife_choice>(option);

    switch(choice)
    {
        case knife_vanilla:
        {
            
        }

        case knife_low_grav: 
        {
            SetEntityGravity(player.client,0.6);
        }

        case knife_high_speed:
        {
            set_client_speed(player.client,2.5);
        }

        case knife_one_hit:
        {
            SetEntityHealth(player.client,50); 
        }

        case knife_fly:
        {
            PrintToChat(player.client,"%s Press e to toggle flying",LR_PREFIX)
            client_fly(player.client);
        }
    }
}

void start_knife_fight(LrPlayer player_t, LrPlayer player_ct, int option)
{
    knife_fight_player_init(player_t,option);
    knife_fight_player_init(player_ct,option);
}

// void knife_fight_menu(int client)
// {
//     Menu menu = new Menu(default_choice_handler);
//     menu.SetTitle("Knife option");

//     menu.AddItem("vanilla","vanilla");
//     menu.AddItem("low grav","low grav");
//     menu.AddItem("high speed","high speed");
//     menu.AddItem("one hit","one hit");
//     menu.AddItem("fly", "fly");

//     menu.ExitButton = false;


//     menu.Display(client,20);        
// }

public OnAllPluginsLoaded()
{
    add_lr(make_lr_impl(start_knife_fight,"Knife fight"));
}
