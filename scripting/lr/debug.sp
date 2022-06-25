

void print_pair(int client,LrPair pair)
{
    PrintToConsole(client,"LR: %s\n",lr_list[pair.type]);
    PrintToConsole(client,"active: %s\n",pair.active? "true" : "false");
    PrintToConsole(client,"ct: %N",pair.ct);
    PrintToConsole(client,"t: %N",pair.t);
}