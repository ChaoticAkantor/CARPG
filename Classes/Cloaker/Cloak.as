string strCloakActivateSound = "player/hud_nightvision.wav";
string strCloakActiveSound = "ambience/alien_twow.wav";
string strCloakNovaSound = "weapons/displacer_impact.wav";

string strCloakNovaSprite = "sprites/laserbeam.spr";

const Vector CLOAK_COLOR = Vector(50, 50, 50); // R G B

dictionary g_PlayerCloaks;

class CloakData
{
    // Cloak.
    private bool m_bActive = false;
    private float m_flAbilityMax = 30.0f; // Max charge.
    private float m_flAbilityRechargeTime = 20.0f; // Seconds to fully recharge from empty.
    private float m_flBaseCloakEnergyCostPerShot = 1.0f; // Base duration drained per damage instance, drain scales with amount of damage dealt.
    private float m_flCloakEnergyCostCap = 10.0f; // Max duration drained per damage instance. Will never drain more than this value.
    private float m_flCloakEnergyDrainInterval = 1.0f; // Energy drain interval.
    private float m_flCloakToggleCooldown = 0.5f; // Cooldown between toggles.
    private float m_flBaseDrainRate = 1.0f; // Base drain rate.

    // Timers.
    private float m_flAbilityCharge = 0.0f;
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flLastEnergyConsumed = 0.0f;

    //Nova.
    private bool m_bNovaActive = false;
    private float m_flNovaRadius = 50.0f * 16.0f; // Radius of the nova. Ft to units.

    private ClassStats@ m_pStats = null;

    ClassStats@ GetStats() { return m_pStats; }

    bool IsActive() { return m_bActive; }
    bool IsNovaActive() { return m_bNovaActive;}
    float GetAbilityCharge() { return m_flAbilityCharge; }
    float GetAbilityMax() { return m_flAbilityMax; }

    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetNovaRadius() { return m_flNovaRadius; }

    // Used specifically for stats menu to display full potential damage bonus, without energy scaling.
    float GetDamageMultiplierTotal() 
    { 
        if(m_pStats is null)
            return 0.0f; // Return default if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_CLOAKER_CLOAKDAMAGE);
        float skillPower = SKILL_CLOAKER_CLOAKDAMAGE;
        float modifier = 1.0f + (skillLevel * skillPower); // Calculate modifier based on skill level.

        return modifier;
    }

    float GetNovaDamage(CBasePlayer@ pPlayer)
    { 
        if(m_pStats is null)
            return 0.0f; // Return 0 if no stats.

        // Scale nova damage.
        float novadamage = 0.0f; // Initialise.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_CLOAKER_CLOAKNOVADAMAGE);
        float skillPower = SKILL_CLOAKER_CLOAKNOVADAMAGE;
        float modifier = 1.0f + (skillLevel * skillPower); // Calculate modifier based on skill level.

        // Scale nova damage based on max and remaining energy and modifier.
        float remainingAbilityCharge = m_flAbilityCharge;
        novadamage = remainingAbilityCharge * modifier;

        return novadamage;
    }

    float GetDamageMultiplier(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || m_flLastEnergyConsumed <= 0) // Normal damage if cloak is inactive.
            return 1.0f;

