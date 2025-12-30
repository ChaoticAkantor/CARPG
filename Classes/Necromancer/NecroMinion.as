string strNecroMinionSoundCreate = "debris/beamstart7.wav";

// Precache strings for monsters. (Yawn)

// Zombie.
    // Models/Sprites.
    string strZombieModel = "models/hunger/hungerzombie.mdl";
    string strZombieModelGibs = "models/zombiegibs1.mdl";

    // Sounds.
    string strZombieSoundClawMiss1 = "zombie/claw_miss1.wav";
    string strZombieSoundClawMiss2 = "zombie/claw_miss2.wav";
    string strZombieSoundClawStrike1 = "zombie/claw_strike1.wav";
    string strZombieSoundClawStrike2 = "zombie/claw_strike2.wav";
    string strZombieSoundClawStrike3 = "zombie/claw_strike3.wav";
    string strZombieSoundAlert10 = "zombie/zo_alert10.wav";
    string strZombieSoundAlert20 = "zombie/zo_alert20.wav";
    string strZombieSoundAlert30 = "zombie/zo_alert30.wav";
    string strZombieSoundAttack1 = "zombie/zo_attack1.wav";
    string strZombieSoundAttack2 = "zombie/zo_attack2.wav";
    string strZombieSoundIdle1 = "zombie/zo_idle1.wav";
    string strZombieSoundIdle2 = "zombie/zo_idle2.wav";
    string strZombieSoundIdle3 = "zombie/zo_idle3.wav";
    string strZombieSoundIdle4 = "zombie/zo_idle4.wav";
    string strZombieSoundPain1 = "zombie/zo_pain1.wav";
    string strZombieSoundPain2 = "zombie/zo_pain2.wav";

// Skeleton (Vortigaunt).
    // Models/Sprites.
    string strSkeletonModel = "models/hunger/hungerslave.mdl";

    // Sounds.
    string strSkeletonSoundShoot1 = "hassault/hw_shoot1.wav";
    string strSkeletonSoundBite = "headcrab/hc_headbite.wav";
    string strSkeletonSoundWord3 = "aslave/slv_word3.wav";
    string strSkeletonSoundWord4 = "aslave/slv_word4.wav";
    string strSkeletonSoundWord5 = "aslave/slv_word5.wav";
    string strSkeletonSoundWord7 = "aslave/slv_word7.wav";
    string strSkeletonSoundPain1 = "aslave/slv_pain1.wav";
    string strSkeletonSoundPain2 = "aslave/slv_pain2.wav";
    string strSkeletonSoundDie1 = "aslave/slv_die1.wav";
    string strSkeletonSoundDie2 = "aslave/slv_die2.wav";
    string strSkeletonSoundZap1 = "debris/zap1.wav";
    string strSkeletonSoundZap4 = "debris/zap4.wav";

// Gonome.
    // Models/Sprites.
    string strGonomeModel = "models/cards/big_skeleton.mdl";
    //string strGonomeModel = "models/hunger/hungergonome.mdl";
    string strGonomeSpriteSpit = "sprites/blood_chnk.spr";

    // Sounds.
    string strGonomeSoundSpit1 = "bullchicken/bc_spithit1.wav";
    string strGonomeSoundDeath2 = "gonome/gonome_death2.wav";
    string strGonomeSoundDeath3 = "gonome/gonome_death3.wav";
    string strGonomeSoundDeath4 = "gonome/gonome_death4.wav";
    string strGonomeSoundIdle1 = "gonome/gonome_idle1.wav";
    string strGonomeSoundIdle2 = "gonome/gonome_idle2.wav";
    string strGonomeSoundIdle3 = "gonome/gonome_idle3.wav";
    string strGonomeSoundPain1 = "gonome/gonome_pain1.wav";
    string strGonomeSoundPain2 = "gonome/gonome_pain2.wav";
    string strGonomeSoundPain3 = "gonome/gonome_pain3.wav";
    string strGonomeSoundPain4 = "gonome/gonome_pain4.wav";
    string strGonomeSoundMelee1 = "gonome/gonome_melee1.wav";
    string strGonomeSoundMelee2 = "gonome/gonome_melee2.wav";
    string strGonomeSoundRun = "gonome/gonome_run.wav";
    string strGonomeSoundEat = "gonome/gonome_eat.wav";

