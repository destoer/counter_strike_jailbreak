

void print_pair(int client,LrPair pair)
{
    PrintToConsole(client,"LR: %s\n",lr_list[pair.type]);
    PrintToConsole(client,"active: %s\n",pair.active? "true" : "false");

    if(is_valid_client(pair.ct))
    {
        PrintToConsole(client,"ct: %N",pair.ct);
    }

    if(is_valid_client(pair.t))
    {
        PrintToConsole(client,"t: %N",pair.t);
    }
}