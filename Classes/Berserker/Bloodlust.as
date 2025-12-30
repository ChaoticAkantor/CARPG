string strBloodlustStartSound = "garg/gar_pain1.wav";
string strBloodlustEndSound = "player/breathe2.wav";
string strBloodlustHitSound = "debris/bustflesh1.wav";
string strBloodlustActiveSound = "player/heartbeat1.wav";
string strBloodlustSprite = "sprites/saveme.spr";

const Vector BLOODLUST_COLOR = Vector(255, 0, 0); // Red glow.

dictionary g_PlayerBloodlusts;

class BloodlustData
{
    // Remember to account for bloodlust double bonus when balancing!
    private bool m_bActive = false; // Used for active state of ability.

    // Bloodlust Energy cost and drain interval.
    private float m_flBloodlustEnergyDrainInterval = 1.0f; // Interval to remove energy.
    private float m_flBloodlustEnergyCost = 1.0f; // Energy drain per interval.

    // Bloodlust stat scaling values.
    private float m_flDamageBonusAtMaxLevel = 2.5f; // Max Damage bonus multiplier at max level, increases per tic while in bloodlust. NOT IMPLEMENTED.
    private float m_flDamageReductionAtMaxLevel = 0.45f; // Damage reduction multiplier at maximum level. Doubles during bloodlust!
    private float m_flLifestealAtMaxLevel = 0.50f; // Lifesteal %, as a multiplier at max level. Doubles during bloodlust!
    private float m_flEnergystealAtMaxLevel = 0.15f; // Energy steal %, as a multiplier at max level. Doubles during bloodlust!
    private float m_flEnergystealFixedAmount = 0.05f; // Fixed energy steal % if scaling is disabled. Doubles during bloodlust!
    private bool m_bEnergyStealIsFixed = false; // Whether energy steal is a fixed % or scales with level.

    // Cooldown and activation timers.
    private float m_flToggleCooldownBloodlust = 0.5f; // Cooldown between toggles.
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;

    private ClassStats@ m_pStats = null;

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }
    
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetEnergyCost() { return m_flBloodlustEnergyCost; } // Grab energy cost.
    float GetEnergySteal() { return (m_flEnergystealAtMaxLevel * 100); } // Grab Energy steal percentage.

    // Bloodlust active damage bonus rampup - NOT IMPLEMENTED.
    float GetDamageBonus()
    {
        float damageBonus = 1.0f; // Base multiplier.
        
        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();

            // Bloodlust stacking damage bonus.
            if(m_bActive)
            {
                float bonusPerLevel = m_flDamageBonusAtMaxLevel / g_iMaxLevel;
                damageBonus += bonusPerLevel * level; // This is applied per tic.
            }
            else
                return 0.0f; // Damage bonus reduced to 0 when ability is not active.
        }
            
        return damageBonus;
    }

    float GetLifestealAmount()
    {
        if(m_pStats is null)
            return 0.0f; // No lifesteal if no stats.

        float lifestealAmount = 1.0f; // Initialise.

        int level = m_pStats.GetLevel();
        float stealPerLevel = m_flLifestealAtMaxLevel / g_iMaxLevel;

        // If bloodlust is active, double the lifesteal.
        if(!m_bActive)
            lifestealAmount *= (stealPerLevel * level);
        else
            lifestealAmount *= (stealPerLevel * level) * 2.0f;
            
        return lifestealAmount;
    }

    float GetEnergystealAmount()
    {
        if(m_pStats is null)
            return 0.0f; // No energy steal if no stats.

        float energystealAmount = 1.0f; // Base multiplier.

        int level = m_pStats.GetLevel();

        if(!m_bEnergyStealIsFixed)
        {
            float stealPerLevel = m_flEnergystealAtMaxLevel / g_iMaxLevel;
            // Check if bloodlust is active, double the energy steal.
            if(!m_bActive)
                energystealAmount *= (stealPerLevel * level);
            else
                energystealAmount *= (stealPerLevel * level) * 2.0f;
        }
        else
        {   
            if(!m_bActive)
                energystealAmount *= m_flEnergystealFixedAmount;
            else
                energystealAmount *= m_flEnergystealFixedAmount * 2.0f;
        }

        return energystealAmount;
    }

    // Damage reduction based on current health.
    float GetDamageReduction(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return 0.0f;

        float damageReduction = 1.0f; // Base multiplier.

        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();
            float reductionPerLevel = m_flDamageReductionAtMaxLevel / g_iMaxLevel;
            damageReduction += (1.0f - (reductionPerLevel * level));
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
        float maxDamageReduction = 1.0f; // Base multiplier.

        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();
            float reductionPerLevel = m_flDamageReductionAtMaxLevel / g_iMaxLevel;
            maxDamageReduction *= (1.0f - (reductionPerLevel * level));
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

        float reductionPercent = GetDamageReduction(pPlayer); // Get damage reduction as percentage (0-100).
        float reductionMultiplier = 1.0f - (reductionPercent / 100.0f); // Convert it to a multiplier (0-1).
        bloodlustReducedDamage = bloodlustDamageTaken * reductionMultiplier; // Apply it as a multiplier.
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

    float ProcessLifesteal(CBasePlayer@ pPlayer, float damageDealt)
    {
        if(pPlayer is null)
            return 0.0f;

        if(m_pStats is null) // If no stats, no lifesteal.
            return 0.0f;

        if(!pPlayer.IsAlive()) // Deactivate Bloodlust if player dies.
        {
            DeactivateBloodlust(pPlayer);
            return 0.0f;
        }

        float lifestealMult = GetLifestealAmount();
        float healAmount = damageDealt * lifestealMult; // Heal amount from lifesteal.
        float healAmountAP = damageDealt * lifestealMult * 0.5f; // 50% effectiveness to AP instead if HP is full.

        if(pPlayer.pev.health < pPlayer.pev.max_health) // Heal HP if below max, or AP at 50% reduction if at max.
        {
            pPlayer.pev.health = Math.min(pPlayer.pev.health + healAmount, pPlayer.pev.max_health);
                return healAmount;
        }
        else if (pPlayer.pev.health >= pPlayer.pev.max_health && pPlayer.pev.armorvalue < pPlayer.pev.armortype)
        {
            pPlayer.pev.armorvalue = Math.min(pPlayer.pev.armorvalue + healAmountAP, pPlayer.pev.armortype); // Cap at max armor.
                return healAmountAP;
        }
        
        ApplyLifestealEffect(pPlayer); // Visual effect for healing from lifesteal.
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBloodlustHitSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);

        return healAmount;
    }

    float ProcessEnergySteal(CBasePlayer@ pPlayer, float damageDealt)
    {
        if(pPlayer is null)
            return 0.0f;

        if(m_pStats is null) // If no stats, no energy steal.
            return 0.0f;

        if(!pPlayer.IsAlive()) // Deactivate if player dies.
        {
            DeactivateBloodlust(pPlayer);
            return 0.0f;
        }

        float energyStealMult = GetEnergystealAmount();
        float gainAmount = damageDealt * energyStealMult;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerClassResources.exists(steamID))
            {
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                if(resources !is null)
                {
                    float currentEnergy = float(resources['current']);
                    float maxEnergy = float(resources['max']);

                    currentEnergy = Math.min(currentEnergy + gainAmount, maxEnergy); // Add energy to variable, but don't exceed max.

                    resources['current'] = currentEnergy; // Add back to energy.
                }
            }

        return gainAmount;
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