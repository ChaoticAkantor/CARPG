string strSnarkModel = "models/w_squeak.mdl";
string strSnarkSpriteTinySpit = "sprites/tinyspit.spr"; // Should already be precached by from bullsquid in XenMinion, but still crashes on They Hunger maps!

dictionary g_PlayerSnarkNests;

class SnarkNestData
{   
    // Snark Swarm ability parameters.
    private float m_flAbilityCost = 1.0f; // Base cost per use (charges).
    private float m_flAbilityMax = 1.0f; // Max charges.
    private float m_flAbilityRechargeTime = 15.0f; // Seconds to fully recharge from empty.
    private float m_flBaseHealth = 100.0f; // Base HP of each snark.
    private int m_iBaseSnarkCount = 10; // Base number of snarks to spawn.

    // Timers.
    private float m_flAbilityCharge = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flToggleCooldown = 4.0f; // Cooldown between spawns.
    private float m_flLaunchForce = 1000.0f; // Velocity that snarks are thrown outward.

    // As far as I know, snark lifespan is hardcoded, would be nice to be able to change it.

    private ClassStats@ m_pStats = null;
    bool HasStats() { return m_pStats !is null; }
    ClassStats@ GetStats() { return m_pStats; }
    float GetAbilityCharge() { return m_flAbilityCharge; }
    float GetAbilityMax() { return m_flAbilityMax; }
    void FillAbilityCharge() { m_flAbilityCharge = GetAbilityMax(); }
    
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    
    void Reset()
    {
        // Clean up any active snarks for this player.
        int playerIndex = -1;
        
        // Find the player index from our stats.
        if(m_pStats !is null)
        {
            // Get the playerIndex from the owner of the stats.
            for(int i = 1; i <= g_Engine.maxClients; i++)
            {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if(pPlayer !is null && pPlayer.IsConnected())
                {
                    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
                    PlayerData@ playerData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                    if(playerData !is null && playerData.GetCurrentClassStats() is m_pStats)
                    {
                        playerIndex = i;
                        break;
                    }
                }
            }
        }
        
        if(playerIndex != -1)
        {
            // Clean up any snarks spawned by this player.
            CBaseEntity@ snarkEntity = null;
            while((@snarkEntity = g_EntityFuncs.FindEntityByTargetname(snarkEntity, "_snark_" + playerIndex)) !is null)
            {
                g_EntityFuncs.Remove(snarkEntity);
            }
        }
    }

    int GetSnarkCount()
    {
        if(m_pStats is null)
            return m_iBaseSnarkCount; // Default if no stats.

        float baseCount = m_iBaseSnarkCount; // Default number of snarks.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_SWARMER_SNARKCOUNT);
        float skillPower = SKILL_SWARMER_SNARKCOUNT;
        float modifier = 1.0f + (skillPower * skillLevel); // Scale with skill level.

        return int(baseCount * modifier); // return as int, can't have part of a snark lol.
    }

    float GetScaledDamage() // Damage scaling applied through MonsterTakeDamage hook.
    {
        if(m_pStats is null)
            return 1.0f; // Default if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_SWARMER_SNARKDAMAGE);
        float skillPower = SKILL_SWARMER_SNARKDAMAGE;
        float modifier = 1.0f + (skillPower * skillLevel);

        return modifier;
    }

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
        if (m_flAbilityCharge >= m_flAbilityMax)
            return;

