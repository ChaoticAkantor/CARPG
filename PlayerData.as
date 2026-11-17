const string strLevelUpSound = "misc/secret.wav"; // Sound played on level up.

string strSaveFileLocation = "scripts/plugins/store/"; // Default is scripts/plugins/store/  Make sure it ends with a slash.

dictionary g_PlayerRPGData;

enum CARPGHUDType
{
    CARPG_HUD_RPG = 0,
    CARPG_HUD_RESOURCE,
    CARPG_HUD_AMMO
}

enum CARPGHUDPosition
{
    CARPG_HUD_TOP_LEFT = 0,
    CARPG_HUD_BOTTOM_LEFT,
    CARPG_HUD_TOP_RIGHT,
    CARPG_HUD_BOTTOM_RIGHT,
    CARPG_HUD_BOTTOM_MIDDLE
}

const array<string> g_CARPGHUDColorNames =
{
    "Cyan", "White", "Red", "Green", "Lime", "Blue", "Light Blue", "Yellow",
    "Orange", "Gold", "Magenta", "Pink", "Purple", "Teal", "Aqua", "Coral",
    "Silver", "Gray", "Navy", "Mint", "Rose", "Amber", "Sky Blue", "Olive"
};

const array<Vector> g_CARPGHUDColorValues =
{
    Vector(0, 255, 255), Vector(255, 255, 255), Vector(255, 64, 64), Vector(0, 200, 80),
    Vector(128, 255, 0), Vector(64, 96, 255), Vector(96, 192, 255), Vector(255, 240, 0),
    Vector(255, 128, 0), Vector(255, 192, 0), Vector(255, 0, 255), Vector(255, 128, 192),
    Vector(160, 64, 255), Vector(0, 160, 160), Vector(0, 255, 160), Vector(255, 112, 80),
    Vector(192, 192, 192), Vector(128, 128, 128), Vector(32, 48, 128), Vector(128, 255, 192),
    Vector(220, 64, 96), Vector(224, 160, 32), Vector(64, 160, 255), Vector(160, 176, 48)
};

string GetCARPGHUDColorName(int colorIndex)
{
    if(colorIndex < 0 || uint(colorIndex) >= g_CARPGHUDColorNames.length())
        colorIndex = 0;
    return g_CARPGHUDColorNames[colorIndex];
}

Vector GetCARPGHUDColorValue(int colorIndex)
{
    if(colorIndex < 0 || uint(colorIndex) >= g_CARPGHUDColorValues.length())
        colorIndex = 0;
    return g_CARPGHUDColorValues[colorIndex];
}

// Returns the player's chosen minion glow colour, or defaultColor if they haven't picked one.
Vector GetMinionGlowColor(CBasePlayer@ pPlayer, const Vector &in defaultColor)
{
    if(pPlayer is null)
        return defaultColor;

    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(!g_PlayerRPGData.exists(steamID))
        return defaultColor;

    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
    if(data is null)
        return defaultColor;

    int colorIndex = data.GetMinionGlowColorIndex();
    if(colorIndex < 0 || uint(colorIndex) >= g_CARPGHUDColorValues.length())
        return defaultColor;

    return g_CARPGHUDColorValues[colorIndex];
}

string GetCARPGHUDPositionName(int hudType, int position)
{
    switch(position)
    {
        case CARPG_HUD_TOP_LEFT: return "Top-left";
        case CARPG_HUD_BOTTOM_LEFT: return "Bottom-left";
        case CARPG_HUD_TOP_RIGHT: return "Top-right";
        case CARPG_HUD_BOTTOM_RIGHT: return "Bottom-right";
        case CARPG_HUD_BOTTOM_MIDDLE:
            return hudType == CARPG_HUD_RESOURCE ? "Bottom-middle" : "Top-right";
    }
    return "Top-right";
}

float GetCARPGHUDPositionX(int hudType, int position)
{
    if(hudType == CARPG_HUD_RESOURCE && position == CARPG_HUD_BOTTOM_MIDDLE)
        return -1.0f;
    if(position == CARPG_HUD_TOP_LEFT || position == CARPG_HUD_BOTTOM_LEFT)
        return hudType == CARPG_HUD_AMMO ? 0.0f : 0.02f;
    return 1.0f;
}

float GetCARPGHUDPositionY(int hudType, int position)
{
    if(position == CARPG_HUD_TOP_LEFT || position == CARPG_HUD_TOP_RIGHT)
        return 0.1f;
    return hudType == CARPG_HUD_AMMO ? 0.92f : 0.9f;
}

// Max level and XP multiplier.
int g_iMaxLevel = 50; // Max player level, skill points are given per level, increasing this will increase skill points available.
int g_iScoreToXP = 1; // Amount of XP each score point is worth, 1 = 1 score is 1 XP.
int g_iXPPerScorePerClassAboveBaseMax = 1; // XP per score for each class above the base level cap.
int g_iMaxRebirthRank = (500 - g_iMaxLevel); // Max rank, reduced by default max player level.
int g_iRankPointsPerRank = 1; // Rank points awarded per rank.
int g_iClassLevelsPerRank = 1; // Level cap increase per rank.
int g_iRankXPBase = 48; // Base XP needed to reach rank 1.
float g_flRankXPMultiplier = 2.0f; // Rank XP requirement multiplier.
float g_flPlayerHUDInterval = 0.2f; // How often the player HUD updates.

int GetXPRequirement(int level, int baseXP, float multiplier)
{
    return int(baseXP * level * multiplier);
}

dictionary g_ClassNames = 
{
    {PlayerClass::CLASS_NONE, "None"},
    {PlayerClass::CLASS_MEDIC, "Medic"},
    {PlayerClass::CLASS_VAMPIRE, "Vampire"},
    {PlayerClass::CLASS_ENGINEER, "Engineer"},
    {PlayerClass::CLASS_ROBOMANCER, "Robomancer"},
    {PlayerClass::CLASS_XENOMANCER, "Xenomancer"},
    {PlayerClass::CLASS_NECROMANCER, "Necromancer"},
    {PlayerClass::CLASS_FROSTGUARD, "Frostguard"},
    {PlayerClass::CLASS_SHOCKTROOPER, "Shocktrooper"},
    {PlayerClass::CLASS_CLOAKER, "Cloaker"},
    {PlayerClass::CLASS_FIREBUG, "Firebug"},
    {PlayerClass::CLASS_SWARMER, "Swarmer"}
};

array<PlayerClass> g_ClassList = 
{
    PlayerClass::CLASS_MEDIC,
    PlayerClass::CLASS_VAMPIRE,
    PlayerClass::CLASS_ENGINEER,
    PlayerClass::CLASS_ROBOMANCER,
    PlayerClass::CLASS_XENOMANCER,
    PlayerClass::CLASS_NECROMANCER,
    PlayerClass::CLASS_FROSTGUARD,
    PlayerClass::CLASS_SHOCKTROOPER,
    PlayerClass::CLASS_CLOAKER,
    PlayerClass::CLASS_FIREBUG,
    PlayerClass::CLASS_SWARMER
};

enum PlayerClass 
{
    CLASS_NONE = 0,
    CLASS_MEDIC,
    CLASS_VAMPIRE,
    CLASS_ENGINEER,
    CLASS_ROBOMANCER,
    CLASS_XENOMANCER,
    CLASS_NECROMANCER,
    CLASS_FROSTGUARD,
    CLASS_SHOCKTROOPER,
    CLASS_CLOAKER,
    CLASS_FIREBUG,
    CLASS_SWARMER
}