        if(m_pStats is null) // Normal damage if no stats.
            return 1.0f;
                
        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_CLOAKER_CLOAKDAMAGE);
        float skillPower = SKILL_CLOAKER_CLOAKDAMAGE;
        float modifier = 1.0f + (skillLevel * skillPower); // Calculate modifier based on skill level.

        float totalPossibleBonus = modifier; // Total possible bonus.
        
        float powerScale = Math.min(1.0f, m_flLastEnergyConsumed / m_flAbilityMax);
        return totalPossibleBonus * powerScale;
    }

    void ToggleCloak(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flCloakToggleCooldown)
            return;

        if(!m_bActive)
        {
            // Cloak needs to be fully charged to activate.
            if(m_flAbilityCharge < m_flAbilityMax)
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Cloak recharging...\n");
                return;
            }

            m_bActive = true;
            m_flLastDrainTime = currentTime;
            m_flLastEnergyConsumed = m_flAbilityCharge;
                    
                    // Visual effects.
                    pPlayer.pev.rendermode = kRenderTransAlpha;
                    pPlayer.pev.renderfx = kRenderFxGlowShell;
                    pPlayer.pev.rendercolor = CLOAK_COLOR; // Set color of effect.
                    pPlayer.pev.renderamt = 5;  // Between 0-255.
                    
                    NetworkMessage message(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pPlayer.pev.origin);
                        message.WriteByte(TE_PARTICLEBURST);
                        message.WriteCoord(pPlayer.pev.origin.x);
                        message.WriteCoord(pPlayer.pev.origin.y);
                        message.WriteCoord(pPlayer.pev.origin.z);
                        message.WriteShort(50);  // radius.
                        message.WriteByte(1);   // particle color.
                        message.WriteByte(3);    // duration (in 0.1 sec).
                    message.End();
                    
                    // AI targeting.
                    pPlayer.pev.flags |= FL_NOTARGET;

                    // Sounds - activation and loop.
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strCloakActivateSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strCloakActiveSound, 0.5f, ATTN_NORM, SND_FORCE_LOOP);
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Cloak Activated!\n");
        }
        else
        {
            // Deactivate
            DeactivateCloak(pPlayer);
        }

        m_flLastToggleTime = 0.0f;
    }

    void DeactivateCloak(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        m_bActive = false;

        // Set charge to 0 when cloak ends so it must fully recharge before re-use.
        m_flAbilityCharge = 0.0f;
        
        // Reset visual effects.
        pPlayer.pev.rendermode = kRenderNormal;
        pPlayer.pev.renderfx = kRenderFxNone;
        pPlayer.pev.renderamt = 255;  // Fully visible.
        
        // Reset AI targeting.
        pPlayer.pev.flags &= ~FL_NOTARGET;
        
        // Stop looping sound and play deactivation sound.
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strCloakActivateSound, 1.0f, ATTN_NORM, 0, PITCH_LOW);    
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strCloakActiveSound, 0.0f, ATTN_NORM, SND_STOP);
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Cloak Deactivated!\n");
        
        // Create damaging nova when cloak ends, if the player has the skill.
        if(m_pStats !is null && m_pStats.GetSkillLevel(SkillID::SKILL_CLOAKER_CLOAKNOVADAMAGE) > 0)
            CreateNova(pPlayer);
        
        m_flLastEnergyConsumed = 0.0f;
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
        if(pPlayer is null)
            return;

        if(!m_bActive)
        {
            // Recharge only when fully inactive (cloak must fully recharge before re-use).
            RechargeAbility();
            return;
        }

        // Deactivate if player is dead.
        if(!pPlayer.IsAlive())
        {
            DeactivateCloak(pPlayer);
            return;
        }

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastDrainTime >= m_flCloakEnergyDrainInterval) // Drain interval.
        {
            m_flLastEnergyConsumed = m_flAbilityCharge;
            m_flAbilityCharge -= m_flBaseDrainRate;
            
            if(m_flAbilityCharge <= 0.0f)
            {
                m_flAbilityCharge = 0.0f;
                DeactivateCloak(pPlayer);
            }
            
            m_flLastDrainTime = currentTime;
        }
    }

    void DrainEnergyFromShot(CBasePlayer@ pPlayer, float damage = 0.0f)
    {
        if(!m_bActive || pPlayer is null)
            return;

        m_flLastEnergyConsumed = m_flAbilityCharge;
        
        // Scale battery drain based on damage dealt.
        float drainAmount = m_flBaseCloakEnergyCostPerShot;
        
        if(damage > 0.0f)
        {
            float damageScale = damage / 10.0f;
            drainAmount += (damageScale * 0.15f * m_flBaseCloakEnergyCostPerShot);
            if(drainAmount > m_flCloakEnergyCostCap)
                drainAmount = m_flCloakEnergyCostCap;
        }
        
        m_flAbilityCharge -= drainAmount;
        
        if(m_flAbilityCharge <= 0.0f)
        {
            m_flAbilityCharge = 0.0f;
            DeactivateCloak(pPlayer);
        }
    }
    
    void CreateNova(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;

        // Calculate explosion damage.
        float explosionDamage = GetNovaDamage(pPlayer);
        
        // Create beam cylinder effect for nova visuals.
        Vector playerOrigin = pPlayer.pev.origin;

        NetworkMessage beamMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, playerOrigin);
            beamMsg.WriteByte(TE_BEAMCYLINDER);
            beamMsg.WriteCoord(playerOrigin.x);
            beamMsg.WriteCoord(playerOrigin.y);
            beamMsg.WriteCoord(playerOrigin.z);
            beamMsg.WriteCoord(playerOrigin.x);
            beamMsg.WriteCoord(playerOrigin.y);
            beamMsg.WriteCoord(playerOrigin.z + m_flNovaRadius); // Height equals radius.
            beamMsg.WriteShort(g_EngineFuncs.ModelIndex(strCloakNovaSprite));
            beamMsg.WriteByte(0); // Start frame.
            beamMsg.WriteByte(0); // Frame rate (no effect).
            beamMsg.WriteByte(5); // Life * 0.1s (0.5s to reach max).
            beamMsg.WriteByte(6); // Width.
            beamMsg.WriteByte(0); // Noise.
            beamMsg.WriteByte(0); // Red.
            beamMsg.WriteByte(50); // Green.
            beamMsg.WriteByte(255); // Blue.
            beamMsg.WriteByte(255); // Brightness.
            beamMsg.WriteByte(0); // Speed (no effect).
        beamMsg.End();

        // Also create a dynamic light at the nova center.
        NetworkMessage lightMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, playerOrigin);
            lightMsg.WriteByte(TE_DLIGHT);
            lightMsg.WriteCoord(playerOrigin.x);
            lightMsg.WriteCoord(playerOrigin.y);
            lightMsg.WriteCoord(playerOrigin.z);
            lightMsg.WriteByte(64); // Radius.
            lightMsg.WriteByte(0);   // Red.
            lightMsg.WriteByte(50); // Green.
            lightMsg.WriteByte(255);   // Blue.
            lightMsg.WriteByte(10);  // Life in 0.1s (1s).
            lightMsg.WriteByte(100);  // Decay rate (instant).
        lightMsg.End();

        // Nova has started.
        m_bNovaActive = true;

        // Apply radius damage centered on the player.
        g_WeaponFuncs.RadiusDamage
        (
            playerOrigin, // Explosion center.
            pPlayer.pev, // Inflictor.
            pPlayer.pev, // Attacker.
            explosionDamage, // Scaled Damage.
            m_flNovaRadius, // Radius.
            CLASS_PLAYER, // Will not damage player or allies.
            DMG_ENERGYBEAM | DMG_ALWAYSGIB // Damage type and always gib.
        );

        // Play explosion sound.
        g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_WEAPON, strCloakNovaSound, 1.0f, ATTN_NORM);

        // Nova has finished.
        m_bNovaActive = false;
    }
}