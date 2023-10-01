#include <sdktools>
#include <sdkhooks>
#include <openfortress>
#include <dhooks>
#pragma newdecls required

#define PLUGIN_VERSION "1.1.2"
public Plugin myinfo = {
    name = "[OF] SWAT",
    author = "Code: Fraeven, Rowedahelicon | Original Concept: Bungie | OF Concept: Greenie",
    description = "SWAT gametype for OF. Assault rifles and revolvers only with headshots enabled.",
    version = PLUGIN_VERSION,
    url = "https://scg.wtf"
};

ConVar g_Cvar_Enabled;
ConVar g_Cvar_DmgARHeadshot;
ConVar g_Cvar_DmgARBodyshot;
ConVar g_Cvar_DmgRevHeadshot;
ConVar g_Cvar_DmgRevBodyshot;
Handle g_Cvar_Tags;

Handle g_hGetDamageType = INVALID_HANDLE;
Handle g_hRespawn = INVALID_HANDLE;
Handle g_hAnnouncerThink = INVALID_HANDLE;

float g_flLastCritSound[MAXPLAYERS+1]  = {0.0};

public void OnPluginStart()
{
    // Custom ConVars
    g_Cvar_Enabled = CreateConVar("of_swat_enabled", "0", "Enable swat mode. DEFAULT: 0 (off)");
    g_Cvar_DmgARHeadshot = CreateConVar("of_swat_dmg_ar_headshot", "75.0", "Assault Rifle Headshot Damage");
    g_Cvar_DmgARBodyshot = CreateConVar("of_swat_dmg_ar_bodyshot", "25.0", "Assault Rifle Bodyshot Damage");
    g_Cvar_DmgRevHeadshot = CreateConVar("of_swat_dmg_rev_headshot", "150.0", "Revolver Headshot Damage");
    g_Cvar_DmgRevBodyshot = CreateConVar("of_swat_dmg_rev_bodyshot", "50.0", "Revolver Bodyshot Damage");

    // OF cvars
    g_Cvar_Tags = FindConVar("sv_tags");

    // For SDK Calls, Hooks, and Detours
    Handle hConf = LoadGameConfigFile("swat.games");

    // Detours
    g_hGetDamageType = DHookCreateFromConf(hConf, "CTFWeaponBase::GetDamageType");
    if (g_hGetDamageType == INVALID_HANDLE)
    {
        SetFailState("[SWAT] Failed to load CTFWeaponBase::GetDamageType");
    }
    DHookEnableDetour(g_hGetDamageType, false, Detour_GetDamageType);

    g_hRespawn = DHookCreateFromConf(hConf, "CWeaponSpawner::Respawn");
    if (g_hGetDamageType == INVALID_HANDLE)
    {
        SetFailState("[SWAT] Failed to load CWeaponSpawner::Respawn");
    }
    DHookEnableDetour(g_hRespawn, false, Detour_Respawn);

    g_hAnnouncerThink = DHookCreateFromConf(hConf, "CWeaponSpawner::AnnouncerThink");
    if (g_hGetDamageType == INVALID_HANDLE)
    {
        SetFailState("[SWAT] Failed to load CWeaponSpawner::AnnouncerThink");
    }
    DHookEnableDetour(g_hAnnouncerThink, false, Detour_AnnouncerThink);

    delete hConf;

    g_Cvar_Enabled.AddChangeHook(ConVar_EnableChanged);

    if (IsEnabled())
    {
        EnableSwat();
    }
}

public void OnPluginEnd()
{
    DisableSwat();
}

public void OF_OnPlayerSpawned(int client)
{
    if (!IsEnabled() ||
        !IsValidClient(client) ||
        GetClientTeam(client) == 0 ||
        GetClientTeam(client) == 1)
    {
        return;
    }

    RequestFrame(RequestFrame_Loadout, client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!IsEnabled())
    {
        return;
    }

    // Remove all weapon spawners
    if (IsWeaponSpawner(classname) || IsPill(classname))
    {
        DisableEntity(entity);
    }

    // Move AR to slot 2 for easier access
    if (IsAssaultRifle(classname))
    {
        SetEntProp(entity, Prop_Send, "m_iSlotOverride", 2);
    }
}

