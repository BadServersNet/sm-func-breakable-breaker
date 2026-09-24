#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"

#define SF_BREAK_TRIGGER_ONLY 1
#define PERMANENT_HEALTH 1000000

public Plugin myinfo =
{
  name = "func_breakable Breaker",
  author = "BuSheeZy",
  description = "Breaks shootable func_breakable entities at round start while leaving static and map-controlled ones intact.",
  version = PLUGIN_VERSION,
  url = "https://BadServers.net"
};

int g_BrokenCount;
bool g_ClientNotified[MAXPLAYERS + 1];

public void OnPluginStart()
{
  HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
  HookEvent("player_team", OnPlayerTeam, EventHookMode_Post);
}

public void OnMapStart()
{
  g_BrokenCount = 0;
}

public void OnClientConnected(int client)
{
  g_ClientNotified[client] = false;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
  g_BrokenCount = BreakBreakables();
}

public void OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
  bool isDisconnecting = event.GetBool("disconnect");

  if (isDisconnecting)
  {
    return;
  }

  int userId = event.GetInt("userid");
  int client = GetClientOfUserId(userId);

  if (client == 0 || IsFakeClient(client))
  {
    return;
  }

  if (g_ClientNotified[client] || g_BrokenCount == 0)
  {
    return;
  }

  g_ClientNotified[client] = true;
  PrintToChat(client, " \x04[BadServers]\x01 Broke \x04%d\x01 breakable%s on this map.", g_BrokenCount, g_BrokenCount == 1 ? "" : "s");
}

int BreakBreakables()
{
  int brokenCount = 0;
  int entity = -1;

  while ((entity = FindEntityByClassname(entity, "func_breakable")) != -1)
  {
    bool isStatic = IsStaticBreakable(entity);

    if (isStatic)
    {
      continue;
    }

    bool broken = AcceptEntityInput(entity, "Break");

    if (!broken)
    {
      LogError("Failed to break func_breakable %d.", entity);
      continue;
    }

    brokenCount++;
  }

  return brokenCount;
}

bool IsStaticBreakable(int entity)
{
  int spawnFlags = GetEntProp(entity, Prop_Data, "m_spawnflags");
  bool breaksOnTriggerOnly = (spawnFlags & SF_BREAK_TRIGGER_ONLY) != 0;

  if (breaksOnTriggerOnly)
  {
    return true;
  }

  int health = GetEntProp(entity, Prop_Data, "m_iHealth");

  if (health <= 0)
  {
    return true;
  }

  return health >= PERMANENT_HEALTH;
}
