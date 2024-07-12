Handle cell_auto_timer;

int get_hammer_id(int entity)
{
    return GetEntProp(entity, Prop_Data, "m_iHammerID");
}

public void OnButtonPressed(const char[] output, int button, int activator, float delay)
{
    if(!IsValidEntity(button))
    {
        return;
    }

    char name[64];
    GetEntPropString(button, Prop_Data, "m_iName", name, sizeof(name));


    // button log
    if(is_valid_client(activator))
    {
        for(int i = 1; i <= MaxClients; i++)
        {   
            if(is_valid_client(i))
            {
                PrintToConsole(i,"[BUTTON LOG]: %N Pushed %d %d '%s'",activator,button,get_hammer_id(button),name);
            }
        }
    }
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
            AcceptEntityInput(entity,"Use");
            PrintCenterTextAll("Opening cell doors");
            PrintToChatAll("%s Opening cell doors",JB_PREFIX);
            return;
        }
    }
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


Database database = null;

void database_connect()
{
    SQL_TConnect(T_Connect,"cell_door");
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