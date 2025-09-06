string strNecroMinionSoundCreate = "debris/beamstart7.wav";

// Precache strings for monsters. (Yawn)

// Zombie.
    // Models/Sprites.
    string strZombieSoldierModel = "models/zombie_soldier.mdl";
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

// Gonome.
    // Models/Sprites.
    string strGonomeModel = "models/gonome.mdl";
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
    NECRO_GONOME = 2
}

const array<string> NECRO_NAMES = 
{
    "Zombie",
    "Gonome"
};

const array<string> NECRO_ENTITIES = 
{
    "monster_zombie_soldier",
    "monster_gonome"    
};

const array<int> NECRO_COSTS = // Pool cost per summon of each type. All zombies are technically upgrades except for the gonome, they need to cost the same!
{
    1, // Zombie.
    2 // Gonome.
};

// Level requirements for each Zombie type.
const array<int> NECRO_LEVEL_REQUIREMENTS = 
{   
    1,   // Zombie.
    1    // Gonome.
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
    private float m_flBaseHealth = 200.0;
    private float m_flHealthScale = 0.18; // Health % scaling per level.
    private float m_flHealthRegen = 0.002; // // Health recovery % per second of Minions.
    private float m_flDamageScale = 0.12; // Damage % scaling per level.
    private float m_flLifestealPercent = 0.10; // 10% of minion damage is returned as health to the owner (Enhancement).
    private int m_iMinionResourceCost = 1; // Cost to summon specific minion.
    private float m_flReservePool = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flLastMessageTime = 0.0f;
    private float m_flToggleCooldown = 1.0f;
    private ClassStats@ m_pStats = null;

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

    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    int GetMinionCount() { return m_hMinions.length(); }

    float GetReservePool() { return m_flReservePool; }
    
    void SetReservePoolZero() { m_flReservePool = 0.0f; }
    
    float GetMinionRegen() { return m_flHealthRegen; }

    float GetLifestealPercent() 
    { 
        // Only return lifesteal percent if Enhancement 1 is unlocked.
        return (m_pStats !is null && m_pStats.HasUnlockedEnhancement1()) ? m_flLifestealPercent : 0.0f;
    }

    bool HasStats() { return m_pStats !is null; }
    
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
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Maximum Creature Capacity reached!\n");
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
        keys["origin"] = vecSrc.ToString();
        keys["angles"] = Vector(0, pPlayer.pev.v_angle.y, 0).ToString();
        keys["targetname"] = "_NecroMinion_" + pPlayer.entindex();
        keys["displayname"] = string(pPlayer.pev.netname) + "'s " + NECRO_NAMES[minionType];
        keys["health"] = string(scaledHealth);
        keys["scale"] = "1";
        keys["friendly"] = "1";
        keys["spawnflag"] = "32";
        keys["is_player_ally"] = "1";

        CBaseEntity@ pNecroMinion = g_EntityFuncs.CreateEntity(NECRO_ENTITIES[minionType], keys, true);
        if(pNecroMinion !is null)
        {
            // Apply glow effect before dispatch.
            ApplyMinionGlow(pNecroMinion);

            g_EntityFuncs.DispatchSpawn(pNecroMinion.edict()); // Dispatch the entity.

            // Stuff to set after dispatch.
            @pNecroMinion.pev.owner = @pPlayer.edict(); // Set the owner to the spawning player.

            // Cast so we can alter monster float variables.
            CBaseMonster@ pMonster = cast<CBaseMonster@>(pNecroMinion);
            if(pMonster !is null)
            {
                pMonster.m_flFieldOfView = -1.0; // Max their field of view so they become more effective.
                                                //  -1.0 = 360 degrees, 0.0 = 90 degrees, 1.0 = 60 degrees.
            }

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
            
            // Enhanced death check - check multiple conditions
            bool isDead = false;
            
            if(pMonster !is null)
            {
                isDead = (pMonster.pev.deadflag != DEAD_NO);
            }
            
            // Also check standard health and IsAlive
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
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No Zombies to destroy!\n");
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
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "All Zombies killed!\n");
        else
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Zombies cleared!\n");
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

                    float flHealAmount = pMinion.pev.max_health * m_flHealthRegen; // Calculate amount from max health.

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

    float GetScaledHealth()
    {
        if(m_pStats is null)
            return m_flBaseHealth; // Base health without scaling if no stats.

        float level = m_pStats.GetLevel();
        float flScaledHealth = m_flBaseHealth * (1.0f + (float(level) * m_flHealthScale));
        return flScaledHealth;
    }

    float GetScaledDamage() // Damage scaling works a little differently, through MonsterTakeDamage.
    {
        if(m_pStats is null)
            return 0.0f; // Technically should never be zero, but is always null when we have no minions.

        float level = m_pStats.GetLevel();
        float flScaledDamage = (float(level) * m_flDamageScale); // Essentially just increasing the multiplier per level as there is no base damage.
        return flScaledDamage;
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
            
        // Check if the enhancement is unlocked.
        if(m_pStats is null || !m_pStats.HasUnlockedEnhancement1())
            return;

        // Calculate health to return to player and minion.
        float flHealthToGive = flDamageDealt * m_flLifestealPercent;
        
        // Apply the healing if the player isn't already at max health.
        if(pPlayer.pev.health < pPlayer.pev.max_health)
        {
            pPlayer.pev.health = Math.min(pPlayer.pev.health + flHealthToGive, pPlayer.pev.max_health);
            
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
                        pMinion.pev.health = Math.min(pMinion.pev.health + flHealthToGive, pMinion.pev.max_health);

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