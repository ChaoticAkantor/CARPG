string strBloodlustStartSound = "garg/gar_pain1.wav";
string strBloodlustEndSound = "player/breathe2.wav";
string strBloodlustHitSound = "debris/bustflesh1.wav";
string strBloodlustActiveSound = "player/heartbeat1.wav";
string strBloodlustSprite = "sprites/saveme.spr";

const Vector BLOODLUST_COLOR = Vector(255, 0, 0); // Red glow.

dictionary g_PlayerBloodlusts;

class BloodlustData
{
    private bool m_bActive = false;
    private float m_flBloodlustEnergyDrainInterval = 0.5f; // Interval to remove energy.
    private float m_flBloodlustEnergyCost = 1.0f; // Energy drain per interval.
    private float m_flBaseDamageReduction = 0.10f; // Base damage reduction at lowest health.
    private float m_flDamageReductionBonusPerLevel = 0.01f; // Bonus damage reduction scaling per level.
    private float m_flBaseDamageLifesteal = 0.05f; // % Base damage dealt returned as health, reduced when bloodlust is not active.
    private float m_flLifestealPerLevel = 0.02f; // % Increase lifesteal per level.
    private float m_flEnergysteal = 0.04f; // % Energy steal, doubled when bloodlust is not active.
    private float m_flToggleCooldownBloodlust = 0.5f; // Cooldown between toggles.
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    
    // Perk 1 - Bloodlust stacking damage bonus, added per tic, reset on toggle.
    private float m_flBloodlustDamageBonus = 0.02f; // Damage bonus added per tic.

