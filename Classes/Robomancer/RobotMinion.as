string strRobogruntSoundCreate = "weapons/mine_deploy.wav";

// Minion Models.
string strRobogruntModel = "models/rgrunt.mdl";
string strRobogruntModelF = "models/rgruntf.mdl";

string strRobogruntRope = "sprites/rope.spr";
string strRobogruntModelChromegibs = "models/chromegibs.mdl";
string strRobogruntModelComputergibs = "models/computergibs.mdl";
string strRobogruntModelShell = "models/shell.mdl"; // Classic mode enabled fallback (It seems to get removed from precache list).
string strRobogruntModelShotgunShell = "models/shotgunshell.mdl"; // Classic mode enabled fallback (It seems to get removed from precache list).
string strRobogruntModelClassicShell = "models/hlclassic/shell.mdl"; // Used when Classic mode is enabled.
string strRobogruntModelClassicShotgunShell = "models/hlclassic/shotgunshell.mdl"; // Used when Classic mode is enabled.

//  Death Sounds.
string strRobogruntSoundDeath = "turret/tu_die.wav";
string strRobogruntSoundDeath2 = "turret/tu_die2.wav";

// Interaction Sounds.
string strRobogruntSoundButton2 = "buttons/button2.wav";
string strRobogruntSoundButton3 = "buttons/button3.wav";

//  Alert Sounds.
string strRobogruntSoundBeam = "debris/beamstart14.wav";

// Repair (Wrench heal) Sound.
string strRobogruntSoundRepair = "debris/metal6.wav";

// Weapons Sounds.
string strRobogruntSoundMP5 = "hgrunt/gr_mgun1.wav";
string strRobogruntSoundM16 = "weapons/m16_3round.wav";
string strRobogruntSoundReload = "hgrunt/gr_reload1.wav";

// Kick. 
string strRobogruntSoundKick = "zombie/claw_miss2.wav";

dictionary g_PlayerMinions;

enum MinionType // Minion gun type. Not all are supported.
{
    MINION_SHOTGUN = 10, // Shotgun + Frags. Keyvalue weapons(10).
    MINION_MP5 = 3, // MP5 + Frags. Keyvalue weapons(3).
    MINION_M16 = 5 // M16 + M203. Keyvalue weapons(5).
}

const array<float> ROBO_HP_MODIFIERS =
{
    0.75,  // Shotgun.
    1.00,  // MP5.
    1.25   // M16.
};

const array<float> ROBO_DMG_MODIFIERS = 
{
    1.50,  // Shotgun. Pump, not semi-auto so the DPS is terrible without a modifier.
    1.00,  // MP5.
    1.00   // M16.
};

const array<Vector> ROBO_GLOW_COLORS =
{
    Vector(125, 75 , 255),   // Shotgun Orchid.
    Vector(125, 50, 255),   // MP5 Violet.
    Vector(125, 0, 255)    // M16 Purple.
};

const array<string> MINION_NAMES = 
{
    "Robogrunt: SPAS-12 + Frags",
    "Robogrunt: MP5 + Frags",
    "Robogrunt: M16A1/M203"
};

const array<int> MINION_COSTS = 
{
    1,  // Shotgun.
    2,  // MP5.
    4   // M16.
};

// Structure to track minion type.
class MinionInfo
{
    EHandle hMinion;
    int type;
    
    MinionInfo() { type = 0; }
    MinionInfo(EHandle h, int t) { hMinion = h; type = t; }
}

class MinionData
{
    private MinionMenu@ m_pMenu;
    private array<MinionInfo> m_hMinions;
    private bool m_bActive = false;

    // Monster variables.
    private int m_iMinionPointMax = 1; // Max pool for minions. Can be increased with skill.
    private float m_flAbilityRechargeTime = 30.0f; // Time in seconds to recharge one minion point.
    private float m_flBaseHealth = 150.0; // Base health of Robogrunts.
    private float m_flHealthRegenInterval = 1.0f; // Interval for regen.
    private float m_flAnimationSpeed = 1.30; // Animation speed modifier, for ALL types.