dictionary g_NecromancerMinions;

enum ZombieType
{   
    NECRO_ZOMBIE = 1,
    NECRO_SKELETON = 2,
    NECRO_ABOMINATION = 3
}

// Used to swap bodygroups for Zombies.
const array<int> ZOMBIE_BODYGROUPS = 
{
    1,  // Male burnt.
    2,  // Male burnt headless.
    3,  // Male suit.
    4,  // Male suit headless.
    5,  // Male police.
    6,  // Female.
    7,  // Male Hazmat.
    8,  // Male Army dress.
    9,  // Male scientist burnt.
    10, // Male scientist.
    11  // Male patient.
};

const array<float> NECRO_ANIMATION_SPEEDS = 
{
    3.00,  // Zombie.
    1.50,  // Skeleton.
    2.00   // Abomination (Gonome).
};

// Used to change monster name in UI.
const array<string> NECRO_NAMES = 
{
    "Zombie",
    "Skeleton",
    "Abomination"
};

// Used to swap monster type.
const array<string> NECRO_ENTITIES = 
{
    "monster_zombie",
    "monster_alien_slave",
    "monster_gonome"    
};

// Used to swap models.
const array<string> NECRO_MODELS = 
{
    strZombieModel,
    strSkeletonModel,
    strGonomeModel
};

const array<int> NECRO_COSTS = // Pool cost per summon of each type.
{
    1, // Zombie.
    2, // Skeleton (Vortigaunt).
    2 // Abomination (Gonome).
};

// Level requirements for each Zombie type.
const array<int> NECRO_LEVEL_REQUIREMENTS = 
{   
    1,   // Zombie.
    5,  // Skeleton (Vortigaunt).
    15    // Abomination (Gonome).
};

// Structure to track minion type.
class NecroMinionInfo
{
    EHandle hMinion;
    int type;
    
    NecroMinionInfo() { type = 0; }
    NecroMinionInfo(EHandle h, int t) { hMinion = h; type = t; }
}

class NecroMinionData
{
    private NecroMinionMenu@ m_pMenu;
    private array<NecroMinionInfo> m_hMinions;
    private bool m_bActive = false;
    private float m_flBaseHealth = 200.0; // Base health of Minions, currently the same for all of them.
    private float m_flHealthScaleAtMaxLevel = 9.0; // Health modifier at max level.
    private float m_flHealthRegenAtMaxLevel = 0.01; // // Health recovery % per second at max level.
    private float m_flDamageScaleAtMaxLevel = 4.0; // Damage modifier at max level.
    private float m_flLifestealPercentAtMaxLevel = 0.25; // Lifesteal at max level.
    private float m_flRegenInterval = 1.0f; // Interval for regen.
    private int m_iMinionResourceCost = 1; // Cost to summon specific minion.
    private float m_flReservePool = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flLastRegenTime = 0.0f;
    private float m_flLastMessageTime = 0.0f;
    private float m_flToggleCooldown = 1.0f;
    private ClassStats@ m_pStats = null;

    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    ClassStats@ GetStats() { return m_pStats; }

    int GetMinionCount() { return m_hMinions.length(); }
    float GetReservePool() { return m_flReservePool; }
    void SetReservePoolZero() { m_flReservePool = 0.0f; }
    bool HasStats() { return m_pStats !is null; }

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

