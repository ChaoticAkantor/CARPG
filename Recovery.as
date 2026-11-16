// Created by Chaotic Akantor.
// This file handles player recovery and hurt delay.

// Configurable variables for recovery system.

// HP/AP regen skills are handled in BasicSkills.as. This file keeps the hurt delay that pauses them.
const float flHurtDelay = 3.0f; // Total time to stay "hurt" before regen starts again (in seconds).

dictionary g_PlayerRecoveryData; // Dictionary for recovery data.

float g_CurrentRecoveryMapMultiplier = 1.0f; // Global map multiplier for recovery systems.
float g_CurrentAPRecoveryMapMultiplier = 1.0f;
float g_CurrentHurtDelayMapMultiplier = 1.0f;
bool g_bShowRecoveryPrefixMessage = true; // Toggle for displaying prefix message in chat.
string g_RecoveryPrefixMessage = ""; // Store prefix message to display to connecting players.

class RecoveryData
{
    float regenResumeTime = 0.0f;
}

void InitializeRecovery() // Called in PluginInit().
{
    g_CurrentRecoveryMapMultiplier = g_iCARPGCurrentMapMode == CARPG_MAP_BALANCED ? g_flCARPGHPRecoveryMultiplier : 1.0f;
    g_CurrentAPRecoveryMapMultiplier = g_iCARPGCurrentMapMode == CARPG_MAP_BALANCED ? g_flCARPGAPRecoveryMultiplier : 1.0f;
    g_CurrentHurtDelayMapMultiplier = g_iCARPGCurrentMapMode == CARPG_MAP_BALANCED ? g_flCARPGHurtDelayMultiplier : 1.0f;
    g_RecoveryPrefixMessage = ""; // Reset message to default.

    if(g_iCARPGCurrentMapMode == CARPG_MAP_BALANCED)
    {
        g_RecoveryPrefixMessage = "=== CARPG Recovery Balancing: ===\nMap rule '" + g_szCARPGMatchedMapPattern
            + "' detected.\nHP Regen: " + g_CurrentRecoveryMapMultiplier + "x slower | AP Regen: "
            + g_CurrentAPRecoveryMapMultiplier + "x slower | Hurt Delay: " + g_CurrentHurtDelayMapMultiplier + "x slower";
        g_Game.AlertMessage(at_console, g_RecoveryPrefixMessage + "\n\n");
    }
}

bool CanPlayerRegen(CBasePlayer@ pPlayer) // True unless the player is currently in their hurt delay.
{
    if(pPlayer is null)
        return false;

    string playerKey = string(pPlayer.entindex());
    if(!g_PlayerRecoveryData.exists(playerKey))
        return true;

    RecoveryData@ data = cast<RecoveryData@>(g_PlayerRecoveryData[playerKey]);
    if(data is null)
    {
        g_Game.AlertMessage(at_console, "CARPG: Invalid recovery data for player " + playerKey + ".\n");
        return false;
    }
    return g_Engine.time >= data.regenResumeTime;
}

void StopPlayerRegen(CBasePlayer@ pPlayer)
{
    if(IsCARPGDisabledOnCurrentMap() || pPlayer is null)
        return;
        
    string playerKey = string(pPlayer.entindex());
    if(!g_PlayerRecoveryData.exists(playerKey))
    {
        RecoveryData newData;
        @g_PlayerRecoveryData[playerKey] = newData;
    }

    RecoveryData@ data = cast<RecoveryData@>(g_PlayerRecoveryData[playerKey]);
    if(data !is null)
        data.regenResumeTime = g_Engine.time + flHurtDelay * g_CurrentHurtDelayMapMultiplier;
    else
        g_Game.AlertMessage(at_console, "CARPG: Invalid recovery data for player " + playerKey + ".\n");
}