// --- Per-class stat definitions. ---
class ClassDefinition 
{
    string name;
    float baseHP = 100.0f; // Base HP before skill bonuses.
    float baseAP = 100.0f; // Base AP before skill bonuses.

    ClassDefinition(string _name) 
    {
        name = _name;
    }
}

dictionary g_ClassDefinitions;

// --- Initialize per-class base stats and scaling. ---
void InitializeClassDefinitions()
{
    if(g_ClassDefinitions !is null)
        g_ClassDefinitions.deleteAll();

    for(uint i = 0; i < g_ClassList.length(); i++)
    {
        PlayerClass pClass = g_ClassList[i];
        if(g_ClassNames.exists(pClass))
        {
            ClassDefinition@ def = ClassDefinition(string(g_ClassNames[pClass]));
            @g_ClassDefinitions[pClass] = @def;
        }
    }
}

class ClassStats
{   
    // Skillpoint Handling.
    private int m_iSkillPointsPerLevel = 1; // Skill points gained per level.
    private int m_iSkillPoints = 1; // Total skill points earned (also level 1 start amount).

    // Skill levels: one entry per SkillID.
    private array<int> m_SkillLevels(int(SkillID::SKILL_MAX_COUNT), 0);

    // XP / Level tracking.
    private int m_iLevel = 1; // Current level.
    private int m_iCurrentLevelXP = 0; // XP accumulated within the current level.
    private int m_iXPNeededBase = 24; // Base XP needed for first level up.
    private float m_fXPNeededMult = 2.0f; // Multiply XP needed by this factor for each level.
    private int m_iMaxLevel = g_iMaxLevel; // Set default max level from global setting.
    private int m_iBasicSkillCapBonus = 0;
    private int m_iClassSkillCapBonus = 0;
    private string m_szSteamID;

    int GetSkillPointsPerLevel() { return m_iSkillPointsPerLevel; }
    int GetTotalSkillPoints()    { return m_iSkillPoints; }
    int GetSkillPoints()         { return m_iSkillPoints - GetSpentSkillPoints(); }

    int GetLevel()          { return m_iLevel; }
    int GetMaxLevel()       { return m_iMaxLevel; }
    int GetCurrentLevelXP() { return m_iCurrentLevelXP; }
    int GetNeededXP()       { return GetXPForLevel(m_iLevel); }

    bool IsMaxLevel() { return m_iLevel >= m_iMaxLevel; }

    // --- Skill methods ---

    int GetSkillLevel(SkillID id)
    {
        int idx = int(id);
        if(idx < 0 || idx >= int(SkillID::SKILL_MAX_COUNT)) return 0;
        return m_SkillLevels[idx];
    }

    float GetEffectiveSkillLevel(SkillID id)
    {
        int idx = int(id);
        if(idx < 0 || idx >= int(g_SkillDefs.length()) || g_SkillDefs[idx] is null)
            return 0.0f;
        return g_SkillDefs[idx].GetEffectiveLevel(GetSkillLevel(id));
    }

    int GetSkillMaxLevel(SkillID id)
    {
        int idx = int(id);
        if(idx < 0 || idx >= int(g_SkillDefs.length()) || g_SkillDefs[idx] is null)
            return 0;
        int bonus = idx <= int(SkillID::SKILL_BASIC_MEDKITCAPACITY) ? m_iBasicSkillCapBonus : m_iClassSkillCapBonus;
        return g_SkillDefs[idx].GetEffectiveMaxLevel(bonus);
    }

    int GetSpentSkillPoints()
    {
        int spent = 0;
        for(int i = 0; i < int(SkillID::SKILL_MAX_COUNT); i++)
            spent += m_SkillLevels[i];
        return spent;
    }

    // Attempts to spend one skill point on the given skill.
    // Returns true if successful.
    bool TrySpendSkillPoint(SkillID id)
    {
        if(GetSkillPoints() < 1) return false;
        int idx = int(id);
        if(idx < 0 || idx >= int(SkillID::SKILL_MAX_COUNT)) return false;
        if(g_SkillDefs.length() == 0) return false;
        SkillDefinition@ def = g_SkillDefs[idx];
        if(def is null) return false;
        int effectiveMax = GetSkillMaxLevel(id);
        if(m_SkillLevels[idx] >= effectiveMax) return false;
        m_SkillLevels[idx]++;
        return true;
    }

    // Refunds all spent skill points for this class.
    void ResetSkills()
    {
        for(int i = 0; i < int(SkillID::SKILL_MAX_COUNT); i++)
            m_SkillLevels[i] = 0;
    }

    // Serialises skill levels to a comma-separated string for saving.
    string GetSkillLevelsString()
    {
        string result = "";
        for(int i = 0; i < int(SkillID::SKILL_MAX_COUNT); i++)
        {
            if(i > 0) result += ",";
            result += string(m_SkillLevels[i]);
        }
        return result;
    }

    // Parses a comma-separated string produced by GetSkillLevelsString.
    void SetSkillLevelsFromString(const string& in data)
    {
        if(data.IsEmpty()) return;
        array<string>@ parts = data.Split(",");
        for(uint i = 0; i < parts.length() && i < uint(SkillID::SKILL_MAX_COUNT); i++)
        {
            int val = atoi(parts[i]);
            if(val < 0) val = 0;
            m_SkillLevels[i] = val;
        }
    }
    
    private int GetXPForLevel(int level)
    {
        return GetXPRequirement(level, m_iXPNeededBase, m_fXPNeededMult);
    }

    // Sets level directly (debug / save loading).
    // Resets current-level XP and recalculates skill points from scratch.
    void SetLevel(int level)
    {
        if(level < 1) level = 1;
        if(level > m_iMaxLevel) level = m_iMaxLevel;
        m_iLevel = level;
        m_iCurrentLevelXP = 0;
        m_iSkillPoints = m_iLevel * m_iSkillPointsPerLevel;
    }

    // Load before rank skills are known; their caps are applied after the whole save is read.
    void SetLoadedLevel(int level)
    {
        m_iLevel = level < 1 ? 1 : level;
        m_iSkillPoints = m_iLevel * m_iSkillPointsPerLevel;
    }

    void SetLoadedCurrentLevelXP(int xp)
    {
        m_iCurrentLevelXP = xp < 0 ? 0 : xp;
    }

    bool SetRankCaps(int levelBonus, int basicBonus, int classBonus)
    {
        m_iMaxLevel = Math.max(1, g_iMaxLevel + levelBonus);
        m_iBasicSkillCapBonus = basicBonus;
        m_iClassSkillCapBonus = classBonus;
        bool corrected = false;
        if(m_iLevel > m_iMaxLevel)
        {
            g_Game.AlertMessage(at_console, "CARPG: Reducing class level from " + m_iLevel + " to " + m_iMaxLevel + " and refunding all class skillpoints.\n");
            SetLevel(m_iMaxLevel);
            ResetSkills();
            corrected = true;
        }
        if(IsMaxLevel() && m_iCurrentLevelXP != 0)
        {
            m_iCurrentLevelXP = 0;
            corrected = true;
        }
        for(int i = 0; i < int(SkillID::SKILL_MAX_COUNT); i++)
        {
            if(g_SkillDefs[i] is null) continue;
            int cap = GetSkillMaxLevel(SkillID(i));
            if(m_SkillLevels[i] > cap)
            {
                g_Game.AlertMessage(at_console, "CARPG: Refunding " + (m_SkillLevels[i] - cap) + " points from " + g_SkillDefs[i].name + " after rank cap change.\n");
                m_SkillLevels[i] = cap;
                corrected = true;
            }
        }
        if(RefundExcessSkillPoints())
            corrected = true;
        return corrected;
    }