    // Timers and trackers.
    private float m_flAbilityCharge = 1.0f; // Current available charge (in minion points).
    private int m_iMinionResourceCost = 0; // Initialisation cost to summon 1 minion default.
    private int m_iReservePool = 0; // Tracks the current reserve pool used for minions.
    private float m_flLastToggleTime = 0.0f;
    private float m_flLastRegenTime = 0.0f;
    private float m_flLastMessageTime = 0.0f;
    private float m_flToggleCooldown = 1.0f;
    private bool m_bInitialized = false;
    private ClassStats@ m_pStats = null;

    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    ClassStats@ GetStats() { return m_pStats; }

    bool IsInitialized() { return m_bInitialized; }
    void SetInitialized() { m_bInitialized = true; }

    int GetMinionCount() { return m_hMinions.length(); }
    int GetReservePool() { return m_iReservePool; }
    void SetReservePoolZero() { m_iReservePool = 0; }
    bool HasStats() { return m_pStats !is null; }

    int GetMinionPointIncrease()
    {
        if(m_pStats is null)
            return 0; // No increase if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_MINIONPOINT);
        return int(SKILL_MINIONPOINT * skillLevel); // Bonus minion points from skill.
    }

    int GetAbilityMax() { return m_iMinionPointMax + GetMinionPointIncrease(); }

    float GetAbilityCharge() { return m_flAbilityCharge; }

    float GetScaledAbilityRecharge()
    {
        if (m_pStats is null)
            return SKILL_ABILITYRECHARGE; // Return base if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_ABILITYRECHARGE);
        float rechargeBonus = SKILL_ABILITYRECHARGE * skillLevel; // Bonus ability recharge speed based on skill level.

        return rechargeBonus + 1.0f;
    }

    void RechargeAbility()
    {
        float chargeMax = float(GetAbilityMax() - m_iReservePool);
        if (m_flAbilityCharge >= chargeMax)
            return;

        float rechargeRate = 1.0f / m_flAbilityRechargeTime * GetScaledAbilityRecharge();
        m_flAbilityCharge += rechargeRate * flSchedulerInterval;
        if (m_flAbilityCharge > chargeMax)
            m_flAbilityCharge = chargeMax;
    }

    bool IsActive() 
    { 
        // Clean invalid minions first.
        for(int i = m_hMinions.length() - 1; i >= 0; i--)
        {
            // Checking IsValid(), GetEntity(), and also if the entity is alive.
            EHandle hMinion = m_hMinions[i].hMinion;
            if(!hMinion.IsValid())
            {
                m_hMinions.removeAt(i);
                continue;
            }
            
            CBaseEntity@ pEntity = hMinion.GetEntity();
            if(pEntity is null || !pEntity.IsAlive() || pEntity.pev.health <= 0)
            {
                m_hMinions.removeAt(i);
            }
        }
        
        // The minions are active if there are any in the list.
        return m_hMinions.length() > 0;
    }

    float GetScaledHealth(int minionType = 0)
    {
        if(m_pStats is null)
            return m_flBaseHealth * ROBO_HP_MODIFIERS[minionType]; // Return base health with type modifier if no stats.

        float minionScaledHealth = m_flBaseHealth; // Start with base health.

        float skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_MINIONHP);
        float skillPower = SKILL_MINIONHP;

        float modifier = 1.0f + (skillLevel * skillPower); // Calculate modifier based on skill level.

        minionScaledHealth *= modifier * ROBO_HP_MODIFIERS[minionType]; // Apply skill and type modifier.