        float rechargeRate = m_flAbilityMax / m_flAbilityRechargeTime * GetScaledAbilityRecharge();
        m_flAbilityCharge += rechargeRate * flSchedulerInterval;
        if (m_flAbilityCharge > m_flAbilityMax)
            m_flAbilityCharge = m_flAbilityMax;
    }

    void Update(CBasePlayer@ pPlayer)
    {
        RechargeAbility();
    }

    void SummonSnarks(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
        {
            // Still on cooldown.
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Snark Swarm on cooldown!\n");
            return;
        }

        m_flLastToggleTime = 0.0f;

        // Check energy requirements for deployment.
        if(m_flAbilityCharge < m_flAbilityCost)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No Snark Swarms!\n");
            return;
        }

        m_flAbilityCharge -= m_flAbilityCost;

        // Get player's gun position for effects.
        Vector gunPos = pPlayer.GetGunPosition();
        
        // Play sound (Use from bloodlust).
        g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_WEAPON, strBloodlustHitSound, 1.0f, ATTN_NORM);
        
        // Spawn snarks from the player's gun.
        int snarkCount = GetSnarkCount();
        SpawnSnarksFromGun(pPlayer, gunPos, snarkCount);
        
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Snark Swarm released!\n");
    }
    
    // Function to spawn snarks from the player's gun position and send them outward.
    void SpawnSnarksFromGun(CBasePlayer@ pPlayer, Vector position, int snarkCount)
    {
        if(pPlayer is null || !pPlayer.IsConnected())
            return;
        
        // Start the simple sequential spawning.
        dictionary spawnParams;
        spawnParams["player_index"] = pPlayer.entindex();
        spawnParams["snarks_remaining"] = snarkCount;
        
        // Spawn the first snark immediately for feedback.
        SpawnSingleSnark(spawnParams);
        
        // Schedule the next spawn
        g_Scheduler.SetTimeout("ContinueSnarkSpawning", 0.05f, spawnParams);
    }
    
    // Spawn a single snark from the player's gun position.
    void SpawnSingleSnark(dictionary@ spawnParams)
    {
        int playerIndex = int(spawnParams["player_index"]);
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(playerIndex);
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;
            
        // Get current player gun position.
        Vector gunPos = pPlayer.GetGunPosition();
            
        // Get player's aim direction using AngleVectors.
        Vector aimDir, right, up;
        g_EngineFuncs.AngleVectors(pPlayer.pev.v_angle, aimDir, right, up);
        
        // Create variation around the player's view direction.
        float horizontalVariation = Math.RandomFloat(-0.3f, 0.3f); // +/- 0.3 radians (~17 degrees).
        float verticalVariation = Math.RandomFloat(-0.3f, 0.3f);   // +/- 0.3 radians (~17 degrees).
        
        // Apply variation to the aim direction
        Vector finalDir = aimDir;
        finalDir = finalDir + (right * horizontalVariation);
        finalDir = finalDir + (up * verticalVariation);
        finalDir = finalDir.Normalize();
        
        // Calculate spawn position with offset to prevent collisions.
        Vector spawnPos = gunPos + (finalDir * 15.0f);
        
        // Calculate velocity in the aim direction with variation.
        Vector velocity = finalDir * m_flLaunchForce;

        // Add a slight upward component to throw them in an arch.
        velocity.z += Math.RandomFloat(20.0f, 50.0f);

        // Create visual effect on player per snark.
        // Use gun position for effect start.
        Vector origin = gunPos;
        
        // Use finalDir (aim direction with variation) to calculate endpoint.
        // This makes the trail shoot out in front of the player along their view direction.
        Vector endPoint = origin + (finalDir * 100.0f); // Trail shoots out X units in front.

        // Create sprite trail effect. (Same as the one from HealAura poison).
        NetworkMessage msg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            msg.WriteByte(TE_SPRITETRAIL);
            msg.WriteCoord(origin.x);
            msg.WriteCoord(origin.y);
            msg.WriteCoord(origin.z);
            msg.WriteCoord(endPoint.x);
            msg.WriteCoord(endPoint.y);
            msg.WriteCoord(endPoint.z);
            msg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraPoisonEffectSprite));
            msg.WriteByte(2);   // Count.
            msg.WriteByte(1);   // Life in 0.1's.
            msg.WriteByte(5);   // Scale in 0.1's.
            msg.WriteByte(25);  // Velocity along vector in 10's.
            msg.WriteByte(10);  // Random velocity in 10's - already adds randomness to particles.
        msg.End();
        
        // Create the snark.
        dictionary keys;
        keys["origin"] = spawnPos.ToString();
        keys["angles"] = pPlayer.pev.v_angle.ToString(); // Use player's view angle
        keys["targetname"] = "_snark_" + playerIndex;
        keys["displayname"] = string(pPlayer.pev.netname) + "'s Snark";
        keys["health"] = string(m_flBaseHealth); // Base health.
        keys["spawnflags"] = "32";
        keys["is_player_ally"] = "1";
        
        CBaseEntity@ pSnark = g_EntityFuncs.CreateEntity("monster_snark", keys, true);
        if(pSnark !is null)
        {
            g_EntityFuncs.DispatchSpawn(pSnark.edict());

            @pSnark.pev.owner = @pPlayer.edict(); // Set the owner to the spawning player.

            float baseHealth = m_flBaseHealth;
            pSnark.pev.max_health = baseHealth; // Set max health based on player level
            pSnark.pev.health = baseHealth;

            // Apply velocity to launch the snark outward.
            pSnark.pev.velocity = velocity;
            
            // Make the snark glow to show it's friendly.
            pSnark.pev.renderfx = kRenderFxGlowShell;
            pSnark.pev.rendermode = kRenderNormal;
            pSnark.pev.renderamt = 1;
            pSnark.pev.rendercolor = Vector(255, 255, 0); // Yellow glow.
        }
    }
    
    // Continue spawning one snark at a time.
    void ContinueSpawning(dictionary@ spawnParams)
    {
        int snarksRemaining = int(spawnParams["snarks_remaining"]) - 1;
        if(snarksRemaining <= 0)
            return; // All done.
            
        spawnParams["snarks_remaining"] = snarksRemaining;
        
        // Spawn one snark.
        SpawnSingleSnark(spawnParams);
        
        // Schedule the next spawn.
        g_Scheduler.SetTimeout("ContinueSnarkSpawning", 0.05f, spawnParams);
    }

    // Called when a minion deals damage to an enemy.
    void ProcessMinionDamage(CBasePlayer@ pPlayer, float flDamageDealt, CBaseEntity@ pSnark)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        if(pSnark is null)
            return;

        Vector snarkOrigin = pSnark.pev.origin;
        float explRadius = 25.0f * 16.0f;

        // Snarks detonate on first instance of damage.
        g_WeaponFuncs.RadiusDamage
        (
            snarkOrigin, // Explosion center.
            pPlayer.pev, // Inflictor.
            pPlayer.pev, // Attacker.
            15.0f, // Scaled Damage.
            explRadius, // Radius.
            CLASS_PLAYER, // Will not damage player or allies.
            DMG_ACID | DMG_ALWAYSGIB // Damage type and always gib.
        );

        NetworkMessage lightMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, snarkOrigin);
            lightMsg.WriteByte(TE_DLIGHT);
            lightMsg.WriteCoord(snarkOrigin.x);
            lightMsg.WriteCoord(snarkOrigin.y);
            lightMsg.WriteCoord(snarkOrigin.z);
            lightMsg.WriteByte(uint8(explRadius)); // Radius.
            lightMsg.WriteByte(0);   // Red.
            lightMsg.WriteByte(255); // Green.
            lightMsg.WriteByte(30);   // Blue.
            lightMsg.WriteByte(10);  // Life in 0.1s (1s).
            lightMsg.WriteByte(10);  // Decay rate (instant).
        lightMsg.End();
    }
}

