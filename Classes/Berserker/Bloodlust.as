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

    // Bloodlust stat scaling values, passively gained but doubled whilst bloodlust is active.
    private float m_flDamageReductionAtMaxLevel = 0.495f; // Damage reduction multiplier at maximum level. Doubles during bloodlust!
    private float m_flLifestealAtMaxLevel = 0.30f; // Lifesteal %, as a multiplier at max level. Doubles during bloodlust!
    private float m_flOverhealPercent = 0.60f; // Percent of max health that can be overhealed to.
    private float m_flEnergystealAtMaxLevel = 0.08f; // Energy steal %, as a multiplier at max level. Doubles during bloodlust!
    private float m_flEnergystealFixedAmount = 0.08f; // Fixed energy steal % if scaling is disabled. Doubles during bloodlust!
    private bool m_bEnergyStealIsFixed = false; // Whether energy steal is a fixed or scales with level.

    // Cooldown and activation timers.
    private float m_flToggleCooldownBloodlust = 0.5f; // Cooldown between toggles.
    private float m_flLastDrainTime = 0.0f; // Stores last drain time.
    private float m_flLastToggleTime = 0.0f; // Stores last toggle time.

    private ClassStats@ m_pStats = null;

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }
    
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetEnergyCost() { return m_flBloodlustEnergyCost; } // Grab energy cost.
    float GetEnergySteal() { return (m_flEnergystealAtMaxLevel * 100); } // Grab Energy steal percentage.

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

        float damageReduction = 0.0f; // The actual damage REDUCTION.

        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();
            float reductionPerLevel = m_flDamageReductionAtMaxLevel / g_iMaxLevel;
            damageReduction = (reductionPerLevel * level);
        }

        // Calculate missing health percentage
        float maxHealth = pPlayer.pev.max_health;
        float currentHealth = Math.max(1.0f, pPlayer.pev.health); // Ensure at least 1 health.
        float missingHealth = maxHealth - currentHealth;
        float missingHealthPercent = Math.max(0.0f, Math.min(100.0f, (missingHealth / maxHealth) * 200.0f)); // Full bonus at 50% HP lost, clamped to 0% at full health.

        // Apply missing health scaling
        if(!m_bActive)
            damageReduction *= (missingHealthPercent / 100.0f); // Passive.
        else
            damageReduction *= (missingHealthPercent / 100.0f) * 2.0f; // Active is double.

        // Convert to percentage for display.
        damageReduction = Math.min(damageReduction * 100.0f, 100.0f);
        return damageReduction;
    }

    // Maximum possible damage reduction for stat menu display.
    float GetDamageReductionMax()
    {
        if(m_pStats is null)
            return 0.0f;

        int level = m_pStats.GetLevel();
        float reductionPerLevel = m_flDamageReductionAtMaxLevel / g_iMaxLevel;
        float maxReduction = (reductionPerLevel * level) * 100.0f;

        return Math.min(maxReduction, 100.0f);
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

    float GetOverhealPercent() 
    { 
        if(m_pStats is null)
            return 1.0f; // No overheal if no stats.
            
        if(m_bActive)
            return (1.0f + m_flOverhealPercent) * 2.0f; // Double if active.
        else
            return 1.0f + m_flOverhealPercent; // Passive overheal.
    }

    float GetOverhealPercentFlat() 
    { 
        if(m_pStats is null)
            return 1.0f; // No overheal if no stats.
            
        return 1.0f + m_flOverhealPercent; // Passive overheal.
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
        float overhealPercent = pPlayer.pev.max_health * GetOverhealPercent(); // Max health including overheal.

        if(pPlayer.pev.health < overhealPercent) // Heal HP if below max.
        {
            pPlayer.pev.health = Math.min(pPlayer.pev.health + healAmount, overhealPercent);
                return healAmount;
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

        NetworkMessage bubbleMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
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
        NetworkMessage msg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pPlayer.pev.origin);
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