    private bool RefundExcessSkillPoints()
    {
        int excess = GetSpentSkillPoints() - m_iSkillPoints;
        if(excess <= 0)
            return false;

        g_Game.AlertMessage(at_console, "CARPG: Refunding " + excess + " skillpoints exceeding the class total.\n");
        for(int i = int(SkillID::SKILL_MAX_COUNT) - 1; i >= 0 && excess > 0; i--)
        {
            int removed = Math.min(excess, m_SkillLevels[i]);
            m_SkillLevels[i] -= removed;
            excess -= removed;
        }
        return true;
    }

    // Sets XP position within the current level. Used when loading a save.
    void SetCurrentLevelXP(int xp)
    {
        m_iCurrentLevelXP = (xp < 0) ? 0 : xp;
        if(IsMaxLevel()) m_iCurrentLevelXP = 0;
    }

    void AddXP(int amount, CBasePlayer@ pPlayer, PlayerData@ playerData)
    {
        if(amount <= 0) return;

        // Add to Rebirth progress (even if class is maxed).
        if(playerData !is null)
            playerData.AddRebirthXP(amount, pPlayer);

        // If class is maxed, stop here.
        if(IsMaxLevel()) return;

        // Normal class XP accumulation.
        m_iCurrentLevelXP += amount;

        while(!IsMaxLevel())
        {
            int needed = GetXPForLevel(m_iLevel);
            if(m_iCurrentLevelXP >= needed)
            {
                m_iCurrentLevelXP -= needed;
                m_iLevel++;
                m_iSkillPoints += m_iSkillPointsPerLevel;

                if(pPlayer !is null && playerData !is null)
                {
                    string className = playerData.GetClassName(playerData.GetCurrentClass());
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[CARPG] Your (" + className + ") is now Level " + m_iLevel + "!\n");
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strLevelUpSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);

                    NetworkMessage message(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pPlayer.pev.origin);
                    message.WriteByte(TE_PARTICLEBURST);
                    message.WriteCoord(pPlayer.pev.origin.x);
                    message.WriteCoord(pPlayer.pev.origin.y);
                    message.WriteCoord(pPlayer.pev.origin.z);
                    message.WriteShort(80);
                    message.WriteByte(255);
                    message.WriteByte(5);
                    message.End();

                    playerData.CalculateStats(pPlayer);
                    playerData.SaveToFile();
                }
            }
            else
                break;
        }

        if(IsMaxLevel())
            m_iCurrentLevelXP = 0;
    }

    void SetSteamID(string steamID) { m_szSteamID = steamID; }

    // Validates that total skillpoints match the expected amount for the current level.
    bool ValidateSkillPoints()
    {
        bool corrected = false;
        int expected = m_iLevel * m_iSkillPointsPerLevel;
        if(m_iSkillPoints != expected)
        {
            g_Game.AlertMessage(at_console, "CARPG: Correcting skillpoint total from " + m_iSkillPoints + " to " + expected + " (level " + m_iLevel + ").\n");
            m_iSkillPoints = expected;
            corrected = true;
        }
        if(RefundExcessSkillPoints())
            corrected = true;
        return corrected;
    }
}

// --- PlayerData and stat calculation ---
class PlayerData
{
    // Player identification.
    private string m_szSteamID;
    
    // Class system.
    private PlayerClass m_CurrentClass = PlayerClass::CLASS_NONE;
    private dictionary m_ClassData;
    
    // Score tracking.
    private int m_iScore = 0;
    private int m_iLastScore = 0;

    // Rebirth Rank tracking (player-wide, not per-class).
    private int m_iRebirthRank = 0;
    private int m_iCurrentRebirthRankXP = 0;
    private int m_iMaxRebirthRank = g_iMaxRebirthRank;
    private array<int> m_RankSkillLevels(int(RankSkillID::RANK_SKILL_COUNT), 0);
    private bool m_bSaveBlocked = false;

    private int m_iRPGHUDColor = 0;
    private int m_iRPGHUDPosition = CARPG_HUD_TOP_RIGHT;
    private int m_iResourceHUDColor = 0;
    private int m_iResourceHUDPosition = CARPG_HUD_BOTTOM_MIDDLE;
    private int m_iAmmoHUDColor = 0;
    private int m_iAmmoHUDPosition = CARPG_HUD_BOTTOM_RIGHT;

    private int m_iMinionGlowColor = -1; // -1 uses each class's default glow colour.

    int GetMinionGlowColorIndex()
    {
        return m_iMinionGlowColor;
    }

    void SetMinionGlowColorIndex(int colorIndex)
    {
        if(colorIndex < -1 || uint(colorIndex) >= g_CARPGHUDColorValues.length())
            return;

        m_iMinionGlowColor = colorIndex;
        SaveToFile();
    }

    int GetHUDColorIndex(int hudType)
    {
        if(hudType == CARPG_HUD_RESOURCE) return m_iResourceHUDColor;
        if(hudType == CARPG_HUD_AMMO) return m_iAmmoHUDColor;
        return m_iRPGHUDColor;
    }

    int GetHUDPositionIndex(int hudType)
    {
        if(hudType == CARPG_HUD_RESOURCE) return m_iResourceHUDPosition;
        if(hudType == CARPG_HUD_AMMO) return m_iAmmoHUDPosition;
        return m_iRPGHUDPosition;
    }

    void SetHUDColorIndex(int hudType, int colorIndex)
    {
        if(colorIndex < 0 || uint(colorIndex) >= g_CARPGHUDColorNames.length())
            return;

        if(hudType == CARPG_HUD_RESOURCE)
            m_iResourceHUDColor = colorIndex;
        else if(hudType == CARPG_HUD_AMMO)
            m_iAmmoHUDColor = colorIndex;
        else
            m_iRPGHUDColor = colorIndex;
        SaveToFile();
    }

    void SetHUDPositionIndex(int hudType, int positionIndex)
    {
        int positionCount = hudType == CARPG_HUD_RESOURCE ? 5 : 4;
        if(positionIndex < 0 || positionIndex >= positionCount)
            return;

        if(hudType == CARPG_HUD_RESOURCE)
            m_iResourceHUDPosition = positionIndex;
        else if(hudType == CARPG_HUD_AMMO)
            m_iAmmoHUDPosition = positionIndex;
        else
            m_iRPGHUDPosition = positionIndex;
        SaveToFile();
    }

    private Menu::ClassMenu@ m_ClassMenu = null;
    private Menu::SkillsMenu@ m_SkillsMenu = null;
    private Menu::RankMenu@ m_RankMenu = null;

    ClassStats@ GetClassStats(PlayerClass pClass)
    {
        return cast<ClassStats@>(m_ClassData[pClass]);
    }
    