    float GetScaledHealth()
    {
        if(m_pStats is null)
            return m_flBaseHealth; // Return base health without scaling if no stats.

        float minionScaledHealth = m_flBaseHealth; // Start with base health.

        float level = m_pStats.GetLevel();
        float healthMultiplier = 1.0f + ((m_flHealthScaleAtMaxLevel / g_iMaxLevel) * level);
        minionScaledHealth *= healthMultiplier;

        return minionScaledHealth;
    }

    float GetScaledDamage() // Damage scaling is applied through MonsterTakeDamage.
    {
        if(m_pStats is null)
            return 1.0f; // Restore to default, but is always null when we have no minions.

        float minionScaledDamage = 1.0f; // Default multiplier.

        float level = m_pStats.GetLevel();
        float damagePerLevel = m_flDamageScaleAtMaxLevel / g_iMaxLevel;
        minionScaledDamage += damagePerLevel * level;

        return minionScaledDamage;
    }
    
    float GetMinionRegen() // Get minion regen based on level.
    { 
        if(m_pStats is null)
            return 0.0f; // Default if no stats.

        float minionRegen = 0.0f; // Default to zero.

        float level = m_pStats.GetLevel();
        minionRegen = m_flHealthRegenAtMaxLevel * (float(level) / g_iMaxLevel);

        return minionRegen; 
    }

    float GetLifestealPercent() // Get minion lifesteal based on level.
    { 
        if(m_pStats is null)
            return 0.0f; // Default if no stats.

        float lifeSteal = 0.0f; // Default to zero.

        float level = m_pStats.GetLevel();
        lifeSteal = m_flLifestealPercentAtMaxLevel * (float(level) / g_iMaxLevel);

        return lifeSteal;
    }
    
    bool IsMinionTypeUnlocked(int minionType)
    {
        if(m_pStats is null)
            return minionType == NECRO_ZOMBIE; // Only allow normal Zombies if no stats.

        int playerLevel = m_pStats.GetLevel();
    
        // Check level requirement for each minion type.
        if(minionType >= 0 && uint(minionType) < NECRO_LEVEL_REQUIREMENTS.length())
            return playerLevel >= NECRO_LEVEL_REQUIREMENTS[minionType];
        
        return false;
    }
    
    array<NecroMinionInfo>@ GetMinions() { return m_hMinions; }
    
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

    NecroMinionData() 
    {
        @m_pMenu = NecroMinionMenu(this);
    }

    void SpawnNecroMinion(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
            return;

        m_flLastToggleTime = 0.0f;

        m_pMenu.ShowNecroMinionMenu(pPlayer); // Show menu.
    }

    void SpawnSpecificMinion(CBasePlayer@ pPlayer, int minionType)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;

        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        int current = int(resources['current']);
        
        // First clean up invalid minions to make sure we have an accurate count.
        for(int i = m_hMinions.length() - 1; i >= 0; i--)
        {
            if(!m_hMinions[i].hMinion.IsValid())
            {
                m_hMinions.removeAt(i);
            }
        }

