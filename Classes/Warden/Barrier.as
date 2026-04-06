string strBarrierToggleSound = "debris/glass2.wav";
string strBarrierHitSound = "debris/glass1.wav";
string strBarrierBreakSound = "debris/bustglass2.wav";
string strBarrierActiveSound = "ambience/alien_powernode.wav";
string strBarrierReflectSprite = "sprites/blueflare2.spr";

const Vector BARRIER_COLOR = Vector(130, 200, 255); // R G B.
const float BARRIER_PROTECTION_RANGE = 2400.0f; // Range in units for the barrier protection to work.

dictionary g_PlayerBarriers; // Dictionary to store player Barrier data.

class BarrierData
{
    private bool m_bActive = false;
    private float m_flAbilityMax = 100.0f; // Base Max HP of Ice Shield.
    private float m_flAbilityRechargeTime = 20.0f; // Time it takes for the ability to fully recharge.
    private float m_flBarrierDamageReduction = 1.00f; // Player damage reduction multiplier whilst shield is active. 1.0 = 100% damage reduction (no damage to HP/AP).
    private float m_flBarrierDurabilityMultiplier = 1.0f; // Shield damage reduction multiplier, used to make shield tougher or weaker overall.
    private float m_flBarrierDeactivateEnergyCost = 0.25f; // Energy cost percentage when manually deactivating barrier.
    private float m_flToggleCooldown = 0.5f; // Cooldown between toggles.
    

    // Timers.
    private float m_flAbilityCharge = 0.0f;
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flGlowUpdateInterval = 0.1f;