public Action Hook_Disable(int entity, int client)
{
    return Plugin_Handled;
}

public MRESReturn Detour_Respawn(int spawner)
{
    if (!IsEnabled())
    {
        return MRES_Ignored;
    }

    return MRES_Supercede;
}

public MRESReturn Detour_AnnouncerThink(int spawner)
{
    if (!IsEnabled())
    {
        return MRES_Ignored;
    }

    return MRES_Supercede;
}

public MRESReturn Detour_GetDamageType(int weapon, Handle hReturn)
{
    if (!IsEnabled())
    {
        return MRES_Ignored;
    }

    char classname[64];
    GetEntityClassname(weapon, classname, sizeof(classname));

    if (IsRevolver(classname) || IsAssaultRifle(classname))
    {
        // No damage falloff, enable headshots
        DHookSetReturn(hReturn, DMG_BULLET | DMG_NOCLOSEDISTANCEMOD | DMG_USE_HITLOCATIONS);

        return MRES_Supercede;
    }

    return MRES_Ignored;
}

public void ConVar_EnableChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!!StringToInt(newValue))
    {
        EnableSwat();
    }
    else
    {
        DisableSwat();
    }
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!IsEnabled() ||
        !IsValidClient(attacker) ||
        !IsValidClient(victim) ||
        attacker == victim ||
        TF2_IsPlayerInCondition(attacker, TFCond_Taunting) ||
        IsInvulnerable(victim))
    {
        return Plugin_Continue;
    }

    float originalDamage = damage;
    bool isHeadshot = !!(damagetype & DMG_CRIT);

    char weaponClass[64];
    GetClientWeapon(attacker, weaponClass, sizeof(weaponClass));

    if (IsAssaultRifle(weaponClass))
    {
        if (isHeadshot)
        {
            damage = GetConVarFloat(g_Cvar_DmgARHeadshot) / 3.0;
            PlayCritReceived(victim);
        }
        else
        {
            damage = GetConVarFloat(g_Cvar_DmgARBodyshot);
        }
    }
    else if (IsRevolver(weaponClass))
    {
        if (isHeadshot)
        {
            damage = GetConVarFloat(g_Cvar_DmgRevHeadshot) / 3.0;
            PlayCritReceived(victim);
        }
        else
        {
            damage = GetConVarFloat(g_Cvar_DmgRevBodyshot);
        }
    }

    if (originalDamage != damage)
    {
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

bool IsEnabled()
{
    return GetConVarBool(g_Cvar_Enabled);
}

void EnableSwat()
{
    // Give all players the swat loadouts and add hook
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client))
        {
            TF2_RemoveAllWeapons(client);
            SpawnLoadout(client);
            SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
            SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
        }
    }

    // Disable all disallowed entities
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "dm_weapon_spawner")) != -1)
    {
        DisableEntity(ent);
    }

    while ((ent = FindEntityByClassname(ent, "item_healthkit_tiny")) != -1)
    {
        DisableEntity(ent);
    }

    MyAddServerTag("SWAT");
}

void DisableSwat()
{
    // Remove the Take Damage hook from all players
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client))
        {
            SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
        }
    }

    // Enable all disallowed entities
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "dm_weapon_spawner")) != -1)
    {
        EnableEntity(ent);
    }

    while ((ent = FindEntityByClassname(ent, "item_healthkit_tiny")) != -1)
    {
        EnableEntity(ent);
    }

    // Reset the slot override for the assault rifle
    while ((ent = FindEntityByClassname(ent, "tf_weapon_assaultrifle")) != -1)
    {
        SetEntProp(ent, Prop_Send, "m_iSlotOverride", -1);
    }

    MyRemoveServerTag("SWAT");
}

void EnableEntity(int entity)
{
    RequestFrame(RequestFrame_EnableEntity, entity);
}

void DisableEntity(int entity)
{
    RequestFrame(RequestFrame_DisableEntity, entity);
}

