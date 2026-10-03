string strBarrierToggleSound = "debris/glass2.wav";
string strBarrierHitSound = "debris/glass1.wav";
string strBarrierBreakSound = "debris/bustglass2.wav";
string strBarrierActiveSound = "ambience/alien_powernode.wav";
string strBarrierReflectSprite = "sprites/blueflare2.spr";
string strBarrierLinkSprite = "sprites/zbeam6.spr";

const Vector BARRIER_COLOR = Vector(130, 200, 255); // R G B.
const float BARRIER_PROTECTION_RANGE = 50 * 16.0f; // Range in units for the barrier protection to work.
const float BARRIER_LINK_RANGE = 50.0f * 16.0f; // Range in units for the barrier to play link effects.

dictionary g_PlayerBarriers; // Dictionary to store player Barrier data.

class BarrierData
{
    private bool m_bActive = false;
    private float m_flAbilityMax = 100.0f; // Base Max HP of Ice Shield.
    private float m_flAbilityRechargeTime = 20.0f; // Time it takes for the ability to fully recharge.
    private float m_flBarrierDamageReduction = 1.00f; // Player damage reduction multiplier whilst shield is active. 1.0 = 100% damage reduction (no damage to HP/AP).
    private float m_flBarrierDurabilityMultiplier = 1.0f; // Shield damage reduction multiplier, used to make shield tougher or weaker overall.
    private float m_flBarrierDeactivateCost = 0.30f; // Energy cost percentage when manually deactivating barrier.
    private float m_flToggleCooldown = 0.5f; // Cooldown between toggles.

    // Link skill.
    private float m_flLinkedDamageReductionMax = 0.75f; // Maximum reduction to shield charge damage from linked players.
    

    // Timers.
    private float m_flAbilityCharge = 0.0f;
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flGlowUpdateInterval = 0.1f;
    private array<int> m_LinkedPlayerIndexes;
    private array<string> m_LinkedPlayerAuthIDs;

