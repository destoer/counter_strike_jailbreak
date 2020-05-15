/** [CS:S/CS:GO] CT Bans
 * Copyright (C) 2011-2017 by databomb
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// Double #include protection
#if defined _CTBan_Included_
	#endinput
#endif

#define _CTBan_Included_

// Common constant checks
#if !defined INVALID_WEAPON
	#define INVALID_WEAPON -1
#else
	#assert INVALID_WEAPON == -1
#endif 
#if !defined ZERO
	#define ZERO 0
#else
	#assert ZERO == 0
#endif
#if !defined ONE
	#define ONE 1
#else
	#assert ONE == 1
#endif
#if !defined TWO 2
	#define TWO 2
#else
	#assert TWO == 2
#endif
#if !defined THREE
	#define THREE 3
#else
	#assert THREE == 3
#endif
#if !defined FOUR
	#define FOUR 4
#else
	#assert FOUR == 4
#endif
#if !defined FIVE
	#define FIVE 5
#else
	#assert FIVE == 5
#endif
#if !defined SIX
	#define SIX 6
#else
	#assert SIX == 6
#endif
#if !defined SEVEN
	#define SEVEN 7
#else
	#assert SEVEN == 7
#endif

// Specific constants
#define VALUE_NOT_FOUND_IN_ARRAY -1
#define SUBSTRING_NOT_FOUND -1
#define RAGEBAN_ADMIN_LEVEL ADMFLAG_SLAY
#define CTBAN_ADMIN_LEVEL ADMFLAG_SLAY
#define UNCTBAN_ADMIN_LEVEL ADMFLAG_SLAY
#define FORCECT_ADMIN_LEVEL ADMFLAG_SLAY
#define UNFORCECT_ADMIN_LEVEL ADMFLAG_SLAY
#define JOINFAILREASON_ONECHANGE 0
#define MENUCHOICE_USERID 0
#define MENUCHOICE_TIME 1
#define CALLER_NATIVE -2
#define COOKIE_BANNED_STRING "1"
#define COOKIE_UNBANNED_STRING "0"
#define ARG_ZERO_GET_COMMAND_NAME 0
#define FORCECT_ARG_TARGET 1
#define UNFORCECT_ARG_TARGET 1
#define ISBANNED_ARG_TARGET 1
#define CTBAN_ARG_PLAYER 1
#define CTBAN_ARG_TIME 2
#define CTBAN_ARG_REASON 3
#define CTBAN_NO_REASON_GIVEN -1
#define CTBAN_PERM_BAN_LENGTH 0
#define RAGEBAN_ARG_CONSOLE_TARGET 1
#define UNCTBAN_ARG_TARGET 1
#define CHANGE_TIME_ARG_TARGET 1
#define CHANGE_TIME_ARG_TIME 2
#define JOINTEAM_ARG_TEAM_STRING 1
#define CLIENT_DISCONNECT_CB_FIELD_TIMELEFT 0
#define FIND_COOKIE_CB_FIELD_COOKIE_ID 0
#define CLIENT_AUTHED_CB_FIELD_TIMELEFT 0
#define ISBANNED_CB_FIELD_TIMESTAMP 0
#define ISBANNED_CB_FIELD_ADMINNAME 1
#define ISBANNED_CB_FIELD_REASON 2
#define ISBANNED_OFF_CB_FIELD_TIMESTAMP 0
#define ISBANNED_OFF_CB_FIELD_ADMINNAME 1
#define ISBANNED_OFF_CB_FIELD_REASON 2
#define ISBANNED_OFF_CB_FIELD_TIMELEFT 3
#define ISBANNED_OFF_CB_FIELD_PERPNAME 4
#define NATIVE_ISBANNED_CELL_CLIENT 1
#define NATIVE_GET_TIMELEFT_CELL_CLIENT 1
#define NATIVE_GET_OVERRIDE_CELL_CLIENT 1
#define NATIVE_GETBANINFO_CELL_CLIENT 1
#define NATIVE_GETBANINFO_OFF_STR_AUTHID 1
#define NATIVE_CTBAN_CELL_CLIENT 1
#define NATIVE_CTBAN_CELL_TIME 2
#define NATIVE_CTBAN_CELL_ADMIN 3
#define NATIVE_CTBAN_STR_REASON 4
#define NATIVE_CTBAN_OFF_STR_AUTHID 1
#define NATIVE_CHANGE_TIME_CELL_CLIENT 1
#define NATIVE_CHANGE_TIME_CELL_TIME 2
#define NATIVE_CHANGE_TIME_CELL_ADMIN 3
#define NATIVE_UNBAN_CELL_CLIENT 1
#define NATIVE_UNBAN_CELL_ADMIN 2
#define NATIVE_UNBAN_OFF_STR_AUTHID 1
#define NATIVE_FORCECT_CELL_CLIENT 1
#define NATIVE_FORCECT_CELL_ADMIN 2
#define NATIVE_UNFORCECT_CELL_CLIENT 1
#define NATIVE_UNFORCECT_CELL_ADMIN 2
#define NATIVE_MIN_AUTHID_LENGTH 3
#define FIELD_AUTHID_MAXLENGTH 22
#define FIELD_NAME_MAXLENGTH 32
#define FIELD_REASON_MAXLENGTH 200
#define QUERY_MAXLENGTH 350
#define COOKIE_INIT_CHECK_TIME 0.0
#define COOKIE_RESCAN_TIME 5.0
#define DELAY_ENFORCEMENT_TIME 1.8
#define AUTH_RESCAN_TIME 4.0
#define DECREMENT_TIMEBAN_INTERVAL 60.0
#define PLAY_COMMAND_STRING "play "
#define PLAY_COMMAND_STRING_LENGTH 5
#define CSGO_MAX_PAGE_MENU_ITEMS 6
#define CSS_MAX_PAGE_MENU_ITEMS 7
#define CTBAN_COMMAND "sm_ctban"
#define REMOVECTBAN_COMMAND "sm_removectban"
#define RAGEBAN_COMMAND "sm_rageban"
#define FORCECT_COMMAND "sm_forcect"
#define UNFORCECT_COMMAND "sm_unforcect"
#define MAX_UNBAN_CMD_LENGTH 16
#define MAX_TABLE_LENGTH 32
#define MAX_DEFAULT_TABLE_LENGTH 12
#define MAX_CHAT_BANNER_LENGTH 36
#define MAX_RESET_ARG_LENGTH 10
#define MAX_USERID_LENGTH 32
#define MAX_COOKIE_STR_LENGTH 7
#define MAX_JOINTEAM_ARG_LENGTH 5
#define MAX_TIME_ARG_LENGTH 32
#define MAX_TIME_INFO_STR_LENGTH 150
#define MAX_JOIN_BAN_MSG_LENGTH 100
#define MAX_ADMINFLAGS_LENGTH 27
#define MAX_REASON_MENU_CHOICE_LENGTH 10
#define MAX_MENU_INT_CHOICE_LENGTH 4
#define MAX_DATABASE_ID_LENGTH 7
#define CTBAN_ADMIN_IS_CONSOLE 0
#define CONSOLE_USER_NAME "Console"
#define CONSOLE_AUTHID "STEAM_0:1:1"
#define RAGEBAN_LOG_REASON "Rage ban"
#define OFFLINE_NAME_UNAVAILBLE "Unavailable"
#define REASON_OFFLINECTBAN "Offline AuthId Ban"
#define CALLER_DO_NOT_REPLY -1

// Pre-processor macros
#define MAX_SAFE_ESCAPE_QUERY(%1) (TWO*(%1)+ONE)

/**
 * Checks if a client has been banned from CT.
 *
 * @param iClient		Client index.
 * @return 				The integer value of the CTBan cookie. A positive number indicates the client is CT Banned.
 * @error				Invalid client index.
 */
