const string strLevelUpSound = "misc/secret.wav";

dictionary g_PlayerRPGData;

// Used for debug menu.
int g_iMaxLevel = 50;
int g_iPerk1LvlReq = 10; // Level required to unlock first perk.
int g_iPerk2LvlReq = 20;
int g_iPerk3LvlReq = 30;

dictionary g_ClassNames = 
{
    {PlayerClass::CLASS_NONE, "None"},
    {PlayerClass::CLASS_MEDIC, "Medic"},
    {PlayerClass::CLASS_BERSERKER, "Berserker"},
    {PlayerClass::CLASS_ENGINEER, "Engineer"},
    {PlayerClass::CLASS_ROBOMANCER, "Robomancer"},
    {PlayerClass::CLASS_XENOLOGIST, "Xenologist"},
    {PlayerClass::CLASS_DEFENDER, "Warden"},
    {PlayerClass::CLASS_SHOCKTROOPER, "Shocktrooper"},
    {PlayerClass::CLASS_CLOAKER, "Cloaker"},
    {PlayerClass::CLASS_DEMOLITIONIST, "Demolitionist"}
};

array<PlayerClass> g_ClassList = 
{
    PlayerClass::CLASS_MEDIC,
    PlayerClass::CLASS_BERSERKER,
    PlayerClass::CLASS_ENGINEER,
    PlayerClass::CLASS_ROBOMANCER,
    PlayerClass::CLASS_XENOLOGIST,
    PlayerClass::CLASS_DEFENDER,
    PlayerClass::CLASS_SHOCKTROOPER,
    PlayerClass::CLASS_CLOAKER,
    PlayerClass::CLASS_DEMOLITIONIST
};

enum PlayerClass 
{
    CLASS_NONE = 0,
    CLASS_MEDIC,
    CLASS_BERSERKER,
    CLASS_ENGINEER,
    CLASS_ROBOMANCER,
    CLASS_XENOLOGIST,
    CLASS_DEFENDER,
    CLASS_SHOCKTROOPER,
    CLASS_CLOAKER,
    CLASS_DEMOLITIONIST
}

// --- Per-class stat definitions. ---
class ClassDefinition 
{
    // Base stats for each class. Typically overridden on a per class basis.
    string name;
    float baseHP = 100.0f; // Base health.
    float baseAP = 100.0f; // Base armor.
    float baseResource = 100.0f; // Base max ability charge/duration.
    float baseResourceRegen = 1.0f; // Base ability regen per second.

    float healthPerLevel = 0.02f; // 2% of base health per level.
    float armorPerLevel = 0.01f; // 1% of base armor per level.
    float energyPerLevel = 0.1f; // 10% of base energy per level.
    float energyRegenPerLevel = 0.05f; // 5% of base energy regen per level.

    ClassDefinition(string _name) 
    {
        name = _name;
    }

