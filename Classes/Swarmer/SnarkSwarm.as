dictionary g_PlayerSnarkNests;

class SnarkNestData
{
    private float m_flEnergyCost = 1.0f; // Base cost per use (charges).
    private int m_iBaseSnarkCount = 30; // Base number of snarks to spawn.
    private float m_flSnarkHealth = 50.0f; // Health of each snark.
    private float m_flSnarkHealthScale = 0.02f; // Health % increase per level.
    private float m_flSnarkDamageScale = 0.08f; // Damage % increase per level.
    private float m_flSnarkCountScale = 0.02f; // Count % increase in snarks in swarm per level.
    private float m_flLastToggleTime = 0.0f;
    private float m_flToggleCooldown = 4.0f; // Cooldown between spawns.
    private float m_flLaunchForce = 1000.0f; // Velocity that snarks are thrown outward.

    private ClassStats@ m_pStats = null;
    bool HasStats() { return m_pStats !is null; }
    ClassStats@ GetStats() { return m_pStats; }
    
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
            while((@snarkEntity = g_EntityFuncs.FindEntityByTargetname(snarkEntity, "_snark_" + playerIndex + "_*")) !is null)
            {
                g_EntityFuncs.Remove(snarkEntity);
            }
        }
    }

    int GetSnarkCount()
    {
        if(m_pStats is null)
            return m_iBaseSnarkCount;

        float level = float(m_pStats.GetLevel());
        float scaledCount = m_iBaseSnarkCount * (1.0f + (level * m_flSnarkCountScale));
        return int(scaledCount);
    }
    
    float GetScaledDamage() // Damage scaling works similarly to XenMinion, through MonsterTakeDamage hook
    {
        if(m_pStats is null)
            return 0.0f;

        float level = m_pStats.GetLevel();
        float flScaledDamage = (float(level) * m_flSnarkDamageScale);
        return flScaledDamage;
    }
    
    float GetScaledHealth()
    {
        if(m_pStats is null)
            return m_flSnarkHealth; // Base health without scaling if no stats.
            
        float level = m_pStats.GetLevel();
        float flScaledHealth = m_flSnarkHealth * (1.0f + (float(level) * m_flSnarkHealthScale));
        return flScaledHealth;
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

        m_flLastToggleTime = currentTime;

        // Check energy requirements for deployment.
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;

        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        float current = float(resources['current']);
        float energyCost = m_flEnergyCost;

        // Check if we have enough energy.
        if(current < energyCost)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No Snark Swarms!\n");
            return;
        }

        // Deduct energy cost.
        current -= energyCost;
        resources['current'] = current;

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
        keys["targetname"] = "_snark_" + playerIndex + "_" + Math.RandomLong(1000, 9999);
        keys["displayname"] = string(pPlayer.pev.netname) + "'s Snark";
        keys["health"] = string(GetScaledHealth());
        keys["spawnflags"] = "32";
        keys["is_player_ally"] = "1";
        
        CBaseEntity@ pSnark = g_EntityFuncs.CreateEntity("monster_snark", keys, true);
        if(pSnark !is null)
        {
            g_EntityFuncs.DispatchSpawn(pSnark.edict());

            @pSnark.pev.owner = @pPlayer.edict(); // Set the owner to the spawning player.

            float scaledHealth = GetScaledHealth();
            pSnark.pev.max_health = scaledHealth; // Set max health based on player level
            pSnark.pev.health = scaledHealth;

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

void CheckSnarkNests()
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
                
                /*
                // Check for any snarks belonging to this player and check their frags.
                CBaseEntity@ snarkEntity = null;
                string searchPattern = "_snark_" + i + "_*";
                while((@snarkEntity = g_EntityFuncs.FindEntityByTargetname(snarkEntity, searchPattern)) !is null)
                {
                    
                    // Check if snark has gained a frag.
                    //if(snarkEntity.pev.frags > 0)
                    {
                        // Transfer frags to player.
                        pPlayer.pev.frags += snarkEntity.pev.frags;
                        snarkEntity.pev.frags = 0;
                    }
                }
                */
            }
        }
    }
}