// Function to continue the staggered snark spawning.
void ContinueSnarkSpawning(dictionary@ spawnParams)
{
    int playerIndex = int(spawnParams["player_index"]);
    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(playerIndex);
    if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
        return;
        
    // Get our snark nest data.
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(!g_PlayerSnarkNests.exists(steamID))
        return;
        
    SnarkNestData@ snarkNest = cast<SnarkNestData@>(g_PlayerSnarkNests[steamID]);
    if(snarkNest is null)
        return;
        
    snarkNest.ContinueSpawning(spawnParams);
}

void CheckSnarks()
{   
    // Process player data.
    for(int i = 1; i <= g_Engine.maxClients; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            
            if(!g_PlayerSnarkNests.exists(steamID))
            {
                SnarkNestData data;
                @g_PlayerSnarkNests[steamID] = data;
            }

            SnarkNestData@ snarkNest = cast<SnarkNestData@>(g_PlayerSnarkNests[steamID]);
            if(snarkNest !is null)
            {
                if(g_PlayerRPGData.exists(steamID))
                {
                    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                    if(data !is null && data.GetCurrentClass() != PlayerClass::CLASS_SWARMER)
                    {
                        continue;
                    }
                    else if(!snarkNest.HasStats())
                    {
                        snarkNest.Initialize(data.GetCurrentClassStats());
                    }
                }

                snarkNest.Update(pPlayer);
                
                // Check for any snarks belonging to this player and check their frags.
                CBaseEntity@ snarkEntity = null;
                string searchPattern = "_snark_" + i;
                while((@snarkEntity = g_EntityFuncs.FindEntityByTargetname(snarkEntity, searchPattern)) !is null)
                {
                    
                    // Check if snark has gained a frag.
                    if(snarkEntity.pev.frags > 0)
                    {
                        // Transfer frags to player.
                        pPlayer.pev.frags += snarkEntity.pev.frags;
                        snarkEntity.pev.frags = 0;
                    }
                }
            }
        }
    }
}
