#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>


public Plugin myinfo =
{
    name        = "TickrateDoorFixes",
    author      = "Sir, Griffin, TouchMe",
    description = "Fixes a handful of silly Tickrate bugs",
    version     = "build_0002",
    url         = "https://github.com/TouchMe-Inc/l4d2_tickrate_door_fixes"
}


#define ENTITY_MAX_NAME_LENGTH      32

#define MAX_EDICTS                  (1 << 11) /*< Max # of edicts in a level */


enum
{
    DoorsTypeTracked_None = -1,
    DoorsTypeTracked_Prop_Door_Rotating = 0,
    DoorTypeTracked_Prop_Door_Rotating_Checkpoint = 1
};

StringMap g_mDoorTypes = null;


char g_szDoorTypeTracked[][ENTITY_MAX_NAME_LENGTH] =
{
    "prop_door_rotating",
    "prop_door_rotating_checkpoint"
};

float g_fDoorSpeedDefault[MAX_EDICTS];

ConVar g_cvDoorSpeed = null;
float g_fTickDoorSpeed = 1.0;


public void OnPluginStart()
{
    g_cvDoorSpeed = CreateConVar("tick_door_speed", "1.3", "Sets the speed of all prop_door entities on a map. 1.3 means = 130% speed");
    g_cvDoorSpeed.AddChangeHook(CvChange_DoorSpeed);
    g_fTickDoorSpeed = g_cvDoorSpeed.FloatValue;

    g_mDoorTypes = new StringMap();
    g_mDoorTypes.SetValue(g_szDoorTypeTracked[DoorsTypeTracked_Prop_Door_Rotating], DoorsTypeTracked_Prop_Door_Rotating);
    g_mDoorTypes.SetValue(g_szDoorTypeTracked[DoorTypeTracked_Prop_Door_Rotating_Checkpoint], DoorTypeTracked_Prop_Door_Rotating_Checkpoint);

    char szClassname[ENTITY_MAX_NAME_LENGTH];

    for (int iEntity = (MaxClients + 1); iEntity < MAX_EDICTS; iEntity++)
    {
        if (!IsValidEntity(iEntity)) {
            continue;
        }

        GetEntityClassname(iEntity, szClassname, sizeof szClassname);

        if (!g_mDoorTypes.ContainsKey(szClassname)) {
            continue;
        }

        g_fDoorSpeedDefault[iEntity] = GetEntPropFloat(iEntity, Prop_Data, "m_flSpeed");
    }
}

void CvChange_DoorSpeed(ConVar convar, const char[] szOldValue, const char[] szNewValue)
{
    g_fTickDoorSpeed = convar.FloatValue;

    UpdateDoorSpeedAll();
}

public void OnPluginEnd() {
    UpdateDoorSpeedAll(.bRestore = true);
}

public void OnEntityCreated(int iEntity, const char[] szClassname)
{
    if (!g_mDoorTypes.ContainsKey(szClassname)) {
        return;
    }

    SDKHook(iEntity, SDKHook_SpawnPost, Hook_DoorSpawn_Post);
}

void Hook_DoorSpawn_Post(int iEntity)
{
    if (!IsValidEntity(iEntity)) {
        return;
    }

    float fDoorSpeed = GetEntPropFloat(iEntity, Prop_Data, "m_flSpeed");
    SetEntPropFloat(iEntity, Prop_Data, "m_flSpeed", fDoorSpeed * g_fTickDoorSpeed);

    g_fDoorSpeedDefault[iEntity] = fDoorSpeed;
}

void UpdateDoorSpeedAll(bool bRestore = false)
{
    char szClassname[ENTITY_MAX_NAME_LENGTH];

    for (int iEntity = (MaxClients + 1); iEntity < MAX_EDICTS; iEntity++)
    {
        if (!IsValidEntity(iEntity)) {
            continue;
        }

        GetEntityClassname(iEntity, szClassname, sizeof szClassname);

        if (!g_mDoorTypes.ContainsKey(szClassname)) {
            continue;
        }

        SetEntPropFloat(iEntity, Prop_Data, "m_flSpeed", bRestore ? g_fDoorSpeedDefault[iEntity] : g_fDoorSpeedDefault[iEntity] * g_fTickDoorSpeed);
    }
}
