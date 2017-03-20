#pragma semicolon 1

#define PLUGIN_AUTHOR "Totenfluch"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>

#pragma newdecls required

int g_iCounter;
int g_iThreshold = 12;
int g_iThresholdRange = 8;

float g_fPlayerSpawn[MAXPLAYERS + 1][3];

public Plugin myinfo = 
{
	name = "Anti Rush / Spawn Kill", 
	author = PLUGIN_AUTHOR, 
	description = "Prevents Spawnrush", 
	version = PLUGIN_VERSION, 
	url = "http://ggc-base.de"
};

public void OnPluginStart() {
	HookEvent("player_death", onPlayerDeath);
	HookEvent("player_spawn", onPlayerSpawn);
	HookEvent("round_start", onRoundStart);
	g_iCounter = 1000;
}

public void onRoundStart(Event event, const char[] name, bool dontBroadcast) {
	g_iCounter = 0;
}

public void onPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!isValidClient(client))
		return;
	if (!IsPlayerAlive(client))
		return;
	if (GetClientTeam(client) != 2 && GetClientTeam(client) != 3)
		return;
	float cpos[3];
	GetClientAbsOrigin(client, cpos);
	g_fPlayerSpawn[client][0] = cpos[0];
	g_fPlayerSpawn[client][1] = cpos[1];
	g_fPlayerSpawn[client][2] = cpos[2];
}

public void onPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if (g_iCounter > g_iThreshold)
		return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (!isValidClient(attacker) || !isValidClient(client))
		return;
		
	if(client == attacker)
		return;
	
	float cpos[3];
	float checkPos[3];
	checkPos[0] = g_fPlayerSpawn[client][0];
	checkPos[1] = g_fPlayerSpawn[client][1];
	checkPos[2] = g_fPlayerSpawn[client][2];
	GetClientAbsOrigin(client, cpos);
	if (GetVectorDistance(cpos, checkPos) >= 100.0)
		return;
	
	if (g_iCounter <= g_iThresholdRange) {
		float apos[3];
		
		GetClientAbsOrigin(attacker, apos);
		if (GetVectorDistance(cpos, apos) < 600.0) {
			CreateTimer(0.1, delayedKick, GetClientUserId(attacker));
			CS_RespawnPlayer(client);
			return;
		}
	}
	
	if (g_iCounter <= g_iThreshold) {
		CreateTimer(0.1, delayedKick, GetClientUserId(attacker));
		CS_RespawnPlayer(client);
	}
	
}

public Action delayedKick(Handle Timer, int client) {
	int theClient = GetClientOfUserId(client);
	if (isValidClient(theClient)) {
		CPrintToChatAll("{red}Kicked %N for Spawnrush/Spawnkill", theClient);
		KickClient(theClient, "Spawnrush/Spawnkill");
	}
}

public void OnMapStart() {
	CreateTimer(1.0, refreshTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action refreshTimer(Handle Timer) {
	g_iCounter++;
}

stock bool isValidClient(int client) {
	return (1 <= client <= MaxClients && IsClientInGame(client));
} 