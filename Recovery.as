// Created by Chaotic Akantor.
// This file handles player recovery and hurt delay.

// Configurable variables for recovery system.

// Timer intervals.
const float flRegenTickHP = 1.0f; // Time between HP regen ticks (in seconds).
const float flRegenTickAP = 1.0f; // Time between AP regen ticks (in seconds).

// Hurt delay.
const float flHurtDelayTick = 0.5f; // Time between hurt delay ticks (in seconds).
const float flHurtDelay = 2.0f; // Total time to stay "hurt" before regen starts again (in seconds).

// Toggles for enabling/disabling regen separately.
const bool bAllowHPRegen = true;
const bool bAllowAPRegen = true;

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

void RegenTickHP() // Regen HP.
{   
    if(IsCARPGDisabledOnCurrentMap())
        return;

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
                float skillBonusHP = 0.0f;
                PlayerData@ rpgData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if (rpgData !is null)
                {
                    int skillLevel = rpgData.GetSkillLevel(SkillID::SKILL_BASIC_REGENHP);
                    if (skillLevel > 0)
                        skillBonusHP = SKILL_BASIC_REGENHP * flRegenTickHP * float(skillLevel);
                }

                float flCalcPercHP = (pPlayer.pev.max_health * skillBonusHP) * g_CurrentRecoveryMapMultiplier;
                float flRegenHP = flCalcPercHP;

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
    if(IsCARPGDisabledOnCurrentMap())
        return;

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
                float skillBonusAP = 0.0f;
                PlayerData@ rpgData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if (rpgData !is null)
                {
                    int skillLevel = rpgData.GetSkillLevel(SkillID::SKILL_BASIC_REGENAP);
                    if (skillLevel > 0)
                        skillBonusAP = SKILL_BASIC_REGENAP * flRegenTickAP * float(skillLevel);
                }

                float flCalcPercAP = (pPlayer.pev.armortype * skillBonusAP) * g_CurrentAPRecoveryMapMultiplier;
                float flRegenAP = flCalcPercAP;
                //Math.max(flCalcPercAP, 1.0f);

                if (pPlayer.pev.armorvalue < pPlayer.pev.armortype)
                {
                    pPlayer.pev.armorvalue = Math.min(pPlayer.pev.armorvalue + flRegenAP, pPlayer.pev.armortype);
                }
            }
        }
    }
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

void ApplyLifestealEffectBasic(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(steamID.IsEmpty() || !g_PlayerRPGData.exists(steamID))
            return;
 
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data is null || data.GetSkillLevel(SkillID::SKILL_BASIC_LIFESTEAL) <= 0)
            return;

        Vector pos = pPlayer.pev.origin;
        Vector mins = pos - Vector(16, 16, 0);
        Vector maxs = pos + Vector(16, 16, 64);

        NetworkMessage bubbleMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
            bubbleMsg.WriteByte(TE_BUBBLES);
            bubbleMsg.WriteCoord(mins.x);
            bubbleMsg.WriteCoord(mins.y);
            bubbleMsg.WriteCoord(mins.z);
            bubbleMsg.WriteCoord(maxs.x);
            bubbleMsg.WriteCoord(maxs.y);
            bubbleMsg.WriteCoord(maxs.z);
            bubbleMsg.WriteCoord(112.0f);
            bubbleMsg.WriteShort(GetModelIndex(strBloodlustSprite));
            bubbleMsg.WriteByte(1); // Count.
            bubbleMsg.WriteCoord(2.0f);
        bubbleMsg.End();

        // Add dynamic light
        NetworkMessage msg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pPlayer.pev.origin);
            msg.WriteByte(TE_DLIGHT);
            msg.WriteCoord(pPlayer.pev.origin.x);
            msg.WriteCoord(pPlayer.pev.origin.y);
            msg.WriteCoord(pPlayer.pev.origin.z);
            msg.WriteByte(5); // Radius
            msg.WriteByte(int(BLOODLUST_COLOR.x));
            msg.WriteByte(int(BLOODLUST_COLOR.y));
            msg.WriteByte(int(BLOODLUST_COLOR.z));
            msg.WriteByte(2); // Life in 0.1s
            msg.WriteByte(1); // Decay rate
        msg.End();
    }

