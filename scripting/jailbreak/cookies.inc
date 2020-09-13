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
	
	for (int client = 1; client < MaxClients; client++)
	{
		OnClientCookiesCached(client);
	}
}

public void OnClientCookiesCached(int client)
{
	// get draw laser setting
	char cookie_str[12];
	GetClientCookie(client, client_laser_color_pref, cookie_str, sizeof(cookie_str));
	int color = StringToInt(cookie_str);
	
	// set to something valid
	if(color >= LASER_COLOR_SIZE)
	{
		color = 0;
	}
	
	
	laser_color[client] = color;
	
	GetClientCookie(client, client_laser_draw_pref, cookie_str, sizeof(cookie_str));
	
	int draw = StringToInt(cookie_str);
	
	use_draw_laser_settings[client] = draw > 0;
}