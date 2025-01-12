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
    version     = "build_0001",
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

DoorsData g_eDoors[MAX_EDICTS];

ConVar g_cvDoorSpeed = null;

float g_fDoorSpeed = 1.0;

public void OnPluginStart()
{
    // Slow Doors
    g_cvDoorSpeed = CreateConVar("tick_door_speed", "1.3", "Sets the speed of all prop_door entities on a map. 1.05 means = 105% speed");
    g_cvDoorSpeed.AddChangeHook(CvChange_DoorSpeed);
    g_fDoorSpeed = g_cvDoorSpeed.FloatValue;

    Door_ClearSettingsAll();
    Door_GetSettingsAll();
    Door_SetNewSpeedAll();
}

void CvChange_DoorSpeed(ConVar convar, const char[] sOldValue, const char[] sNewValue)
{
    g_fDoorSpeed = convar.FloatValue;

    Door_SetNewSpeedAll();
}

public void OnPluginEnd()
{
    Door_ResetSpeedAll();
}

public void OnEntityCreated(int iEntity, const char[] szClassname)
{
    if (szClassname[0] != 'p') {
        return;
    }

    for (int i = 0; i < sizeof(g_szDoorTypeTracked); i++)
    {
        if (strcmp(szClassname, g_szDoorTypeTracked[i], true) == 0)
        {
            SDKHook(iEntity, SDKHook_SpawnPost, Hook_DoorSpawnPost);
            break;
        }
    }
}

void Hook_DoorSpawnPost(int iEntity)
{
    if (!IsValidEntity(iEntity)) {
        return;
    }

    char szClassname[ENTITY_MAX_NAME_LENGTH];
    GetEntityClassname(iEntity, szClassname, sizeof(szClassname));

    // Save Original Settings.
    for (int i = 0; i < sizeof(g_szDoorTypeTracked); i++)
    {
        if (strcmp(szClassname, g_szDoorTypeTracked[i], true) == 0)
        {
            Door_GetSettings(iEntity, i);
            Door_SetNewSpeed(iEntity);
            break;
        }
    }
}

void Door_SetNewSpeed(int iEntity)
{
    float fSpeed = g_eDoors[iEntity].DoorsData_Speed * g_fDoorSpeed;

    SetEntPropFloat(iEntity, Prop_Data, "m_flSpeed", fSpeed);
}

void Door_ResetSpeed(int iEntity)
{
    float fSpeed = g_eDoors[iEntity].DoorsData_Speed;

    SetEntPropFloat(iEntity, Prop_Data, "m_flSpeed", fSpeed);
}

void Door_GetSettings(int iEntity, int iDoorType)
{
    g_eDoors[iEntity].DoorsData_Type = iDoorType;
    g_eDoors[iEntity].DoorsData_Speed = GetEntPropFloat(iEntity, Prop_Data, "m_flSpeed");
    g_eDoors[iEntity].DoorsData_ForceClose = view_as<bool>(GetEntProp(iEntity, Prop_Data, "m_bForceClosed"));
}

void Door_SetNewSpeedAll()
{
    int iEntity = -1;

    for (int i = 0; i < sizeof(g_szDoorTypeTracked); i++) {
        while ((iEntity = FindEntityByClassname(iEntity, g_szDoorTypeTracked[i])) != INVALID_ENT_REFERENCE) {
            Door_SetNewSpeed(iEntity);
            SetEntProp(iEntity, Prop_Data, "m_bForceClosed", false);
        }

        iEntity = -1;
    }
}

void Door_ResetSpeedAll()
{
    int iEntity = -1;

    for (int i = 0; i < sizeof(g_szDoorTypeTracked); i++)
    {
        while ((iEntity = FindEntityByClassname(iEntity, g_szDoorTypeTracked[i])) != INVALID_ENT_REFERENCE) {
            Door_ResetSpeed(iEntity);
        }

        iEntity = -1;
    }
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

void Door_ClearSettingsAll()
{
    for (int i = 0; i < MAX_EDICTS; i++)
    {
        g_eDoors[i].DoorsData_Type = DoorsTypeTracked_None;
        g_eDoors[i].DoorsData_Speed = 0.0;
        g_eDoors[i].DoorsData_ForceClose = false;
    }
}
