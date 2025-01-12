#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>


public Plugin myinfo = 
{
    name        = "TickrateDoorFixes",
    author      = "Sir, Griffin",
    description = "Fixes a handful of silly Tickrate bugs",
    version     = "1.4",
    url         = "https://github.com/TouchMe-Inc/l4d2_tickrate_door_fixes"
}


#define ENTITY_MAX_NAME_LENGTH      64

#define MAX_EDICTS                  (1 << 11) /*< Max # of edicts in a level */

enum
{
    DoorsTypeTracked_None = -1,
    DoorsTypeTracked_Prop_Door_Rotating = 0,
    DoorTypeTracked_Prop_Door_Rotating_Checkpoint = 1
};

static const char g_szDoorTypeTracked[][ENTITY_MAX_NAME_LENGTH] = 
{
    "prop_door_rotating",
    "prop_door_rotating_checkpoint"
};

enum struct DoorsData
{
    int DoorsData_Type;
    float DoorsData_Speed;
    bool DoorsData_ForceClose;
}

DoorsData g_ddDoors[MAX_EDICTS];

ConVar g_hCvarDoorSpeed = null;

float g_fDoorSpeed;

public void OnPluginStart()
{
    // Slow Doors
    g_hCvarDoorSpeed = CreateConVar("tick_door_speed", "1.3", "Sets the speed of all prop_door entities on a map. 1.05 means = 105% speed");
    g_hCvarDoorSpeed.AddChangeHook(Cvar_Changed);
    g_fDoorSpeed = g_hCvarDoorSpeed.FloatValue;
    
    Door_ClearSettingsAll();
    Door_GetSettingsAll();
    Door_SetSettingsAll();
}

public void OnPluginEnd()
{
    Door_ResetSettingsAll();
}

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
    if (sClassName[0] != 'p') {
        return;
    }
    
    for (int i = 0; i < sizeof(g_szDoorTypeTracked); i++) {
        if (strcmp(sClassName, g_szDoorTypeTracked[i], false) != 0) {
            continue;
        }
    
        SDKHook(iEntity, SDKHook_SpawnPost, Hook_DoorSpawnPost);
    }
}

void Hook_DoorSpawnPost(int iEntity)
{
    if (!IsValidEntity(iEntity)) {
        return;
    }
    
    char sClassName[ENTITY_MAX_NAME_LENGTH];
    GetEntityClassname(iEntity, sClassName, sizeof(sClassName));

    // Save Original Settings.
    for (int i = 0; i < sizeof(g_szDoorTypeTracked); i++) {
        if (strcmp(sClassName, g_szDoorTypeTracked[i], false) != 0) {
            continue;
        }

        Door_GetSettings(iEntity, i);
    }

    // Set Settings.
    Door_SetSettings(iEntity);
}

void Cvar_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
    g_fDoorSpeed = g_hCvarDoorSpeed.FloatValue;

    Door_SetSettingsAll();
}

void Door_SetSettingsAll()
{
    int iEntity = -1;

    for (int i = 0; i < sizeof(g_szDoorTypeTracked); i++) {
        while ((iEntity = FindEntityByClassname(iEntity, g_szDoorTypeTracked[i])) != INVALID_ENT_REFERENCE) {
            Door_SetSettings(iEntity);
            SetEntProp(iEntity, Prop_Data, "m_bForceClosed", false);
        }
        
        iEntity = -1;
    }
}

void Door_SetSettings(int iEntity)
{
    float fSpeed = g_ddDoors[iEntity].DoorsData_Speed * g_fDoorSpeed;

    SetEntPropFloat(iEntity, Prop_Data, "m_flSpeed", fSpeed);
}

void Door_ResetSettingsAll()
{
    int iEntity = -1;

    for (int i = 0; i < sizeof(g_szDoorTypeTracked); i++)
    {
        while ((iEntity = FindEntityByClassname(iEntity, g_szDoorTypeTracked[i])) != INVALID_ENT_REFERENCE) {
            Door_ResetSettings(iEntity);
        }
        
        iEntity = -1;
    }
}

void Door_ResetSettings(int iEntity)
{

    float fSpeed = g_ddDoors[iEntity].DoorsData_Speed;

    SetEntPropFloat(iEntity, Prop_Data, "m_flSpeed", fSpeed);
}

void Door_GetSettingsAll()
{
    int iEntity = -1;
    
    for (int i = 0; i < sizeof(g_szDoorTypeTracked); i++) {
        while ((iEntity = FindEntityByClassname(iEntity, g_szDoorTypeTracked[i])) != INVALID_ENT_REFERENCE) {
            Door_GetSettings(iEntity, i);
        }
        
        iEntity = -1;
    }
}

void Door_GetSettings(int iEntity, int iDoorType)
{
    g_ddDoors[iEntity].DoorsData_Type = iDoorType;
    g_ddDoors[iEntity].DoorsData_Speed = GetEntPropFloat(iEntity, Prop_Data, "m_flSpeed");
    g_ddDoors[iEntity].DoorsData_ForceClose = view_as<bool>(GetEntProp(iEntity, Prop_Data, "m_bForceClosed"));
}

void Door_ClearSettingsAll()
{
    for (int i = 0; i < MAX_EDICTS; i++)
    {
        g_ddDoors[i].DoorsData_Type = DoorsTypeTracked_None;
        g_ddDoors[i].DoorsData_Speed = 0.0;
        g_ddDoors[i].DoorsData_ForceClose = false;
    }
}