    private ClassStats@ m_pStats = null;

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }
    
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetEnergyCost() { return m_flBloodlustEnergyCost; } // Grab energy cost.
    float GetEnergySteal() { return (m_flEnergysteal * 100); } // Grab Energy steal percentage.

    // Perk 1 damage bonus for each tic bloodlust is active.
    float GetDamageBonus()
    {
        if(m_pStats is null)
            return 1.0f;
            
            return m_flBloodlustDamageBonus;
    }

    // Damage reduction based on current health.
    float GetDamageReduction(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return 0.0f;

        float damageReduction = m_flBaseDamageReduction;

        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();
            damageReduction *= 1.0f + (m_flBaseDamageReduction + level * m_flDamageReductionBonusPerLevel);
        }

        // Calculate missing health percentage
        float maxHealth = pPlayer.pev.max_health;
        float currentHealth = Math.max(1.0f, pPlayer.pev.health); // Ensure at least 1 health.
        float missingHealth = maxHealth - currentHealth;
        float missingHealthPercent = Math.min(99.0f, (missingHealth / maxHealth) * 100.0f); // Cap at 99%, as we will never reach 100%.

        // Apply missing health scaling
        if(!m_bActive)
            damageReduction *= (missingHealthPercent / 100.0f); // 1:1 ratio when not active.
        else
            damageReduction *= (missingHealthPercent / 50.0f);  // 2:1 ratio when active.

        // Convert to percentage for display.
        damageReduction = Math.min(damageReduction * 100.0f, 100.0f);
        return damageReduction;
    }

    // Maximum possible damage reduction for stat menu display (at 1% health).
    float GetDamageReductionMax()
    {
        float maxDamageReduction = m_flBaseDamageReduction;

        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();
            maxDamageReduction *= 1.0f + (m_flBaseDamageReduction + level * m_flDamageReductionBonusPerLevel);
        }

        float maxMissingHealthPercent = 99.0f; // Calculate at maximum missing health, we will never reach 100%.

        maxDamageReduction *= (maxMissingHealthPercent / 100.0f); // Apply maximum missing health scaling.

        // Convert to percentage and cap.
        maxDamageReduction = Math.min(maxDamageReduction * 100.0f, 100.0f);
        return maxDamageReduction;
    }
    
    void ToggleBloodlust(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldownBloodlust)
            return;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerRPGData.exists(steamID))
            return;

        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data is null)
            return;

        if(!m_bActive)
        {
            // Check energy - require FULL energy to activate.
            if(g_PlayerClassResources.exists(steamID))
            {
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                if(resources !is null)
                {
                    float currentEnergy = float(resources['current']);
                    float maxEnergy = float(resources['max']);
                    
                    if(currentEnergy < maxEnergy)
                    {
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Bloodlust Recharging...\n");
                        return;
                    }
                }
            }
            
            m_bActive = true;
            m_flLastDrainTime = currentTime;
            ApplyGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBloodlustStartSound, 1.0f, ATTN_NORM, SND_FORCE_SINGLE, 0, PITCH_NORM);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBloodlustActiveSound, 0.5f, ATTN_NORM, SND_FORCE_LOOP);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Bloodlust Activated!\n");
        }
        else
        {
            DeactivateBloodlust(pPlayer);
        }
        
        m_flLastToggleTime = 0.0f;
    }

    void HandleDamageReduction(CBasePlayer@ pPlayer, float bloodlustDamageTaken, float& out bloodlustReducedDamage)
    {
        if(pPlayer is null || m_pStats is null)
        {
            bloodlustReducedDamage = bloodlustDamageTaken; // No change in damage.
            return;
        }

        float reduction = GetDamageReduction(pPlayer) / 100.0f; // Convert back from percentage.
        float blockedDamage = bloodlustDamageTaken * reduction;
        bloodlustReducedDamage = bloodlustDamageTaken - blockedDamage;

    }

    void Update(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
        {
            DeactivateBloodlust(pPlayer);
            return;
        }

        if(m_pStats is null)
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_BERSERKER)
                {
                    @m_pStats = data.GetCurrentClassStats();
                }
            }
        }

        if(!m_bActive)
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastDrainTime >= m_flBloodlustEnergyDrainInterval) // Interval for energy drain.
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerClassResources.exists(steamID))
            {
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                if(resources !is null)
                {
                    float current = float(resources['current']);
                    current -= m_flBloodlustEnergyCost; // Energy Drain.
                    
                    if(current <= 0)
                    {
                        current = 0;
                        DeactivateBloodlust(pPlayer); // Deactivate if we run out of energy.
                    }
                    
                    resources['current'] = current;
                }
            }

            m_flLastDrainTime = currentTime;
        }
    }

    float GetLifestealAmount()
    {
        float baseAmount = m_flBaseDamageLifesteal;
        
        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();

            // If bloodlust is active, double the lifesteal.
            if(!m_bActive)
                baseAmount *= (1.0f + (level * m_flLifestealPerLevel));
            else
                baseAmount *= (1.0f + (level * m_flLifestealPerLevel)) * 2.0f;
        }
            
        return baseAmount;
    }

    float GetEnergystealAmount()
    {
        float baseAmount = m_flEnergysteal;
        
        // Check if bloodlust is active, double the energy steal.
        if(m_bActive)
            baseAmount *= 2.0f;

        //if(m_pStats !is null)
        //{
        //    int level = m_pStats.GetLevel();
        //    baseAmount *= (1.0f + (level * m_flEnergysteal));
        //}
            
        return baseAmount;
    }

    float ProcessLifesteal(CBasePlayer@ pPlayer, float damageDealt)
    {
        if(pPlayer is null)
            return 0.0f;

        if(m_pStats is null)
            return 0.0f;

        if(!pPlayer.IsAlive())
        {
            DeactivateBloodlust(pPlayer);
            return 0.0f;
        }

        float flLifestealMult = GetLifestealAmount();
        float flHealAmount = damageDealt * flLifestealMult;

        pPlayer.pev.health = Math.min(pPlayer.pev.health + flHealAmount, pPlayer.pev.max_health);
        
        ApplyLifestealEffect(pPlayer); // Visual effect for healing from lifesteal.
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBloodlustHitSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);

        return flHealAmount;
    }

    float ProcessEnergySteal(CBasePlayer@ pPlayer, float damageDealt)
    {
        if(pPlayer is null)
            return 0.0f;

        // Check for valid stats
        if(m_pStats is null)
            return 0.0f;

        // Check if player died
        if(!pPlayer.IsAlive())
        {
            DeactivateBloodlust(pPlayer);
            return 0.0f;
        }

        float flEnergyStealMult = GetEnergystealAmount();
        float flGainAmount = damageDealt * flEnergyStealMult;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerClassResources.exists(steamID))
            {
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                if(resources !is null)
                {
                    float flCurrentEnergy = float(resources['current']);
                    float flMaxEnergy = float(resources['max']);

                    flCurrentEnergy = Math.min(flCurrentEnergy + flGainAmount, flMaxEnergy); // Add energy to variable, but don't exceed max.

                    resources['current'] = flCurrentEnergy; // Add back to energy.
                }
            }

        return flGainAmount;
    }

    void ApplyLifestealEffect(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;

        Vector pos = pPlayer.pev.origin;
        Vector mins = pos - Vector(16, 16, 0);
        Vector maxs = pos + Vector(16, 16, 64);

        NetworkMessage bubbleMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            bubbleMsg.WriteByte(TE_BUBBLES);
            bubbleMsg.WriteCoord(mins.x);
            bubbleMsg.WriteCoord(mins.y);
            bubbleMsg.WriteCoord(mins.z);
            bubbleMsg.WriteCoord(maxs.x);
            bubbleMsg.WriteCoord(maxs.y);
            bubbleMsg.WriteCoord(maxs.z);
            bubbleMsg.WriteCoord(112.0f);
            bubbleMsg.WriteShort(g_EngineFuncs.ModelIndex(strBloodlustSprite));
            bubbleMsg.WriteByte(10);
            bubbleMsg.WriteCoord(2.0f);
        bubbleMsg.End();

        // Add dynamic light
        NetworkMessage msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            msg.WriteByte(TE_DLIGHT);
            msg.WriteCoord(pPlayer.pev.origin.x);
            msg.WriteCoord(pPlayer.pev.origin.y);
            msg.WriteCoord(pPlayer.pev.origin.z);
            msg.WriteByte(5); // Radius
            msg.WriteByte(int(BLOODLUST_COLOR.x));
            msg.WriteByte(int(BLOODLUST_COLOR.y));
            msg.WriteByte(int(BLOODLUST_COLOR.z));
            msg.WriteByte(2); // Life in 0.1s
            msg.WriteByte(1); // Decay rate
        msg.End();
    }

    void DeactivateBloodlust(CBasePlayer@ pPlayer)
    {
        if(!m_bActive)
            return;
            
        if(pPlayer !is null)
        {
            RemoveGlow(pPlayer);
            m_bActive = false;
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBloodlustEndSound, 1.0f, ATTN_NORM, SND_FORCE_SINGLE, PITCH_LOW);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBloodlustActiveSound, 0.0f, ATTN_NORM, SND_STOP);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Bloodlust Ended!\n");
        }
    }

    private void ApplyGlow(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;
            
        // Apply glow shell
        pPlayer.pev.renderfx = kRenderFxGlowShell;
        pPlayer.pev.rendermode = kRenderNormal;
        pPlayer.pev.renderamt = 5; // Shell thickness.
        pPlayer.pev.rendercolor = BLOODLUST_COLOR;
    }

    private void RemoveGlow(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;
        
        pPlayer.pev.renderfx = kRenderFxNone;
        pPlayer.pev.rendermode = kRenderNormal;
        pPlayer.pev.renderamt = 255;
        pPlayer.pev.rendercolor = Vector(255, 255, 255);
    }
}