/*
**
*/
#if defined _BLOCK_INCLUDE_included
 #endinput
#endif
#define _BLOCK_INCLUDE_included


public disable_block_all()
{
	unblock_all_clients(SetCollisionGroup);
}

public Action disable_block_warden_callback(int client, int args)
{
	
	if(client != warden_id)
	{
		return Plugin_Handled;
	}

	PrintCenterTextAll("Player Collision: OFF");
	disable_block_all();
	return Plugin_Handled;
}


// disable block for an admin no warden check
public Action disable_block_admin(int client, int args)
{
	PrintCenterTextAll("Player Collision: OFF!");
	disable_block_all();
	return Plugin_Handled;
}

// same but to enable blocking
public Action enable_block_admin(int client, int args)
{
	PrintCenterTextAll("Player Collision: ON");
	enable_block_all();	
	return Plugin_Handled;
}

public enable_block_all()
{
	block_all_clients(SetCollisionGroup);
}

public Action enable_block_warden_callback(int client, int args)
{
	if(client != warden_id)
	{
		return Plugin_Handled;
	}

	PrintCenterTextAll("Player Collision: ON");
	enable_block_all();
	return Plugin_Handled;
}