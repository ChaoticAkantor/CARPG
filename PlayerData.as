const string strLevelUpSound = "misc/secret.wav"; // Sound played on level up.

string strSaveFileLocation = "scripts/plugins/store/"; // Default is scripts/plugins/store/  Make sure it ends with a slash.

dictionary g_PlayerRPGData;

// Max level and XP multiplier.
int g_iMaxLevel = 50; // Max player level. Increasing this will not make players stronger! Abilities scale against max level.
float g_fXPMultiplier = 1.0f; // Score to XP multiplier, 1.0 = 1 score is 1 XP.

dictionary g_ClassNames = 
{
    {PlayerClass::CLASS_NONE, "None"},
    {PlayerClass::CLASS_MEDIC, "Medic"},
    {PlayerClass::CLASS_BERSERKER, "Berserker"},
    {PlayerClass::CLASS_ENGINEER, "Engineer"},
    {PlayerClass::CLASS_ROBOMANCER, "Robomancer"},
    {PlayerClass::CLASS_XENOMANCER, "Xenomancer"},
    {PlayerClass::CLASS_NECROMANCER, "Necromancer"},
    {PlayerClass::CLASS_DEFENDER, "Warden"},
    {PlayerClass::CLASS_SHOCKTROOPER, "Shocktrooper"},
    {PlayerClass::CLASS_CLOAKER, "Cloaker"},
    {PlayerClass::CLASS_VANQUISHER, "Vanquisher"},
    {PlayerClass::CLASS_SWARMER, "Swarmer"}
};

array<PlayerClass> g_ClassList = 
{
    PlayerClass::CLASS_MEDIC,
    PlayerClass::CLASS_BERSERKER,
    PlayerClass::CLASS_ENGINEER,
    PlayerClass::CLASS_ROBOMANCER,
    PlayerClass::CLASS_XENOMANCER,
    PlayerClass::CLASS_NECROMANCER,
    PlayerClass::CLASS_DEFENDER,
    PlayerClass::CLASS_SHOCKTROOPER,
    PlayerClass::CLASS_CLOAKER,
    PlayerClass::CLASS_VANQUISHER,
    PlayerClass::CLASS_SWARMER
};

enum PlayerClass 
{
    CLASS_NONE = 0,
    CLASS_MEDIC,
    CLASS_BERSERKER,
    CLASS_ENGINEER,
    CLASS_ROBOMANCER,
    CLASS_XENOMANCER,
    CLASS_NECROMANCER,
    CLASS_DEFENDER,
    CLASS_SHOCKTROOPER,
    CLASS_CLOAKER,
    CLASS_VANQUISHER,
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
    private int m_iLevel = 1;
    private int m_iCurrentLevelXP = 0; // XP accumulated within the current level.
    private int m_iXPNeededBase = 20;
    private float m_fXPNeededMult = 1.5f;
    private int m_iMaxLevel = g_iMaxLevel;
    private string m_szSteamID;

    int GetSkillPointsPerLevel() { return m_iSkillPointsPerLevel; }
    int GetTotalSkillPoints()    { return m_iSkillPoints; }
    int GetSkillPoints()         { return m_iSkillPoints - GetSpentSkillPoints(); }