        return minionScaledHealth;
    }

    float GetScaledDamage(int minionType = 0) // Damage scaling is applied through MonsterTakeDamage.
    {
        if(m_pStats is null)
            return ROBO_DMG_MODIFIERS[minionType]; // Return type modifier only if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_MINIONDAMAGE);
        float skillPower = SKILL_MINIONDAMAGE;
        float modifier = 1.0f + (skillLevel * skillPower); // Calculate modifier based on skill level.

        return modifier * ROBO_DMG_MODIFIERS[minionType];
    }

    float GetMinionRegen() // Get minion regen based on skill level.
    { 
        if(m_pStats is null)
            return 0.0f; // Default if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_MINIONREGEN);
        float skillPower = SKILL_MINIONREGEN;
        float modifier = skillLevel * skillPower; // Regen is zero with no skill points spent.

        return modifier;
    }
    
    array<MinionInfo>@ GetMinions() { return m_hMinions; }

    CBaseEntity@ GetMinionEntity(uint index)
    {
        if(index >= m_hMinions.length())
            return null;
            
        // Validate the entity reference before returning it.
        CBaseEntity@ pMinion = m_hMinions[index].hMinion.GetEntity();
        if(pMinion is null || pMinion.pev.health <= 0)
        {
            // Entity is invalid or dead, remove it from our list.
            m_hMinions.removeAt(index);
            RecalculateReservePool();
            return null;
        }
        
        return pMinion;
    }

    MinionData() 
    {
        @m_pMenu = MinionMenu(this);
    }

    void SpawnMinion(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
            return;

        m_flLastToggleTime = 0.0f;

        m_pMenu.ShowRobotMinionMenu(pPlayer); // Show menu.
    }

    void SpawnSpecificMinion(CBasePlayer@ pPlayer, int minionType)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        int maxPool = GetAbilityMax();
        if(maxPool <= 0)
            return;

        // First clean up invalid minions to make sure we have an accurate count.
        for(int i = m_hMinions.length() - 1; i >= 0; i--)
        {
            if(!m_hMinions[i].hMinion.IsValid())
            {
                m_hMinions.removeAt(i);
            }
        }

        // Check resources for spawning new minion.
        if(m_iReservePool + MINION_COSTS[minionType] > maxPool)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Not enough points for " + MINION_NAMES[minionType] + "!\n");
            return;
        }

        if(m_flAbilityCharge < float(MINION_COSTS[minionType]))
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, MINION_NAMES[minionType] + " is recharging!\n");
            return;
        }

        // Initialize stats if needed.
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(m_pStats is null)
        {
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_ROBOMANCER)
                {
                    @m_pStats = data.GetCurrentClassStats();
                }
            }
        }

        Vector vecSrc = pPlayer.GetGunPosition();
        Vector spawnForward, spawnRight, spawnUp;
        g_EngineFuncs.AngleVectors(pPlayer.pev.v_angle, spawnForward, spawnRight, spawnUp);
        
        vecSrc = vecSrc + (spawnForward * 64);
        vecSrc.z -= 32;

        float scaledHealth = GetScaledHealth(minionType);
        float scaledDamage = GetScaledDamage(minionType);
        
        dictionary keys;
        keys["origin"] = vecSrc.ToString();
        keys["angles"] = Vector(0, pPlayer.pev.angles.y, 0).ToString();
        keys["targetname"] = "_minion_" + pPlayer.entindex();
        keys["displayname"] = string(pPlayer.pev.netname) + "'s " + MINION_NAMES[minionType];
        keys["weapons"] = "" + (minionType == 0 ? MINION_SHOTGUN : 
                               minionType == 1 ? MINION_MP5 : 
                               MINION_M16);
        keys["health"] = string(scaledHealth);
        keys["scale"] = "1";
        keys["friendly"] = "1";
        keys["spawnflags"] = "16384";
        keys["is_player_ally"] = "1";
        keys["skin"] = "2";

        CBaseEntity@ pRoboMinion = g_EntityFuncs.CreateEntity("monster_robogrunt", keys, true);
        if(pRoboMinion !is null)
        {   
            // Apply glow effect before dispatch.
            ApplyMinionGlow(pRoboMinion, minionType);

            CBaseMonster@ pMonster = cast<CBaseMonster@>(pRoboMinion);
            if(pMonster !is null)
                pMonster.m_hGuardEnt = EHandle(pPlayer); // Guard the player, turn down follow requests.

            @pRoboMinion.pev.owner = @pPlayer.edict(); // Set the owner to the spawning player.
            //pRoboMinion.SetClassification(pPlayer.Classify()); // Set the same classification as the player to share ally tables.
            //pRoboMinion.SetPlayerAllyDirect (true); // Set directly as ally of owner.

            g_EntityFuncs.DispatchSpawn(pRoboMinion.edict()); // Dispatch the entity.

            // Store both the minion handle and its type
            MinionInfo info;
            info.hMinion = EHandle(pRoboMinion);
            info.type = minionType;
            m_hMinions.insertLast(info);
            
            m_iReservePool += MINION_COSTS[minionType]; // Add to reserve pool when minion is created.
            m_flAbilityCharge -= float(MINION_COSTS[minionType]); // Deduct from ability charge.

            g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_STATIC, strRobogruntSoundCreate, 1.0f, ATTN_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, MINION_NAMES[minionType] + " deployed!\n");
        }
    }

    void RobotUpdate(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;

        // Remove invalid Minions and check frags.
        for(int i = m_hMinions.length() - 1; i >= 0; i--)
        {
            CBaseEntity@ pExistingMinion = m_hMinions[i].hMinion.GetEntity();
            
            // If the minion no longer exists in the game world.
            if(pExistingMinion is null)
            {
                // Remove from our list and update reserve pool.
                m_hMinions.removeAt(i);
                continue;
            }

            // Check if any minions have died.
            if(pExistingMinion.pev.health <= 0 || !pExistingMinion.IsAlive() || pExistingMinion.pev.deadflag != DEAD_NO)
            {
                // Use Killed to properly destroy the minion.
                pExistingMinion.Killed(pPlayer.pev, GIB_ALWAYS); // Ensure gibbing to remove possibility of revival.
                
                // Also immediately remove from our list to prevent multiple Killed calls.
                m_hMinions.removeAt(i);
                continue;
            }
            
            // Cast monster and check monster is not null.
            CBaseMonster@ pMonster = cast<CBaseMonster@>(pExistingMinion);
            if(pMonster !is null)
            {
                // Set some values after casting incase they override.
                pMonster.pev.framerate = m_flAnimationSpeed; // Animation speed modifier, make them far more useful.
                //pMonster.m_flFieldOfView = -1.0; // Max their field of view so they become more effective.
            }

            // Check if minion has gained a frag, transfer to owner.
            if(pExistingMinion.pev.frags > 0)
            {
                // Transfer frags to player.
                pPlayer.pev.frags += pExistingMinion.pev.frags;
                pExistingMinion.pev.frags = 0;
            }
            
            // Ensure max_health is properly set and updated dynamically (e.g. when skills change).
            pExistingMinion.pev.max_health = GetScaledHealth(m_hMinions[i].type);
            if(pExistingMinion.pev.health > pExistingMinion.pev.max_health)
                pExistingMinion.pev.health = pExistingMinion.pev.max_health;
            
            // Ensure glow effect is maintained.
            ApplyMinionGlow(pExistingMinion, m_hMinions[i].type);
        }

        // Always recalculate the reserve pool to ensure it's accurate.
        RecalculateReservePool();

        // Update stats reference for stat menu.
        if(m_pStats is null)
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_ROBOMANCER)
                {
                    @m_pStats = data.GetCurrentClassStats();
                }
            }
        }
    }

    void DestroyAllMinions(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || m_hMinions.length() == 0)
            return;

        uint MinionCount = m_hMinions.length();
        if(MinionCount == 0)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No Robots to destroy!\n");
            return;
        }

        bool anyDestroyed = false;
        
        // Destroy all Minions from last to first.
        for(int i = MinionCount - 1; i >= 0; i--)
        {
            CBaseEntity@ pExistingMinion = m_hMinions[i].hMinion.GetEntity();
            if(pExistingMinion !is null)
            {
                // Use Killed to destroy active minions naturally.
                pExistingMinion.Killed(pPlayer.pev, GIB_ALWAYS); // Ensure gibbing, incase they are in dying state and revivable.
                anyDestroyed = true;
            }
            // Always remove from array, even if entity pointer is null
            m_hMinions.removeAt(i);
        }

        // Reset reserve pool after destroying all minions.
        m_iReservePool = 0;
        
        if(anyDestroyed)
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "All Robots destroyed!\n");
        else
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Robots cleared!\n");
    }
    
    // Reset function to clean up all active minions.
    void Reset()
    {
        // Find the player if possible.
        CBasePlayer@ pPlayer = null;
        
        if(m_pStats !is null)
        {
            for(int i = 1; i <= g_Engine.maxClients; i++)
            {
                CBasePlayer@ tempPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if(tempPlayer !is null && tempPlayer.IsConnected())
                {
                    string steamID = g_EngineFuncs.GetPlayerAuthId(tempPlayer.edict());
                    PlayerData@ playerData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                    if(playerData !is null && playerData.GetCurrentClassStats() is m_pStats)
                    {
                        @pPlayer = tempPlayer;
                        break;
                    }
                }
            }
        }
        
        if(pPlayer !is null)
        {
            DestroyAllMinions(pPlayer);
        }
        else
        {  
            // Just in case, try to remove any that might exist.
            for(int i = m_hMinions.length() - 1; i >= 0; i--)
            {
                CBaseEntity@ pExistingMinion = m_hMinions[i].hMinion.GetEntity();
                if(pExistingMinion !is null)
                {
                    g_EntityFuncs.Remove(pExistingMinion);
                }
            }
            
            // Clear the array and reset pool.
            m_hMinions.resize(0);
            m_iReservePool = 0;
            m_flAbilityCharge = float(GetAbilityMax());
        }
    }

    void MinionRegen()
    {
        // Only process regen if enough time has passed.
        float currentTime = g_Engine.time;
        if(currentTime - m_flLastRegenTime < m_flHealthRegenInterval)
            return;
            
        m_flLastRegenTime = currentTime;

        for(uint i = 0; i < m_hMinions.length(); i++)
        {
            CBaseEntity@ pMinion = m_hMinions[i].hMinion.GetEntity();
            if(pMinion !is null)
            {
                // Cast to CBaseMonster to check monster-specific properties.
                CBaseMonster@ pMonster = cast<CBaseMonster@>(pMinion);
                
                // Only regenerate if the monster is alive (not in a dying state).
                if(pMonster !is null && pMonster.pev.deadflag == DEAD_NO && pMinion.pev.health > 0)
                {
                    // Ensure max_health is properly set.
                    pMinion.pev.max_health = GetScaledHealth(m_hMinions[i].type);

                    // Get scaled regen based on skill level.
                    float regenAmount = GetMinionRegen(); // This already scales with level.
                    float flHealAmount = pMinion.pev.max_health * regenAmount; // Apply scaled regen.

                    if(pMinion.pev.health < pMinion.pev.max_health)
                    {
                        pMinion.pev.health = Math.min(pMinion.pev.health + flHealAmount, pMinion.pev.max_health); // Add health.

                        if(pMinion.pev.health > pMinion.pev.max_health) 
                            pMinion.pev.health = pMinion.pev.max_health; // Clamp to max health.
                    }
                }
            }
        }
    }
    
    void ApplyMinionGlow(CBaseEntity@ pMinion, int minionType = 0)
    {
        if(pMinion is null)
            return;
            
        // Apply the glowing effect.
        pMinion.pev.renderfx = kRenderFxGlowShell; // Effect.
        pMinion.pev.rendermode = kRenderNormal; // Render mode.
        pMinion.pev.renderamt = 1; // Shell thickness.
        pMinion.pev.rendercolor = ROBO_GLOW_COLORS[minionType];
    }
    
    void RecalculateReservePool()
    {
        // Recalculate the reserve pool based on current minions.
        int newReservePool = 0;
        
        // Process from last to first to allow safe removal during iteration
        for(int i = int(m_hMinions.length()) - 1; i >= 0; i--)
        {
            // First verify the minion actually exists and is alive
            CBaseEntity@ pMinion = m_hMinions[i].hMinion.GetEntity();
            if(pMinion is null || !pMinion.IsAlive() || pMinion.pev.health <= 0)
            {
                // Invalid or dead minion, remove it from our tracking
                m_hMinions.removeAt(i);
                continue;
            }
            
            // Only count valid, alive minions toward the reserve pool
            int minionType = m_hMinions[i].type;
            if(minionType >= 0 && uint(minionType) < MINION_COSTS.length())
            {
                newReservePool += MINION_COSTS[minionType];
            }
        }
        
        // Update the reserve pool.
        m_iReservePool = newReservePool;
    }

    // Called when a minion deals damage to an enemy.
    void ProcessMinionDamage(CBasePlayer@ pPlayer, float flDamageDealt)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;
    }

    void TeleportMinions(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        if(m_hMinions.length() == 0)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No Robots to teleport!\n");
            return;
        }

        Vector playerPos = pPlayer.pev.origin;
        Vector spawnForward, spawnRight, spawnUp;
        float radius = 60.0f;
        float angleStep = (180.0f / m_hMinions.length());

        for(uint i = 0; i < m_hMinions.length(); i++)
        {
            CBaseEntity@ pMinion = m_hMinions[i].hMinion.GetEntity();
            if(pMinion !is null)
            {
                float angle = angleStep * i;
                g_EngineFuncs.AngleVectors(Vector(0, angle, 0), spawnForward, spawnRight, spawnUp);
                Vector offset = spawnForward * radius;
                pMinion.pev.origin = playerPos + offset;
                pMinion.pev.angles = pPlayer.pev.angles;
            }
        }

        g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_STATIC, strRobogruntSoundBeam, 1.0f, ATTN_NORM);
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Robots teleported!\n");
    }
}

