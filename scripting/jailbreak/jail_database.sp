Handle cell_auto_timer;

enum struct WardenInfo
{
    char custom_tag[128];
    int wins;
    bool banned;
}

WardenInfo warden_info[64];

Database database = null;

void default_warden_info(int client)
{
    if(!is_valid_client(client))
    {
        return;
    }


    strcopy(warden_info[client].custom_tag,sizeof(warden_info[client].custom_tag),"");
}

void add_warden_db_client(int client)
{
    if(!is_valid_client(client) || !database)
    {
        return;
    }

    char steam_id[40];
    if(!GetClientAuthId(client,AuthId_Engine,steam_id,sizeof(steam_id)))
    {
        PrintToServer("Could not get auth id");
        return;
    }

    char query[256];
    SQL_FormatQuery(database,query,sizeof(query),"INSERT IGNORE INTO warden (steamid,tag,wins,banned) VALUES ('%s' ,'%s','%d','%s')",steam_id,"",0,"false");

    //PrintToServer("Query: %s\n",query);

    // perform the query
    SQL_TQuery(database,T_QueryGeneric,query,client);    
}


void update_warden_tag(char[] steamid, char[] tag)
{
    if(!database)
    {
        return;
    }

    char query[256];
    SQL_FormatQuery(database,query,sizeof(query),"UPDATE warden set TAG = '%s' where steamid = '%s'",tag,steamid);
    SQL_TQuery(database,T_QueryGeneric,query,0);  
}

public void T_load_warden_from_db(Database db, DBResultSet results, const char[] error, int client)
{
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Query failed! %s", error);
    }

    // nothing to do
    if(!is_valid_client(client))
    {
        return;
    }    

    // this user is new, go add them
    if(!results.RowCount)
    {
        add_warden_db_client(client);
        return;        
    }

    //PrintToServer("Fetched results %d : %d\n",results.RowCount,results.FieldCount);

    results.FetchRow();

    // fetch win
    int field;
    results.FieldNameToNum("tag", field);
    char tag[64]
    results.FetchString(field,tag,sizeof(tag));

    // Use the default tag
    if(StrEqual(tag,""))
    {
        Format(WARDEN_PLAYER_PREFIX,PREFIX_SIZE,"\x04%s\x0700BFFF",WARDEN_PLAYER_PREFIX);
    }

    // Use the custom one
    else
    {
        Format(warden_info[client].custom_tag,sizeof(warden_info[client].custom_tag),"\x04[%s]\x0700BFFF",tag);
    }


    results.FieldNameToNum("wins", field);
    warden_info[client].wins = results.FetchInt(field);
}

void load_warden_info_from_db(int client)
{
    if(!database || !is_valid_client(client))
    {
        return;
    }

    char query[256];

    char steam_id[40];
    if(!GetClientAuthId(client,AuthId_Engine,steam_id,sizeof(steam_id)))
    {
        PrintToServer("Could not get auth id");
        return;
    }

    // setup our query
    SQL_FormatQuery(database,query,sizeof(query),"SELECT * FROM warden WHERE steamid = '%s'",steam_id);

    //PrintToServer("Query: %s\n",query);

    // perform the query
    SQL_TQuery(database,T_load_warden_from_db,query,client);
}

public Action load_warden_from_db_callback(Handle timer, int client)
{
    load_warden_info_from_db(client);
    return Plugin_Continue;
}

int get_hammer_id(int entity)
{
    return GetEntProp(entity, Prop_Data, "m_iHammerID");
}

bool fake_press = false;

public void OnButtonPressed(const char[] output, int button, int activator, float delay)
{
    if(!IsValidEntity(button) || fake_press)
    {
        return;
    }

    char name[64];
    GetEntPropString(button, Prop_Data, "m_iName", name, sizeof(name));


    // button log
    for(int i = 1; i <= MaxClients; i++)
    {   
        if(is_valid_client(i))
        {
            if(is_valid_client(activator))
            {
                PrintToConsole(i,"[BUTTON LOG]: %N Pushed %d %d '%s'",activator,button,get_hammer_id(button),name);
            }

            else 
            {
                PrintToConsole(i,"[BUTTON LOG]: invalid ent %d Pushed %d %d '%s'",activator,button,get_hammer_id(button),name);
            }
        }
    }
    
}

void warden_win(int client)
{
    if(!is_valid_client(client) || database == null)
    {
        return;
    }

    warden_info[client].wins += 1;
    PrintToChatAll("%s %N has won as warden %d times",WARDEN_PREFIX,client,warden_info[client].wins);

    char query[256];

    char steam_id[40];
    if(!GetClientAuthId(client,AuthId_Engine,steam_id,sizeof(steam_id)))
    {
        PrintToServer("Could not get auth id");
        return;
    }

    SQL_FormatQuery(database,query,sizeof(query),"UPDATE warden SET wins = wins + 1 WHERE steamid = '%s'",steam_id);
    SQL_TQuery(database,T_QueryGeneric,query,client);
}

