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
    private float m_flAbilityMax = 20.0f; // Max charge (seconds of use).
    private float m_flAbilityRechargeTime = 90.0f; // Seconds to fully recharge from empty.
    private float m_flBloodlustAbilityDrainInterval = 1.0f; // Interval to remove ability charge.
    private float m_flBloodlustAbilityCost = 1.0f; // Ability drain per interval.
    private float m_flBloodlustAbilityDeactivateCost = 0.15f; // Ability cost percentage when manually deactivating bloodlust.

    // Bloodlust stat scaling values, passively gained but doubled whilst bloodlust is active.
    private float m_flBaseLifesteal = 0.04f; // Lifesteal % base. Doubles during bloodlust!


    // Timers.
    private float m_flAbilityCharge = 0.0f; // Current charge.
    private float m_flToggleCooldownBloodlust = 0.5f; // Cooldown between toggles.
    private float m_flLastDrainTime = 0.0f; // Stores last drain time.
    private float m_flLastToggleTime = 0.0f; // Stores last toggle time.

    private ClassStats@ m_pStats = null;

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }
    float GetAbilityCharge() { return m_flAbilityCharge; }
    float GetAbilityMax() { return m_flAbilityMax; }
    
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetAbilityCost() { return m_flBloodlustAbilityCost; } // Grab ability cost.

    float GetDeactivateCost() { return m_flBloodlustAbilityDeactivateCost * m_flAbilityMax;} // Ability cost to deactivate.

    float GetScaledAbilityRecharge()
    {
        if (m_pStats is null)
            return SKILL_ABILITYRECHARGE; // Return base if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_ABILITYRECHARGE);
        float rechargeBonus = SKILL_ABILITYRECHARGE * skillLevel; // Bonus ability recharge speed based on skill level.

        return rechargeBonus + 1.0f;
    }

    float GetScaledLifesteal()
    {
        if(m_pStats is null)
            return 0.0f; // No lifesteal if no stats.

        float baseLifesteal = m_flBaseLifesteal; // Base lifesteal percentage.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_BERSERKER_LIFESTEAL);
        float skillPower = SKILL_BERSERKER_LIFESTEAL;
        float modifier = baseLifesteal + (skillPower * skillLevel); // Scaled from lifesteal skill.

        // If bloodlust is active, double the lifesteal.
        if(!m_bActive)
            return modifier;
        else
            return modifier * 2.0f;
    }

    float GetScaledDamageAbilityCharge()
    {
        if(m_pStats is null)
            return 0.0f; // No damage ability charge if no stats.

        float damageAbilityCharge = 0.0f; // Base.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_BERSERKER_DAMAGEABILITYCHARGE);
        float skillPower = SKILL_BERSERKER_DAMAGEABILITYCHARGE;
        float modifier = skillPower * skillLevel; // Scaled from damage to ability charge skill.

        // Check if bloodlust is active, double the charge.
        if(!m_bActive)
        {
            damageAbilityCharge += modifier;
        }
        else
        {   
            damageAbilityCharge += modifier * 2.0f;
        }

        return damageAbilityCharge;
    }

    // Damage reduction, as a modifier.
    float GetDamageReduction(CBasePlayer@ pPlayer)
    {
        if(m_pStats is null)
            return 0.0f;

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_BERSERKER_DAMAGEREDUCTION);
        float skillPower = SKILL_BERSERKER_DAMAGEREDUCTION;
        float damageReduction = skillPower * skillLevel;

        if(m_bActive)
            damageReduction *= 2.0f; // Double whilst bloodlust is active.

        return damageReduction;
    }

    float GetScaledOverhealPercent() 
    { 
        if(m_pStats is null)
            return 1.0f; // No overheal if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_BERSERKER_OVERHEAL);
        float skillPower = SKILL_BERSERKER_OVERHEAL;
        float overhealBonus = skillPower * skillLevel; // Overheal percent scaled from skill.
            
        if(m_bActive)
            return (1.0f + overhealBonus) * 2.0f; // Double if active.
        else
            return 1.0f + overhealBonus; // Passive overheal.
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
            // Require minimum charge to activate.
            if(m_flAbilityCharge < GetDeactivateCost())
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Need " + int(m_flBloodlustAbilityDeactivateCost * 100.0f) + "%% Charge!");
                return;
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
            // Apply ability cost for manual deactivation.
            m_flAbilityCharge -= GetDeactivateCost();
            if(m_flAbilityCharge < 0.0f)
                m_flAbilityCharge = 0.0f;

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

        float reductionModifier = GetDamageReduction(pPlayer); // 0.0 - 1.0 flat modifier.
        bloodlustReducedDamage = bloodlustDamageTaken * (1.0f - reductionModifier); // Apply directly.
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
        {
            // Recharge when inactive.
            RechargeAbility();
            return;
        }

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastDrainTime >= m_flBloodlustAbilityDrainInterval) // Interval for ability drain.
        {
            m_flAbilityCharge -= m_flBloodlustAbilityCost;
            if(m_flAbilityCharge <= 0.0f)
            {
                m_flAbilityCharge = 0.0f;
                DeactivateBloodlust(pPlayer);
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

        float lifestealMult = GetScaledLifesteal();
        float healAmount = damageDealt * lifestealMult; // Heal amount from lifesteal.
        float overhealPercent = pPlayer.pev.max_health * GetScaledOverhealPercent(); // Max health including overheal.

        if(pPlayer.pev.health < overhealPercent) // Heal HP if below max.
        {
            pPlayer.pev.health = Math.min(pPlayer.pev.health + healAmount, overhealPercent);
                return healAmount;
        }
        
        ApplyLifestealEffect(pPlayer); // Visual effect for healing from lifesteal.
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBloodlustHitSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);

        return healAmount;
    }

    float ProcessDamageAbilityCharge(CBasePlayer@ pPlayer, float damageDealt)
    {
        if(pPlayer is null)
            return 0.0f;

        if(m_pStats is null) // If no stats, no damage ability charge.
            return 0.0f;

        if(!pPlayer.IsAlive()) // Deactivate if player dies.
        {
            DeactivateBloodlust(pPlayer);
            return 0.0f;
        }

        float damageAbilityChargeMult = GetScaledDamageAbilityCharge();
        float gainAmount = damageDealt * damageAbilityChargeMult;

        // Add to current charge, capped at max.
        m_flAbilityCharge = Math.min(m_flAbilityCharge + gainAmount, m_flAbilityMax);

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