        // Check resources for spawning new minion.
        if(current < NECRO_COSTS[minionType])
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Not enough points for " + NECRO_NAMES[minionType] + "!\n");
            return;
        }
        
        // Calculate max resources and ensure we're within limits.
        float maxEnergy = float(resources['max']);
        if(m_flReservePool + NECRO_COSTS[minionType] > maxEnergy)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Maximum Undead Capacity reached!\n");
            return;
        }

        // Initialize stats if needed.
        if(m_pStats is null)
        {
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_NECROMANCER)
                {
                    @m_pStats = data.GetCurrentClassStats();
                }
            }
        }
        
        // Check if the minion type is unlocked based on player level.
        if(!IsMinionTypeUnlocked(minionType))
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "" + NECRO_NAMES[minionType] + " requires Lv. " + NECRO_LEVEL_REQUIREMENTS[minionType] + "!\n");
            return;
        }

        Vector vecSrc = pPlayer.GetGunPosition();
        Vector spawnForward, spawnRight, spawnUp;
        g_EngineFuncs.AngleVectors(pPlayer.pev.v_angle, spawnForward, spawnRight, spawnUp);
        
        vecSrc = vecSrc + (spawnForward * 64);
        vecSrc.z -= 32;

        float scaledHealth = GetScaledHealth();
        float scaledDamage = GetScaledDamage();

        dictionary keys;
        keys["model"] = NECRO_MODELS[minionType];
        keys["origin"] = vecSrc.ToString();
        keys["angles"] = Vector(0, pPlayer.pev.v_angle.y, 0).ToString();
        keys["targetname"] = "_NecroMinion_" + pPlayer.entindex();
        keys["displayname"] = string(pPlayer.pev.netname) + "'s " + NECRO_NAMES[minionType];
        keys["health"] = string(scaledHealth);
        keys["scale"] = "1";
        keys["friendly"] = "1";
        keys["spawnflag"] = "32";
        keys["is_player_ally"] = "1";
        keys["body"] = string(Math.RandomLong(1, 11)); // Random bodygroup for zombies.
        //keys["skin"] = string(randomBody); // Random skin for zombies.

        CBaseEntity@ pNecroMinion = g_EntityFuncs.CreateEntity(NECRO_ENTITIES[minionType], keys, true);
        if(pNecroMinion !is null)
        {
            // Apply glow effect before dispatch.
            ApplyMinionGlow(pNecroMinion);

            g_EntityFuncs.DispatchSpawn(pNecroMinion.edict()); // Dispatch the entity.

            // Stuff to set after dispatch.
            @pNecroMinion.pev.owner = @pPlayer.edict(); // Set the owner to the spawning player.

            // Store both the minion handle and its type.
            NecroMinionInfo info;
            info.hMinion = EHandle(pNecroMinion);
            info.type = minionType;
            m_hMinions.insertLast(info);
            
            m_flReservePool += NECRO_COSTS[minionType]; // Add to reserve pool when minion is created.
            current -= NECRO_COSTS[minionType]; // Subtract from current resources.
            resources['current'] = current;

            g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_STATIC, strNecroMinionSoundCreate, 1.0f, ATTN_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, NECRO_NAMES[minionType] + " summoned!\n");
        }
    }

    void NecroUpdate(CBasePlayer@ pPlayer)
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
            
            // Cast to CBaseMonster to check monster-specific properties.
            CBaseMonster@ pMonster = cast<CBaseMonster@>(pExistingMinion);

            // Set some values after casting incase they override.
            int minionType = m_hMinions[i].type;
            if(minionType >= 0 && uint(minionType) < NECRO_ANIMATION_SPEEDS.length())
            {
                pMonster.pev.framerate = NECRO_ANIMATION_SPEEDS[minionType]; // Different speeds per minion type.
            }

            pMonster.m_flFieldOfView = -1.0; // Max their field of view so they become more effective.
            
            // Enhanced death check - check multiple conditions.
            bool isDead = false;
            
            if(pMonster !is null)
            {
                isDead = (pMonster.pev.deadflag != DEAD_NO);
            }
            
            // Also check standard health and IsAlive.
            if(isDead || pExistingMinion.pev.health <= 0 || !pExistingMinion.IsAlive())
            {
                // Use Killed to properly destroy the minion.
                pExistingMinion.Killed(pPlayer.pev, GIB_ALWAYS); // Ensure gibbing to remove possibility of revival.
                
                // Also immediately remove from our list to prevent multiple Killed calls.
                m_hMinions.removeAt(i);
                continue;
            }

            // Check if minion has gained a frag.
            if(pExistingMinion.pev.frags > 0)
            {
                pPlayer.pev.frags += 1;
                pExistingMinion.pev.frags = 0;
            }
            
            // Ensure max_health is refreshed when leveling up.  
            pExistingMinion.pev.max_health = GetScaledHealth(); // Use our scaled health formula that accounts for player level.

            // Ensure glow effect is not overridden.
            ApplyMinionGlow(pExistingMinion);
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
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_NECROMANCER)
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
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No Undead to destroy!\n");
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

        // Reset individual reserve pool.
        m_flReservePool = 0.0f;
        
        if(anyDestroyed)
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "All Undead killed!\n");
        else
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Undead cleared!\n");
    }
    
    // Reset function to clean up all active minions.
    void Reset()
    {
        // Find the player if possible by iterating through all players
        CBasePlayer@ pPlayer = null;
        string playerSteamID = "";
        
        // Use direct player iteration instead of g_PlayerRPGData.getKeys()
        if(m_pStats !is null)
        {
            // Loop through all possible player slots
            for (int i = 1; i <= g_Engine.maxClients; i++)
            {
                CBasePlayer@ tempPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if (tempPlayer !is null && tempPlayer.IsConnected())
                {
                    // Get the player's SteamID
                    string steamID = g_EngineFuncs.GetPlayerAuthId(tempPlayer.edict());
                    
                    // Check if this player has RPG data
                    if(g_PlayerRPGData.exists(steamID))
                    {
                        PlayerData@ playerData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                        
                        // Check if this player owns these stats
                        if(playerData !is null && playerData.GetCurrentClassStats() is m_pStats)
                        {
                            playerSteamID = steamID;
                            @pPlayer = tempPlayer;
                            break;
                        }
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
            m_flReservePool = 0.0f;
        }
    }

    void MinionRegen()
    {
        // Only process regen if enough time has passed.
        float currentTime = g_Engine.time;
        if(currentTime - m_flLastRegenTime < m_flRegenInterval)
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
                    if(pMinion.pev.max_health <= 0) 
                    {
                        // Get the creature type from our stored information.
                        int creatureType = m_hMinions[i].type;
                        
                        // Use our scaled health formula that accounts for player level.
                        pMinion.pev.max_health = GetScaledHealth();
                    }

                    // Get scaled regen based on player level.
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
    
    void ApplyMinionGlow(CBaseEntity@ pMinion)
    {
        if(pMinion is null)
            return;
            
        // Apply the glowing effect.
        pMinion.pev.renderfx = kRenderFxGlowShell; // Glow shell.
        pMinion.pev.rendermode = kRenderNormal; // Render mode.
        pMinion.pev.renderamt = 1; // Shell thickness.
        pMinion.pev.rendercolor = Vector(255, 195, 205); // Peach.
    }
    
    void RecalculateReservePool()
    {
        // Recalculate the reserve pool based on current minions.
        float newReservePool = 0.0f;
        
        // Process from last to first to allow safe removal during iteration.
        for(int i = int(m_hMinions.length()) - 1; i >= 0; i--)
        {
            // First verify the minion actually exists and is alive.
            CBaseEntity@ pMinion = m_hMinions[i].hMinion.GetEntity();
            if(pMinion is null || !pMinion.IsAlive() || pMinion.pev.health <= 0)
            {
                // Invalid or dead minion, remove it from our tracking.
                m_hMinions.removeAt(i);
                continue;
            }
            
            // Only count valid, alive minions toward the reserve pool.
            int minionType = m_hMinions[i].type;
            if(minionType >= 0 && uint(minionType) < NECRO_COSTS.length())
            {
                newReservePool += NECRO_COSTS[minionType];
            }
        }
        
        // Update the reserve pool.
        m_flReservePool = newReservePool;
    }

    // Called when a minion deals damage to an enemy.
    void ProcessMinionDamage(CBasePlayer@ pPlayer, float flDamageDealt)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        // Calculate health to return to player and minion.
        float healthToGive = flDamageDealt * m_flLifestealPercentAtMaxLevel;
        
        // Apply the healing if the player isn't already at max health.
        if(pPlayer.pev.health < pPlayer.pev.max_health)
        {
            pPlayer.pev.health = Math.min(pPlayer.pev.health + healthToGive, pPlayer.pev.max_health);
            
            // Visual feedback for the lifesteal effect - Heal sprites - Player.
            Vector pos = pPlayer.pev.origin;
            Vector mins = pos - Vector(16, 16, 0);
            Vector maxs = pos + Vector(16, 16, 64);

            NetworkMessage healeffect(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            healeffect.WriteByte(TE_BUBBLES);
            healeffect.WriteCoord(mins.x);
            healeffect.WriteCoord(mins.y);
            healeffect.WriteCoord(mins.z);
            healeffect.WriteCoord(maxs.x);
            healeffect.WriteCoord(maxs.y);
            healeffect.WriteCoord(maxs.z);
            healeffect.WriteCoord(80.0f); // Height of the bubble effect
            healeffect.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraEffectSprite));
            healeffect.WriteByte(18); // Count
            healeffect.WriteCoord(6.0f); // Speed
            healeffect.End();
        }
        
        // Find the active minion that dealt the damage (most likely the last one that dealt damage).
        // Needs better tracking, currently heals all minions.
        for(uint i = 0; i < m_hMinions.length(); i++)
        {
            CBaseEntity@ pMinion = m_hMinions[i].hMinion.GetEntity();
            if(pMinion !is null)
            {
                // Cast to CBaseMonster to check monster-specific properties.
                CBaseMonster@ pMonster = cast<CBaseMonster@>(pMinion);
                
                // Only heal if the monster is alive.
                if(pMonster !is null && pMonster.pev.deadflag == DEAD_NO && pMinion.pev.health > 0)
                {
                    // Apply healing to the minion if it's not at max health.
                    if(pMinion.pev.health < pMinion.pev.max_health)
                    {
                        pMinion.pev.health = Math.min(pMinion.pev.health + healthToGive, pMinion.pev.max_health);

                        // Visual feedback for the lifesteal effect - Heal sprites - Minion.
                        Vector pos = pMinion.pev.origin;
                        Vector mins = pos - Vector(16, 16, 0);
                        Vector maxs = pos + Vector(16, 16, 64);

                        NetworkMessage healeffect(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                        healeffect.WriteByte(TE_BUBBLES);
                        healeffect.WriteCoord(mins.x);
                        healeffect.WriteCoord(mins.y);
                        healeffect.WriteCoord(mins.z);
                        healeffect.WriteCoord(maxs.x);
                        healeffect.WriteCoord(maxs.y);
                        healeffect.WriteCoord(maxs.z);
                        healeffect.WriteCoord(80.0f); // Height of the bubble effect.
                        healeffect.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraEffectSprite));
                        healeffect.WriteByte(18); // Count.
                        healeffect.WriteCoord(6.0f); // Speed.
                        healeffect.End();
                    }
                }
            }
        }
    }

    void TeleportMinions(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        if(m_hMinions.length() == 0)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No Zombies to teleport!\n");
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

        g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_STATIC, strNecroMinionSoundCreate, 1.0f, ATTN_NORM);
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Zombies teleported!\n");
    }
}

