// header gaurd
#if defined _INCLUDE_included
 #endinput
#endif
#define _INCLUDE_included


native int get_warden_id();
native int remove_warden();

forward void OnWardenToLR(int client);