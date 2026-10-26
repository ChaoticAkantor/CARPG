/*
Basic skill's file.
*/

// Basic Skills update interval.
const float g_flBasicSkillsTick = 0.5f; // How often basic skills are updated.

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
    }
}