    float GetPlayerHealth(int level)
    {
        return baseHP * (1.0f + (level * healthPerLevel));
    }
    float GetPlayerArmor(int level)
    {
        return baseAP * (1.0f + (level * armorPerLevel));
    }
    float GetPlayerEnergy(int level)
    {
        float maxEnergy = baseResource;
        return maxEnergy * (1.0f + (level * energyPerLevel));
    }
    float GetPlayerEnergyRegen(int level, float energyRegen)
    {
        return baseResourceRegen * (1.0f + (level * energyRegenPerLevel));
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

            // Set class-specific base stats and scaling.
            switch(pClass)
            {
                case PlayerClass::CLASS_MEDIC:
                    def.baseHP = 100.0f;
                    def.baseAP = 100.0f;
                    def.baseResource = 100.0f;
                    def.baseResourceRegen = 1.0f;
                    def.energyPerLevel = 0.02f; // 200 at level 50.
                    def.energyRegenPerLevel = 0.1f; // 10% per level.
                    break;
                case PlayerClass::CLASS_ENGINEER:
                    def.baseHP = 100.0f;
                    def.baseAP = 100.0f;
                    def.baseResource = 25.0f; // Effective max seconds active.
                    def.baseResourceRegen = 1.0f;
                    def.energyPerLevel = 0.096f; // 120 at level 50.
                    def.energyRegenPerLevel = 0.05f; // 5% per level.
                    break;
                case PlayerClass::CLASS_ROBOMANCER:
                    def.baseHP = 100.0f;
                    def.baseAP = 100.0f;
                    def.baseResource = 25.0f;
                    def.baseResourceRegen = 0.5f;
                    def.energyPerLevel = 0.08f; // 100 at level 50.
                    def.energyRegenPerLevel = 0.01f; // 1% per level.
                    break;
                case PlayerClass::CLASS_XENOLOGIST:
                    def.baseHP = 100.0f;
                    def.baseAP = 100.0f;
                    def.baseResource = 25.0f;
                    def.baseResourceRegen = 0.5f;
                    def.energyPerLevel = 0.06f; // 100 at level 50.
                    def.energyRegenPerLevel = 0.01f; // 1% per level.
                    break;
                case PlayerClass::CLASS_BERSERKER:
                    def.baseHP = 100.0f;
                    def.baseAP = 100.0f;
                    def.baseResource = 100.0f;
                    def.baseResourceRegen = 1.0f;
                    def.energyPerLevel = 0.02f; // 200 at level 50.
                    def.energyRegenPerLevel = 0.05f; // 5% per level.
                    def.healthPerLevel = 0.04f; // Berserkers gain 4% of base health per level instead.
                    def.armorPerLevel = 0.005f; // Berserkers gain 0.5% of base armor per level instead.
                    break;
                case PlayerClass::CLASS_DEFENDER:
                    def.baseHP = 100.0f;
                    def.baseAP = 100.0f;
                    def.baseResource = 100.0f; // Shield Base HP.
                    def.baseResourceRegen = 5.0f; // Defender needs higher base regen to keep up with shield HP scaling.
                    def.energyPerLevel = 0.08f; // 500 at level 50. Shield HP Scaling.
                    def.energyRegenPerLevel = 0.06f; // 6% per level.
                    break;
                case PlayerClass::CLASS_SHOCKTROOPER:
                    def.baseHP = 100.0f;
                    def.baseAP = 100.0f;
                    def.baseResource = 100.0f; // Base Shock Rifle battery capacity.
                    def.baseResourceRegen = 2.0f;
                    def.energyPerLevel = 0.08f; // 500 at level 50. Shockrifle battery capacity scaling.
                    def.energyRegenPerLevel = 0.01f; // 1% per level.
                    break;
                case PlayerClass::CLASS_CLOAKER:
                    def.baseHP = 100.0f;
                    def.baseAP = 100.0f;
                    def.baseResource = 100.0f; // Cloak battery (duration).
                    def.baseResourceRegen = 1.0f;
                    def.energyPerLevel = 0.02f; // 200 at level 50. Cloak battery scaling.
                    def.energyRegenPerLevel = 0.2f; // 20% per level.
                    break;
                case PlayerClass::CLASS_DEMOLITIONIST:
                    def.baseHP = 100.0f;
                    def.baseAP = 100.0f;
                    def.baseResource = 100.0f; // Energy available to convert into explosive rounds.
                    def.baseResourceRegen = 1.0f;
                    def.energyPerLevel = 0.02f; // 200 at level 50. Energy Pool for converting to rounds scaling.
                    def.energyRegenPerLevel = 0.05f; // 5% per level.
                    break;
            }
            @g_ClassDefinitions[pClass] = @def;
        }
    }
}

class ClassStats
{
    private int m_iLevel = 1;
    private int m_iXP = 0;
    private int m_iCurrentLevelXP = 0;
    private int XP_BASE = 25;          // Base XP for calculation.
    private int XP_MULTIPLIER = 2;     // Exponential growth factor. How much increase extra per level up.
    private int MAX_LEVEL = g_iMaxLevel;         // Max level.
    private string m_szSteamID; // Store player's SteamID.
    