    // Rebirth getters.
    int GetRebirthRank() { return m_iRebirthRank; }
    int GetCurrentXPMultiplier()
    {
        int bonus = 0;
        for(uint i = 0; i < g_ClassList.length(); i++)
        {
            ClassStats@ stats = GetClassStats(g_ClassList[i]);
            if(stats !is null && stats.GetLevel() > g_iMaxLevel)
                bonus += g_iXPPerScorePerClassAboveBaseMax;
        }
        return g_iScoreToXP + bonus;
    }
    int GetCurrentRebirthRankXP() { return m_iCurrentRebirthRankXP; }
    int GetNeededRebirthXP() { return GetXPForRank(m_iRebirthRank); }
    int GetMaxRebirthRank()
    {
        return g_bSkillDiminishingReturns ? m_iMaxRebirthRank : Math.min(m_iMaxRebirthRank, g_iHardLimitMaxRank);
    }

    int GetTotalRankPoints() { return m_iRebirthRank * Math.max(0, g_iRankPointsPerRank); }
    int GetRankSkillLevel(RankSkillID id) { return m_RankSkillLevels[int(id)]; }
    float GetRankSkillBonus(RankSkillID id)
    {
        return float(GetRankSkillLevel(id)) * g_RankSkillDefs[int(id)].increase;
    }
    int GetRankPoints()
    {
        int spent = 0;
        for(uint i = 0; i < m_RankSkillLevels.length(); i++)
            spent += m_RankSkillLevels[i];
        return GetTotalRankPoints() - spent;
    }

    private bool ApplyRankCaps()
    {
        int levelBonus = m_iRebirthRank * Math.max(0, g_iClassLevelsPerRank);
        int basicBonus = int(GetRankSkillBonus(RankSkillID::RANK_SKILL_BASIC_CAP));
        int classBonus = int(GetRankSkillBonus(RankSkillID::RANK_SKILL_CLASS_CAP));
        bool corrected = false;
        for(uint i = 0; i < g_ClassList.length(); i++)
        {
            ClassStats@ stats = GetClassStats(g_ClassList[i]);
            if(stats !is null && stats.SetRankCaps(levelBonus, basicBonus, classBonus))
                corrected = true;
        }
        return corrected;
    }

    private bool ValidateRankPoints()
    {
        bool corrected = false;
        int legacyIndex = int(RankSkillID::RANK_SKILL_LEGACY_LEVEL_CAP);
        if(m_RankSkillLevels[legacyIndex] > 0)
        {
            g_Game.AlertMessage(at_console, "CARPG: Refunding " + m_RankSkillLevels[legacyIndex] + " obsolete level cap rank purchases.\n");
            m_RankSkillLevels[legacyIndex] = 0;
            corrected = true;
        }
        int excess = -GetRankPoints();
        if(excess > 0)
        {
            corrected = true;
            g_Game.AlertMessage(at_console, "CARPG: Rank skill spending exceeds available RP; refunding excess purchases.\n");
            for(int i = int(m_RankSkillLevels.length()) - 1; i >= 0 && excess > 0; i--)
            {
                int removed = Math.min(excess, m_RankSkillLevels[i]);
                m_RankSkillLevels[i] -= removed;
                excess -= removed;
            }
        }
        if(ApplyRankCaps())
            corrected = true;
        return corrected;
    }

    bool TrySpendRankPoint(RankSkillID id, CBasePlayer@ pPlayer)
    {
        int idx = int(id);
        if(idx <= int(RankSkillID::RANK_SKILL_LEGACY_LEVEL_CAP) || idx >= int(m_RankSkillLevels.length()) || GetRankPoints() < 1)
            return false;
        m_RankSkillLevels[idx]++;
        ApplyRankCaps();
        if(pPlayer !is null) CalculateStats(pPlayer);
        SaveToFile();
        return true;
    }

    void ResetRankSkills(CBasePlayer@ pPlayer)
    {
        for(uint i = 0; i < m_RankSkillLevels.length(); i++)
            m_RankSkillLevels[i] = 0;
        ApplyRankCaps();
        if(pPlayer !is null)
        {
            ResetPlayer(pPlayer);
            CalculateStats(pPlayer);
        }
        SaveToFile();
    }

    private int GetXPForRank(int rank)
    {
        return GetXPRequirement(rank + 1, g_iRankXPBase, g_flRankXPMultiplier);
    }

    bool IsMaxRebirthRank() { return m_iRebirthRank >= GetMaxRebirthRank(); }

    // Add Rebirth XP, triggers rank-up when threshold is met.
    void AddRebirthXP(int amount, CBasePlayer@ pPlayer)
    {
        if(amount <= 0 || IsMaxRebirthRank()) return;
        m_iCurrentRebirthRankXP += amount;
        while(m_iRebirthRank < GetMaxRebirthRank())
        {
            int needed = GetNeededRebirthXP();
            if(needed <= 0) break; // safety.
            if(m_iCurrentRebirthRankXP >= needed)
            {
                m_iCurrentRebirthRankXP -= needed;
                m_iRebirthRank++;
                ApplyRankCaps();
                if(pPlayer !is null)
                {
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[CARPG] Your rank is now " + m_iRebirthRank + "!\n");
                        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strLevelUpSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
                }

                if(pPlayer !is null)
                    CalculateStats(pPlayer);
                SaveToFile();
            }
            else break;
        }
        if(IsMaxRebirthRank())
            m_iCurrentRebirthRankXP = 0;
    }

    void SetRebirthRank(int rank)
    {
        // Clamp rank to valid range.
        if(rank < 0) rank = 0;
        if(rank > GetMaxRebirthRank()) rank = GetMaxRebirthRank();

        // Only proceed if rank actually changed.
        if(m_iRebirthRank == rank) return;

        bool rankReduced = rank < m_iRebirthRank;
        m_iRebirthRank = rank;
        m_iCurrentRebirthRankXP = 0; // Reset accumulated XP for the new rank.
        ValidateRankPoints();

        CBasePlayer@ pPlayer = FindOwnPlayer();
        if(pPlayer !is null)
        {
            if(rankReduced) ResetPlayer(pPlayer);
            CalculateStats(pPlayer);
        }
        SaveToFile();
    }
    
    void ShowClassMenu(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null) return;
        
        if(m_ClassMenu is null)
            @m_ClassMenu = Menu::ClassMenu(this);
            