native int CTBan_IsClientBanned(int iClient);

/**
 * Checks the amount of time remaining on a ban, if any.
 *
 * @param iClient		Client index.
 * @return 				The minutes left on the CT Ban. If the player is CT Banned a 0 indicates a permanent ban length.
 * @error				Invalid client index.
 */
native int CTBan_GetTimeRemaining(int iClient);

/**
 * Checks if a client is allowed to play on the CT team even if they have a CT Ban.
 *
 * @param iClient		Client index.
 * @return 				True if the client is allowed to play on CT; false otherwise.
 * @error				Invalid client index.
 */
native bool CTBan_GetOverrideStatus(int iClient);

/**
 * Retrieve information on a CT Ban based on client index. The results are returned in the CTBan_GetBanInfoReturn forward.
 * The matching client index will be returned in the CTBan_GetBanInfoReturn forward.
 *
 * @param iClient		Client index.
 * @noreturn
 * @error				Invalid client index.
 */
native void CTBan_GetBanInfo(int iClient);

/**
 * Retrieve information on a CT Ban. The results are returned in the CTBan_GetOfflineBanInfoReturn forward.
 * The matching client AuthID will be returned in the CTBan_GetOfflineBanInfoReturn forward.
 *
 * @param sAuthID		Client AuthID.
 * @noreturn
 * @error				Invalid client AuthID or AuthID currently connected to server.
 */