class NecroMinionMenu 
{
    private CTextMenu@ m_pMenu;
    private NecroMinionData@ m_pOwner;
    
    NecroMinionMenu(NecroMinionData@ owner) 
    {
        @m_pOwner = owner;
    }
    
    void ShowNecroMinionMenu(CBasePlayer@ pPlayer) 
    {
        if(pPlayer is null) return;
        
        @m_pMenu = CTextMenu(TextMenuPlayerSlotCallback(this.MenuCallback));
        m_pMenu.SetTitle("[Zombies Control Menu]\n");
        
        for(uint i = 0; i < NECRO_NAMES.length(); i++) 
        {
            string menuText = "";

            // Check if this minion type is unlocked.
            if(!m_pOwner.IsMinionTypeUnlocked(i))
            {
                menuText += "Summon " + NECRO_NAMES[i] + " (Lv. " + NECRO_LEVEL_REQUIREMENTS[i] + ")";
            }
            else
            {
                menuText += "Summon " + NECRO_NAMES[i] + " (Cost: " + NECRO_COSTS[i] + ")";
            }
            
            m_pMenu.AddItem(menuText + "\n", any(i));
        }
        
        if(m_pOwner.GetMinionCount() > 0) 
        {
            m_pMenu.AddItem("Teleport All\n", any(98));
            m_pMenu.AddItem("Kill All\n", any(99));
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
            
            if(choice == 99) 
            {
                // Destroy all minions.
                m_pOwner.DestroyAllMinions(pPlayer);
            }
            else if(choice == 98)
            {
                // Teleport existing minions.
                m_pOwner.TeleportMinions(pPlayer);
            }
            else if(choice >= 0 && uint(choice) < NECRO_NAMES.length())
            {
                // Check if this minion type is unlocked.
                if(!m_pOwner.IsMinionTypeUnlocked(choice))
                {
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "" + NECRO_NAMES[choice] + " requires Lv. " + NECRO_LEVEL_REQUIREMENTS[choice] + "!\n");
                    return;
                }
                
                // Spawn new minion.
                m_pOwner.SpawnSpecificMinion(pPlayer, choice);
            }
        }
    }
}