    private ClassStats@ m_pStats = null;

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }
    float GetAbilityCharge() { return m_flAbilityCharge; }
    float GetShieldMaxHP() { return GetScaledShieldMaxHP(); }
    float GetShieldDeactivateCost() { return m_flBarrierDeactivateEnergyCost * GetScaledShieldMaxHP(); }

    ClassStats@ GetStats() {return m_pStats;}
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    
    float GetBarrierDurabilityMultiplier() { return m_flBarrierDurabilityMultiplier; }
    float GetBarrierHealthAbsorb() { return GetScaledHealthAbsorb(); }

    float GetScaledAbilityRecharge()
    {
        if (m_pStats is null)
            return SKILL_ABILITYRECHARGE; // Return base if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_ABILITYRECHARGE);
        float rechargeBonus = SKILL_ABILITYRECHARGE * skillLevel; // Bonus ability recharge speed based on skill level.

        return rechargeBonus + 1.0f;
    }

    float GetScaledShieldMaxHP() // Shield max HP.
    {
        if (m_pStats is null)
            return m_flAbilityMax; // Return base if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_WARDEN_SHIELDHP);
        float skillPower = SKILL_WARDEN_SHIELDHP;

        return m_flAbilityMax * (1.0f + skillPower * skillLevel); // Scale max HP based on skill level.
    }
    
    float GetScaledDamageReflection() // Shield Damage reflection.
    {
        if(m_pStats is null)
            return 0.0f; // Return base if no stats.
        
        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_WARDEN_DAMAGEREFLECT);
        float skillPower = SKILL_WARDEN_DAMAGEREFLECT;

        return skillLevel * skillPower; // Scale damage reflection based on skill level.
    }

    float GetScaledHealthAbsorb() // Shield health absorb.
    {
        if(m_pStats is null)
            return 0.0f; // Return base if no stats.
        
        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_WARDEN_HPABSORB);
        float skillPower = SKILL_WARDEN_HPABSORB;

        return skillLevel * skillPower; // Scale health absorb based on skill level.
    }

    float GetScaledActiveRecharge()
    {
        if(m_pStats is null)
            return 0.0f; // Return base if no stats.
        
        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_WARDEN_ACTIVERECHARGE);
        float skillPower = SKILL_WARDEN_ACTIVERECHARGE;

        return skillLevel * skillPower; // Scale recharge penalty based on skill level.
    }

    float GetAbilityRechargeRate() { return GetScaledShieldMaxHP() / m_flAbilityRechargeTime * GetScaledAbilityRecharge(); } // Shield HP recharged per second.
    float GetActiveRechargeRate() { return GetScaledActiveRecharge(); } // Get active recharge rate.

    void RechargeAbility()
    {
        float scaledMax = GetScaledShieldMaxHP();
        if (m_flAbilityCharge >= scaledMax)
            return;

        // Each tick is 0.1s, so add rate * interval per tick.
        float rechargeRate = scaledMax / m_flAbilityRechargeTime;
        m_flAbilityCharge += rechargeRate * flSchedulerInterval;
        if (m_flAbilityCharge > scaledMax)
            m_flAbilityCharge = scaledMax;
    }

    void HandleBarrier(CBasePlayer@ pPlayer, CBaseEntity@ attacker, float incomingDamage, float& out modifiedDamage)
    {
        if(pPlayer is null || attacker is null)
            return;
            
        // Calculate damage reduction.
        float reduction = GetDamageReduction();
        float blockedDamage = incomingDamage * reduction;
        modifiedDamage = incomingDamage - blockedDamage;
        
        // Don't apply damage reflection if the attacker is the player themselves.
        // or another player protected by this barrier.
        bool skipReflection = false;
        
        // Check if attacker is the barrier owner (self-damage).
        if(attacker is pPlayer)
        {
            skipReflection = true;
        }
        
        // Only apply damage reflection if it's not self and the attacker is a valid monster.
        if(!skipReflection)
        {
            CBaseMonster@ pMonster = cast<CBaseMonster@>(attacker);
            if(pMonster !is null)
            {
                // Skip reflection on turrets - reflected damage bypasses their death state machine,
                // causing them to become unkillable while still targeting the player.
                string attackerClass = attacker.GetClassname();
                bool isTurret = (attackerClass == "monster_turret" || attackerClass == "monster_miniturret");

                if(!isTurret)
                {
                    // Apply damage reflection as a specific damage type and proc the debuff.
                    float reflectDamage = incomingDamage * GetScaledDamageReflection();
                    attacker.TakeDamage(pPlayer.pev, attacker.pev, reflectDamage, DMG_FREEZE | DMG_NEVERGIB); // Inflictor is player (shield), attacker is monster itself.
                }
            }
        }

        // Play barrier damage chunks effect on player.
        EffectBarrierDamage(pPlayer.pev.origin, pPlayer);
        
        // Drain barrier health (energy).
        DrainEnergy(pPlayer, blockedDamage);

        // Absorb a portion of the damage as health.
        if(pPlayer.pev.health < pPlayer.pev.max_health) // Only absorb if not at full health.
        {
            float healthAbsorb = incomingDamage * GetScaledHealthAbsorb();
            pPlayer.pev.health += healthAbsorb; // Add the modified absorbed damage to health.

            Vector pos = pPlayer.pev.origin;
            Vector mins = pos - Vector(16, 16, 0);
            Vector maxs = pos + Vector(16, 16, 64);

            // Heal Bubbles Effect.
            NetworkMessage absorbmsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
                absorbmsg.WriteByte(TE_BUBBLES);
                absorbmsg.WriteCoord(mins.x);
                absorbmsg.WriteCoord(mins.y);
                absorbmsg.WriteCoord(mins.z);
                absorbmsg.WriteCoord(maxs.x);
                absorbmsg.WriteCoord(maxs.y);
                absorbmsg.WriteCoord(maxs.z);
                absorbmsg.WriteCoord(80.0f); // Height of the bubble effect.
                absorbmsg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraEffectSprite)); // Borrow sprite from heal aura.
                absorbmsg.WriteByte(12); // Count.
                absorbmsg.WriteCoord(6.0f); // Speed.
                absorbmsg.End();
        }
    }

    void ToggleBarrier(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Barrier on cooldown!\n");
            return;
        }

        if(!m_bActive)
        {
            if(m_flAbilityCharge < GetShieldDeactivateCost())
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield is broken!\n");
                return;
            }

            // Activate.
            m_bActive = true;
            m_flLastDrainTime = currentTime;
            ToggleGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierToggleSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.5f, ATTN_NORM, SND_FORCE_LOOP, 100);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Activated!\n");
        }
        else // MANUAL DEACTIVATION.
        {
            m_bActive = false;
            ToggleGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierBreakSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.0f, ATTN_NORM, SND_STOP, 100);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Shattered!\n"); // MANUALLY SHATTERED.
            EffectBarrierShatter(pPlayer.pev.origin);

            // Apply energy cost for manual deactivation.
            m_flAbilityCharge -= GetShieldDeactivateCost();
            if(m_flAbilityCharge < 0.0f)
                m_flAbilityCharge = 0.0f;
        }

        m_flLastToggleTime = 0.0f;
    }

    float GetDamageReduction()
    {
        if(m_pStats is null)
            return 0.0f;
            
        return m_flBarrierDamageReduction; // Now always 100% damage reduction to player.
    }

    void Update(CBasePlayer@ pPlayer)
    {
        // Recharge logic: active recharges at penalty rate; inactive recharges at full rate.
        float scaledMax = GetScaledShieldMaxHP();
        if(m_flAbilityCharge < scaledMax)
        {
            float fullRechargeRate = GetAbilityRechargeRate() * flSchedulerInterval; // Per tick (0.1s interval).
            float rate = m_bActive ? (fullRechargeRate * GetScaledActiveRecharge()) : fullRechargeRate;
            m_flAbilityCharge += rate;
            if(m_flAbilityCharge > scaledMax)
                m_flAbilityCharge = scaledMax;
        }

        if(!m_bActive || pPlayer is null)
            return;

        ToggleGlow(pPlayer); // Handle glow state.

        if(!pPlayer.IsAlive()) // Deactivate if player dies.
        {
            DeactivateBarrier(pPlayer);
            ToggleGlow(pPlayer);
            return;
        }
    }
    
    void DrainEnergy(CBasePlayer@ pPlayer, float blockedDamage)
    {
        // Drain charge proportional to damage blocked.
        float energyCost = blockedDamage * m_flBarrierDurabilityMultiplier;
        m_flAbilityCharge -= energyCost;
        
        if(m_flAbilityCharge <= 0.0f)
        {
            m_flAbilityCharge = 0.0f;
            DeactivateBarrier(pPlayer);
        }
    }

    void DeactivateBarrier(CBasePlayer@ pPlayer) // Called when DESTROYED, NOT MANUALLY DEACTIVATED.
    {
        if(pPlayer is null)
            return;

        if(m_bActive)
        {
            m_bActive = false;
            ToggleGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierBreakSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.0f, ATTN_NORM, SND_STOP, 100); // Stop looping sound here too.
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Shattered!\n"); // SHATTERED - DESTROYED.
            EffectBarrierShatter(pPlayer.pev.origin);
        }
    }


    private void ToggleGlow(CBasePlayer@ pPlayer)
    {
        // Apply glow shell to player based on if ability is active or not.
        if(pPlayer is null)
            return;

        if(m_bActive)
        {
            // Apply glow shell if ability is active.
            pPlayer.pev.renderfx = kRenderFxGlowShell;
            pPlayer.pev.rendermode = kRenderNormal;
            pPlayer.pev.rendercolor = BARRIER_COLOR;
            pPlayer.pev.renderamt = 5; // Thickness.
        }
        else
        {
            // Remove glow shell if ability is inactive.
            pPlayer.pev.renderfx = kRenderFxNone;
            pPlayer.pev.rendermode = kRenderNormal;
            pPlayer.pev.renderamt = 255;
            pPlayer.pev.rendercolor = Vector(255, 255, 255);
        }
    }

    private void EffectBarrierShatter(Vector origin)
    {
        // Add effect to shatter barrier.
        NetworkMessage breakMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            breakMsg.WriteByte(TE_BREAKMODEL);
            breakMsg.WriteCoord(origin.x);
            breakMsg.WriteCoord(origin.y);
            breakMsg.WriteCoord(origin.z);
            breakMsg.WriteCoord(5); // Size.
            breakMsg.WriteCoord(5); // Size.
            breakMsg.WriteCoord(5); // Size.
            breakMsg.WriteCoord(0); // Gib vel pos Forward/Back.
            breakMsg.WriteCoord(0); // Gib vel pos Left/Right.
            breakMsg.WriteCoord(5); // Gib vel pos Up/Down.
            breakMsg.WriteByte(25); // Gib random speed and direction.
            breakMsg.WriteShort(g_EngineFuncs.ModelIndex(strRobogruntModelChromegibs));
            breakMsg.WriteByte(15); // Count.
            breakMsg.WriteByte(10); // Lifetime.
            breakMsg.WriteByte(1); // Sound Flags.
            breakMsg.End();
    }

    void EffectBarrierDamage(Vector origin, CBaseEntity@ entity)
    {
        if(entity is null)
            return;

        // Add effect to chip off chunks as barrier takes damage.
        NetworkMessage breakMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            breakMsg.WriteByte(TE_BREAKMODEL);
            breakMsg.WriteCoord(origin.x);
            breakMsg.WriteCoord(origin.y);
            breakMsg.WriteCoord(origin.z);
            breakMsg.WriteCoord(3); // Size.
            breakMsg.WriteCoord(3); // Size.
            breakMsg.WriteCoord(3); // Size.
            breakMsg.WriteCoord(0); // Gib vel pos Forward/Back.
            breakMsg.WriteCoord(0); // Gib vel pos Left/Right.
            breakMsg.WriteCoord(5); // Gib vel pos Up/Down.
            breakMsg.WriteByte(20); // Gib random speed and direction.
            breakMsg.WriteShort(g_EngineFuncs.ModelIndex(strRobogruntModelChromegibs));
            breakMsg.WriteByte(2); // Count.
            breakMsg.WriteByte(10); // Lifetime.
            breakMsg.WriteByte(1); // Sound Flags.
            breakMsg.End();

        // Play hit sound with random pitch.
        int randomPitch = int(Math.RandomFloat(80.0f, 120.0f));

        // Play sound at the entity's position.
        g_SoundSystem.PlaySound(entity.edict(), CHAN_ITEM, strBarrierHitSound, 1.0f, 0.8f, 0, randomPitch);
    }

    void ApplyReflectDamage(Vector origin, CBaseEntity@ target)
    {
        if(target is null)
            return;

        // Add glow shell effect to entity taking damage later, with timeout to remove it. *TO DO

        // Also add dynamic light effect to entity.
        NetworkMessage glowreflectMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            glowreflectMsg.WriteByte(TE_DLIGHT);
            glowreflectMsg.WriteCoord(origin.x);
            glowreflectMsg.WriteCoord(origin.y);
            glowreflectMsg.WriteCoord(origin.z);
            glowreflectMsg.WriteByte(16); // Radius in 0.1 units.
            glowreflectMsg.WriteByte(uint8(BARRIER_COLOR.x)); // Red.
            glowreflectMsg.WriteByte(uint8(BARRIER_COLOR.y)); // Green.
            glowreflectMsg.WriteByte(uint8(BARRIER_COLOR.z)); // Blue.
            glowreflectMsg.WriteByte(3); // Life in 0.1s.
            glowreflectMsg.WriteByte(2); // Fade speed.
            glowreflectMsg.End();

        Vector centerPos = target.pev.origin + (target.pev.mins + target.pev.maxs) * 0.5f;

        // Create sprite trail effect for snow/ice particles.
        NetworkMessage snowmsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            snowmsg.WriteByte(TE_SPRITETRAIL);
            snowmsg.WriteCoord(centerPos.x);
            snowmsg.WriteCoord(centerPos.y);
            snowmsg.WriteCoord(centerPos.z);
            snowmsg.WriteCoord(centerPos.x);
            snowmsg.WriteCoord(centerPos.y);
            snowmsg.WriteCoord(centerPos.z);
            snowmsg.WriteShort(g_EngineFuncs.ModelIndex(strBarrierReflectSprite));
            snowmsg.WriteByte(5);   // Count.
            snowmsg.WriteByte(1);   // Life in 0.1's.
            snowmsg.WriteByte(2);   // Scale in 0.1's.
            snowmsg.WriteByte(25);  // Velocity along vector in 10's.
            snowmsg.WriteByte(15);  // Random velocity in 10's.
            snowmsg.End();
    }
}