    int GetLevel() { return m_iLevel; }
    int GetXP() { return m_iXP; }
    int GetNextLevelXP() { return GetXPForLevel(m_iLevel); }
    int GetCurrentLevelXP() { return m_iCurrentLevelXP; }
    int GetNeededXP() { return GetXPForLevel(m_iLevel); }

    bool IsMaxLevel() { return m_iLevel >= MAX_LEVEL; }
    
    private int GetXPForLevel(int level)
    {
        return XP_BASE * XP_MULTIPLIER * level;
    }
    
    private int GetTotalXPForLevel(int level)
    {
        int total = 0;
        for(int i = 1; i < level; i++)
        {
            total += GetXPForLevel(i);
        }
        return total;
    }

    void UpdateCurrentLevelXP()
    {
        int prevLevelTotal = GetTotalXPForLevel(m_iLevel);
        m_iCurrentLevelXP = m_iXP - prevLevelTotal;
    }

    void SetLevel(int level) 
    { 
        if(level < 1) level = 1;
        if(level > MAX_LEVEL) level = MAX_LEVEL;
        m_iLevel = level;
    }
    
    void SetXP(int xp, CBasePlayer@ pPlayer = null, PlayerData@ playerData = null) 
    { 
        m_iXP = xp;
        
        // Handle max level case.
        if(IsMaxLevel())
        {
            m_iXP = GetTotalXPForLevel(MAX_LEVEL);
            m_iCurrentLevelXP = 0;
        }
        
        // Calculate new level and show effects.
        while(!IsMaxLevel())
        {
            int neededForNext = GetXPForLevel(m_iLevel);
            int currentLevelXP = m_iXP - GetTotalXPForLevel(m_iLevel);
            
            if(currentLevelXP >= neededForNext)
            {
                m_iLevel++;
                if(pPlayer !is null && playerData !is null)
                {
                    string className = playerData.GetClassName(playerData.GetCurrentClass());
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[CARPG] Your (" + className + ") is now Level " + m_iLevel + "!\n");
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strLevelUpSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);

                    NetworkMessage message(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
                    message.WriteByte(TE_PARTICLEBURST);
                    message.WriteCoord(pPlayer.pev.origin.x);
                    message.WriteCoord(pPlayer.pev.origin.y);
                    message.WriteCoord(pPlayer.pev.origin.z);
                    message.WriteShort(80);  // Radius.
                    message.WriteByte(255);  // Particle color.
                    message.WriteByte(5);    // Duration (in 0.1s).
                    message.End();

                    playerData.CalculateStats(pPlayer);
                    playerData.SaveToFile();
                }
            }
            else
                break;
        }
        
        UpdateCurrentLevelXP();
    }
    
    void AddXP(int amount, CBasePlayer@ pPlayer, PlayerData@ playerData) 
    {
        if(amount <= 0) return;
        
        if(IsMaxLevel())
        {
            m_iXP = GetTotalXPForLevel(MAX_LEVEL);
            m_iCurrentLevelXP = 0;
            return;
        }
        
        m_iXP += amount;
        
        while(!IsMaxLevel())
        {
            int neededForNext = GetXPForLevel(m_iLevel);
            int currentLevelXP = m_iXP - GetTotalXPForLevel(m_iLevel);
            
            if(currentLevelXP >= neededForNext)
            {
                m_iLevel++;
                if(pPlayer !is null)
                {
                    string className = playerData.GetClassName(playerData.GetCurrentClass());
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[CARPG] Your (" + className + ") is now Level " + m_iLevel + "!\n");
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strLevelUpSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);

                    // Level up effect.
                    NetworkMessage message(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
                    message.WriteByte(TE_PARTICLEBURST);
                    message.WriteCoord(pPlayer.pev.origin.x);
                    message.WriteCoord(pPlayer.pev.origin.y);
                    message.WriteCoord(pPlayer.pev.origin.z);
                    message.WriteShort(80);  // Radius.
                    message.WriteByte(255);  // Particle color - 255 is confetti-like.
                    message.WriteByte(5);    // Duration (in 0.1s).
                    message.End();

                    playerData.CalculateStats(pPlayer);
                    playerData.SaveToFile();
                }
            }
            else
                break;
        }
        
        UpdateCurrentLevelXP();
    }

