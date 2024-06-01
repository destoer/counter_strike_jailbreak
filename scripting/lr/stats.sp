enum struct Stats
{
    int lr_win[LR_SIZE_ACTUAL];
    int lr_loss[LR_SIZE_ACTUAL];
    bool dirty_win[LR_SIZE_ACTUAL];
    bool dirty_loss[LR_SIZE_ACTUAL];
}

Stats stats[MAXPLAYERS+1];

void clear_stat(int client)
{
    for(int i = 0; i < LR_SIZE_ACTUAL; i++)
    {
        stats[client].lr_win[i] = 0;
        stats[client].lr_loss[i] = 0;
    }
}


Database database = null;

void database_connect()
{
    SQL_TConnect(T_Connect,"lr_stats");
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

void setup_db()
{
    if(!database)
    {
        return;
    }

    SQL_TQuery(database,T_QueryGeneric,"CREATE TABLE IF NOT EXISTS stats (steamid varchar(64) PRIMARY KEY,name varchar(64))");


        // add each col if not present

        // not working on new sql versions
        
    /* 
        // win
        SQL_FormatQuery(database,query,sizeof(query),"ALTER TABLE stats ADD COLUMN IF NOT EXISTS %s int DEFAULT 0",lr_win_field[i]);
        SQL_TQuery(database,T_QueryGeneric,query);

        // loss
        SQL_FormatQuery(database,query,sizeof(query),"ALTER TABLE stats ADD COLUMN IF NOT EXISTS %s int DEFAULT 0",lr_loss_field[i]);
        SQL_TQuery(database,T_QueryGeneric,query);
    */
    
    // use a seperate query
    SQL_TQuery(database,T_create_table,"SHOW COLUMNS FROM stats");

    PrintToServer("[LR]: stat database setup sucessfully");
}

public void T_create_table(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || results == null || error[0] != '\0' || !results.RowCount)
    {
        LogError("Query failed! %s", error);
    }

    // TODO: this will error out the first time we add a new lr...
    if(((results.RowCount) == (LR_SIZE_ACTUAL * 2) + 2))
    {
        return;
    }

    char query[256];

    for(int i = 0; i < LR_SIZE_ACTUAL; i++)
    {
        // win
        SQL_FormatQuery(database,query,sizeof(query),"ALTER TABLE stats ADD COLUMN %s int DEFAULT 0",lr_win_field[i]);
        SQL_TQuery(database,T_QueryGeneric,query);
        

        // loss
        SQL_FormatQuery(database,query,sizeof(query),"ALTER TABLE stats ADD COLUMN %s int DEFAULT 0",lr_loss_field[i]);
        SQL_TQuery(database,T_QueryGeneric,query);     
    }    
}

public Action load_from_db_callback(Handle timer, int client)
{
    load_from_db(client);
    return Plugin_Continue;
}

void load_from_db(int client)
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
    SQL_FormatQuery(database,query,sizeof(query),"SELECT * FROM stats WHERE steamid = '%s'",steam_id);

    //PrintToServer("Query: %s\n",query);

    // perform the query
    SQL_TQuery(database,T_load_from_db,query,client);
}

void add_db_client(int client)
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
    SQL_FormatQuery(database,query,sizeof(query),"INSERT IGNORE INTO stats (steamid,name) VALUES ('%s' ,'%N')",steam_id,client);

    //PrintToServer("Query: %s\n",query);

    // perform the query
    SQL_TQuery(database,T_QueryGeneric,query,client);    
}

public void T_load_from_db(Database db, DBResultSet results, const char[] error, int client)
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
        add_db_client(client);

        // ct ban client because this player is new
        if(check_command_exists("sm_ctban") && ct_ban)
        {
            CTBan_Client(client,45,0,"Please play on T for a while to learn the rules");
            PrintToChat(client,"%s Please read the rules before joining ct you can join in 45 minutes\n",LR_PREFIX);
        }

        return;        
    }

    //PrintToServer("Fetched results %d : %d\n",results.RowCount,results.FieldCount);

    results.FetchRow();

    for(int i = 0; i < LR_SIZE_ACTUAL; i++)
    {
        // fetch win
        int field;
        results.FieldNameToNum(lr_win_field[i], field);
        stats[client].lr_win[i] = results.FetchInt(field);
        
        // fetch loss
        results.FieldNameToNum(lr_loss_field[i], field);
        stats[client].lr_loss[i] = results.FetchInt(field);      
    }
}


void win_db(int client, lr_type type)
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

    int idx = view_as<int>(type);

    SQL_FormatQuery(database,query,sizeof(query),"UPDATE stats SET %s = %s + 1 WHERE steamid = '%s'",lr_win_field[idx],lr_win_field[idx],steam_id);

    SQL_TQuery(database,T_QueryGeneric,query,client);
}

void lose_db(int client, lr_type type)
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

    int idx = view_as<int>(type);

    SQL_FormatQuery(database,query,sizeof(query),"UPDATE stats SET %s = %s + 1 WHERE steamid = '%s'",lr_loss_field[idx],lr_loss_field[idx],steam_id);

    SQL_TQuery(database,T_QueryGeneric,query,client);  
}

void lr_win(int client, lr_type type)
{
    int idx = view_as<int>(type);
    stats[client].lr_win[idx] += 1;

    // inform clients of lr win!
    Call_StartForward(lr_win_forward);
    Call_PushCell(client);
    Call_PushCell(type);
    int unused;
    Call_Finish(unused);
    

    win_db(client,type);
}

void lr_lose(int client, lr_type type)
{
    int idx = view_as<int>(type);
    stats[client].lr_loss[idx] += 1;

    lose_db(client,type);
}

void print_lr_stat(int client, int player, int i)
{
    PrintToChat(client,"\x07F8F8FF %s %20d : %d (win,loss)",lr_list[i],stats[player].lr_win[i],stats[player].lr_loss[i]);
}

void print_lr_stat_all(int player, int i)
{
    PrintToChatAll("%s %N %s %d : %d (win,loss)",LR_PREFIX,player,lr_list[i],stats[player].lr_win[i],stats[player].lr_loss[i]);
}

void sum_stats(int client, int& win_total, int& loss_total)
{
    for(int i = 0; i < LR_SIZE_ACTUAL; i++)
    { 
        win_total += stats[client].lr_win[i];
        loss_total += stats[client].lr_loss[i];
    }   
}

void list_lr_stats(int client, int player)
{
    PrintToChat(client,"%s LR stats for %N",LR_PREFIX,player);

    int win_total = 0;
    int loss_total = 0;

    sum_stats(player,win_total,loss_total);

    for(int i = 0; i < LR_SIZE_ACTUAL; i++)
    {
        print_lr_stat(client,player,i);
    }

    PrintToChat(client,"%s %N total %d : %d (win,loss)",LR_PREFIX,player,win_total,loss_total);
}

public Action lr_stats(int client, int args)
{
    int player = client;

    // if we have args try to get another player
    if(GetCmdArgs() == 1)
    {
        new String:arg[64];

        GetCmdArg(1,arg,sizeof(arg));

        int tmp = FindTarget(client,arg,false,false);

        if(is_valid_client(tmp))
        {
            player = tmp;
        }   
    }

    list_lr_stats(client,player);
    return Plugin_Continue;
}
