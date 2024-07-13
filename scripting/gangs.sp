#define GANGS_PREFIX "[\x04Gangs\x07]:"
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include "lib.inc"

enum struct GangMember 
{
    int kills;
    int gang_id;
    int lr_wins;
    int warden_wins;
    char steam_id[40];
    char name[40];
    int credits;
}


enum struct Gang 
{
    int gang_id;
    char name[40];
    char owner_steam_id[40];
    int tier;

    // SQL Only
    /*
        SteamId[] members;
    */
}

Gang gang_table[64];
int gangs_size = 0;
GangMember gang_member[64];

#define CREATE_GANG_COST 50
#define TIER_SIZE 4

int tier_cost[TIER_SIZE] = {500, 1000, 5000, 10000};

void increase_tier(int client,int gang_id)
{
    int tier = gang_table[gang_id].tier;

    if(tier >= TIER_SIZE)
    {
        PrintToChat(client,"%s You cannot upgrade your gang any more",GANGS_PREFIX);
        return;
    }

    if(spend_credits(client,tier_cost[tier]))
    {
        gang_table[gang_id].tier += 1;
    }
}

void make_gang(int client, char[] name)
{
    // build gang struct, but don't insert it unless they player has the credits
    // and is authed
    Gang gang;
    int id = gangs_size;
    gang.gang_id = id;
    strcopy(gang.name,sizeof(gang.name),name);
    gang.tier = 0;

    if(!GetClientAuthId(client,AuthId_Engine,gang.owner_steam_id,sizeof(gang.owner_steam_id)))
    {
        PrintToServer("Could not get auth id");
        PrintToChat(client,"%s Your steam id is not authorized",GANGS_PREFIX);
        return;
    }

    if(!spend_credits(client,CREATE_GANG_COST))
    {
        PrintToChat(client,"You do not have %d credits to create a gang",CREATE_GANG_COST);
        return;
    }

    PrintToChat(client,"%s Created gang %s",GANGS_PREFIX,name);
    gangs_size += 1;

    add_member(client,id);
}

void add_member(int client,int gang_id)
{
    gang_member[client].gang_id = gang_id;
}

void add_credits(int client, int credits)
{
    gang_member[client].credits += credits;
}

bool spend_credits(int client, int credits)
{
    if(gang_member[client].credits < credits)
    {
        return false;
    }

    gang_member[client].credits -= credits;
    return true;
}

void print_gang_member(int client)
{
    
}

void gang_info(int client,int gang_id)
{
    PrintToChat(client,"%s gang name: %s",GANGS_PREFIX,gang_table[gang_id].name);
    PrintToChat(client,"%s max members: %s",GANGS_PREFIX,gang_table[gang_id].tier * 5);

    // Grab gang stats
    int total_kills = 0;
    int total_warden_wins = 0;
    int total_lr_wins = 0;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(!is_valid_client(i))
        {
            continue;
        }

        print_gang_member(i);

        if(gang_member[i].gang_id == gang_id)
        {
            total_kills += gang_member[gang_id].kills;
            total_lr_wins += gang_member[gang_id].lr_wins;
            total_warden_wins += gang_member[gang_id].warden_wins;
        }
    }

    PrintToChat(client,"%s total kills: %d",GANGS_PREFIX,total_kills);
    PrintToChat(client,"%s total warden wins: %d",GANGS_PREFIX,total_warden_wins);
    PrintToChat(client,"%s total lr wins: %d",GANGS_PREFIX,total_lr_wins);

}