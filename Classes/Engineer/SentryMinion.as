string strSentryCreate = "weapons/mine_deploy.wav";
string strSentryRecall = "turret/tu_die.wav";

// Sentry Models.
string strSentryModel = "models/sentry.mdl";
string strSentryGibs = "models/computergibs.mdl";

// Sentry Sounds.
string strSentryFire = "weapons/hks_hl3.wav";
string strSentryPing = "turret/tu_ping.wav";
string strSentryActive = "turret/tu_active2.wav";
string strSentryDie = "turret/tu_die3.wav";
string strSentryDeploy = "turret/tu_deploy.wav";
string strSentrySpinUp = "turret/tu_spinup.wav";
string strSentrySpinDown = "turret/tu_spindown.wav";
string strSentrySearch = "turret/tu_search.wav";
string strSentryAlert = "turret/tu_alert.wav";

const Vector ELEMENT_COLOR = Vector(130, 200, 255); // R G B.

dictionary g_PlayerSentries;

class SentryData
{
    private EHandle m_hSentry;
    private bool m_bActive = false;
    private float m_flBaseHealth = 1000.0; // Base health of the sentry. Sentry seems to take considerably more damage, so health must scale very high!
    private float m_flHealthScaleAtMaxLevel = 4.0; // Health modifier at max level.
    private float m_flDamageScaleAtMaxLevel = 3.0; // Damage modifier at max level.
    private float m_flBaseHealAmount = 1.0; // Base healing per second.
    private float m_flHealScaleAtMaxLevel = 5.0f; // Healing modifier at max level.
    private float m_flSelfHealModifier = 5.0f; // Sentry self-healing multiplier.
    private float m_flHealRadius = 8000.0; // Radius in which the sentry can heal players.
    private int m_iCryoShotsRadius = 64; // Radius of bonus damage on shots.
    private float m_flCryoShotsDamageAtMaxLevel = 0.30f; // Damage modifier for cryo shots at max level.
    private float m_flCryoShotsSlowAtMaxLevel = 0.80f; // Slow effect at max level.
    private float m_flCryoShotsSlowDuration = 6.0f; // Duration of slow effect in seconds.
    private float m_flEnergyDrain = 1.0; // Energy drain per interval.
    private float m_flDrainInterval = 1.0f; // Energy drain interval in seconds.
    private float m_flRecallEnergyCost = 0.0f; // Energy % cost to recall.

    private float m_flNextDrain = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flToggleCooldown = 1.0f;
    private float m_flNextHeal = 0.0f;
    private float m_flHealInterval = 1.0f;
    private float m_flNextVisualUpdate = 0.0f;
    private float m_flVisualUpdateInterval = 1.0f; // Time between visual updates. Same as heal rate.
    private Vector m_vAuraColor = Vector(0, 255, 0); // Green color for healing.

    private ClassStats@ m_pStats = null;

    ClassStats@ GetStats() { return m_pStats; }
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    bool HasStats() { return m_pStats !is null; }

    bool IsActive() 
    { 
        // First check if we think we're active.
        if(!m_bActive)
            return false;
        
        // Check if the handle is valid.
        if(!m_hSentry.IsValid())
        {
            // Reset active state if handle is invalid.
            m_bActive = false;
            m_hSentry = null;
            return false;
        }
            
        // Then verify sentry exists and is alive.
        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry is null || !pSentry.IsAlive())
        {
            // Reset active state if sentry doesn't exist or is dead.
            m_bActive = false;
            m_hSentry = null;
            return false;
        }

        return true;
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

    float GetScaledHealAmount()
    {
        if(!HasStats() || m_pStats is null)
            return m_flBaseHealAmount; // Return default if no stats.

        float healAmount = m_flBaseHealAmount; // Default heal amount.

        float level = float(m_pStats.GetLevel());
        float healPerLevel = m_flHealScaleAtMaxLevel / g_iMaxLevel;
        healAmount += healPerLevel * level;

        return healAmount;
    }