class MinionMenu 
{
    private CTextMenu@ m_pMenu;
    private MinionData@ m_pOwner;
    
    MinionMenu(MinionData@ owner) 
    {
        @m_pOwner = owner;
    }
    
    void ShowRobotMinionMenu(CBasePlayer@ pPlayer) 
    {
        if(pPlayer is null) return;
        
        @m_pMenu = CTextMenu(TextMenuPlayerSlotCallback(this.MenuCallback));
        m_pMenu.SetTitle("[Robot Control Menu]\n");
        
        // Always show spawn options since limit is now resource-based.
        for(uint i = 0; i < MINION_NAMES.length(); i++) 
        {
            m_pMenu.AddItem("Deploy " + MINION_NAMES[i] + " (Cost: " + MINION_COSTS[i] + ")\n", any(i));
        }

        // Add management options if we have minions.
        if(m_pOwner.GetMinionCount() > 0) 
        {
            m_pMenu.AddItem("Teleport All\n", any(99));
            m_pMenu.AddItem("Destroy All\n", any(98));
        }
        
        m_pMenu.Register();
        m_pMenu.Open(0, 0, pPlayer);
    }
    
    private void MenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item) 
    {
        if(item !is null && pPlayer !is null) 
        {
            int choice;
            item.m_pUserData.retrieve(choice);
            
            if(choice == 98) 
            {
                // Destroy all minions.
                m_pOwner.DestroyAllMinions(pPlayer);
            }
            else if(choice == 99)
            {
                // Teleport existing minions.
                m_pOwner.TeleportMinions(pPlayer);
            }
            else if(choice >= 0 && uint(choice) < MINION_NAMES.length())
            {
                // Spawn new minion with selected weapon.
                m_pOwner.SpawnSpecificMinion(pPlayer, choice);
            }
        }
    }
}

