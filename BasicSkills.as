/*
Basic skill's file.
*/

// Basic Skills update interval.
const float g_flBasicSkillsTick = 0.5f; // How often basic skills are updated.

// Toggles for enabling/disabling regen separately.
const bool bAllowHPRegen = true;
const bool bAllowAPRegen = true;

// Max HP, Max AP and basic HP -> AP Conversion Skills.
// The Vampire class skill (AP -> HP, SKILL_VAMPIRE_APCONVERSION) is separate and is applied afterwards from CalculateStats.
void ApplyBasicMaxStats(CBasePlayer@ pPlayer, ClassStats@ stats, ClassDefinition@ def)
{
    if (pPlayer is null || stats is null || def is null)
        return;

    // Base HP/AP + SKILL_BASIC_MAXHP / SKILL_BASIC_MAXAP bonuses.
    float maxHealth = def.baseHP * (1.0f + SKILL_BASIC_MAXHP * stats.GetSkillLevel(SkillID::SKILL_BASIC_MAXHP));
    float maxArmor = def.baseAP * (1.0f + SKILL_BASIC_MAXAP * stats.GetSkillLevel(SkillID::SKILL_BASIC_MAXAP));

    // Basic HP -> AP conversion skill.
    float hpConversionBonus = SKILL_BASIC_HPCONVERSION * stats.GetSkillLevel(SkillID::SKILL_BASIC_HPCONVERSION);
    float hpToConvert = maxHealth * hpConversionBonus; // HP amount converted to AP.

    pPlayer.pev.max_health = maxHealth - hpToConvert;
    pPlayer.pev.armortype = maxArmor + hpToConvert;

    // Ensure max health doesn't ever drop below 1, otherwise it will render the player dead!
    if (pPlayer.pev.max_health < 1.0f)
        pPlayer.pev.max_health = 1.0f;
}

// HP Regen Skill. Skill value is % of max HP per second, scaled to the tick interval.
void ApplyHPRegen(CBasePlayer@ pPlayer, PlayerData@ rpgData)
{
    if (!bAllowHPRegen || pPlayer is null || rpgData is null || !pPlayer.IsAlive())
        return;

    int skillLevel = rpgData.GetSkillLevel(SkillID::SKILL_BASIC_REGENHP);
    if (skillLevel <= 0 || pPlayer.pev.health >= pPlayer.pev.max_health)
        return;

    float regenHP = pPlayer.pev.max_health * SKILL_BASIC_REGENHP * g_flBasicSkillsTick * float(skillLevel) * g_CurrentRecoveryMapMultiplier;
    pPlayer.pev.health = Math.min(pPlayer.pev.health + regenHP, pPlayer.pev.max_health);
}

// AP Regen Skill. Skill value is % of max AP per second, scaled to the tick interval.
void ApplyAPRegen(CBasePlayer@ pPlayer, PlayerData@ rpgData)
{
    if (!bAllowAPRegen || pPlayer is null || rpgData is null || !pPlayer.IsAlive())
        return;

    int skillLevel = rpgData.GetSkillLevel(SkillID::SKILL_BASIC_REGENAP);
    if (skillLevel <= 0 || pPlayer.pev.armorvalue >= pPlayer.pev.armortype)
        return;

    float regenAP = pPlayer.pev.armortype * SKILL_BASIC_REGENAP * g_flBasicSkillsTick * float(skillLevel) * g_CurrentAPRecoveryMapMultiplier;
    pPlayer.pev.armorvalue = Math.min(pPlayer.pev.armorvalue + regenAP, pPlayer.pev.armortype);
}

// Medkit Capacity Skill.
const float flMedkitBaseCapacity = 100.0f; // Base medkit capacity.

float GetScaledMedkitCapacity(PlayerData@ rpgData)
{
    if (rpgData is null)
        return flMedkitBaseCapacity;

    int skillLevel = rpgData.GetSkillLevel(SkillID::SKILL_BASIC_MEDKITCAPACITY);

    return flMedkitBaseCapacity * (1.0f + SKILL_BASIC_MEDKITCAPACITY * skillLevel);
}

void ApplyMedkitCapacity(CBasePlayer@ pPlayer, PlayerData@ rpgData)
{
    if (pPlayer is null || rpgData is null)
        return;

    pPlayer.SetMaxAmmo('health', int(GetScaledMedkitCapacity(rpgData)));
}

// Lifesteal and Armorsteal Skills. Called from the OnTakeDamage hook in CARPG.as.
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

    NetworkMessage bubbleMsgHP(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
        bubbleMsgHP.WriteByte(TE_BUBBLES);
        bubbleMsgHP.WriteCoord(mins.x);
        bubbleMsgHP.WriteCoord(mins.y);
        bubbleMsgHP.WriteCoord(mins.z);
        bubbleMsgHP.WriteCoord(maxs.x);
        bubbleMsgHP.WriteCoord(maxs.y);
        bubbleMsgHP.WriteCoord(maxs.z);
        bubbleMsgHP.WriteCoord(80.0f); // Height of bubbles effect.
        bubbleMsgHP.WriteShort(GetModelIndex(strHealAuraEffectSprite));
        bubbleMsgHP.WriteByte(2); // Count.
        bubbleMsgHP.WriteCoord(6.0f);
    bubbleMsgHP.End();
}

// Lifesteal and Armorsteal Skills. Called from the OnTakeDamage hook in CARPG.as.
void ApplyArmorstealEffectBasic(CBasePlayer@ pPlayer)
{
    if(pPlayer is null)
        return;

    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(steamID.IsEmpty() || !g_PlayerRPGData.exists(steamID))
        return;

    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
    if(data is null || data.GetSkillLevel(SkillID::SKILL_BASIC_ARMORSTEAL) <= 0)
        return;

        Vector origin = pPlayer.pev.origin;
        origin.z += 32; // Offset to center of entity.
        
        Vector endPoint = origin;
        endPoint.z += 10; // Trail moves upward.

        // Create sprite trail effect.
        NetworkMessage msg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            msg.WriteByte(TE_SPRITETRAIL);
            msg.WriteCoord(origin.x);
            msg.WriteCoord(origin.y);
            msg.WriteCoord(origin.z);
            msg.WriteCoord(endPoint.x);
            msg.WriteCoord(endPoint.y);
            msg.WriteCoord(endPoint.z);
            msg.WriteShort(GetModelIndex(strHealAuraAPEffectSprite));
            msg.WriteByte(2);  // Count.
            msg.WriteByte(1);  // Life in 0.1's.
            msg.WriteByte(2);  // Scale in 0.1's.
            msg.WriteByte(15); // Velocity along vector in 10's.
            msg.WriteByte(5);  // Random velocity in 10's.
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

        ApplyArmorstealEffectBasic(pPlayer); // Visual effect for restoration from armorsteal.

        return healAmount;
    }

    return 0.0f;
}

void UpdateBasicSkills() // Update basic skills.
{
    if(IsCARPGDisabledOnCurrentMap())
        return;

    const int iMaxPlayers = g_Engine.maxClients;
    for (int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if (pPlayer is null || !pPlayer.IsConnected())
            continue;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if (steamID.IsEmpty() || !g_PlayerRPGData.exists(steamID))
            continue;

        PlayerData@ rpgData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if (rpgData is null)
            continue;

        // Apply/update basic skills.
        ApplyMedkitCapacity(pPlayer, rpgData);

        // Regen is paused while the player is in their hurt delay (see Recovery.as).
        if (CanPlayerRegen(steamID))
        {
            ApplyHPRegen(pPlayer, rpgData);
            ApplyAPRegen(pPlayer, rpgData);
        }
    }
}