    CBaseEntity@ GetSentryEntity()
    {
        return m_hSentry.GetEntity();
    }

    int GetCryoShotsRadius() { return m_iCryoShotsRadius; }

    float GetCryoShotsDamageMult() 
    { 
        if(m_pStats is null)
            return m_flCryoShotsDamageAtMaxLevel; // Default if no stats.

        float damageMult = 1.0f; // Default damage multiplier.

        float level = float(m_pStats.GetLevel());
        float damagePerLevel = m_flCryoShotsDamageAtMaxLevel / g_iMaxLevel;
        damageMult *= damagePerLevel * level;

        return damageMult;
    }

    float GetCryoShotsSlow() // Reduce animation speed for slowing effect.
    { 
        if(m_pStats is null)
            return m_flCryoShotsSlowAtMaxLevel;

        float SlowStrength = 1.0f; // Default modifier.

        float level = float(m_pStats.GetLevel());
        float slowPerLevel = m_flCryoShotsSlowAtMaxLevel / g_iMaxLevel;
        SlowStrength *= slowPerLevel * level;

        return 1.0f - SlowStrength; // Replace framerate with this returned number.
    }

    float GetCryoShotsSlowInverse() // For stat display, to show inverse value.
    { 
        if(m_pStats is null)
            return m_flCryoShotsSlowAtMaxLevel; // Default if no stats.

        float SlowStrength = 1.0f; // Default modifier.

        float level = float(m_pStats.GetLevel());
        SlowStrength *= m_flCryoShotsSlowAtMaxLevel * (float(level) / g_iMaxLevel);

        return SlowStrength * 100.0f; // Return as percentage.
    }

    void ToggleSentry(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
            return;

        if(m_bActive)
        {
            DestroySentry(pPlayer);
            return;
        }

        // Check energy requirements for deployment.
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;

        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        float current = float(resources['current']);
        float maximum = float(resources['max']);

        // Check energy - require FULL energy to activate.
        if(current < maximum)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry Recharging...\n");
            return;
        }