    int GetLevel()          { return m_iLevel; }
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
        if(m_SkillLevels[idx] >= def.maxLevel) return false;
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
            if(int(i) < int(g_SkillDefs.length()))
            {
                SkillDefinition@ def = g_SkillDefs[i];
                if(def !is null && val > def.maxLevel) val = def.maxLevel;
            }
            m_SkillLevels[i] = val;
        }
    }
    
    private int GetXPForLevel(int level)
    {
        return int(m_iXPNeededBase * level * m_fXPNeededMult);
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

    // Sets XP position within the current level. Used when loading a save.
    void SetCurrentLevelXP(int xp)
    {
        m_iCurrentLevelXP = (xp < 0) ? 0 : xp;
        if(IsMaxLevel()) m_iCurrentLevelXP = 0;
    }

    void AddXP(int amount, CBasePlayer@ pPlayer, PlayerData@ playerData)
    {
        if(amount <= 0 || IsMaxLevel()) return;

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
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strLevelUpSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);

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

        if(IsMaxLevel()) m_iCurrentLevelXP = 0;
    }

    void SetSteamID(string steamID) { m_szSteamID = steamID; }

    // Validates that total skillpoints match the expected amount for the current level.
    void ValidateSkillPoints()
    {
        int expected = m_iLevel * m_iSkillPointsPerLevel;
        if(m_iSkillPoints != expected)
        {
            g_Game.AlertMessage(at_console, "CARPG: Correcting skillpoint total from " + m_iSkillPoints + " to " + expected + " (level " + m_iLevel + ").\n");
            m_iSkillPoints = expected;
        }
        if(GetSpentSkillPoints() > m_iSkillPoints)
        {
            g_Game.AlertMessage(at_console, "CARPG: Spent skillpoints (" + GetSpentSkillPoints() + ") exceed total (" + m_iSkillPoints + "). Resetting skills.\n");
            ResetSkills();
        }
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

    private Menu::ClassMenu@ m_ClassMenu = null;
    private Menu::SkillsMenu@ m_SkillsMenu = null;

    ClassStats@ GetClassStats(PlayerClass pClass)
    {
        return cast<ClassStats@>(m_ClassData[pClass]);
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
                case PlayerClass::CLASS_DEFENDER: // Clean up barrier data.
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
                            aura.DeactivateAura(pPlayer);
                        }
                        g_HealingAuras.delete(m_szSteamID);
                    }
                    break;
                    
                case PlayerClass::CLASS_BERSERKER: // Clean up bloodlust data.
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
                    
                case PlayerClass::CLASS_VANQUISHER: // Clean up Dragon's Breath data.
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
        if(pPlayer is null || m_CurrentClass == PlayerClass::CLASS_NONE)
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
                        
            case PlayerClass::CLASS_DEFENDER:
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
                    g_PlayerMinions[steamID] = data;
                }
                break;

            case PlayerClass::CLASS_XENOMANCER:
                if(!g_XenologistMinions.exists(steamID))
                {
                    XenMinionData data;
                    data.Initialize(GetCurrentClassStats());
                    g_XenologistMinions[steamID] = data;
                }
                break;
                
            case PlayerClass::CLASS_NECROMANCER:
                if(!g_NecromancerMinions.exists(steamID))
                {
                    NecroMinionData data;
                    data.Initialize(GetCurrentClassStats());
                    g_NecromancerMinions[steamID] = data;
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
                        
               case PlayerClass::CLASS_BERSERKER:
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

               case PlayerClass::CLASS_VANQUISHER:
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
        if(stats is null) return;
        
        if(g_ClassDefinitions.exists(m_CurrentClass))
        {
            ClassDefinition@ def = cast<ClassDefinition@>(g_ClassDefinitions[m_CurrentClass]);

            // Base HP/AP + SKILL_MAXHP / SKILL_MAXAP bonuses.
            float maxHealth = def.baseHP * (1.0f + SKILL_MAXHP * stats.GetSkillLevel(SkillID::SKILL_MAXHP));
            float maxArmor  = def.baseAP * (1.0f + SKILL_MAXAP * stats.GetSkillLevel(SkillID::SKILL_MAXAP));

            // Set Max HP/AP.
            pPlayer.pev.max_health = maxHealth;
            pPlayer.pev.armortype = maxArmor;

            // Clamp current HP/AP down if they exceed the new max.
            // Never boost current values here — free refill is only granted on RefillHealthArmor.
            if(pPlayer.pev.health > maxHealth)
                pPlayer.pev.health = maxHealth;

            if(pPlayer.pev.armorvalue > maxArmor)
                pPlayer.pev.armorvalue = maxArmor;
            
            // Class-specific weapon loadouts and other non-basic scaling bonuses like ammo and capacity.
            switch(m_CurrentClass)
            {
                case PlayerClass::CLASS_MEDIC:
                    break;
                case PlayerClass::CLASS_BERSERKER:
                    break;
                case PlayerClass::CLASS_ENGINEER:
                    break;
                case PlayerClass::CLASS_ROBOMANCER:
                    break;
                case PlayerClass::CLASS_DEFENDER:
                    break;
                case PlayerClass::CLASS_SHOCKTROOPER:
                    break;
                case PlayerClass::CLASS_CLOAKER:
                    break;
                case PlayerClass::CLASS_VANQUISHER:
                    break;
                case PlayerClass::CLASS_SWARMER:
                    break;
            }

            GiveClassWeapons(pPlayer, m_CurrentClass);
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
                m_iScore += int(scoreDiff * g_fXPMultiplier);
                
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
                                    stats.AddXP(scoreDiff, pOtherPlayer, otherData); // Add the actual XP.
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
        File@ file = g_FileSystem.OpenFile(filePath, OpenFile::WRITE);
        if(file !is null && file.IsOpen())
        {
            file.Write("v5\n");
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

            if(line != "v5")
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
            // Format: <classID> <level> <currentLevelXP> <totalSkillPoints> <skillLevelsCSV>
            // Classes absent from the file just keep their default stats.
            bool bNeedsResave = false;
            while(!file.EOFReached())
            {
                line = "";
                file.ReadLine(line);
                if(line.IsEmpty()) continue;

                array<string>@ parts = line.Split(" ");
                if(parts.length() < 5) continue;

                PlayerClass pClass = PlayerClass(atoi(parts[0]));
                ClassStats@ stats = cast<ClassStats@>(m_ClassData[pClass]);
                if(stats is null) continue;

                int savedLevel       = atoi(parts[1]);
                int savedCurrentXP   = atoi(parts[2]);
                int savedTotalSP     = atoi(parts[3]);
                string savedSkills   = parts[4];

                stats.SetLevel(savedLevel);
                stats.SetCurrentLevelXP(savedCurrentXP);
                stats.SetSkillLevelsFromString(savedSkills);

                stats.ValidateSkillPoints();

                // If the saved total doesn't match the recomputed total, m_iSkillPointsPerLevel
                // changed between sessions — reset invested skills so the player can reallocate.
                if(savedTotalSP != stats.GetTotalSkillPoints())
                {
                    g_Game.AlertMessage(at_console, "CARPG: Skillpoints-per-level changed for class "
                        + parts[0] + " (saved " + savedTotalSP + ", now "
                        + stats.GetTotalSkillPoints() + "). Resetting skills.\n");
                    stats.ResetSkills();
                    bNeedsResave = true;
                }
            }

            file.Close();
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
        RPGHudParams.x = 1;
        RPGHudParams.y = 0.1;
        RPGHudParams.effect = 0;
        RPGHudParams.r1 = 0;
        RPGHudParams.g1 = 255;
        RPGHudParams.b1 = 255;
        RPGHudParams.a1 = 255;
        RPGHudParams.fadeinTime = 0;
        RPGHudParams.fadeoutTime = 0;
        RPGHudParams.holdTime = 0.2;
        
        string RPGHudText = "Lvl: " + stats.GetLevel() + " | " + GetClassName(m_CurrentClass) + "\n";
        RPGHudText += "XP: " + (stats.IsMaxLevel() ? "(--/--)" : "(" + stats.GetCurrentLevelXP() + "/" + stats.GetNeededXP() + ")") + "\n";
        if(stats.GetSkillPoints() > 0) 
            RPGHudText += "Skillpoints: " + stats.GetSkillPoints() + "\n";
        
        g_PlayerFuncs.HudMessage(pPlayer, RPGHudParams, RPGHudText);
    }
}

string GetClassName(PlayerClass pClass)
{
    if(g_ClassNames.exists(pClass))
        return string(g_ClassNames[pClass]);
    return "Unknown";
}