        m_ClassMenu.Show(pPlayer);
    }

    void ShowSkillsMenu(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || m_CurrentClass == PlayerClass::CLASS_NONE) return;

        if(m_SkillsMenu is null)
            @m_SkillsMenu = Menu::SkillsMenu(this);

        m_SkillsMenu.ShowMain(pPlayer);
    }

    void ShowRankMenu(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null) return;
        if(m_RankMenu is null)
            @m_RankMenu = Menu::RankMenu(this);
        m_RankMenu.ShowMain(pPlayer);
    }

    // Returns unspent skill points for the current class.
    int GetSkillPoints()
    {
        ClassStats@ stats = GetCurrentClassStats();
        if(stats is null) return 0;
        return stats.GetSkillPoints();
    }

    int GetSkillLevel(SkillID id)
    {
        ClassStats@ stats = GetCurrentClassStats();
        if(stats is null) return 0;
        return stats.GetSkillLevel(id);
    }

    float GetEffectiveSkillLevel(SkillID id)
    {
        ClassStats@ stats = GetCurrentClassStats();
        return stats is null ? 0.0f : stats.GetEffectiveSkillLevel(id);
    }

    // Spends one skill point on id for the current class.
    // Recalculates stats and saves on success.
    bool TrySpendSkillPoint(SkillID id, CBasePlayer@ pPlayer = null)
    {
        ClassStats@ stats = GetCurrentClassStats();
        if(stats is null) return false;
        bool spent = stats.TrySpendSkillPoint(id);
        if(spent)
        {
            if(pPlayer is null)
                @pPlayer = FindOwnPlayer();
            if(pPlayer !is null)
                CalculateStats(pPlayer);
            SaveToFile();
        }
        return spent;
    }

    // Refunds all skill points for the current class.
    void ResetCurrentSkills(CBasePlayer@ pPlayer)
    {
        ClassStats@ stats = GetCurrentClassStats();
        if(stats is null) return;

        stats.ResetSkills();

        if(pPlayer !is null)
        {
            CalculateStats(pPlayer);
            //RefillHealthArmor(pPlayer);
        }

        SaveToFile();
    }

    private CBasePlayer@ FindOwnPlayer()
    {
        for(int i = 1; i <= g_Engine.maxClients; ++i)
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
            if(pPlayer !is null && g_EngineFuncs.GetPlayerAuthId(pPlayer.edict()) == m_szSteamID)
                return pPlayer;
        }
        return null;
    }
    
    // Constructor.
    PlayerData(string steamID)
    {
        m_szSteamID = steamID;
        InitializeClasses();
        InitializeClassDefinitions();
        InitializeSkillDefinitions();
        
        // Initialize last score properly by checking current score before loading from file.
        const int iMaxPlayers = g_Engine.maxClients;
        for(int i = 1; i <= iMaxPlayers; ++i)
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
            if(pPlayer !is null && g_EngineFuncs.GetPlayerAuthId(pPlayer.edict()) == steamID)
            {
                m_iLastScore = int(pPlayer.pev.frags);
                break;
            }
        }
        
        LoadFromFile(); // Now load from file after setting last score.
    }
    
    private void InitializeClasses()
    {
        for(uint i = 0; i < g_ClassList.length(); i++)
        {
            ClassStats stats();
            @m_ClassData[g_ClassList[i]] = @stats;
        }
    }
    
    void SetClass(PlayerClass newClass)
    {
        if(m_CurrentClass == newClass) return;
        
        // Clean up previous class abilities if necessary.
        if (m_CurrentClass != PlayerClass::CLASS_NONE)
        {
            // Find the player for cleanup operations.
            CBasePlayer@ pPlayer = null;
            for(int i = 1; i <= g_Engine.maxClients; ++i) 
            {
                CBasePlayer@ tempPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if(tempPlayer !is null && g_EngineFuncs.GetPlayerAuthId(tempPlayer.edict()) == m_szSteamID) 
                {
                    @pPlayer = tempPlayer;
                    break;
                }
            }
            
            // Handle class-specific cleanup.
            switch(m_CurrentClass) 
            {
                case PlayerClass::CLASS_FROSTGUARD: // Clean up barrier data.
                    if (g_PlayerBarriers.exists(m_szSteamID)) 
                    {
                        BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[m_szSteamID]);
                        if (barrier !is null && barrier.IsActive() && pPlayer !is null) 
                        {
                            barrier.DeactivateBarrier(pPlayer);
                        }
                        
                        g_PlayerBarriers.delete(m_szSteamID);
                    }
                    break;
                    
                case PlayerClass::CLASS_MEDIC: 
                    if (g_HealingAuras.exists(m_szSteamID)) 
                    {
                        HealingAura@ aura = cast<HealingAura@>(g_HealingAuras[m_szSteamID]);
                        if (aura !is null && aura.IsActive() && pPlayer !is null) 
                        {
                            aura.DeactivateHeal(pPlayer);
                        }
                        g_HealingAuras.delete(m_szSteamID);
                    }
                    break;
                    
                case PlayerClass::CLASS_VAMPIRE: // Clean up bloodlust data.
                    if (g_PlayerBloodlusts.exists(m_szSteamID)) 
                    {
                        BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[m_szSteamID]);
                        if (bloodlust !is null && bloodlust.IsActive() && pPlayer !is null) 
                        {
                            bloodlust.DeactivateBloodlust(pPlayer);
                        }
                        g_PlayerBloodlusts.delete(m_szSteamID);
                    }
                    break;
                    
                case PlayerClass::CLASS_ENGINEER: // Clean up sentry data.
                    if (g_PlayerSentries.exists(m_szSteamID)) 
                    {
                        SentryData@ sentry = cast<SentryData@>(g_PlayerSentries[m_szSteamID]);
                        if (sentry !is null) 
                        {
                            sentry.Reset(); // Delete minions of this type.
                        }
                        g_PlayerSentries.delete(m_szSteamID);
                    }
                    break;
                    
                case PlayerClass::CLASS_ROBOMANCER: // Clean up minion data.
                    if (g_PlayerMinions.exists(m_szSteamID)) 
                    {
                        MinionData@ minions = cast<MinionData@>(g_PlayerMinions[m_szSteamID]);
                        if (minions !is null && pPlayer !is null) 
                        {
                            minions.DestroyAllMinions(pPlayer); // Delete minions of this type.
                        }
                        g_PlayerMinions.delete(m_szSteamID);
                    }
                    break;
                    
                case PlayerClass::CLASS_XENOMANCER: // Clean up xen minion data.
                    if (g_XenologistMinions.exists(m_szSteamID)) 
                    {
                        XenMinionData@ xenMinions = cast<XenMinionData@>(g_XenologistMinions[m_szSteamID]);
                        if (xenMinions !is null && pPlayer !is null) 
                        {
                            xenMinions.DestroyAllMinions(pPlayer); // Delete minions of this type.
                        }
                        g_XenologistMinions.delete(m_szSteamID);
                    }
                    break;
                    
                case PlayerClass::CLASS_NECROMANCER: // Clean up necro minion data.
                    if (g_NecromancerMinions.exists(m_szSteamID)) 
                    {
                        NecroMinionData@ necroMinions = cast<NecroMinionData@>(g_NecromancerMinions[m_szSteamID]);
                        if (necroMinions !is null && pPlayer !is null) 
                        {
                            necroMinions.DestroyAllMinions(pPlayer); // Delete minions of this type.
                        }
                        g_NecromancerMinions.delete(m_szSteamID);
                    }
                    break;
                    
                case PlayerClass::CLASS_SHOCKTROOPER: // Clean up shock rifle data.
                    if (g_ShockRifleData.exists(m_szSteamID)) 
                    {
                        g_ShockRifleData.delete(m_szSteamID);
                    }
                    break;
                    
                case PlayerClass::CLASS_CLOAKER: // Clean up cloak data.
                    if (g_PlayerCloaks.exists(m_szSteamID)) 
                    {
                        CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[m_szSteamID]);
                        if (cloak !is null && cloak.IsActive() && pPlayer !is null) 
                        {
                            cloak.DeactivateCloak(pPlayer);
                        }
                        g_PlayerCloaks.delete(m_szSteamID);
                    }
                    break;
                    
                case PlayerClass::CLASS_FIREBUG: // Clean up Dragon's Breath data.
                    if (g_PlayerDragonsBreath.exists(m_szSteamID)) 
                    {
                        g_PlayerDragonsBreath.delete(m_szSteamID);
                    }
                    break;
                    
                case PlayerClass::CLASS_SWARMER: // Clean up snark nest data.
                    if (g_PlayerSnarkNests.exists(m_szSteamID)) 
                    {
                        SnarkNestData@ snarkNest = cast<SnarkNestData@>(g_PlayerSnarkNests[m_szSteamID]);
                        if (snarkNest !is null) 
                        {
                            snarkNest.Reset(); // Remove all snarks.
                        }
                        g_PlayerSnarkNests.delete(m_szSteamID);
                    }
                    break;
            }
        }
        
        m_CurrentClass = newClass; // Set new class.
    
        // Find the player and update their stats.
        const int iMaxPlayers = g_Engine.maxClients;
        for(int i = 1; i <= iMaxPlayers; ++i)
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
            if(pPlayer !is null && g_EngineFuncs.GetPlayerAuthId(pPlayer.edict()) == m_szSteamID)
            {
                string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

                CalculateStats(pPlayer);

                break;
            }
        }
        
        SaveToFile();
    }
    
    PlayerClass GetCurrentClass() { return m_CurrentClass; }
    
    ClassStats@ GetCurrentClassStats()
    {
        if(m_CurrentClass == PlayerClass::CLASS_NONE)
            return null;
            
        return cast<ClassStats@>(m_ClassData[m_CurrentClass]);
    }

    void CalculateStats(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;

        if(IsCARPGDisabledOnCurrentMap())
        {
            pPlayer.pev.max_health = 100.0f;
            pPlayer.pev.armortype = 100.0f;

            if(pPlayer.pev.health > pPlayer.pev.max_health)
                pPlayer.pev.health = pPlayer.pev.max_health;

            if(pPlayer.pev.armorvalue > pPlayer.pev.armortype)
                pPlayer.pev.armorvalue = pPlayer.pev.armortype;
            return;
        }

        if(m_CurrentClass == PlayerClass::CLASS_NONE)
            return;
            
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

        // Initialize abilities if they don't exist.
        // Initialize class-specific data if they don't exist.
        switch(m_CurrentClass)
        {
            case PlayerClass::CLASS_MEDIC:
                if(!g_HealingAuras.exists(steamID))
                {
                    HealingAura data;
                    data.Initialize(GetCurrentClassStats());
                    g_HealingAuras[steamID] = data;
                }
                break;
                        
            case PlayerClass::CLASS_FROSTGUARD:
                if(!g_PlayerBarriers.exists(steamID))
                {
                    BarrierData data;
                    data.Initialize(GetCurrentClassStats());
                    g_PlayerBarriers[steamID] = data;
                 }
                 break;
                    
            case PlayerClass::CLASS_ROBOMANCER:
                if(!g_PlayerMinions.exists(steamID))
                {
                    MinionData data;
                    data.Initialize(GetCurrentClassStats());
                    @g_PlayerMinions[steamID] = data;
                }
                break;

            case PlayerClass::CLASS_XENOMANCER:
                if(!g_XenologistMinions.exists(steamID))
                {
                    XenMinionData data;
                    data.Initialize(GetCurrentClassStats());
                    @g_XenologistMinions[steamID] = data;
                }
                break;
                
            case PlayerClass::CLASS_NECROMANCER:
                if(!g_NecromancerMinions.exists(steamID))
                {
                    NecroMinionData data;
                    data.Initialize(GetCurrentClassStats());
                    @g_NecromancerMinions[steamID] = data;
                }
                break;
                        
              case PlayerClass::CLASS_SHOCKTROOPER:
                if(!g_ShockRifleData.exists(steamID))
                {
                    ShockRifleData data;
                    data.Initialize(GetCurrentClassStats());
                    g_ShockRifleData[steamID] = data;
                }
                break;
                        
               case PlayerClass::CLASS_VAMPIRE:
                if(!g_PlayerBloodlusts.exists(steamID))
                {
                    BloodlustData data;
                    data.Initialize(GetCurrentClassStats());
                    @g_PlayerBloodlusts[steamID] = data;
                }
                break;

               case PlayerClass::CLASS_CLOAKER:
                   if(!g_PlayerCloaks.exists(steamID))
                   {
                      CloakData data;
                     data.Initialize(GetCurrentClassStats());
                    g_PlayerCloaks[steamID] = data;
                }
                break;

               case PlayerClass::CLASS_FIREBUG:
                if(!g_PlayerDragonsBreath.exists(steamID))
                {
                    DragonsBreathData data;
                    data.Initialize(GetCurrentClassStats());
                    g_PlayerDragonsBreath[steamID] = data;
                }
                break;

               case PlayerClass::CLASS_SWARMER:
                if(!g_PlayerSnarkNests.exists(steamID))
                {
                    SnarkNestData data;
                    data.Initialize(GetCurrentClassStats());
                    g_PlayerSnarkNests[steamID] = data;
                }
                break;

            case PlayerClass::CLASS_ENGINEER:
                if(!g_PlayerSentries.exists(steamID))
                {
                    SentryData data;
                    data.Initialize(GetCurrentClassStats());
                    g_PlayerSentries[steamID] = data;
                }
                break;
        }

        ClassStats@ stats = GetCurrentClassStats();
        if(stats is null)
            return;
        
        if(g_ClassDefinitions.exists(m_CurrentClass))
        {
            ClassDefinition@ def = cast<ClassDefinition@>(g_ClassDefinitions[m_CurrentClass]);

            // Basic Max HP/AP skills and the basic HP -> AP conversion skill.
            ApplyBasicMaxStats(pPlayer, stats, def);

            // Special case for Vampire's own AP -> HP conversion (separate class skill), applied after the basic stats.
            if (PlayerClass::CLASS_VAMPIRE == m_CurrentClass)
            {
                // Vampire's Bloodlust grants bonus HP based on missing health, so we need to trigger a recalculation here.
                if(g_PlayerBloodlusts.exists(steamID))
                {
                    BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                    if(bloodlust !is null)
                    {
                        bloodlust.ConvertAPToHP(pPlayer);
                    }
                }
            }

            // Clamp current HP/AP to the final converted max.
            if(pPlayer.pev.health > pPlayer.pev.max_health)
                pPlayer.pev.health = pPlayer.pev.max_health;

            if(pPlayer.pev.armorvalue > pPlayer.pev.armortype)
                pPlayer.pev.armorvalue = pPlayer.pev.armortype;
            
            // Class-specific weapon loadouts and other non-basic scaling bonuses like ammo and capacity.
            switch(m_CurrentClass)
            {
                case PlayerClass::CLASS_MEDIC:
                    break;
                case PlayerClass::CLASS_VAMPIRE:
                    break;
                case PlayerClass::CLASS_ENGINEER:
                    break;
                case PlayerClass::CLASS_ROBOMANCER:
                    break;
                case PlayerClass::CLASS_FROSTGUARD:
                    break;
                case PlayerClass::CLASS_SHOCKTROOPER:
                    break;
                case PlayerClass::CLASS_CLOAKER:
                    break;
                case PlayerClass::CLASS_FIREBUG:
                    break;
                case PlayerClass::CLASS_SWARMER:
                    break;
            }
        }
    }
    
    // Score tracking.
    void CheckScoreChange(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null) return;
        
        int currentScore = int(pPlayer.pev.frags);
        if(currentScore != m_iLastScore)
        {
            int scoreDiff = currentScore - m_iLastScore;
            if(scoreDiff > 0)
            {
                int xpAward = scoreDiff * GetCurrentXPMultiplier();
                m_iScore += xpAward;
                
                // Share XP with all players.
                const int iMaxPlayers = g_Engine.maxClients;
                for(int i = 1; i <= iMaxPlayers; i++)
                {
                    CBasePlayer@ pOtherPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                    if(pOtherPlayer !is null && pOtherPlayer.IsConnected())
                    {
                        string otherSteamID = g_EngineFuncs.GetPlayerAuthId(pOtherPlayer.edict());
                            
                        if(g_PlayerRPGData.exists(otherSteamID))
                        {
                            PlayerData@ otherData = cast<PlayerData@>(g_PlayerRPGData[otherSteamID]);
                            if(otherData !is null)
                            {
                                ClassStats@ stats = otherData.GetCurrentClassStats();
                                if(stats !is null)
                                {
                                    int sharedXPAward = scoreDiff * otherData.GetCurrentXPMultiplier();
                                    stats.AddXP(sharedXPAward, pOtherPlayer, otherData); // Add the actual XP.
                                    //g_PlayerFuncs.ClientPrint(pOtherPlayer, HUD_PRINTCONSOLE, "+" + scoreDiff + " XP\n"); // Show gained XP.
                                }
                            }
                        }
                    }
                }
            }
            m_iLastScore = currentScore;
            SaveToFile();
        }
    }
    
    string GetClassName(PlayerClass pClass)
    {
        if(g_ClassNames.exists(pClass))
            return string(g_ClassNames[pClass]);
        return "Unknown";
    }
        
    private string GetSafeFileName()
    {
        string safeSteamID = m_szSteamID.Replace(":", "_");
        return strSaveFileLocation + safeSteamID + ".txt";
    }

    void SaveToFile()
    {
        string filePath = GetSafeFileName();
        if(m_bSaveBlocked)
        {
            g_Game.AlertMessage(at_console, "CARPG: Refusing to overwrite invalid rank data in " + filePath + ".\n");
            CBasePlayer@ pPlayer = FindOwnPlayer();
            if(pPlayer !is null)
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[CARPG] Save failed: invalid rank data. Contact a server administrator.\n");
            return;
        }
        File@ file = g_FileSystem.OpenFile(filePath, OpenFile::WRITE);
        if(file !is null && file.IsOpen())
        {
            file.Write("v8\n");
            file.Write(string(int(m_CurrentClass)) + "\n");

            // One line per class, keyed by class ID so order and additions don't matter.
            // <classID> <level> <currentLevelXP> <totalSkillPoints> <skillLevelsCSV>.
            for(uint i = 0; i < g_ClassList.length(); i++)
            {
                PlayerClass pClass = g_ClassList[i];
                ClassStats@ stats = cast<ClassStats@>(m_ClassData[pClass]);
                if(stats !is null)
                {
                    file.Write(string(int(pClass)) + " "
                        + string(stats.GetLevel()) + " "
                        + string(stats.GetCurrentLevelXP()) + " "
                        + string(stats.GetTotalSkillPoints()) + " "
                        + stats.GetSkillLevelsString() + "\n");
                }
            }

            // Write rebirth section.
            file.Write("REBIRTH\n");
            file.Write(string(m_iRebirthRank) + " " + string(m_iCurrentRebirthRankXP) + "\n");

            file.Write("HUD\n");
            file.Write(string(m_iRPGHUDColor) + " " + string(m_iRPGHUDPosition) + " "
                + string(m_iResourceHUDColor) + " " + string(m_iResourceHUDPosition) + " "
                + string(m_iAmmoHUDColor) + " " + string(m_iAmmoHUDPosition) + " "
                + string(m_iMinionGlowColor) + "\n");

            file.Write("RANKSKILLS\n");
            string rankSkills = "";
            for(uint i = 0; i < m_RankSkillLevels.length(); i++)
            {
                if(i > 0) rankSkills += ",";
                rankSkills += string(m_RankSkillLevels[i]);
            }
            file.Write(string(GetTotalRankPoints()) + " " + rankSkills + "\n");

            file.Close();
        }
        else
        {
            g_Game.AlertMessage(at_console, "CARPG: Could not save data to " + filePath + "\n");
        }
    }
    
    void LoadFromFile()
    {
        string filePath = GetSafeFileName();
        File@ file = g_FileSystem.OpenFile(filePath, OpenFile::READ);
        if(file !is null && file.IsOpen())
        {
            string line;
            file.ReadLine(line);

            // Check version.
            string saveVersion = line;
            if(saveVersion != "v5" && saveVersion != "v6" && saveVersion != "v7" && saveVersion != "v8")
            {
                file.Close();
                g_Game.AlertMessage(at_console, "CARPG: Incompatible save version '" + line + "', starting fresh.\n");
                return;
            }

            // Load current class.
            line = "";
            file.ReadLine(line);
            m_CurrentClass = PlayerClass(atoi(line));
            g_Game.AlertMessage(at_console, "CARPG: Loaded class: " + GetClassName(m_CurrentClass) + "\n");

            // Load each class line, keyed by class ID.
            bool bNeedsResave = saveVersion != "v8";
            while(!file.EOFReached())
            {
                line = "";
                file.ReadLine(line);
                if(line.IsEmpty()) continue;

                // If we hit the REBIRTH marker, stop reading class lines.
                if(line == "REBIRTH")
                    break;

                array<string>@ parts = line.Split(" ");
                if(parts.length() < 5) continue;

                PlayerClass pClass = PlayerClass(atoi(parts[0]));
                ClassStats@ stats = cast<ClassStats@>(m_ClassData[pClass]);
                if(stats is null) continue;

                int savedLevel       = atoi(parts[1]);
                int savedCurrentXP   = atoi(parts[2]);
                int savedTotalSP     = atoi(parts[3]);
                string savedSkills   = parts[4];

                stats.SetLoadedLevel(savedLevel);
                stats.SetLoadedCurrentLevelXP(savedCurrentXP);
                stats.SetSkillLevelsFromString(savedSkills);

                // Recompute the available total; caps and excess spending are validated after rank skills load.
                if(savedTotalSP != stats.GetTotalSkillPoints())
                {
                    g_Game.AlertMessage(at_console, "CARPG: Skillpoint total changed for class "
                        + parts[0] + " (saved " + savedTotalSP + ", now "
                        + stats.GetTotalSkillPoints() + "). Validating allocations.\n");
                    bNeedsResave = true;
                }
            }

            // If we stopped because of REBIRTH marker, load rebirth data.
            if(line == "REBIRTH")
            {
                string rebirthLine;
                file.ReadLine(rebirthLine);
                array<string>@ parts = rebirthLine.Split(" ");
                if(parts.length() >= 2)
                {
                    m_iRebirthRank = atoi(parts[0]);
                    m_iCurrentRebirthRankXP = atoi(parts[1]);
                    if(m_iRebirthRank < 0) m_iRebirthRank = 0;
                    if(m_iRebirthRank > GetMaxRebirthRank())
                    {
                        g_Game.AlertMessage(at_console, "CARPG: Saved rank exceeds configured maximum; clamping rank.\n");
                        m_iRebirthRank = GetMaxRebirthRank();
                        m_iCurrentRebirthRankXP = 0;
                        bNeedsResave = true;
                    }
                    g_Game.AlertMessage(at_console, "CARPG: Loaded rebirth rank " + m_iRebirthRank + " with XP " + m_iCurrentRebirthRankXP + "\n");
                }

                if(saveVersion == "v7" || saveVersion == "v8")
                {
                    string hudMarker;
                    file.ReadLine(hudMarker);
                    if(hudMarker == "HUD")
                    {
                        string hudSettingsLine;
                        file.ReadLine(hudSettingsLine);
                        array<string>@ hudParts = hudSettingsLine.Split(" ");
                        if(hudParts.length() >= 6)
                        {
                            int savedRPGColor = atoi(hudParts[0]);
                            int savedRPGPosition = atoi(hudParts[1]);
                            int savedResourceColor = atoi(hudParts[2]);
                            int savedResourcePosition = atoi(hudParts[3]);
                            int savedAmmoColor = atoi(hudParts[4]);
                            int savedAmmoPosition = atoi(hudParts[5]);

                            if(savedRPGColor >= 0 && uint(savedRPGColor) < g_CARPGHUDColorNames.length()) m_iRPGHUDColor = savedRPGColor;
                            if(savedRPGPosition >= 0 && savedRPGPosition < 4) m_iRPGHUDPosition = savedRPGPosition;
                            if(savedResourceColor >= 0 && uint(savedResourceColor) < g_CARPGHUDColorNames.length()) m_iResourceHUDColor = savedResourceColor;
                            if(savedResourcePosition >= 0 && savedResourcePosition < 5) m_iResourceHUDPosition = savedResourcePosition;
                            if(savedAmmoColor >= 0 && uint(savedAmmoColor) < g_CARPGHUDColorNames.length()) m_iAmmoHUDColor = savedAmmoColor;
                            if(savedAmmoPosition >= 0 && savedAmmoPosition < 4) m_iAmmoHUDPosition = savedAmmoPosition;

                            if(hudParts.length() >= 7)
                            {
                                int savedMinionGlow = atoi(hudParts[6]);
                                if(savedMinionGlow >= -1 && savedMinionGlow < int(g_CARPGHUDColorValues.length()))
                                    m_iMinionGlowColor = savedMinionGlow;
                            }
                        }
                    }

                    if(saveVersion == "v8")
                    {
                        string rankMarker;
                        file.ReadLine(rankMarker);
                        if(rankMarker == "RANKSKILLS")
                        {
                            string rankLine;
                            file.ReadLine(rankLine);
                            array<string>@ rankParts = rankLine.Split(" ");
                            if(rankParts.length() >= 2)
                            {
                                array<string>@ levels = rankParts[1].Split(",");
                                for(uint i = 0; i < levels.length() && i < m_RankSkillLevels.length(); i++)
                                    m_RankSkillLevels[i] = Math.max(0, atoi(levels[i]));
                                if(atoi(rankParts[0]) != GetTotalRankPoints())
                                    bNeedsResave = true;
                            }
                            else
                            {
                                g_Game.AlertMessage(at_console, "CARPG: Invalid rank skills data in " + filePath + ".\n");
                                m_bSaveBlocked = true;
                            }
                        }
                        else
                        {
                            g_Game.AlertMessage(at_console, "CARPG: Missing rank skills data in " + filePath + ".\n");
                            m_bSaveBlocked = true;
                        }
                    }
                }
            }
            else
            {
                // If no rebirth section (v5 or earlier), set to 0.
                if(saveVersion == "v8")
                {
                    g_Game.AlertMessage(at_console, "CARPG: Missing rebirth data in " + filePath + ".\n");
                    m_bSaveBlocked = true;
                }
                m_iRebirthRank = 0;
                m_iCurrentRebirthRankXP = 0;
                g_Game.AlertMessage(at_console, "CARPG: No rebirth data found, initializing to 0.\n");
                bNeedsResave = true;
            }

            file.Close();
            if(m_bSaveBlocked)
                return;
            if(ValidateRankPoints())
                bNeedsResave = true;
            for(uint i = 0; i < g_ClassList.length(); i++)
            {
                ClassStats@ stats = GetClassStats(g_ClassList[i]);
                if(stats !is null && stats.ValidateSkillPoints())
                    bNeedsResave = true;
            }
            g_Game.AlertMessage(at_console, "CARPG: Loaded data from " + filePath + "\n");

            if(bNeedsResave)
                SaveToFile();
        }
        else
        {
            g_Game.AlertMessage(at_console, "CARPG: Could not load data from " + filePath + "\n");
        }
    }

    void UpdateRPGHUD(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null) return;
        
        ClassStats@ stats = GetCurrentClassStats();
        if(stats is null) return;
        
        HUDTextParams RPGHudParams;
        RPGHudParams.channel = 7;
        RPGHudParams.x = GetCARPGHUDPositionX(CARPG_HUD_RPG, m_iRPGHUDPosition);
        RPGHudParams.y = GetCARPGHUDPositionY(CARPG_HUD_RPG, m_iRPGHUDPosition);
        RPGHudParams.effect = 0;
        Vector hudColor = GetCARPGHUDColorValue(m_iRPGHUDColor);
        RPGHudParams.r1 = int(hudColor.x);
        RPGHudParams.g1 = int(hudColor.y);
        RPGHudParams.b1 = int(hudColor.z);
        RPGHudParams.a1 = 255;
        RPGHudParams.fadeinTime = 0;
        RPGHudParams.fadeoutTime = 0;
        RPGHudParams.holdTime = g_flPlayerHUDInterval * 1.5f;
        
        string RPGHudText = "";
        RPGHudText += "" + GetClassName(m_CurrentClass) + "\n"; // Class.
        RPGHudText += "Level: " + stats.GetLevel() + "/" + stats.GetMaxLevel() + " | ";
        RPGHudText += "XP: " + (stats.IsMaxLevel() ? "(--/--)" : "(" + stats.GetCurrentLevelXP() + "/" + stats.GetNeededXP() + ")") + "\n\n"; // XP.

        RPGHudText += "Rank: " + m_iRebirthRank + " | "; // Rank.
        RPGHudText += "XP: " + (IsMaxRebirthRank() ? "(--/--)" : "(" + m_iCurrentRebirthRankXP + "/" + GetNeededRebirthXP() + ")") + "\n\n"; // Rank XP.

        if(GetCurrentXPMultiplier() > g_iScoreToXP)
            RPGHudText += "XP Bonus: " + "(+" + (GetCurrentXPMultiplier() - g_iScoreToXP) + ")" + "\n\n"; // XP per score bonus.

        if(GetRankPoints() > 0)
            RPGHudText += "RP: " + GetRankPoints() + "\n";

        if(stats.GetSkillPoints() > 0) 
            RPGHudText += "SP: " + stats.GetSkillPoints() + "\n"; // Current skillpoints.
        
        g_PlayerFuncs.HudMessage(pPlayer, RPGHudParams, RPGHudText);
    }
}

string GetClassName(PlayerClass pClass)
{
    if(g_ClassNames.exists(pClass))
        return string(g_ClassNames[pClass]);
    return "Unknown";
}