        SpawnSentry(pPlayer);
        m_flLastToggleTime = 0.0f;
    }

    void ApplyMinionGlow(CBaseEntity@ pMinion)
    {
        if(pMinion is null)
            return;

        // Apply the glowing effect.
        pMinion.pev.renderfx = kRenderFxGlowShell;
        pMinion.pev.rendermode = kRenderNormal;
        pMinion.pev.renderamt = 1;
        pMinion.pev.rendercolor = Vector(0, 255, 150); // Light Green.
    }

    private void SpawnSentry(CBasePlayer@ pPlayer)
    {
        Vector vecSrc = pPlayer.GetGunPosition();
        Vector spawnForward, spawnRight, spawnUp;
        g_EngineFuncs.AngleVectors(pPlayer.pev.v_angle, spawnForward, spawnRight, spawnUp);
        
        vecSrc = vecSrc + (spawnForward * 64);
        vecSrc.z -= 32;

        float scaledHealth = GetScaledHealth();
        
        dictionary keys;
        keys["origin"] = vecSrc.ToString();
        keys["angles"] = Vector(0, pPlayer.pev.angles.y, 0).ToString();
        keys["targetname"] = "_sentry_" + pPlayer.entindex();
        keys["displayname"] = string(pPlayer.pev.netname) + "'s Sentry";
        keys["health"] = string(scaledHealth);
        keys["scale"] = "1"; // Size of the sentry.
        keys["friendly"] = "1"; // Force friendly.
        keys["spawnflags"] = "32"; // 32 (ACTIVE).
        keys["is_player_ally"] = "1"; // Force ally with player.

        CBaseEntity@ pSentry = g_EntityFuncs.CreateEntity("monster_sentry", keys, true);
        if(pSentry !is null)
        {
            ApplyMinionGlow(pSentry); // Apply glow effect before dispatch.

            g_EntityFuncs.DispatchSpawn(pSentry.edict()); // Dispatch the spawn.

            @pSentry.pev.owner = @pPlayer.edict(); // Set player as owner to stop collision.

            // Sentry won't wake unless touched or damaged, regardless of spawnflags. Gently encourage it.
            pSentry.TakeDamage(pPlayer.pev, pPlayer.pev, 0.0f, DMG_GENERIC);

            m_hSentry = EHandle(pSentry);

            g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_WEAPON, strSentryCreate, 1.0f, ATTN_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry Deployed!\n");

            m_bActive = true;
        }
    }

    void DestroySentry(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
        {
            // Just handle the cleanup
            if(m_hSentry.IsValid())
            {
                CBaseEntity@ pSentry = m_hSentry.GetEntity();
                if(pSentry !is null)
                {
                    g_EntityFuncs.Remove(pSentry);
                }
            }
            
            // Always ensure we reset the state.
            m_bActive = false;
            m_hSentry = null;
            return;
        }
        
        if(!m_bActive)
        {
            m_bActive = false;
            m_hSentry = null;
            return;
        }

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry !is null)
        {
            // Handle different destroy conditions.
            if(pSentry.pev.health <= 0)
            {
                // Remove all energy if killed by damage.
                if(g_PlayerClassResources.exists(steamID))
                {
                    dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                    resources['current'] = 0.0f;
                }
                g_EntityFuncs.Remove(pSentry);
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry Destroyed!\n");
            }
            else
            {
                // Manual destruction - apply recall cost.
                if(g_PlayerClassResources.exists(steamID))
                {
                    dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                    float current = float(resources['current']);
                    float recallCost = current * m_flRecallEnergyCost; // Get recall cost as percentage of current total.
                    resources['current'] = current - recallCost;
                }
                
                g_EntityFuncs.Remove(pSentry); // Remove the sentry entity.
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry Recalled!\n");
                g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_WEAPON, strSentryRecall, 1.0f, ATTN_NORM);
            }
        }

        // Always ensure we reset the state properly.
        m_bActive = false;
        m_hSentry = null;
    }
    
    // Reset function to clean up any active sentries.
    void Reset()
    {   
        // Find the player using the same method as other abilities.
        CBasePlayer@ pPlayer = null;
        
        if(m_pStats !is null)
        {
            // Find the player via stats.
            for(int i = 1; i <= g_Engine.maxClients; i++)
            {
                CBasePlayer@ tempPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if(tempPlayer !is null && tempPlayer.IsConnected())
                {
                    string steamID = g_EngineFuncs.GetPlayerAuthId(tempPlayer.edict());
                    if(g_PlayerRPGData.exists(steamID))
                    {
                        PlayerData@ playerData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                        if(playerData !is null && playerData.GetCurrentClassStats() is m_pStats)
                        {
                            @pPlayer = tempPlayer;
                            break;
                        }
                    }
                }
            }
        }
        
        // Try to find player from sentry owner if available.
        if(pPlayer is null && m_hSentry.IsValid())
        {
            CBaseEntity@ pSentry = m_hSentry.GetEntity();
            if(pSentry !is null && pSentry.pev.owner !is null)
            {
                @pPlayer = cast<CBasePlayer@>(g_EntityFuncs.Instance(pSentry.pev.owner));
            }
        }
        
        if(pPlayer !is null)
        {
            DestroySentry(pPlayer);
        }
        else
        {
            // If we can't find the player, just remove the sentry directly.
            if(m_hSentry.IsValid())
            {
                CBaseEntity@ pSentry = m_hSentry.GetEntity();
                if(pSentry !is null)
                {
                    g_EntityFuncs.Remove(pSentry);
                }
            }
            
            // Always ensure we reset the active state and clear the handle.
            m_bActive = false;
            m_hSentry = null;
        }
    }

    void Update(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry is null || !pSentry.IsAlive())
        {
            // Ensure we properly reset state if sentry is invalid.
            DestroySentry(pPlayer);
            return;
        }

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(g_PlayerClassResources.exists(steamID))
        {
            float currentTime = g_Engine.time;
            
            SentryHeal(pSentry);
            UpdateVisualEffect(pPlayer);
            
            // Handle energy drain.
            if(currentTime >= m_flNextDrain)
            {
                m_flNextDrain = currentTime + m_flDrainInterval;
                
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                float current = float(resources['current']);
                float drainAmount = GetEnergyDrain();
                
                if(current > 0)
                {
                    if(current - drainAmount < 0)
                        drainAmount = current;
                    
                    current -= drainAmount;
                    resources['current'] = current;

                    if(current <= 0)
                    {
                        DestroySentry(pPlayer);
                        return;
                    }
                }

                // Handle frag transfer.
                if(pSentry.pev.frags > 0)
                {
                    pPlayer.pev.frags += 1;
                    pSentry.pev.frags = 0;
                }
            }
        }
    }

    // Apply Elemental Shots.
    void ApplyElementalShots(Vector targetPos, CBaseEntity@ attacker, CBaseEntity@ victim, float damage)
    {
        if(attacker is null || attacker.pev.owner is null || victim is null)
            return;

        // Get the sentry owner (player).
        CBasePlayer@ pOwner = cast<CBasePlayer@>(g_EntityFuncs.Instance(attacker.pev.owner));
        if(pOwner is null)
            return;

        string steamId = g_EngineFuncs.GetPlayerAuthId(pOwner.edict());
        if(!g_PlayerSentries.exists(steamId))
            return;

        SentryData@ sentryData = cast<SentryData@>(g_PlayerSentries[steamId]);
        if(sentryData is null)
            return;

        // Add glow shell effect to entity taking damage.
        ApplyDamageGlow(victim);

        // Offsets for sprite trail.
        Vector originOffset = targetPos;
        originOffset.z += 32; // Offset to top of entity.

        Vector endPoint = originOffset;
        endPoint.z += 10; // Trail moves upward.

        // Create sprite trail effect for snow/ice particles.
        NetworkMessage radiusSlowmsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, targetPos);
            radiusSlowmsg.WriteByte(TE_SPRITETRAIL);
            radiusSlowmsg.WriteCoord(targetPos.x);
            radiusSlowmsg.WriteCoord(targetPos.y);
            radiusSlowmsg.WriteCoord(targetPos.z);
            radiusSlowmsg.WriteCoord(endPoint.x);
            radiusSlowmsg.WriteCoord(endPoint.y);
            radiusSlowmsg.WriteCoord(endPoint.z);
            radiusSlowmsg.WriteShort(g_EngineFuncs.ModelIndex(strBarrierReflectDamageSprite));
            radiusSlowmsg.WriteByte(2);   // Count.
            radiusSlowmsg.WriteByte(1);   // Life in 0.1's.
            radiusSlowmsg.WriteByte(3);   // Scale in 0.1's.
            radiusSlowmsg.WriteByte(25);  // Velocity along vector in 10's.
            radiusSlowmsg.WriteByte(15);  // Random velocity in 10's.
            radiusSlowmsg.End();

        // Calculate explosive damage based on original damage.
        float explosiveDamage = damage * sentryData.GetCryoShotsDamageMult();

        // Apply radius damage with the sentry as inflictor and owner as attacker.
        g_WeaponFuncs.RadiusDamage(
            targetPos,                // Center on where the target was hit.
            attacker.pev,            // Inflictor (the sentry).
            pOwner.pev,              // Attacker (the player).
            explosiveDamage,         // Scaled explosive damage.
            sentryData.GetCryoShotsRadius(),
            CLASS_PLAYER,              // Ignore players.
            DMG_FREEZE | DMG_ALWAYSGIB
        );

        ApplySlowEffect(victim); // Turret applies slow effect to targets.
    }

    void ApplySlowEffect(CBaseEntity@ victim)
    {
        if(victim is null)
            return;

        CBaseMonster@ slowTargetSentry = cast<CBaseMonster@>(victim);
        if(slowTargetSentry !is null)
        {
            if (slowTargetSentry.pev.framerate >= 1.0f) // Check if framerate is already reduced.
            {
                slowTargetSentry.pev.framerate = GetCryoShotsSlow(); // Reduce the target's animation speed.

                // Schedule a think function to remove the slow effect after the duration.
                g_Scheduler.SetTimeout("RemoveSlowEffect", m_flCryoShotsSlowDuration, victim.entindex());
            }
        }
    }

    void ApplyDamageGlow(CBaseEntity@ victim)
    {
        if(victim is null)
            return;

        // Add glow shell effect to entity taking damage.
        victim.pev.renderfx = kRenderFxGlowShell;
        victim.pev.rendermode = kRenderNormal;
        victim.pev.rendercolor = ELEMENT_COLOR; // Light Blue.
        victim.pev.renderamt = 10; // Thickness.
    }

    private void SentryHeal(CBaseEntity@ pSentry)
    {
        float currentTime = g_Engine.time;
        if(currentTime < m_flNextHeal)
            return;
            
        m_flNextHeal = currentTime + m_flHealInterval;
        float healAmount = GetScaledHealAmount();

        // The sentry should include itself when healing.
        if(pSentry.pev.health < pSentry.pev.max_health)
        {
            // Sentry self-healing is modified.
            pSentry.pev.health = Math.min(pSentry.pev.health + (healAmount * m_flSelfHealModifier), pSentry.pev.max_health);
        }

        ApplyRegenEffect(pSentry); // Do regen effect on sentry.

        for(int i = 1; i <= g_Engine.maxClients; i++)
        {
            CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex(i);
            if(pTarget !is null && pTarget.IsConnected() && pTarget.IsAlive())
            {
                float distance = (pTarget.pev.origin - pSentry.pev.origin).Length();
                if(distance <= m_flHealRadius)
                {
                    if(pTarget.pev.health < pTarget.pev.max_health)
                    {
                        pTarget.pev.health = Math.min(pTarget.pev.health + healAmount, pTarget.pev.max_health);
                    }

                    ApplyRegenEffect(pTarget); // Do regen effect on players.
                }
            }
        }
    }

    private void ApplyRegenEffect(CBaseEntity@ target)
    {
        if(target is null)
            return;

        Vector pos = target.pev.origin;
        Vector mins = pos - Vector(16, 16, 0);
        Vector maxs = pos + Vector(16, 16, 64);

        // Bubbles Effect.
        NetworkMessage aura2msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            aura2msg.WriteByte(TE_BUBBLES);
            aura2msg.WriteCoord(mins.x);
            aura2msg.WriteCoord(mins.y);
            aura2msg.WriteCoord(mins.z);
            aura2msg.WriteCoord(maxs.x);
            aura2msg.WriteCoord(maxs.y);
            aura2msg.WriteCoord(maxs.z);
            aura2msg.WriteCoord(80.0f); // Height of the bubble effect.
            aura2msg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraEffectSprite));
            aura2msg.WriteByte(18); // Count.
            aura2msg.WriteCoord(6.0f); // Speed.
            aura2msg.End();
    }

    private void UpdateVisualEffect(CBasePlayer@ pPlayer)
    {
        if (!m_bActive || pPlayer is null)
            return;
            
        float currentTime = g_Engine.time;
        if(currentTime < m_flNextVisualUpdate)
            return;

        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry is null)
            return;
        
        m_flNextVisualUpdate = currentTime + m_flVisualUpdateInterval;

        // Ensure glow effect is maintained.
        ApplyMinionGlow(pSentry);

        Vector pos = pSentry.pev.origin;
        Vector mins = pos - Vector(16, 16, 0);
        Vector maxs = pos + Vector(16, 16, 64);
        
        // Beam cylinder effect.
        NetworkMessage auramsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, pos);
            auramsg.WriteByte(TE_BEAMCYLINDER);
            auramsg.WriteCoord(pos.x);
            auramsg.WriteCoord(pos.y);
            auramsg.WriteCoord(pos.z);
            auramsg.WriteCoord(pos.x);
            auramsg.WriteCoord(pos.y);
            auramsg.WriteCoord(pos.z + 24); // Height.
            auramsg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraSprite));
            auramsg.WriteByte(0); // Starting frame.
            auramsg.WriteByte(0); // Frame rate (no effect).
            auramsg.WriteByte(5); // Life.
            auramsg.WriteByte(32); // Width.
            auramsg.WriteByte(0); // Noise.
            auramsg.WriteByte(int(m_vAuraColor.x));
            auramsg.WriteByte(int(m_vAuraColor.y));
            auramsg.WriteByte(int(m_vAuraColor.z));
            auramsg.WriteByte(128); // Brightness.
            auramsg.WriteByte(0); // Scroll speed.
            auramsg.End();

        // Health Bubbles Effect.
        NetworkMessage aura2msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            aura2msg.WriteByte(TE_BUBBLES);
            aura2msg.WriteCoord(mins.x);
            aura2msg.WriteCoord(mins.y);
            aura2msg.WriteCoord(mins.z);
            aura2msg.WriteCoord(maxs.x);
            aura2msg.WriteCoord(maxs.y);
            aura2msg.WriteCoord(maxs.z);
            aura2msg.WriteCoord(80.0f); // Height of the bubble effect.
            aura2msg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraEffectSprite));
            aura2msg.WriteByte(18); // Count.
            aura2msg.WriteCoord(6.0f); // Speed.
            aura2msg.End();
    }

    float GetHealRadius()
    {
        if(!HasStats() || m_pStats is null)
            return m_flHealRadius;

        float radius = m_flHealRadius;

        return radius;
    }

    float GetEnergyDrain()
    {
        if(!HasStats() || m_pStats is null)
            return m_flEnergyDrain;

        float drain = m_flEnergyDrain;

        return drain;
    }
}

