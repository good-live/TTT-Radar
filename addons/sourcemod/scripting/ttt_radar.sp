#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "good_live"
#define PLUGIN_VERSION "1.01"

#include <sourcemod>
#include <sdktools>
#include <ttt>
#include <ttt_shop>
#include <cstrike>


public Plugin myinfo = 
{
	name = "ttt_radar", 
	author = PLUGIN_AUTHOR, 
	description = "Allows Traitor to buy a Compasss and Detctives to buy a jammer", 
	version = PLUGIN_VERSION, 
	url = "painlessgaming.eu"
};


bool g_bHasRadar[MAXPLAYERS + 1] = { false, ... };
bool g_bHasJammer[MAXPLAYERS + 1] = { false, ... };

ConVar g_cRadar_price;
ConVar g_cRadar_name;
ConVar g_cJammer_price;
ConVar g_cJammer_name;
public void OnPluginStart()
{
	TTT_IsGameCSGO();
	
	g_cRadar_price = CreateConVar("ttt_radar_price", "6000", "The Price of the radar");
	g_cRadar_name = CreateConVar("ttt_radar_name", "Radar","The name of the radar in the shop");
	g_cJammer_price = CreateConVar("ttt_jammer_price", "6000", "The Price of the jammer");
	g_cJammer_name = CreateConVar("ttt_jammer_name", "Jammer","The name of the jammer in the shop");
	
	CreateTimer(1.0, checkPlayers, _, TIMER_REPEAT);
	LoadTranslations("ttt.phrases");
	AutoExecConfig();
}

public void OnAllPluginsLoaded()
{
	char sJName[64];
	char sRName[64];
	g_cJammer_name.GetString(sJName, sizeof(sJName));
	g_cRadar_name.GetString(sRName, sizeof(sRName));
	TTT_RegisterCustomItem("jammer", sJName, g_cRadar_price.IntValue, TTT_TEAM_DETECTIVE);
	TTT_RegisterCustomItem("radar", sRName, g_cJammer_price.IntValue, TTT_TEAM_TRAITOR);
}

public void Reset()
{
	LoopValidClients(i){
		g_bHasRadar[i] = false;
		g_bHasJammer[i] = false;
	}
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	Reset();
	return Plugin_Continue;
}

public Action TTT_OnRoundStart_Pre()
{
	Reset();
	return Plugin_Continue;
}

public void TTT_OnRoundStartFailed(int p, int r, int d)
{
	Reset();
}

public void TTT_OnRoundStart(int i, int t, int d)
{
	Reset();
}

public void TTT_OnClientDeath(int v, int a)
{
	g_bHasRadar[v] = false;
	g_bHasJammer[v] = false;
}

public Action TTT_OnItemPurchased(int client, const char[] itemshort)
{
	if(TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if(strcmp(itemshort, "radar", false) == 0)
		{
			g_bHasRadar[client] = true;
			char log[MAX_NAME_LENGTH + 128];
			Format(log, sizeof(log), "%N bought a Radar", client);
			TTT_LogString(log);
		}
		else if(strcmp(itemshort, "jammer", false) == 0)
		{
			g_bHasJammer[client] = true;
		}
	}
}

public Action checkPlayers(Handle timer, any data)
{
	char unitString[12];
	char unitStringOne[12];
	
	float clientOrigin[3];
	float searchOrigin[3];
	float near;
	float distance;
	
	int nearest;
	
	
	Format(unitString, sizeof(unitString), "meters");
	Format(unitStringOne, sizeof(unitStringOne), "meter");
	
	
	
	
	// Client loop
	for (int client = 1; client <= MaxClients; client++)
	{
		// Valid client?
		if (g_bHasRadar[client] && IsPlayerAlive(client))
		{
			
			nearest = 0;
			near = 0.0;
			
			// Get origin
			GetClientAbsOrigin(client, clientOrigin);
			
			// Next client loop
			for (int search = 1; search <= MaxClients; search++)
			{
				if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && !g_bHasJammer[search] && TTT_GetClientRole(search) != TTT_TEAM_TRAITOR)
				{
					// Get distance to first client
					GetClientAbsOrigin(search, searchOrigin);
					
					distance = GetVectorDistance(clientOrigin, searchOrigin);
					
					// Is he more near to the player as the player before?
					if (near == 0.0)
					{
						near = distance;
						nearest = search;
					}
					
					if (distance < near)
					{
						near = distance;
						nearest = search;
					}
				}
			}
			
			// Found a player?
			if (nearest != 0)
			{
				float dist;
				float vecPoints[3];
				float vecAngles[3];
				float clientAngles[3];
				
				char directionString[64];
				char textToPrint[64];
				
				
				// Get the origin of the nearest player
				GetClientAbsOrigin(nearest, searchOrigin);
				
				// Angles
				GetClientAbsAngles(client, clientAngles);
				
				// Angles from origin
				MakeVectorFromPoints(clientOrigin, searchOrigin, vecPoints);
				GetVectorAngles(vecPoints, vecAngles);
				
				// Differenz
				float diff = clientAngles[1] - vecAngles[1];
				
				// Correct it
				if (diff < -180)
				{
					diff = 360 + diff;
				}
				
				if (diff > 180)
				{
					diff = 360 - diff;
				}
				
				
				// Now geht the direction
				
				// Up
				if (diff >= -22.5 && diff < 22.5)
				{
					Format(directionString, sizeof(directionString), "\xe2\x86\x91");
				}
				
				// right up
				else if (diff >= 22.5 && diff < 67.5)
				{
					Format(directionString, sizeof(directionString), "\xe2\x86\x97");
				}
				
				// right
				else if (diff >= 67.5 && diff < 112.5)
				{
					Format(directionString, sizeof(directionString), "\xe2\x86\x92");
				}
				
				// right down
				else if (diff >= 112.5 && diff < 157.5)
				{
					Format(directionString, sizeof(directionString), "\xe2\x86\x98");
				}
				
				// down
				else if (diff >= 157.5 || diff < -157.5)
				{
					Format(directionString, sizeof(directionString), "\xe2\x86\x93");
				}
				
				// down left
				else if (diff >= -157.5 && diff < -112.5)
				{
					Format(directionString, sizeof(directionString), "\xe2\x86\x99");
				}
				
				// left
				else if (diff >= -112.5 && diff < -67.5)
				{
					Format(directionString, sizeof(directionString), "\xe2\x86\x90");
				}
				
				// left up
				else if (diff >= -67.5 && diff < -22.5)
				{
					Format(directionString, sizeof(directionString), "\xe2\x86\x96");
				}
				
				
				
				Format(textToPrint, sizeof(textToPrint), "%s\n", directionString);
				
				
				// Distance to meters
				dist = near * 0.01905;
				
				
				Format(textToPrint, sizeof(textToPrint), "%s(%i %s)", textToPrint, RoundFloat(dist), (RoundFloat(dist) == 1 ? unitStringOne : unitString));
				
				Format(textToPrint, sizeof(textToPrint), "%s%N", textToPrint, nearest);
				
				// Print text
				PrintHintText(client, textToPrint);
			}
		}
	}
	
	return Plugin_Continue;
}