    private ClassStats@ m_pStats = null;

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }
    float GetAbilityCharge() { return m_flAbilityCharge; }
    void FillAbilityCharge() { m_flAbilityCharge = GetShieldMaxHP(); }
    float GetShieldMaxHP() { return GetScaledShieldMaxHP(); }
    float GetShieldDeactivateCost() { return m_flBarrierDeactivateCost * GetScaledShieldMaxHP(); }

    ClassStats@ GetStats() {return m_pStats;}
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    
    float GetBarrierDurabilityMultiplier() { return m_flBarrierDurabilityMultiplier; }
    float GetBarrierHealthAbsorb() { return GetScaledHealthAbsorb(); }

    float GetScaledAbilityRecharge()
    {
        if (m_pStats is null)
            return SKILL_BASIC_ABILITYRECHARGE; // Return base if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_BASIC_ABILITYRECHARGE);
        float rechargeBonus = SKILL_BASIC_ABILITYRECHARGE * skillLevel; // Bonus ability recharge speed based on skill level.

        return rechargeBonus + 1.0f;
    }

    float GetScaledShieldMaxHP() // Shield max HP.
    {
        if (m_pStats is null)
            return m_flAbilityMax; // Return base if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_FROSTGUARD_SHIELDHP);
        float skillPower = SKILL_FROSTGUARD_SHIELDHP;

        return m_flAbilityMax * (1.0f + skillPower * skillLevel); // Scale max HP based on skill level.
    }
    
    float GetScaledDamageReflection() // Shield Damage reflection.
    {
        if(m_pStats is null)
            return 0.0f; // Return base if no stats.
        
        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_FROSTGUARD_DAMAGEREFLECT);
        float skillPower = SKILL_FROSTGUARD_DAMAGEREFLECT;

        return skillLevel * skillPower; // Scale damage reflection based on skill level.
    }

    float GetScaledHealthAbsorb() // Shield health absorb.
    {
        if(m_pStats is null)
            return 0.0f; // Return base if no stats.
        
        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_FROSTGUARD_HPABSORB);
        float skillPower = SKILL_FROSTGUARD_HPABSORB;

        return skillLevel * skillPower; // Scale health absorb based on skill level.
    }

    float GetScaledActiveRecharge()
    {
        if(m_pStats is null)
            return 0.0f; // Return base if no stats.
        
        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_FROSTGUARD_ACTIVERECHARGE);
        float skillPower = SKILL_FROSTGUARD_ACTIVERECHARGE;

        return skillLevel * skillPower; // Scale recharge penalty based on skill level.
    }

    float GetAbilityRechargeRate() { return GetScaledShieldMaxHP() / m_flAbilityRechargeTime * GetScaledAbilityRecharge(); } // Shield HP recharged per second.
    float GetActiveRechargeRate() { return GetScaledActiveRecharge(); } // Get active recharge rate.
    int GetLinkedPlayerCount() { return int(m_LinkedPlayerIndexes.length()); }
    float GetLinkedDamageReduction()
    {
        if(m_pStats is null)
            return 0.0f;

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_FROSTGUARD_TEAMLINK);
        return Math.min(float(skillLevel) * SKILL_FROSTGUARD_TEAMLINK * float(GetLinkedPlayerCount()), m_flLinkedDamageReductionMax);
    }

    bool IsLinkedPlayer(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return false;

        string playerAuthID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        for(uint i = 0; i < m_LinkedPlayerIndexes.length(); ++i)
        {
            if(m_LinkedPlayerIndexes[i] == pPlayer.entindex() && m_LinkedPlayerAuthIDs[i] == playerAuthID)
                return true;
        }

        return false;
    }

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

    void HandleBarrier(CBasePlayer@ pPlayer, CBaseEntity@ attacker, float incomingDamage, float& out modifiedDamage, CBasePlayer@ pProtectedPlayer = null, float flChargeDamageReduction = 0.0f)
    {
        if(pPlayer is null || incomingDamage <= 0.0f)
            return;

        if(pProtectedPlayer is null)
            @pProtectedPlayer = pPlayer;
            
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
        if(!skipReflection && attacker !is null)
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
                    if(reflectDamage > 0.0f)
                        attacker.TakeDamage(pPlayer.pev, attacker.pev, reflectDamage, DMG_FREEZE | DMG_NEVERGIB); // Inflictor is player (shield), attacker is monster itself.
                }
            }
        }

        // Play barrier damage chunks effect on player.
        EffectBarrierDamage(pProtectedPlayer.pev.origin, pProtectedPlayer);
        
        // Drain barrier health (energy).
        float shieldDamage = blockedDamage * (1.0f - Math.min(Math.max(flChargeDamageReduction, 0.0f), 1.0f));
        DrainEnergy(pPlayer, shieldDamage);

        // Absorb a portion of the damage as health.
        if(pProtectedPlayer.pev.health < pProtectedPlayer.pev.max_health) // Only absorb if not at full health.
        {
            float healthAbsorb = incomingDamage * GetScaledHealthAbsorb();
            pProtectedPlayer.pev.health += healthAbsorb; // Add the modified absorbed damage to health.

            Vector pos = pProtectedPlayer.pev.origin;
            Vector mins = pos - Vector(16, 16, 0);
            Vector maxs = pos + Vector(16, 16, 64);

            // Heal Bubbles Effect.
            NetworkMessage absorbmsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos); // Send to clients in the effect origin's PVS.
                absorbmsg.WriteByte(TE_BUBBLES); // Spawn bubbles in a bounding box.
                absorbmsg.WriteCoord(mins.x); // Bounding-box minimum X.
                absorbmsg.WriteCoord(mins.y); // Bounding-box minimum Y.
                absorbmsg.WriteCoord(mins.z); // Bounding-box minimum Z.
                absorbmsg.WriteCoord(maxs.x); // Bounding-box maximum X.
                absorbmsg.WriteCoord(maxs.y); // Bounding-box maximum Y.
                absorbmsg.WriteCoord(maxs.z); // Bounding-box maximum Z.
                absorbmsg.WriteCoord(80.0f); // Bubble column height.
                absorbmsg.WriteShort(GetModelIndex(strHealAuraEffectSprite)); // Bubble sprite model index.
                absorbmsg.WriteByte(12); // Number of bubbles.
                absorbmsg.WriteCoord(6.0f); // Bubble rise speed.
                absorbmsg.End(); // Finish the bubble temp-entity message.
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
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Need " + formatFloat(m_flBarrierDeactivateCost * 100, "f", 0, 2) + "%% Charge!");
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
        {
            m_LinkedPlayerIndexes.resize(0);
            m_LinkedPlayerAuthIDs.resize(0);
            return;
        }

        ToggleGlow(pPlayer); // Handle glow state.

        if(!pPlayer.IsAlive()) // Deactivate if player dies.
        {
            DeactivateBarrier(pPlayer);
            ToggleGlow(pPlayer);
            m_LinkedPlayerIndexes.resize(0);
            m_LinkedPlayerAuthIDs.resize(0);
            return;
        }

        UpdateLinkedPlayers(pPlayer);
        DrawLinkedPlayerBeams(pPlayer);
    }

    private void UpdateLinkedPlayers(CBasePlayer@ pOwner)
    {
        m_LinkedPlayerIndexes.resize(0);
        m_LinkedPlayerAuthIDs.resize(0);
        if(m_pStats is null || m_pStats.GetSkillLevel(SkillID::SKILL_FROSTGUARD_TEAMLINK) <= 0)
            return;

        for(int i = 1; i <= g_Engine.maxClients; ++i)
        {
            if(i == pOwner.entindex())
                continue;

            CBasePlayer@ pCandidate = g_PlayerFuncs.FindPlayerByIndex(i);
            if(pCandidate is null || !pCandidate.IsConnected() || !pCandidate.IsAlive())
                continue;

            if((pCandidate.pev.origin - pOwner.pev.origin).Length() > BARRIER_LINK_RANGE)
                continue;

            m_LinkedPlayerIndexes.insertLast(i);
            m_LinkedPlayerAuthIDs.insertLast(g_EngineFuncs.GetPlayerAuthId(pCandidate.edict()));
        }
    }

    private void DrawLinkedPlayerBeams(CBasePlayer@ pOwner)
    {
        for(uint i = 0; i < m_LinkedPlayerIndexes.length(); ++i)
        {
            CBasePlayer@ pLinkedPlayer = g_PlayerFuncs.FindPlayerByIndex(m_LinkedPlayerIndexes[i]);
            if(pLinkedPlayer is null || !pLinkedPlayer.IsConnected() || !pLinkedPlayer.IsAlive() || g_EngineFuncs.GetPlayerAuthId(pLinkedPlayer.edict()) != m_LinkedPlayerAuthIDs[i])
                continue;

            Vector end = pLinkedPlayer.pev.origin + (pLinkedPlayer.pev.mins + pLinkedPlayer.pev.maxs) * 0.5f;
            NetworkMessage beamMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pOwner.pev.origin); // Send to clients in the beam start's PVS.
                beamMsg.WriteByte(TE_BEAMENTPOINT); // Draw a beam from an entity to a fixed point.
                beamMsg.WriteShort(pOwner.entindex()); // Entity attached to the beam start.
                beamMsg.WriteCoord(end.x); // Beam endpoint X (linked player's midpoint).
                beamMsg.WriteCoord(end.y); // Beam endpoint Y.
                beamMsg.WriteCoord(end.z); // Beam endpoint Z.
                beamMsg.WriteShort(GetModelIndex(strBarrierLinkSprite)); // Beam sprite model index.
                beamMsg.WriteByte(0); // Starting frame.
                beamMsg.WriteByte(0); // Frame rate.
                beamMsg.WriteByte(2); // Beam lifetime in tenths of a second.
                beamMsg.WriteByte(12); // Beam width.
                beamMsg.WriteByte(0); // Beam noise amplitude.
                beamMsg.WriteByte(uint8(BARRIER_COLOR.x)); // Beam red component.
                beamMsg.WriteByte(uint8(BARRIER_COLOR.y)); // Beam green component.
                beamMsg.WriteByte(uint8(BARRIER_COLOR.z)); // Beam blue component.
                beamMsg.WriteByte(200); // Beam brightness.
                beamMsg.WriteByte(0); // Texture scroll speed.
                beamMsg.End(); // Finish the beam temp-entity message.
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
        NetworkMessage breakMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin); // Send to clients near the shatter origin.
            breakMsg.WriteByte(TE_BREAKMODEL); // Break model into flying pieces.
            breakMsg.WriteCoord(origin.x); // Break origin X.
            breakMsg.WriteCoord(origin.y); // Break origin Y.
            breakMsg.WriteCoord(origin.z); // Break origin Z.
            breakMsg.WriteCoord(5); // Piece bounding-box size X.
            breakMsg.WriteCoord(5); // Piece bounding-box size Y.
            breakMsg.WriteCoord(5); // Piece bounding-box size Z.
            breakMsg.WriteCoord(0); // Base piece velocity X.
            breakMsg.WriteCoord(0); // Base piece velocity Y.
            breakMsg.WriteCoord(5); // Base piece velocity Z.
            breakMsg.WriteByte(25); // Random velocity added to pieces.
            breakMsg.WriteShort(GetModelIndex(strRobogruntModelChromegibs)); // Piece model index.
            breakMsg.WriteByte(15); // Number of pieces.
            breakMsg.WriteByte(10); // Piece lifetime in tenths of a second.
            breakMsg.WriteByte(1); // Break sound/render flags.
            breakMsg.End(); // Finish the shatter temp-entity message.
    }

    void EffectBarrierDamage(Vector origin, CBaseEntity@ entity)
    {
        if(entity is null)
            return;

        // Add effect to chip off chunks as barrier takes damage.
        NetworkMessage breakMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin); // Send to clients near the impact origin.
            breakMsg.WriteByte(TE_BREAKMODEL); // Break model into flying pieces.
            breakMsg.WriteCoord(origin.x); // Break origin X.
            breakMsg.WriteCoord(origin.y); // Break origin Y.
            breakMsg.WriteCoord(origin.z); // Break origin Z.
            breakMsg.WriteCoord(3); // Piece bounding-box size X.
            breakMsg.WriteCoord(3); // Piece bounding-box size Y.
            breakMsg.WriteCoord(3); // Piece bounding-box size Z.
            breakMsg.WriteCoord(0); // Base piece velocity X.
            breakMsg.WriteCoord(0); // Base piece velocity Y.
            breakMsg.WriteCoord(5); // Base piece velocity Z.
            breakMsg.WriteByte(20); // Random velocity added to pieces.
            breakMsg.WriteShort(GetModelIndex(strRobogruntModelChromegibs)); // Piece model index.
            breakMsg.WriteByte(2); // Number of pieces.
            breakMsg.WriteByte(10); // Piece lifetime in tenths of a second.
            breakMsg.WriteByte(1); // Break sound/render flags.
            breakMsg.End(); // Finish the impact temp-entity message.

        // Play hit sound with random pitch.
        int randomPitch = int(Math.RandomFloat(80.0f, 120.0f));

        // Play sound at the entity's position.
        g_SoundSystem.PlaySound(entity.edict(), CHAN_ITEM, strBarrierHitSound, 1.0f, 0.8f, 0, randomPitch);
    }

    void ApplyReflectDamage(Vector origin, CBaseEntity@ target)
    {
        if(target is null)
            return;

        // Also add dynamic light effect to entity.
        NetworkMessage glowreflectMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin); // Send to clients near the reflection origin.
            glowreflectMsg.WriteByte(TE_DLIGHT); // Create a dynamic light.
            glowreflectMsg.WriteCoord(origin.x); // Light origin X.
            glowreflectMsg.WriteCoord(origin.y); // Light origin Y.
            glowreflectMsg.WriteCoord(origin.z); // Light origin Z.
            glowreflectMsg.WriteByte(16); // Light radius parameter, scaled by 10 in the engine.
            glowreflectMsg.WriteByte(uint8(BARRIER_COLOR.x)); // Light red component.
            glowreflectMsg.WriteByte(uint8(BARRIER_COLOR.y)); // Light green component.
            glowreflectMsg.WriteByte(uint8(BARRIER_COLOR.z)); // Light blue component.
            glowreflectMsg.WriteByte(2); // Light lifetime in tenths of a second.
            glowreflectMsg.WriteByte(2); // Light radius decay rate.
            glowreflectMsg.End(); // Finish the dynamic-light temp-entity message.

        Vector centerPos = target.pev.origin + (target.pev.mins + target.pev.maxs) * 0.5f;

        // Create sprite trail effect for snow/ice particles.
        NetworkMessage snowmsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin); // Send to clients near the reflection origin.
            snowmsg.WriteByte(TE_SPRITETRAIL); // Emit a trail of sprites.
            snowmsg.WriteCoord(centerPos.x); // Trail start X.
            snowmsg.WriteCoord(centerPos.y); // Trail start Y.
            snowmsg.WriteCoord(centerPos.z); // Trail start Z.
            snowmsg.WriteCoord(centerPos.x); // Trail end X.
            snowmsg.WriteCoord(centerPos.y); // Trail end Y.
            snowmsg.WriteCoord(centerPos.z); // Trail end Z.
            snowmsg.WriteShort(GetModelIndex(strBarrierReflectSprite)); // Trail sprite model index.
            snowmsg.WriteByte(3); // Number of sprites.
            snowmsg.WriteByte(1); // Sprite lifetime in tenths of a second.
            snowmsg.WriteByte(2); // Sprite scale in tenths of a unit.
            snowmsg.WriteByte(25); // Forward velocity in tens of units.
            snowmsg.WriteByte(15); // Random velocity in tens of units.
            snowmsg.End(); // Finish the sprite-trail temp-entity message.
    }
}