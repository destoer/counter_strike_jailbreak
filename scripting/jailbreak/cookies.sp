/*
**
*/
#if defined COOKIE_INCLUDE_included
 #endinput
#endif
#define COOKIE_INCLUDE_included

void register_cookies()
{
	client_laser_draw_pref = RegClientCookie("client_laser_draw_pref", "use draw laser y/n", CookieAccess_Protected);
	client_laser_color_pref = RegClientCookie("client_laser_color_pref", "laser color", CookieAccess_Protected);
	client_warden_text_pref = RegClientCookie("client_warden_text_pref", "laser color", CookieAccess_Protected);
	
	for (int client = 1; client < MaxClients; client++)
	{
		OnClientCookiesCached(client);
	}
}

int get_cookie_int(int client, Handle cookie)
{
	char cookie_str[512];
	GetClientCookie(client, cookie, cookie_str, sizeof(cookie_str));

	int ans = StringToInt(cookie_str);

	return ans;
}

void set_cookie_int(int client,int v, Handle cookie)
{
	char str[512];
	IntToString(v, str, sizeof(str));
	
	SetClientCookie(client, cookie, str);	
}

public void OnClientCookiesCached(int client)
{
	char cookie_str[512];
	GetClientCookie(client, client_warden_text_pref, cookie_str, sizeof(cookie_str));

	// not intialised for warden text
	if(StrEqual(cookie_str,""))
	{
		set_cookie_int(client,1,client_warden_text_pref);
	}

	// get draw laser setting
	int color =  get_cookie_int(client,client_laser_color_pref);
	
	// set to something valid
	if(color >= LASER_COLOR_SIZE)
	{
		color = 0;
	}

	jb_players[client].laser_color = color;
	
#if defined DRAW_CUSTOM_FLAGS 

#else
	// default draw laser to on if we dont have flag restrictions
	GetClientCookie(client, client_laser_draw_pref, cookie_str, sizeof(cookie_str));
	if(StrEqual(cookie_str,""))
	{
		set_cookie_int(client,1,client_laser_draw_pref);
	}
#endif

	int draw = get_cookie_int(client,client_laser_draw_pref);
	jb_players[client].draw_laser = draw > 0;

	int text_enable = get_cookie_int(client,client_warden_text_pref);
	jb_players[client].warden_text = text_enable > 0;
}