void CheckEngineerMinions()
{   
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            
            // Initialize MinionData if it doesn't exist.
            if(!g_PlayerMinions.exists(steamID))
            {
                MinionData data;
                @g_PlayerMinions[steamID] = data;
            }

            MinionData@ Minion = cast<MinionData@>(g_PlayerMinions[steamID]);
            if(Minion !is null)
            {
                // Reset stale minions once on map load or plugin reload.
                if(!Minion.IsInitialized())
                {
                    Minion.Reset();
                    Minion.SetInitialized();
                }
                
                // Check if player switched away from Engineer.
                if(g_PlayerRPGData.exists(steamID))
                {
                    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                    if(data !is null)
                    {
                        if(data.GetCurrentClass() != PlayerClass::CLASS_ROBOMANCER)
                        {
                            // Player is not Engineer, destroy active minions or clear references.
                            if(Minion.IsActive())
                            {
                                //g_Game.AlertMessage(at_console, "CARPG: Player " + steamID + " is not Robomancer, clearing minions\n");
                                Minion.DestroyAllMinions(pPlayer);
                                continue;  // Skip rest of updates.
                            }
                        }
                        else if(!Minion.HasStats())
                        {
                            // Update stats for Robomancer.
                            Minion.Initialize(data.GetCurrentClassStats());
                        }
                    }
                }
                
                // Make sure resource limits are enforced.
                Minion.RecalculateReservePool();
                int roboMax = Minion.GetAbilityMax();
                if(roboMax > 0 && Minion.GetReservePool() > roboMax)
                {
                    // Over the limit, destroy minions until we're within limits.
                    Minion.DestroyAllMinions(pPlayer);
                }

                Minion.MinionRegen(); // Minion Regeneration.
                Minion.RechargeAbility(); // Recharge minion points.

                // Always update scaling values for stats menu.
                Minion.GetScaledHealth();
                Minion.GetScaledDamage();

                // Normal update for active minions.
                Minion.RobotUpdate(pPlayer);
            }
        }
    }
}