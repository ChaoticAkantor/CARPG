// Created by Chaotic Akantor.
// This file handles player recovery and hurt delay.

// Configurable variables for recovery system.

// Timer intervals.
const float flRegenTickHP = 1.0f; // Time between HP regen ticks (in seconds).
const float flRegenTickAP = 4.0f; // Time between AP regen ticks (in seconds).

// Regen percentages.
const float flPercentHPRegen = 1.0f; // Percentage of HP to regen per tick.
const float flPercentAPRegen = 1.0f; // Percentage of AP to regen per tick.

// Hurt delay.
const float flHurtDelayTick = 0.5f; // Time between hurt delay ticks (in seconds).
const float flHurtDelay = 2.0f; // Total time to stay "hurt" before regen starts again (in seconds).

// Toggles for enabling/disabling regen separately.
const bool bAllowHPRegen = true;
const bool bAllowAPRegen = true;

// Sprite on hud for icon when hurt delay is active.
const string strHurtDelaySprite = "tfchud06.spr";

dictionary g_PlayerRecoveryData; // Dictionary for recovery data.
dictionary g_RecoveryMapMultipliers; // Dictionary for map-specific multipliers.

float g_CurrentRecoveryMapMultiplier = 1.0f; // Global map multiplier for recovery systems.
bool g_bShowRecoveryPrefixMessage = true; // Toggle for displaying prefix message in chat.
string g_RecoveryPrefixMessage = ""; // Store prefix message to display to connecting players.

class RecoveryData
{
    bool isRegenerating = true;
    float hurtDelayCounter = 0.0f;
    float lastHurtTime = 0.0f;
}

class RecoveryMapMultipliers
{
    float hpRegenTickMultiplier;
    float apRegenTickMultiplier;
    float hurtDelayMultiplier;
    
    RecoveryMapMultipliers(float hpMult = 1.0f, float apMult = 1.0f, float hurtMult = 1.0f)
    {
        hpRegenTickMultiplier = hpMult;
        apRegenTickMultiplier = apMult;
        hurtDelayMultiplier = hurtMult;
    }
}

void InitializeRecovery() // Called in PluginInit().
{
// Balance recovery separately for different map series by multiplying the regen timers and hurt delay.
    @g_RecoveryMapMultipliers["th_"] = RecoveryMapMultipliers(2.0f, 2.0f, 3.0f);    // They Hunger.
    @g_RecoveryMapMultipliers["aom_"] = RecoveryMapMultipliers(2.0f, 2.0f, 3.0f);   // Afraid of Monsters Classic.
    @g_RecoveryMapMultipliers["aomdc_"] = RecoveryMapMultipliers(2.0f, 2.0f, 3.0f); // Afraid of Monsters Directors-Cut.
    @g_RecoveryMapMultipliers["hl_"] = RecoveryMapMultipliers(1.2f, 1.2f, 1.0f);    // Half-Life Campaign.
    @g_RecoveryMapMultipliers["of_"] = RecoveryMapMultipliers(1.2f, 1.2f, 1.0f);    // Opposing-Force Campaign.
    @g_RecoveryMapMultipliers["bs_"] = RecoveryMapMultipliers(1.2f, 1.2f, 1.0f);    // Blue-Shift Campaign.

    string mapName = string(g_Engine.mapname).ToLowercase(); // Update map multiplier first.
    g_CurrentRecoveryMapMultiplier = 1.0f; // Default multiplier.
    g_RecoveryPrefixMessage = ""; // Reset message to default.
    
    dictionary@ prefixes = g_RecoveryMapMultipliers;
    array<string>@ prefixKeys = prefixes.getKeys();
    
    for(uint i = 0; i < prefixKeys.length(); i++)
    {
        string prefix = prefixKeys[i].ToLowercase();
        if(mapName.Length() >= prefix.Length() && mapName.SubString(0, prefix.Length()) == prefix)
        {
            RecoveryMapMultipliers@ multipliers = cast<RecoveryMapMultipliers@>(prefixes[prefixKeys[i]]);
            if(multipliers !is null)
            {
                g_CurrentRecoveryMapMultiplier = multipliers.hpRegenTickMultiplier;
                g_RecoveryPrefixMessage = "=== CARPG Recovery: ===\\nMap prefix'" + prefixKeys[i] + "' detected.\nHP Regen: " + multipliers.hpRegenTickMultiplier + "x | AP Regen: " + multipliers.apRegenTickMultiplier + "x | Hurt Delay: " + multipliers.hurtDelayMultiplier + "x";
                g_Game.AlertMessage(at_console, g_RecoveryPrefixMessage + "\n\n");
            }
            break;
        }
    }
}

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
                float flCalcPercHP = (pPlayer.pev.max_health * flPercentHPRegen / 100) * g_CurrentRecoveryMapMultiplier;
                float flRegenHP = Math.max(int(flCalcPercHP), 1);

                if (pPlayer.pev.health < pPlayer.pev.max_health)
                {
                    pPlayer.pev.health = Math.min(pPlayer.pev.health + flRegenHP, pPlayer.pev.max_health);
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
                float flCalcPercAP = (pPlayer.pev.armortype * flPercentAPRegen / 100) * g_CurrentRecoveryMapMultiplier;
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
                    data.hurtDelayCounter = flHurtDelay * g_CurrentRecoveryMapMultiplier;
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
                numParams.x = 0;
                numParams.y = -0.1;
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
        data.hurtDelayCounter = flHurtDelay * g_CurrentRecoveryMapMultiplier;
        data.lastHurtTime = g_Engine.time;
    }
}