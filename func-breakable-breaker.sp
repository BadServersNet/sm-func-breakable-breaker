#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

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

public void OnPluginStart()
{
  HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
  int brokenCount = BreakBreakables();

  if (brokenCount == 0)
  {
    return;
  }

  PrintToChatAll(" \x04[BadServers]\x01 Broke \x04%d\x01 breakable%s.", brokenCount, brokenCount == 1 ? "" : "s");
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