void CheckNecromancerMinions()
{   
    // Iterate directly through all player slots instead of using g_PlayerRPGData.getKeys()
    for (int i = 1; i <= g_Engine.maxClients; i++)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if (pPlayer is null || !pPlayer.IsConnected())
            continue;
            
        // Get the player's SteamID
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        
        // Skip if player doesn't have RPG data
        if (!g_PlayerRPGData.exists(steamID))
            continue;
            
        // Initialize MinionData if it doesn't exist.
        if(!g_NecromancerMinions.exists(steamID))
        {
            NecroMinionData data;
            @g_NecromancerMinions[steamID] = data;
        }

        NecroMinionData@ NecroMinion = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
        if(NecroMinion !is null)
        {
            // Reset all minions on first check after map load or plugin reload.
            if(!NecroMinion.IsActive())
            {
                //g_Game.AlertMessage(at_console, "CARPG: Resetting Necromancer minions for player " + steamID + " on map load\n");
                NecroMinion.Reset();
            }
            
            // Check if player switched class.
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null)
                {
                    if(data.GetCurrentClass() != PlayerClass::CLASS_NECROMANCER)
                    {
                        // Player is no longer this class, destroy active minions.
                        if(NecroMinion.GetMinionCount() > 0)
                        {
                            NecroMinion.DestroyAllMinions(pPlayer);
                            continue;  // Skip rest of updates.
                        }
                    }
                    else if(!NecroMinion.HasStats())
                    {
                        // Update stats.
                        NecroMinion.Initialize(data.GetCurrentClassStats());
                    }
                }
            }
            
                // Make sure resource limits are enforced
                if(g_PlayerClassResources.exists(steamID))
                {
                    dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                    if(resources !is null)
                    {
                        // First recalculate the reserve pool to ensure it's accurate
                        NecroMinion.RecalculateReservePool();
                        
                        float maxEnergy = float(resources['max']);
                        if(NecroMinion.GetReservePool() > maxEnergy)
                        {
                            // Over the limit, destroy minions until we're within limits.
                            NecroMinion.DestroyAllMinions(pPlayer);
                        }
                    }
                }            NecroMinion.MinionRegen(); // Minion Regeneration.

            // Always update scaling values for stats menu.
            NecroMinion.GetScaledHealth();
            NecroMinion.GetScaledDamage();

            // Always run Update for proper minion tracking
            NecroMinion.NecroUpdate(pPlayer);
        }
    }
}