void CheckSentries()
{   
    for(int i = 1; i <= g_Engine.maxClients; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            
            if(!g_PlayerSentries.exists(steamID))
            {
                SentryData data;
                @g_PlayerSentries[steamID] = data;
            }

            SentryData@ sentry = cast<SentryData@>(g_PlayerSentries[steamID]);
            if(sentry !is null)
            {
                // Check for invalid entity references first.
                if(sentry.IsActive())
                {
                    // The IsActive() call will reset m_bActive if the sentry is invalid.
                    if(!sentry.IsActive())
                    {
                        sentry.Reset();
                    }
                }
                
                // Check if player switched class
                if(g_PlayerRPGData.exists(steamID))
                {
                    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                    if(data !is null)
                    {
                        if(data.GetCurrentClass() != PlayerClass::CLASS_ENGINEER)
                        {
                            // Player is no longer Engineer, destroy any active sentries.
                            if(sentry.IsActive())
                            {
                                sentry.DestroySentry(pPlayer);
                            }
                            continue;
                        }
                        else if(!sentry.HasStats())
                        {
                            // Initialize stats if needed.
                            sentry.Initialize(data.GetCurrentClassStats());
                        }
                    }
                }

                // Update the sentry if we have one.
                sentry.Update(pPlayer);
            }
        }
    }
}

void RemoveSlowEffect(int victimIndex)
{
    CBaseEntity@ victim = g_EntityFuncs.Instance(victimIndex);
    if(victim is null)
        return;

    CBaseMonster@ slowTargetSentry = cast<CBaseMonster@>(victim);
    if(slowTargetSentry !is null)
    {
        slowTargetSentry.pev.framerate = 1.0f; // Reset animation speed to normal.
            
        // Remove the glow shell effect.
        victim.pev.renderfx = kRenderFxNone;
        victim.pev.rendermode = kRenderNormal;
        victim.pev.renderamt = 0;
    }   
}