    void SetSteamID(string steamID) { m_szSteamID = steamID; }
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
    
    // Constructor.
    PlayerData(string steamID)
    {
        m_szSteamID = steamID;
        InitializeClasses();
        InitializeClassDefinitions();
        
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
        
        m_CurrentClass = newClass;
    
        // Find the player and update their stats
        const int iMaxPlayers = g_Engine.maxClients;
        for(int i = 1; i <= iMaxPlayers; ++i)
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
            if(pPlayer !is null && g_EngineFuncs.GetPlayerAuthId(pPlayer.edict()) == m_szSteamID)
            {
                string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
                
                // Initialize base resources once
                if(!g_PlayerClassResources.exists(steamID))
                {
                    dictionary resources = 
                    {
                        {'current', 0.0f}, // Start at 0 or set to max after CalculateStats.
                        {'max', 0.0f},
                        {'regen', 0.0f}
                    };
                    @g_PlayerClassResources[steamID] = resources;
                }
                
                CalculateStats(pPlayer);
                
                // Update resource caps after stats calculation
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                if(resources !is null)
                {   
                    float currentEnergy = float(resources['current']);
                    float maxEnergy = float(resources['max']);
                    if(currentEnergy > maxEnergy)
                        resources['current'] = maxEnergy;
                }

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
        // Initialize class-specific data.
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

            case PlayerClass::CLASS_XENOLOGIST:
                if(!g_XenologistMinions.exists(steamID))
                {
                    XenMinionData data;
                    data.Initialize(GetCurrentClassStats());
                    g_XenologistMinions[steamID] = data;
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

               case PlayerClass::CLASS_DEMOLITIONIST:
                if(!g_PlayerExplosiveRounds.exists(steamID))
                {
                    ExplosiveRoundsData data;
                    data.Initialize(GetCurrentClassStats());
                    g_PlayerExplosiveRounds[steamID] = data;
                }
                break;
        }

        ClassStats@ stats = GetCurrentClassStats();
        if(stats is null) return;
                
        int level = stats.GetLevel();
        
        if(g_ClassDefinitions.exists(m_CurrentClass))
        {
            ClassDefinition@ def = cast<ClassDefinition@>(g_ClassDefinitions[m_CurrentClass]);

            float maxHealth = def.GetPlayerHealth(level);
            float maxArmor = def.GetPlayerArmor(level);
            float maxResource = def.GetPlayerEnergy(level);
            float resourceRegen = def.GetPlayerEnergyRegen(level, maxResource);

            // Set Max HP/AP.
            pPlayer.pev.max_health = maxHealth;
            pPlayer.pev.armortype = maxArmor;

            if(!g_PlayerClassResources.exists(steamID))
            {
                dictionary resources;
                @g_PlayerClassResources[steamID] = resources;
            }
            
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            resources['max'] = maxResource;
            resources['regen'] = resourceRegen;
            
            // If we heal over max, set it back (except for Berserkers).
            if(pPlayer.pev.health > maxHealth && m_CurrentClass != PlayerClass::CLASS_BERSERKER)
                pPlayer.pev.health = maxHealth;
                
            // Same for armor.
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
                case PlayerClass::CLASS_DEMOLITIONIST:
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
                m_iScore += scoreDiff;
                
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
                                    stats.AddXP(scoreDiff, pOtherPlayer, otherData);
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
            return "scripts/plugins/store/" + safeSteamID + ".txt";
        }

    void SaveToFile()
    {
        string filePath = GetSafeFileName();
        File@ file = g_FileSystem.OpenFile(filePath, OpenFile::WRITE);
        if(file !is null && file.IsOpen())
        {
            // Save last selected class.
            file.Write(string(int(m_CurrentClass)) + "\n");
            
            // Save each class's stats separately.
            for(uint i = 1; i <= PlayerClass::CLASS_DEMOLITIONIST; i++)
            {
                ClassStats@ stats = cast<ClassStats@>(m_ClassData[i]);
                if(stats !is null)
                {
                    file.Write(string(stats.GetLevel()) + "\n");
                    file.Write(string(stats.GetXP()) + "\n");
                }
            }
            
            file.Close();

            //g_Game.AlertMessage(at_console, "RPG: Successfully saved to " + filePath + "\n"); // Debug.
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
            
            // Load last selected class.
            file.ReadLine(line);
            m_CurrentClass = PlayerClass(atoi(line));
            g_Game.AlertMessage(at_console, "CARPG: Loaded class: " + GetClassName(m_CurrentClass) + "\n");
            
            // Load each class's stats separately.
            for(uint i = 1; i <= PlayerClass::CLASS_DEMOLITIONIST; i++)
            {
                ClassStats@ stats = cast<ClassStats@>(m_ClassData[i]);
                if(stats !is null)
                {
                    line = "";
                    file.ReadLine(line);
                    stats.SetLevel(atoi(line));
                    
                    line = "";
                    file.ReadLine(line);
                    stats.SetXP(atoi(line));
                }
            }
            
            file.Close();
            g_Game.AlertMessage(at_console, "CARPG: Loaded data from " + filePath + "\n");
        }
        else
        {
            g_Game.AlertMessage(at_console, "CARPG: Could not load data from " + filePath + "\n");
        }
    }

    private void InitializeClassResource(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;
            
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(g_PlayerClassResources.exists(steamID))
        {
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            
            // Get resource values from class definition
            if(g_ClassDefinitions.exists(m_CurrentClass))
            {
                ClassDefinition@ def = cast<ClassDefinition@>(g_ClassDefinitions[m_CurrentClass]);
                ClassStats@ stats = GetCurrentClassStats();
                
                if(stats !is null)
                {
                    int level = stats.GetLevel();
                    float resourceMax = def.GetPlayerEnergy(level);
                    float resourceRegen = def.GetPlayerEnergyRegen(level, resourceMax);
                    
                    resources['max'] = resourceMax;
                    resources['regen'] = resourceRegen;
                }
            }
        }
    }

    void UpdateRPGHUD(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null) return;
        
        ClassStats@ stats = GetCurrentClassStats();
        if(stats is null) return;
        
        HUDTextParams RPGHudParams;
        RPGHudParams.x = 1;
        RPGHudParams.y = 0.1;
        RPGHudParams.effect = 0;
        RPGHudParams.r1 = 0;
        RPGHudParams.g1 = 255;
        RPGHudParams.b1 = 255;
        RPGHudParams.a1 = 255;
        RPGHudParams.fadeinTime = 0;
        RPGHudParams.fadeoutTime = 0;
        RPGHudParams.holdTime = 0.5;
        RPGHudParams.channel = 3;
        
        string RPGHudText = "Lvl: " + stats.GetLevel() + " | " + GetClassName(m_CurrentClass) + "\n";
        RPGHudText += "XP: " + (stats.IsMaxLevel() ? "(--/--)" : "(" + stats.GetCurrentLevelXP() + "/" + stats.GetNeededXP() + ")") + "\n";
        
        g_PlayerFuncs.HudMessage(pPlayer, RPGHudParams, RPGHudText);
    }
}

string GetClassName(PlayerClass pClass)
{
    if(g_ClassNames.exists(pClass))
        return string(g_ClassNames[pClass]);
    return "Unknown";
}