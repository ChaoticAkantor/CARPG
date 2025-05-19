// Plugin Created by Chaotic Akantor.
// This file handles player recovery and hurt delay.

dictionary g_PlayerRecoveryData;

class RecoveryData
{
    bool isRegenerating = true;
    float hurtDelayCounter = 0.0f;
    float lastHurtTime = 0.0f;
}

const float flRegenTickHP = 1.0f; // Time between HP regen ticks.
const float flRegenTickAP = 2.0f; // Time between AP regen ticks.
const float flHurtDelayTick = 0.5f; // Time between hurt delay ticks.
const float flHurtDelay = 3.0f; // Total time to stay "hurt" before regen starts.
const float flPercentHPRegen = 1.0f; // % of HP to regen per tick.
const float flPercentAPRegen = 1.0f; // % of AP to regen per tick.
const bool bAllowHPRegen = true;
const bool bAllowAPRegen = true;
const string strMedkitSound = "items/weapondrop1.wav";
const string strHurtDelaySprite = "tfchud06.spr";

void RegenTickHP() // Regen HP.
{   
    const int iMaxPlayers = g_Engine.maxClients;
    for (int i = 1; i <= iMaxPlayers; ++i)
    {   
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if (pPlayer !is null && pPlayer.IsAlive())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(!g_PlayerRecoveryData.exists(steamID))
            {
                RecoveryData data;
                @g_PlayerRecoveryData[steamID] = data;
            }

            RecoveryData@ data = cast<RecoveryData@>(g_PlayerRecoveryData[steamID]);
            if(data !is null && data.isRegenerating && bAllowHPRegen)
            {
                float flCalcPercHP = pPlayer.pev.max_health * flPercentHPRegen / 100;
                float iRegenHP = Math.max(int(flCalcPercHP), 1);

                if (pPlayer.pev.health < pPlayer.pev.max_health)
                {
                    pPlayer.pev.health = Math.min(pPlayer.pev.health + iRegenHP, pPlayer.pev.max_health);
                }
            }
        }
    }
}

void RegenTickAP() // Regen AP.
{   
    const int iMaxPlayers = g_Engine.maxClients;
    for (int i = 1; i <= iMaxPlayers; ++i)
    {   
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if (pPlayer !is null && pPlayer.IsAlive())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(!g_PlayerRecoveryData.exists(steamID))
            {
                RecoveryData data;
                @g_PlayerRecoveryData[steamID] = data;
            }

            RecoveryData@ data = cast<RecoveryData@>(g_PlayerRecoveryData[steamID]);
            if(data !is null && data.isRegenerating && bAllowAPRegen)
            {
                float flCalcPercAP = pPlayer.pev.armortype * flPercentAPRegen / 100;
                float iRegenAP = Math.max(int(flCalcPercAP), 1);

                if (pPlayer.pev.armorvalue < pPlayer.pev.armortype)
                {
                    pPlayer.pev.armorvalue = Math.min(pPlayer.pev.armorvalue + iRegenAP, pPlayer.pev.armortype);
                }
            }
        }
    }
}

void HurtDelayTick() // Think.
{
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
                    data.hurtDelayCounter = flHurtDelay;
                    data.isRegenerating = true;
                }
            }
        }
    }
}

void UpdateHUDHurtDelay() // Update HUD for hurt delay sprite.
{
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
                HUDNumDisplayParams numParams;
                numParams.channel = 6;
                numParams.x = 0.05;
                numParams.y = 10;
                numParams.fadeinTime = 0;
                numParams.fadeoutTime = 0;
                numParams.holdTime = 0.5;
                numParams.fxTime = 0;
                numParams.spritename = strHurtDelaySprite;
                numParams.left = 176;
                numParams.top = 120;
                numParams.width = 38;
                numParams.height = 38;
                numParams.defdigits = 1;
                numParams.maxdigits = 1;
                numParams.value = data.hurtDelayCounter;
                numParams.color1 = RGBA(255, 0, 0, 255);
                numParams.color2 = RGBA(255, 0, 0, 255);

                g_PlayerFuncs.HudNumDisplay(pPlayer, numParams);
            }
        }
    }
}

void StopPlayerRegen(CBasePlayer@ pPlayer) // Stop Player Regen when hurt, called in OnTakeDamage Hook.
{
    if(pPlayer is null)
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
        data.hurtDelayCounter = flHurtDelay;
        data.lastHurtTime = g_Engine.time;
    }
}