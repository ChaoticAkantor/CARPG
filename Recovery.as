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
                g_RecoveryPrefixMessage = "=== CARPG Recovery Balancing: ===\nMap prefix'" + prefixKeys[i] + "' detected.\nHP Regen: " + multipliers.hpRegenTickMultiplier + "x slower | AP Regen: " + multipliers.apRegenTickMultiplier + "x slower | Hurt Delay: " + multipliers.hurtDelayMultiplier + "x slower";
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
                float skillBonusHP = 0.0f;
                PlayerData@ rpgData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if (rpgData !is null)
                {
                    int skillLevel = rpgData.GetSkillLevel(SkillID::SKILL_REGENHP);
                    if (skillLevel > 0)
                        skillBonusHP = SKILL_REGENHP * flRegenTickHP * float(skillLevel);
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
                    int skillLevel = rpgData.GetSkillLevel(SkillID::SKILL_REGENAP);
                    if (skillLevel > 0)
                        skillBonusAP = SKILL_REGENAP * flRegenTickAP * float(skillLevel);
                }

                float flCalcPercAP = (pPlayer.pev.armortype * skillBonusAP) * g_CurrentRecoveryMapMultiplier;
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

void ApplyLifestealEffectBasic(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(steamID.IsEmpty() || !g_PlayerRPGData.exists(steamID))
            return;
 
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data is null || data.GetSkillLevel(SkillID::SKILL_LIFESTEAL) <= 0)
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
            bubbleMsg.WriteShort(g_EngineFuncs.ModelIndex(strBloodlustSprite));
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

    int skillLevel = data.GetSkillLevel(SkillID::SKILL_LIFESTEAL);
    float skillPower = SKILL_LIFESTEAL;
    float modifier = skillPower * skillLevel; // Scaled from lifesteal skill.

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

    if (healAmount > 0.0f && healAmount < 1.0f) // Ensure at 1HP healed if healAmount returns a value below 1.
        healAmount = 1.0f;

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