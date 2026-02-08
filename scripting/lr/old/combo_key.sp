

#define BUTTON_SIZE 8
new const String:BUTTON_NAMES[BUTTON_SIZE][] =
{
    "Forward",
    "Back",
    "Left",
    "Right",
    "Use",
    "Crouch",
    "Attack",
    "Reload",
};

int BUTTON_FLAGS[BUTTON_SIZE] = 
{
    IN_FORWARD,
    IN_BACK,
    IN_MOVELEFT,
    IN_MOVERIGHT,
    IN_USE,
    IN_DUCK,
    IN_ATTACK,
    IN_RELOAD,
};

void print_current_input(int id)
{
    int client = slots[id].client;

    PrintToChat(client,"%s (Button %d of %d) Press %s",LR_PREFIX,
        slots[id].current_button + 1,slots[id].button_size,
        BUTTON_NAMES[slots[id].combo_buttons[slots[id].current_button]]);
}

void check_button(int id, int buttons)
{
    buttons &= (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT | IN_USE | IN_DUCK | IN_ATTACK | IN_RELOAD);

    // No change in input we don't care
    if(buttons == slots[id].buttons_old)
    {
        return;
    }


    slots[id].buttons_old = buttons;

    int client = slots[id].client;

    // No input or finished is fine
    if(buttons == 0 || slots[id].current_button >= slots[id].button_size)
    {
        return;
    }

    else if(buttons ==  BUTTON_FLAGS[slots[id].combo_buttons[slots[id].current_button]])
    {
        slots[id].current_button += 1;

        if(slots[id].current_button >= slots[id].button_size)
        {
            int partner = slots[id].partner

            // prevent edge cases
            if(slots[partner].current_button < slots[partner].button_size)
            {
                ForcePlayerSuicide(slots[partner].client);
            }
        }

        else
        {
            print_current_input(id);
        }
    }

    else
    {
        slots[id].current_button = 0;
        PrintToChat(client,"%s Wrong button, try again!", LR_PREFIX);
        print_current_input(id);
    }
}

void combo_key_player_init(int id, int[] button, int button_size)
{
    int client = slots[id].client;

    SetEntityHealth(client,100);
    strip_all_weapons(client); // remove all the players weapons
    
    slots[id].weapon_string = "weapon_knife"
    slots[id].weapon = GivePlayerItem(client,slots[id].weapon_string);

    for(int i = 0; i < button_size; i++)
    {
        slots[id].combo_buttons[i] = button[i];
    }

    slots[id].button_size = button_size;
    slots[id].current_button = 0;
    slots[id].buttons_old = 0;

    print_current_input(id);
}

void start_combo_key(int t_slot, int ct_slot)
{
    int button[16];
    int button_size = 10;

    for(int i = 0; i < button_size; i++)
    {
        button[i] = GetRandomInt(0,BUTTON_SIZE - 1);
    }

    combo_key_player_init(t_slot,button,button_size);
    combo_key_player_init(ct_slot,button,button_size);
}