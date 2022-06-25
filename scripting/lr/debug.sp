

void print_slot(int client,LrSlot pair)
{
    PrintToConsole(client,"LR: %s\n",lr_list[pair.type]);
    PrintToConsole(client,"active: %s\n",pair.active? "true" : "false");

    if(is_valid_client(slots[pair.partner].client))
    {
        PrintToConsole(client,"partner: %N",slots[pair.partner].client);
    }

    if(is_valid_client(client))
    {
        PrintToConsole(client,"client: %N",pair.client);
    }
}