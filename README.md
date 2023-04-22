# counter_strike_jailbreak
sourcemod plugins for jailbreak!


# config


sd_prefix_css - sd prefix for css (string)  
sd_prefix_csgo - sd prefix for csgo (string)  

sd_ctbanenable - ctban support (bool)  
sd_gangs - enable gangs support (bool)  
sd_store - enable store support (bool)  
sd_standalone - make plugin operate without jailbreak (bool)  
sd_freeze - enable freeze commands (bool)  



jb_prefix_css - prefix for plugin info (string)   
warden_prefix_css - prefix for warden info (string)  
warden_player_prefix_css - prefix for warden typing in chat (string)  



jb_prefix_csgo - prefix for plugin info (string)  
warden_prefix_csgo - prefix for warden info (string)  
warden_player_prefix_csgo - prefix for warden typing in chat (string)  

jb_noblock - players pass through eachover (bool)  
jb_stuck - enable stuck command (bool)  
jb_kill_laser - enable kill laser (bool)  
jb_t_laser - enable t laser (bool)  
jb_gun_commands - enable ct gun menu (bool)  
jb_armor give ct armor on spawn (bool)
jb_warden_block - enable warden block commands (bool)

jb_mute - mute t's at round start (bool)
jb_rebel - print rebels being killed (bool)


# setup
NOTE: please ensure hosties block setting is the same as jailbreak if used
also make sure no other no block plugins are active as this may intefere with sd/jb
which uses SetCollisionGroup rather than SetEntProp to prevent physics breaking