native void CTBan_GetBanInfo_Offline(char[] sAuthID);

/**
 * Issues a CT Ban on the target in-game player.
 *
 * @param iClient		Client index.
 * @param iMinutes		Ban duration in minutes spent alive (0 for permanent duration).
 * @param iAdmin		Admin index.
 * @param sReason		Reason for ban.
 * @noreturn
 * @error				Invalid client index, Invalid time (less than 0), Invalid admin index, or Invalid reason.
 */
native void CTBan_Client(int iClient, int iMinutes = CTBAN_PERM_BAN_LENGTH, int iAdmin = CTBAN_ADMIN_IS_CONSOLE, char[] sReason = "No Reason Given.");

/**
 * Issues a CT Ban on the target AuthID.
 *
 * @param sAuthID		Client AuthID.
 * @noreturn
 * @error				Old version of SourceMod, Invalid client AuthID, or AuthID currently connected to server.
 */
native void CTBan_Client_Offline(char[] sAuthID);

/**
 * Changes the length of an existing CT Ban.
 *
 * @param iClient		Client index.
 * @param iMinutes		Ban duration in minutes spent alive (0 for permanent duration).
 * @param iAdmin		Admin index.
 * @noreturn
 * @error				Client Not CT Banned, Invalid client index, Invalid time (less than 0 or same time as existing CT Ban), or Invalid admin index.
 */
native void CTBan_ChangeBanLength(int iClient, int iMinutes, int iAdmin = CTBAN_ADMIN_IS_CONSOLE);

/**
 * Issues a CT UnBan on the target in-game player.
 *
 * @param iClient		Client index.
 * @param iAdmin		Admin index.
 * @noreturn
 * @error				Client Not CT Banned, Invalid client index, Invalid admin index, or Cookies Not Cached.
 */
native void CTBan_UnbanClient(int iClient, int iAdmin = CTBAN_ADMIN_IS_CONSOLE);

/**
 * Issues a CT UnBan on the target AuthID.
 *
 * @param sAuthID		Client AuthID.
 * @noreturn
 * @error				Old version of SourceMod, Invalid client AuthID, or AuthID currently connected to server.
 */
native void CTBan_UnbanClient_Offline(char[] sAuthID);

/**
 * Allows target to temporarily play on CT Team regardless of CT Ban status.
 *
 * @param iClient		Client index.
 * @param iAdmin		Admin index.
 * @noreturn
 * @error				Client Already on CT Team, Invalid client index, or Invalid admin index.
 */
native void CTBan_ForceCT(int iClient, int iAdmin = CTBAN_ADMIN_IS_CONSOLE);