void force_cell_doors()
{
    if(global_ctx.cell_door_hammer_id == -1)
    {
        return;
    }

    // Find the button and press it!
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "func_button")) != INVALID_ENT_REFERENCE)
    {
        if (get_hammer_id(entity) == global_ctx.cell_door_hammer_id)
        {
            for(int i = 1; i <= MaxClients; i++) 
            {
                // Find a player to fake press this button 
                if(is_valid_client(i) && GetClientTeam(i) == CS_TEAM_CT)
                {
                    fake_press = true;
                    AcceptEntityInput(entity,"Use",1);
                    PrintCenterTextAll("Opening cell doors");
                    PrintToChatAll("%s Opening cell doors",JB_PREFIX);  
                    fake_press = false;
                    return;  
                }
            }

            PrintToChatAll("%s No CT to fake press the cell button\n", JB_PREFIX);
            return;
        }
    }

    PrintToChatAll("%s Could not find cell button\n", JB_PREFIX); 
}

public Action auto_open_cell_callback(Handle timer)
{
    cell_auto_timer = null;
    force_cell_doors();

    return Plugin_Continue;
}

public Action force_cell_doors_cmd(int client, int args)
{
    if(global_ctx.warden_id != client && !is_admin(client))
    {
        PrintToChat(client,"%s Only the warden or admin can force open doors",WARDEN_PREFIX);
        return Plugin_Continue;
    }

    if(global_ctx.cell_door_hammer_id == -1)
    {
        PrintToChat(client,"%s There is no cell button tagged",WARDEN_PREFIX);
        return Plugin_Continue;  
    }

    PrintToChat(client,"%s Forcing cell doors via button %d",WARDEN_PREFIX,global_ctx.cell_door_hammer_id);

    force_cell_doors();

    return Plugin_Handled;
}


public Action set_cell_button_cmd(int client, int args)
{
    if(GetCmdArgs() != 1)
    {
        PrintToChat(client,"%s usage: !set_cell_button <hammer_id>",JB_PREFIX);
        return Plugin_Handled;
    }

    new String:arg[64];


    GetCmdArg(1,arg,sizeof(arg));

    int hammer_id = StringToInt(arg);

    PrintToChat(client,"%s Adding door hammer id: %d",JB_PREFIX,hammer_id);

    char map_name[64];
    GetCurrentMap(map_name, sizeof(map_name));

    add_door(map_name,hammer_id);

    // set it for current session for convenince
    global_ctx.cell_door_hammer_id = hammer_id;

    return Plugin_Handled;
}

void database_connect()
{
    SQL_TConnect(T_Connect,"jailbreak");
}

public void T_Connect(DBDriver driver,Database db, const char[] error, any data)
{
    if(!database)
    {
        database = db;

        if(!db || !driver)
        {
            LogError("Database failure: %s", error);
            return;
        }

        setup_db(); 
    }

    else if(db)
    {
        // active setup db, just grab the door
        setup_door_id();


        delete db;
        return;
    }
}

public void T_QueryGeneric(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Query failed! %s", error);
    }    
}

public void T_setup_done(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Query failed! %s", error);
    }    

    setup_door_id();
}

void setup_db()
{
    if(!database)
    {
        return;
    }

    SQL_TQuery(database,T_setup_done,"CREATE TABLE IF NOT EXISTS cell_door (map_name varchar(64) PRIMARY KEY,hammer_id int)");
    SQL_TQuery(database,T_QueryGeneric,
        "CREATE TABLE IF NOT EXISTS warden (steamid varchar(64) PRIMARY KEY,tag varchar(64) DEFAULT 'Warden', wins int DEFAULT 0, banned boolean DEFAULT false)"
    );
}


void add_door(char map_name[64],int hammer_id)
{
    if(!database)
    {
        return;
    }

    char query[256];
    SQL_FormatQuery(database,query,sizeof(query),"INSERT IGNORE INTO cell_door (map_name,hammer_id) VALUES ('%s' ,'%d')",map_name,hammer_id);

    //PrintToServer("Query: %s\n",query);

    // perform the query
    SQL_TQuery(database,T_QueryGeneric,query,hammer_id);    
}


void setup_door_id()
{
    if(!database)
    {
        return;
    }

    char map_name[64];
    GetCurrentMap(map_name, sizeof(map_name));

    // setup our query
    char query[256];
    SQL_FormatQuery(database,query,sizeof(query),"SELECT * FROM cell_door WHERE map_name = '%s'",map_name);

    //PrintToServer("Query: %s\n",query);

    // perform the query
    SQL_TQuery(database,T_load_hammer_id,query,0);  
}


public void T_load_hammer_id(Database db, DBResultSet results, const char[] error, int client)
{
    if (db == null || results == null || error[0] != '\0')
    {
        LogError("Could not get jail door id %s", error);
    }

    // this user is new, go add them
    if(!results.RowCount)
    {
        return;        
    }

    //PrintToServer("Fetched results %d : %d\n",results.RowCount,results.FieldCount);

    results.FetchRow();

    int field;
    results.FieldNameToNum("hammer_id", field);
    global_ctx.cell_door_hammer_id = results.FetchInt(field);
}