float GetScaledBasicLifesteal(PlayerData@ data)
{
    if(data is null)
        return 0.0f; // No lifesteal if no stats.

    int skillLevel = data.GetSkillLevel(SkillID::SKILL_BASIC_LIFESTEAL);
    float skillPower = SKILL_BASIC_LIFESTEAL;
    float modifier = skillPower * skillLevel; // Scaled from lifesteal skill.

    return modifier;
}

float GetScaledBasicArmorsteal(PlayerData@ data)
{
    if(data is null)
        return 0.0f; // No armorsteal if no stats.

    int skillLevel = data.GetSkillLevel(SkillID::SKILL_BASIC_ARMORSTEAL);
    float skillPower = SKILL_BASIC_ARMORSTEAL;
    float modifier = skillPower * skillLevel; // Scaled from armorsteal skill.

    return modifier;
}

float ProcessBasicLifesteal(CBasePlayer@ pPlayer, float damageDealt)
{
    if(pPlayer is null)
        return 0.0f;

    if(!pPlayer.IsAlive()) // No lifesteal if player is dead.
        return 0.0f;

    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(steamID.IsEmpty() || !g_PlayerRPGData.exists(steamID))
        return 0.0f;

    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
    if(data is null)
        return 0.0f;

    float lifestealMult = GetScaledBasicLifesteal(data);
    float healAmount = damageDealt * lifestealMult; // Heal amount from lifesteal.
    float maxHealth = pPlayer.pev.max_health; // Max health including overheal.
    float healAmountMin = 0.5f; // Minimum lifesteal amount to heal.

    // Clamp to minimum value if it's below the threshold. Gives the skill more oomph if it returns too low.
    if (healAmount > 0.0f && healAmount < healAmountMin) // Ensure a minimum amount is healed if healAmount returns a value below 1.
        healAmount = healAmountMin;

    if(pPlayer.pev.health < maxHealth) // Heal HP if below max.
    {
        pPlayer.pev.health = Math.min(pPlayer.pev.health + healAmount, maxHealth);

        ApplyLifestealEffectBasic(pPlayer); // Visual effect for healing from lifesteal.

        int randomPitch = int(Math.RandomFloat(80.0f, 120.0f));
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_ITEM, strBloodlustHitSound, 0.2f, 0.2f, 0, randomPitch);

        return healAmount;
    }

    return 0.0f;
}

float ProcessBasicArmorsteal(CBasePlayer@ pPlayer, float damageDealt)
{
    if(pPlayer is null)
        return 0.0f;

    if(!pPlayer.IsAlive()) // No armorsteal if player is dead.
        return 0.0f;

    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(steamID.IsEmpty() || !g_PlayerRPGData.exists(steamID))
        return 0.0f;

    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
    if(data is null)
        return 0.0f;

    float armorstealMult = GetScaledBasicArmorsteal(data);
    float healAmount = damageDealt * armorstealMult; // Heal amount from armorsteal.
    float maxArmor = pPlayer.pev.armortype; // Max armor including overheal.
    float healAmountMin = 0.25f; // Minimum armorsteal amount to heal.

    // Clamp to minimum value if it's below the threshold. Gives the skill more oomph if it returns too low.
    if (healAmount > 0.0f && healAmount < healAmountMin) // Ensure a minimum amount is healed if healAmount returns a value below 1.
        healAmount = healAmountMin;

    if(pPlayer.pev.armorvalue < maxArmor) // Heal armor if below max.
    {
        pPlayer.pev.armorvalue = Math.min(pPlayer.pev.armorvalue + healAmount, maxArmor);

        ApplyLifestealEffectBasic(pPlayer); // Visual effect for healing from lifesteal. TO CHANGE

        int randomPitch = int(Math.RandomFloat(80.0f, 120.0f));
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_ITEM, strBloodlustHitSound, 0.2f, 0.2f, 0, randomPitch);

        return healAmount;
    }

    return 0.0f;
}