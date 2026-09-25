#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.0"

#define SF_BREAK_TRIGGER_ONLY 1
#define PERMANENT_HEALTH 1000000
#define MATERIAL_UNBREAKABLE_GLASS 7

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
StringMap g_DamageScriptedHammerIds;

public void OnPluginStart()
{
  HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
  HookEvent("player_team", OnPlayerTeam, EventHookMode_Post);
}

public void OnMapStart()
{
  g_BrokenCount = 0;

  delete g_DamageScriptedHammerIds;
  g_DamageScriptedHammerIds = FindDamageScriptedHammerIds();
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

  int material = GetEntProp(entity, Prop_Data, "m_Material");

  if (material == MATERIAL_UNBREAKABLE_GLASS)
  {
    return true;
  }

  bool isDamageScripted = IsDamageScripted(entity);

  if (isDamageScripted)
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

bool IsDamageScripted(int entity)
{
  int hammerId = GetEntProp(entity, Prop_Data, "m_iHammerID");
  char hammerIdKey[16];
  IntToString(hammerId, hammerIdKey, sizeof(hammerIdKey));

  return g_DamageScriptedHammerIds.ContainsKey(hammerIdKey);
}

StringMap FindDamageScriptedHammerIds()
{
  StringMap hammerIds = new StringMap();
  int entryCount = EntityLump.Length();

  for (int i = 0; i < entryCount; i++)
  {
    EntityLumpEntry entry = EntityLump.Get(i);
    AddDamageScriptedHammerId(entry, hammerIds);
    delete entry;
  }

  return hammerIds;
}

void AddDamageScriptedHammerId(EntityLumpEntry entry, StringMap hammerIds)
{
  char classname[64];
  entry.GetNextKey("classname", classname, sizeof(classname));

  if (!StrEqual(classname, "func_breakable"))
  {
    return;
  }

  bool hasDamageOutput = HasDamageOutput(entry);

  if (!hasDamageOutput)
  {
    return;
  }

  char hammerIdKey[16];
  int hammerIdIndex = entry.GetNextKey("hammerid", hammerIdKey, sizeof(hammerIdKey));

  if (hammerIdIndex == -1)
  {
    return;
  }

  hammerIds.SetValue(hammerIdKey, true);
}

bool HasDamageOutput(EntityLumpEntry entry)
{
  int keyCount = entry.Length;
  char key[64];

  for (int i = 0; i < keyCount; i++)
  {
    entry.Get(i, key, sizeof(key));
    bool isDamageOutput = StrEqual(key, "OnHealthChanged", false) || StrEqual(key, "OnTakeDamage", false);

    if (isDamageOutput)
    {
      return true;
    }
  }

  return false;
}
