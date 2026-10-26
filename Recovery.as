// Created by Chaotic Akantor.
// This file handles player recovery and hurt delay.

// Configurable variables for recovery system.

// Timer intervals.
// HP/AP regen skills are handled in BasicSkills.as. This file keeps the hurt delay that pauses them.
const float flHurtDelayTick = 0.5f; // Time between hurt delay ticks (in seconds).
const float flHurtDelay = 2.0f; // Total time to stay "hurt" before regen starts again (in seconds).

// Sprite on hud for icon when hurt delay is active.
const string strHurtDelaySprite = "tfchud06.spr";

dictionary g_PlayerRecoveryData; // Dictionary for recovery data.

float g_CurrentRecoveryMapMultiplier = 1.0f; // Global map multiplier for recovery systems.
float g_CurrentAPRecoveryMapMultiplier = 1.0f;
float g_CurrentHurtDelayMapMultiplier = 1.0f;
bool g_bShowRecoveryPrefixMessage = true; // Toggle for displaying prefix message in chat.
string g_RecoveryPrefixMessage = ""; // Store prefix message to display to connecting players.

class RecoveryData
{
    bool isRegenerating = true;
    float hurtDelayCounter = 0.0f;
    float lastHurtTime = 0.0f;
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

bool CanPlayerRegen(const string& in steamID) // True unless the player is currently in their hurt delay.
{
    if(!g_PlayerRecoveryData.exists(steamID))
        return true;

    RecoveryData@ data = cast<RecoveryData@>(g_PlayerRecoveryData[steamID]);
    return data is null || data.isRegenerating;
}

void HurtDelayTick() // Think.
{
    if(IsCARPGDisabledOnCurrentMap())
        return;

    const int iMaxPlayers = g_Engine.maxClients;
    for (int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if (pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(!g_PlayerRecoveryData.exists(steamID))
                continue;

            RecoveryData@ data = cast<RecoveryData@>(g_PlayerRecoveryData[steamID]);
            if(data !is null && !data.isRegenerating)
            {
                data.hurtDelayCounter -= flHurtDelayTick;
                if(data.hurtDelayCounter <= 0)
                {
                    data.hurtDelayCounter = flHurtDelay * g_CurrentHurtDelayMapMultiplier;
                    data.isRegenerating = true;
                }
            }
        }
    }
}

void StopPlayerRegen(CBasePlayer@ pPlayer) // Stop Player Regen when hurt, called in OnTakeDamage Hook.
{
    if(IsCARPGDisabledOnCurrentMap() || pPlayer is null)
        return;
        
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(!g_PlayerRecoveryData.exists(steamID))
    {
        RecoveryData data;
        @g_PlayerRecoveryData[steamID] = data;
    }

    RecoveryData@ data = cast<RecoveryData@>(g_PlayerRecoveryData[steamID]);
    if(data !is null)
    {
        data.isRegenerating = false;
        data.hurtDelayCounter = flHurtDelay * g_CurrentHurtDelayMapMultiplier;
        data.lastHurtTime = g_Engine.time;
    }
}