void RequestFrame_EnableEntity(int entity)
{
    if (!IsValidEntity(entity))
    {
        return;
    }

    SDKUnhook(entity, SDKHook_SetTransmit, Hook_Disable);
    SDKUnhook(entity, SDKHook_Touch, Hook_Disable);
}

void RequestFrame_DisableEntity(int entity)
{
    if (!IsValidEntity(entity))
    {
        return;
    }

    SDKHook(entity, SDKHook_SetTransmit, Hook_Disable);
    SDKHook(entity, SDKHook_Touch, Hook_Disable);
}

void RequestFrame_Loadout(int client)
{
    if (!IsEnabled() || !IsValidClient(client))
    {
        return;
    }

    TF2_RemoveAllWeapons(client);
    SpawnLoadout(client);

    SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
    SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

void SpawnLoadout(int client)
{
    SpawnWeapon(client, "tf_weapon_crowbar");
    SpawnWeapon(client, "tf_weapon_revolver_mercenary");
    SpawnWeapon(client, "tf_weapon_assaultrifle");

    FakeClientCommand(client, "use tf_weapon_assaultrifle");
}

void SpawnWeapon(int client, char[] name)
{
    if (!IsValidClient(client))
    {
        return;
    }

    int weapon = GivePlayerItem(client, name);
    EquipPlayerWeapon(client, weapon);

    return;
}

bool IsRevolver(const char[] classname)
{
    return StrEqual(classname, "tf_weapon_revolver_mercenary");
}

bool IsAssaultRifle(const char[] classname)
{
    return StrEqual(classname, "tf_weapon_assaultrifle");
}

bool IsWeaponSpawner(const char[] classname)
{
    return StrEqual(classname, "dm_weapon_spawner");
}

bool IsPill(const char[] classname)
{
    return StrEqual(classname, "item_healthkit_tiny");
}

bool IsInvulnerable(int client)
{
    return TF2_IsPlayerInCondition(client, TFCond_Ubercharged) || TF2_IsPlayerInCondition(client, TFCond_SpawnProtect)
}

bool IsValidClient(int client)
{
    if (!client || client > MaxClients || client < 1)
    {
        return false;
    }

    if (!IsClientInGame(client))
    {
        return false;
    }

    return true;
}

void PlayCritReceived(int client)
{
    float currentTime = GetGameTime();
    float lastCritTime = g_flLastCritSound[client];

    bool recentPlayedCritSound = currentTime - lastCritTime < 0.5

    if (!IsFakeClient(client) && !recentPlayedCritSound)
    {
        EmitSoundToClient(client, "player/crit_received1.wav");
        g_flLastCritSound[client] = currentTime;
    }
}

stock void MyAddServerTag(const char[] tag)
{
    char currtags[128];
    if (g_Cvar_Tags == INVALID_HANDLE)
    {
        return;
    }

    GetConVarString(g_Cvar_Tags, currtags, sizeof(currtags));
    if (StrContains(currtags, tag) > -1)
    {
        // already have tag
        return;
    }

    char newtags[128];
    Format(newtags, sizeof(newtags), "%s%s%s", currtags, (currtags[0]!=0) ? ",": "", tag);
    int flags = GetConVarFlags(g_Cvar_Tags);
    SetConVarFlags(g_Cvar_Tags, flags & ~FCVAR_NOTIFY);
    SetConVarString(g_Cvar_Tags, newtags);
    SetConVarFlags(g_Cvar_Tags, flags);
}

stock void MyRemoveServerTag(const char[] tag)
{
    char newtags[128];
    if (g_Cvar_Tags == INVALID_HANDLE)
    {
        return;
    }

    GetConVarString(g_Cvar_Tags, newtags, sizeof(newtags));
    if (StrContains(newtags, tag) == -1)
    {
        return;
    }

    ReplaceString(newtags, sizeof(newtags), tag, "");
    ReplaceString(newtags, sizeof(newtags), ",,", "");
    int flags = GetConVarFlags(g_Cvar_Tags);
    SetConVarFlags(g_Cvar_Tags, flags & ~FCVAR_NOTIFY);
    SetConVarString(g_Cvar_Tags, newtags);
    SetConVarFlags(g_Cvar_Tags, flags);
}
