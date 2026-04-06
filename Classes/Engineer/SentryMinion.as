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
    // Sentry.
    private EHandle m_hSentry;
    private bool m_bActive = false;
    private float m_flAbilityMax = 60.0f; // Max duration.
    private float m_flAbilityRechargeTime = 30.0f; // Seconds to fully recharge from empty.
    private float m_flBaseHealth = 2000.0; // Base health of the sentry. Sentry seems to take considerably more damage, so health must scale very high!
    private float m_flDamageScaleAtMaxLevel = 3.0; // Damage multiplier at max level.
    private float m_flSelfHealModifier = 2.0f; // Sentry self-healing multiplier.
    private float m_flHealRadius = 50.0f * 16.0f; // Radius in which the sentry can heal players (ft converted to units).

    private float m_flEnergyDrain = 1.0; // Energy drain per interval.
    private float m_flDrainInterval = 1.0f; // Energy drain interval in seconds.
    private float m_flRecallEnergyCost = 0.15f; // Energy percentage cost to recall.

    // Timers.
    private float m_flAbilityCharge = 0.0f;
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
    float GetAbilityCharge() { return m_flAbilityCharge; }
    float GetAbilityMax() { return m_flAbilityMax; }

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

    float GetScaledAbilityRecharge()
    {
        if (m_pStats is null)
            return SKILL_ABILITYRECHARGE; // Return base if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_ABILITYRECHARGE);
        float rechargeBonus = SKILL_ABILITYRECHARGE * skillLevel; // Bonus ability recharge speed based on skill level.

        return rechargeBonus + 1.0f;
    }

    float GetScaledDamage() // Damage scaling is applied through MonsterTakeDamage.
    {
        if(m_pStats is null)
            return 1.0f; // Restore to default, but is always null when we have no minions.

        float sentryScaledDamage = 1.0f; // Default multiplier, must be 1.0f to not alter base damage.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_ENGINEER_SENTRYDAMAGE);
        float skillPower = SKILL_ENGINEER_SENTRYDAMAGE;
        sentryScaledDamage += skillPower * skillLevel; // This is just adding to the default modifier of 1.0.

        return sentryScaledDamage;
    }

    float GetScaledHealAmount()
    {
        if(!HasStats() || m_pStats is null)
            return 0.0f; // Return default if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_ENGINEER_MINIHEALAURA);
        float skillPower = SKILL_ENGINEER_MINIHEALAURA;
        float modifier = skillPower * skillLevel;

        return modifier;
    }

    CBaseEntity@ GetSentryEntity()
    {
        return m_hSentry.GetEntity();
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

        // Check ability charge requirements for deployment.
        if(m_flAbilityCharge <= 0.0f)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry out of battery!\n");
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
        
        dictionary keys;
        keys["origin"] = vecSrc.ToString();
        keys["angles"] = Vector(0, pPlayer.pev.angles.y, 0).ToString();
        keys["targetname"] = "_sentry_" + pPlayer.entindex();
        keys["displayname"] = string(pPlayer.pev.netname) + "'s Sentry";
        keys["health"] = string(m_flBaseHealth); // Base health.
        keys["scale"] = "1"; // Size of the sentry.
        keys["friendly"] = "1"; // Force friendly.
        keys["spawnflags"] = "16384"; // 16384 No Dyn Collision, 32 (ACTIVE).
        keys["is_player_ally"] = "1"; // Force ally with player.

        CBaseEntity@ pSentry = g_EntityFuncs.CreateEntity("monster_sentry", keys, true);
        if(pSentry !is null)
        {
            ApplyMinionGlow(pSentry); // Apply glow effect before dispatch.

            g_EntityFuncs.DispatchSpawn(pSentry.edict()); // Dispatch the spawn.

            @pSentry.pev.owner = @pPlayer.edict(); // Set player as owner.

            // Sentry won't wake unless touched or damaged, regardless of spawnflags. Gently encourage it :P.
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
                m_flAbilityCharge = 0.0f;
                g_EntityFuncs.Remove(pSentry);
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry Destroyed!\n");
            }
            else
            {
                // Manual destruction - apply recall cost.
                m_flAbilityCharge *= (1.0f - m_flRecallEnergyCost);

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
        if(pPlayer is null)
            return;

        if(!m_bActive)
        {
            // Recharge whilst sentry is not deployed.
            RechargeAbility();
            return;
        }

        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry is null || !pSentry.IsAlive())
        {
            // Ensure we properly reset state if sentry is invalid.
            DestroySentry(pPlayer);
            return;
        }

        float currentTime = g_Engine.time;

        SentryHeal(pSentry);
        UpdateVisualEffect(pPlayer);

        // Handle energy drain.
        if(currentTime >= m_flNextDrain)
        {
            m_flNextDrain = currentTime + m_flDrainInterval;

            float drainAmount = GetEnergyDrain();
            if(m_flAbilityCharge > 0.0f)
            {
                m_flAbilityCharge -= Math.min(drainAmount, m_flAbilityCharge);

                if(m_flAbilityCharge <= 0.0f)
                {
                    DestroySentry(pPlayer);
                    return;
                }
            }

            // Handle frag transfer.
            if(pSentry.pev.frags > 0)
            {
                // Transfer frags to player.
                pPlayer.pev.frags += pSentry.pev.frags;
                pSentry.pev.frags = 0;
            }
        }
    }

    private void SentryHeal(CBaseEntity@ pSentry)
    {
        if(m_pStats.GetSkillLevel(SkillID::SKILL_ENGINEER_MINIHEALAURA) <= 0)
            return;

        float currentTime = g_Engine.time;
        if(currentTime < m_flNextHeal)
            return;
            
        m_flNextHeal = currentTime + m_flHealInterval;
        float healAmount = 0.0f;

        // The sentry should include itself when healing.
        if(pSentry.pev.health < pSentry.pev.max_health)
        {
            // Sentry self-healing is modified.
            healAmount = GetScaledHealAmount() * pSentry.pev.max_health / 100; // Calculate heal amount based on sentry's max health and scaling.
            pSentry.pev.health = Math.min(pSentry.pev.health + (healAmount * m_flSelfHealModifier), pSentry.pev.max_health);
        }

        ApplyHealEffect(pSentry); // Do regen effect on sentry.

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
                        healAmount = GetScaledHealAmount() * pTarget.pev.max_health / 100; // Calculate heal amount based on target's max health.
                        pTarget.pev.health = Math.min(pTarget.pev.health + healAmount, pTarget.pev.max_health);
                    }

                    ApplyHealEffect(pTarget); // Do regen effect on players.
                }
            }
        }
    }

    private void ApplyHealEffect(CBaseEntity@ target)
    {
        if(target is null)
            return;

        Vector pos = target.pev.origin;
        Vector mins = pos - Vector(16, 16, 0);
        Vector maxs = pos + Vector(16, 16, 64);

        // Bubbles Effect.
        NetworkMessage aura2msg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
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

        // Aura Beam Cylinder Effect.
        NetworkMessage auramsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
            auramsg.WriteByte(TE_BEAMCYLINDER);
            auramsg.WriteCoord(pos.x);
            auramsg.WriteCoord(pos.y);
            auramsg.WriteCoord(pos.z);
            auramsg.WriteCoord(pos.x);
            auramsg.WriteCoord(pos.y);
            auramsg.WriteCoord(pos.z + m_flHealRadius); // Height.
            auramsg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraSprite));
            auramsg.WriteByte(0); // Starting frame.
            auramsg.WriteByte(0); // Frame rate (no effect).
            auramsg.WriteByte(uint8(m_flHealInterval * 10)); // Life * 0.1s (make life match duration).
            auramsg.WriteByte(32); // Width.
            auramsg.WriteByte(0); // Noise.
            auramsg.WriteByte(int(m_vAuraColor.x));
            auramsg.WriteByte(int(m_vAuraColor.y));
            auramsg.WriteByte(int(m_vAuraColor.z));
            auramsg.WriteByte(128); // Brightness.
            auramsg.WriteByte(0); // Scroll speed (no effect).
            auramsg.End();

        // Health Bubbles Effect.
        NetworkMessage aura2msg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
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