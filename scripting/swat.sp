#include <sdktools>
#include <sdkhooks>
#include <openfortress>
#include <ofitems>
#include <dhooks>

#define PLUGIN_VERSION "1.0.0"
public Plugin myinfo = {
    name = "[OF] Swat",
    author = "Code: Fraeven, Rowedahelicon | Original Concept: Bungie | OF Concept: Greenie",
    description = "Swat gametype for OF. Assault rifles and revolvers only with headshots enabled.",
    version = PLUGIN_VERSION,
    url = "https://scg.wtf"
};

ConVar g_Cvar_Enabled;
ConVar g_Cvar_DmgARHeadshot;
ConVar g_Cvar_DmgARBodyshot;
ConVar g_Cvar_DmgRevHeadshot;
ConVar g_Cvar_DmgRevBodyshot;

Handle g_hGetDamageType = INVALID_HANDLE;

public void OnPluginStart()
{
    // Custom ConVars
    g_Cvar_Enabled = CreateConVar("of_swat_enabled", "0", "Enable swat mode. DEFAULT: 0 (off)");
    g_Cvar_DmgARHeadshot = CreateConVar("of_swat_dmg_ar_headshot", "50.0", "Assault Rifle Headshot Damage");
    g_Cvar_DmgARBodyshot = CreateConVar("of_swat_dmg_ar_bodyshot", "25.0", "Assault Rifle Bodyshot Damage");
    g_Cvar_DmgRevHeadshot = CreateConVar("of_swat_dmg_rev_headshot", "150.0", "Revolver Headshot Damage");
    g_Cvar_DmgRevBodyshot = CreateConVar("of_swat_dmg_rev_bodyshot", "40.0", "Revolver Bodyshot Damage");

    // For SDK Calls, Hooks, and Detours
    Handle hConf = LoadGameConfigFile("swat.games");

    // Detours
    g_hGetDamageType = DHookCreateFromConf(hConf, "CTFWeaponBase::GetDamageType");
    if (g_hGetDamageType == INVALID_HANDLE)
    {
        SetFailState("[Swat] Failed to load CTFWeaponBase::GetDamageType");
    }
    DHookEnableDetour(g_hGetDamageType, false, Detour_GetDamageType);

    delete hConf;

    g_Cvar_Enabled.AddChangeHook(ConVar_EnableChanged);
}

public bool IsEnabled()
{
    return GetConVarBool(g_Cvar_Enabled);
}

public void ConVar_EnableChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!!StringToInt(newValue))
    {
        EnableSwat();
    }
}

public void EnableSwat()
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

    // Remove all disallowed entities
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "dm_weapon_spawner")) != -1)
    {
        RequestFrame(RequestFrame_RemoveEntity, ent);
    }

    while ((ent = FindEntityByClassname(ent, "item_healthkit_tiny")) != -1)
    {
        RequestFrame(RequestFrame_RemoveEntity, ent);
    }
}

stock Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!IsEnabled())
    {
        return Plugin_Continue;
    }

    float originalDamage = damage;
    bool isHeadshot = !!(damagetype & DMG_CRIT);

    char weaponClass[64];
    GetClientWeapon(attacker, weaponClass, sizeof(weaponClass));

    if (StrEqual(weaponClass, "tf_weapon_assaultrifle"))
    {
        if (isHeadshot)
        {
            damage = GetConVarFloat(g_Cvar_DmgARHeadshot) / 3.0;
        }
        else
        {
            damage = GetConVarFloat(g_Cvar_DmgARBodyshot);
        }
    }
    else if (StrEqual(weaponClass, "tf_weapon_revolver_mercenary"))
    {
        if (isHeadshot)
        {
            damage = GetConVarFloat(g_Cvar_DmgRevHeadshot) / 3.0;
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

public void OF_OnPlayerSpawned(int client)
{
    if (!IsEnabled() || !IsValidClient(client))
    {
        return;
    }

    RequestFrame(RequestFrame_Loadout, client);
    SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
    SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void RequestFrame_Loadout(client)
{
    if (!IsEnabled() || !IsValidClient(client))
    {
        return;
    }

    TF2_RemoveAllWeapons(client);
    SpawnLoadout(client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!IsEnabled())
    {
        return;
    }

    // Remove all weapon spawners
    if (StrEqual(classname, "dm_weapon_spawner") || StrEqual(classname, "item_healthkit_tiny"))
    {
        RequestFrame(RequestFrame_RemoveEntity, entity);
    }
}

void RequestFrame_RemoveEntity(int entity)
{
    if (!IsEnabled())
    {
        return;
    }

    RemoveEntity(entity);
}

stock bool IsValidClient(int client)
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

stock void SpawnLoadout(int client)
{
    SpawnWeapon(client, "tf_weapon_crowbar");
    SpawnWeapon(client, "tf_weapon_revolver_mercenary");
    SpawnWeapon(client, "tf_weapon_assaultrifle");

    FakeClientCommand(client, "use tf_weapon_assaultrifle");
}

stock void SpawnWeapon(int client, char[] name)
{
    if (!IsValidClient(client))
    {
        return;
    }

    int weapon = GivePlayerItem(client, name);
    EquipPlayerWeapon(client, weapon);

    return;
}

public MRESReturn Detour_GetDamageType(int weapon, Handle hReturn)
{
    if (!IsEnabled())
    {
        return MRES_Ignored;
    }

    // No damage falloff, enable headshots
    DHookSetReturn(hReturn, DMG_BULLET | DMG_NOCLOSEDISTANCEMOD | DMG_USE_HITLOCATIONS);
    return MRES_Supercede;
}