/**
 * Removes any temporary override of a CT Ban placed on target.
 *
 * @param iClient		Client index.
 * @param iAdmin		Admin index.
 * @noreturn
 * @error				Invalid client index or Invalid admin index.
 */
native void CTBan_UnForceCT(int iClient, int iAdmin = CTBAN_ADMIN_IS_CONSOLE);

/**
 * Paired response to CTBan_GetBanInfo native.
 *
 * @param bFoundCompleteInfo	False only iClient and iTimeLeft is returned, otherwise all information is retrievable (Note: Reason may be blank).
 * @param iClient				Client index.
 * @param iTimeLeft				CT Ban duration remaining in minutes spent alive (0 indicates permanent duration).
 * @param iTimeStamp			UNIX timestamp of when the ban was initially entered.
 * @param sAdminName			Admin name at the time of the CT Ban.
 * @param sReason				CT Ban reason (Note: Reason may be blank).
 */
forward void CTBan_GetBanInfoReturn(bool bFoundCompleteInfo, int iClient, int iTimeLeft, int iTimeStamp, char[] sAdminName, char[] sReason);

/**
 * Paired response to CTBan_GetBanInfo_Offline native.
 *
 * @param bFoundInfo	False only sAuthID is returned, otherwise all information is retrievable (Note: Reason may be blank).
 * @param sAuthID		Client AuthID.
 * @param iTimeLeft		CT Ban duration remaining in minutes spent alive (0 indicates permanent duration).
 * @param iTimeStamp	UNIX timestamp of when the ban was initially entered.
 * @param sAdminName	Admin name at the time of the CT Ban.
 * @param sReason		CT Ban reason (Note: Reason may be blank).
 * @param sPerpName		The CT Banned player's name at the time of the CT Ban.
 */
forward void CTBan_GetOfflineBanInfoReturn(bool bFoundInfo, char[] sAuthID, int iTimeLeft, int iTimeStamp, char[] sAdminName, char[] sReason, char[] sPerpName);

/**
 * Called when a client is CT Banned.
 *
 * @param iClient		Client index.
 * @param iAdmin		Admin index.
 * @param iMinutes		CT Ban duration remaining in minutes spent alive (0 indicates permanent duration).
 * @param sReason		CT Ban reason (Note: Reason may be blank).
 */
forward void CTBan_OnClientBan(int iClient, int iAdmin, int iMinutes, const char[] sReason);

/**
 * Called when a client is CT UnBanned.
 *
 * @param iClient		Client index.
 * @param iAdmin		Admin index.
 */
forward void CTBan_OnClientUnban(int iClient, int iAdmin);

/**
 * Called when a client is Offline CT Banned.
 *
 * @param sAuthID		Client AuthID.
 * @param iAdmin		Admin index.
 */
forward void CTBan_OnClientBan_Offline(char[] sAuthID, int iAdmin);

/**
 * Called when a client is Offline CT UnBanned.
 *
 * @param sAuthID		Client AuthID.
 * @param iAdmin		Admin index.
 */
forward void CTBan_OnClientUnban_Offline(char[] sAuthID, int iAdmin);

/**
 * Called when a client is forced to CT even if the player has a CT Ban.
 *
 * @param iClient		Client index.
 * @param iAdmin		Admin index.
 */
forward void CTBan_OnForceCT(int iClient, int iAdmin);

/**
 * Called when a temporary override on CT Ban status is removed.
 *
 * @param iClient		Client index.
 * @param iAdmin		Admin index.
 */
forward void CTBan_OnUnforceCT(int iClient, int iAdmin);

/**
 * Check to see if a player's AuthID is currently connected to the server.
 *
 * @param sAuthID		Client AuthID.
 * @return				If connected returns the client index, 0 otherwise.
 */
stock int IsAuthIdConnected(char[] sAuthID)
{
	char sIndexAuthID[FIELD_AUTHID_MAXLENGTH];
	for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
	{
		if (IsClientInGame(iIndex))
		{
			GetClientAuthId(iIndex, AuthId_Steam2, sIndexAuthID, sizeof(sIndexAuthID));
			if (StrEqual(sAuthID, sIndexAuthID))
			{
				return iIndex;
			}
		}
	}

	return ZERO;
}

/**
 * Parse the reasons to CTBan a player and store in a dynamic array.
 *
 * @param hReasonsArray		Handle to dynamic array. Should be already created by a 'CreateArray(FIELD_REASON_MAXLENGTH)'.
 * @noreturn
 */
stock void ParseCTBanReasonsFile(Handle hReasonsArray)
{
	ClearArray(hReasonsArray);

	char sPathReasons[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPathReasons, sizeof(sPathReasons), "configs/ctban_reasons.ini");
	Handle hReasonsFile = OpenFile(sPathReasons, "r");

	if (hReasonsFile != null)
	{
		char sReasonsLine[FIELD_REASON_MAXLENGTH];

		while (ReadFileLine(hReasonsFile, sReasonsLine, sizeof(sReasonsLine)))
		{
			PushArrayString(hReasonsArray, sReasonsLine);
		}
	}
	
	CloseHandle(hReasonsFile);
}

/**
 * Parses the ban lengths and stores in a key value handle.
 *
 * @param hKeyValues		Handle to the key values structure. This should already be a global variable.
 * @return					Handle to the key values structure if created successfully, otherwise INVALID_HANDLE.
 */
stock Handle ParseCTBanLengthsFile(Handle hKeyValues)
{
	if (hKeyValues != INVALID_HANDLE)
	{
		CloseHandle(hKeyValues);
	}
	
	hKeyValues = CreateKeyValues("length");
	
	char sPathLengths[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPathLengths, sizeof(sPathLengths), "configs/ctban_times.ini");
	
	if (FileToKeyValues(hKeyValues, sPathLengths))
	{
		KvRewind(hKeyValues);
	}
	else
	{
		CloseHandle(hKeyValues);
		return INVALID_HANDLE;
	}
	
	return hKeyValues;
}

/**
 * Sets the colors in the [CTBAN] chat tag and exits if the game engine is not supported. 
 * If editing then do not exceed MAX_CHAT_BANNER_LENGTH or increase MAX_CHAT_BANNER_LENGTH.
 *
 * @param e_EngineVersion	EngineVersion from a GetEngineVersion() call.
 * @param sChatBanner		String to hold the chat banner inside.
 * @noreturn
 */
stock void SetCTBanChatBanner(EngineVersion e_EngineVersion, char sChatBanner[MAX_CHAT_BANNER_LENGTH])
{
	switch (e_EngineVersion) 
	{
		case Engine_CSS, Engine_TF2:
		{
			sChatBanner = "[\x0799CCFFCTBAN\x01] \x07FFD700%t";
		}
		case Engine_CSGO:
		{
			sChatBanner = "[\x0BCTBAN\x01] \x10%t";
		}
		default:
		{
			SetFailState("Game engine is not supported.");
		}
	}
}

public SharedPlugin __pl_ctban = 
{
	name = "ctban",
	file = "sm_ctban.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_ctban_SetNTVOptional()
{
	MarkNativeAsOptional("CTBan_IsClientBanned");
	MarkNativeAsOptional("CTBan_GetTimeRemaining");
	MarkNativeAsOptional("CTBan_GetOverrideStatus");
	MarkNativeAsOptional("CTBan_GetBanInfo");
	MarkNativeAsOptional("CTBan_GetBanInfo_Offline");
	MarkNativeAsOptional("CTBan_Client");
	MarkNativeAsOptional("CTBan_Client_Offline");
	MarkNativeAsOptional("CTBan_ChangeBanLength");
	MarkNativeAsOptional("CTBan_UnbanClient");
	MarkNativeAsOptional("CTBan_UnbanClient_Offline");
	MarkNativeAsOptional("CTBan_ForceCT");
	MarkNativeAsOptional("CTBan_UnForceCT");
}
#endif
