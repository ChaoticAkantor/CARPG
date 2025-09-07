string strCloakActivateSound = "player/hud_nightvision.wav";
string strCloakActiveSound = "ambience/alien_twow.wav";
string strCloakNovaSound = "weapons/shock_impact.wav";

string strCloakNovaSprite = "sprites/laserbeam.spr";

const Vector CLOAK_COLOR = Vector(50, 50, 50); // R G B

dictionary g_PlayerCloaks;

class CloakData
{
    // Cloak.
    private bool m_bActive = false;
    private float m_flBaseCloakEnergyCostPerShot = 1.0f; // Base duration drained per damage instance, drain scales with amount of damage dealt.
    private float m_flCloakEnergyCostCap = 10.0f; // Max duration drained per damage instance. Will never drain more than this value.
    private float m_flCloakEnergyDrainInterval = 1.0f; // Energy drain interval.
    private float m_flCloakToggleCooldown = 0.5f; // Cooldown between toggles.
    private float m_flBaseDrainRate = 1.0f; // Base drain rate.
    private float m_flBaseDamageBonus = 1.0f; // Base % damage increase.
    private float m_flDamageBonusPerLevel = 0.02f; // Bonus % per level.
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flLastEnergyConsumed = 0.0f;

    //Nova.
    private float m_flExplosionRadius = 800.0f; // Radius of the electric nova.
    private float m_flExplosionDamageMultiplier = 3.0f; // Damage scaling of electric nova. Multiplies max duration by this value.

    // Perk 1 - AP Stealing Nova.
    private bool m_bNovaActive = false;
    private float m_flAPStealPercent = 0.25f; // % of damage dealt that is returned as AP to the player, or health if AP is 0.

    private ClassStats@ m_pStats = null;

    ClassStats@ GetStats() { return m_pStats; }

    bool IsActive() { return m_bActive; }
    bool IsNovaActive() { return m_bNovaActive;}

    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    float GetDamageBonus() { return m_flBaseDamageBonus * (1.0f + m_pStats.GetLevel() * m_flDamageBonusPerLevel); }
    float GetEnergyCost () { return m_flBaseDrainRate; }
    float GetEnergyCostPerShot() { return m_flBaseCloakEnergyCostPerShot; }
    float GetAPStealPercent() { return m_flAPStealPercent; }
    float GetNovaRadius() { return m_flExplosionRadius; }

    float GetNovaDamage(CBasePlayer@ pPlayer)
    { 
        // Scale nova damage.
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        float currentEnergy = 0.0f;
        float maxEnergy = 10.0f; // Default fallback.
        
        if(g_PlayerClassResources.exists(steamID))
        {
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            if(resources !is null)
            {
                maxEnergy = float(resources['max']); // Get max energy for scaling.
                currentEnergy = float(resources['current']); // Get current energy for scaling.
            }
        }

        float novaDamage = maxEnergy + currentEnergy * m_flExplosionDamageMultiplier;
        return novaDamage;
    }

    float GetDamageMultiplier(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || m_flLastEnergyConsumed <= 0)
            return 1.0f;
                
        // Get total potential damage bonus based on level.
        float totalPossibleBonus = m_flBaseDamageBonus; // First set it to base.
        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();
            totalPossibleBonus *= (1.0f + (level * m_flDamageBonusPerLevel)); // Now multiply with level bonus.
        }
        
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(g_PlayerClassResources.exists(steamID))
        {
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            if(resources !is null)
            {
                float maxEnergy = float(resources['max']);
                float energyScale = Math.min(1.0f, m_flLastEnergyConsumed / maxEnergy);
                float actualBonus = totalPossibleBonus * energyScale;
                
                return 1.0f + actualBonus;
            }
        }
        
        return 1.0f;
    }

    void ToggleCloak(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flCloakToggleCooldown)
            return;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(g_PlayerClassResources.exists(steamID))
        {
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            if(resources !is null)
            {
                if(!m_bActive)
                {
                    // Activate.
                    float currentEnergy = float(resources['current']);
                    float maxEnergy = float(resources['max']);
                    
                    // Check energy - require FULL energy to activate.
                    if(currentEnergy < maxEnergy) // Cloak needs to be fully charged between uses.
                    {
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Cloak recharging...\n");
                        return;
                    }

                    m_bActive = true;
                    m_flLastDrainTime = currentTime;
                    
                    // Set initial energy value for damage calculation.
                    m_flLastEnergyConsumed = currentEnergy;
                    
                    // Visual effects.
                    pPlayer.pev.rendermode = kRenderTransAlpha;
                    pPlayer.pev.renderfx = kRenderFxGlowShell;
                    pPlayer.pev.rendercolor = CLOAK_COLOR; // Set color of effect.
                    pPlayer.pev.renderamt = 5;  // Between 0-255.
                    
                    NetworkMessage message(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
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
            }
        }

        m_flLastToggleTime = currentTime;
    }

    void DeactivateCloak(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        m_bActive = false;

        // Set duration to 0 if we end early, so that nova can't be spammed.
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(g_PlayerClassResources.exists(steamID))
        {
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            if(resources !is null)
            {      
                resources['current'] = 0.0f;
            }
        }
        
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
        
        // Create damaging nova when cloak ends.
        CreateNova(pPlayer);
        
        m_flLastEnergyConsumed = 0.0f;
    }

    void Update(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        // Deactivate if player is dead.
        if(!pPlayer.IsAlive())
        {
            DeactivateCloak(pPlayer);
            return;
        }

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastDrainTime >= m_flCloakEnergyDrainInterval) // Drain interval.
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerClassResources.exists(steamID))
            {
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                if(resources !is null)
                {      
                    // Apply drain and update last energy consumed for damage scaling.
                    float current = float(resources['current']);
                    m_flLastEnergyConsumed = current;
                    current -= m_flBaseDrainRate;
                    
                    if(current <= 0)
                    {
                        current = 0;
                        DeactivateCloak(pPlayer);
                    }
                    
                    resources['current'] = current;
                }
                m_flLastDrainTime = currentTime;
            }
        }
    }

    void DrainEnergyFromShot(CBasePlayer@ pPlayer, float damage = 0.0f)
    {
        if(!m_bActive || pPlayer is null)
            return;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(g_PlayerClassResources.exists(steamID))
        {
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            if(resources !is null)
            {
                float current = float(resources['current']);
                m_flLastEnergyConsumed = current;
                
                // Scale battery drain based on damage dealt.
                float drainAmount = m_flBaseCloakEnergyCostPerShot;
                
                if(damage > 0.0f)
                {
                    // Simple linear scaling with damage dealt.
                    // Add % of scaled damage to base cost.
                    float damageScale = damage / 10.0f;
                    drainAmount += (damageScale * 0.15f * m_flBaseCloakEnergyCostPerShot);
                    
                    // Cap the amount drained to prevent per damage instance.
                    if(drainAmount > m_flCloakEnergyCostCap)
                        drainAmount = m_flCloakEnergyCostCap;
                }
                
                current -= drainAmount;
                
                // End cloak if energy runs out
                if(current <= 0)
                {
                    current = 0;
                    DeactivateCloak(pPlayer);
                }
                
                resources['current'] = current;
            }
        }
    }
    
    void CreateNova(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;

        // Calculate explosion damage.
        float explosionDamage = GetNovaDamage(pPlayer);
        
        // Play explosion sound.
        g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_WEAPON, strCloakNovaSound, 1.0f, ATTN_NORM);
        
        // Create beam cylinder effect for nova visuals.
        Vector playerOrigin = pPlayer.pev.origin;
        NetworkMessage beamMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, playerOrigin);
            beamMsg.WriteByte(TE_BEAMCYLINDER);
            beamMsg.WriteCoord(playerOrigin.x);
            beamMsg.WriteCoord(playerOrigin.y);
            beamMsg.WriteCoord(playerOrigin.z);
            beamMsg.WriteCoord(playerOrigin.x);
            beamMsg.WriteCoord(playerOrigin.y);
            beamMsg.WriteCoord(playerOrigin.z + m_flExplosionRadius); // Height equals radius.
            beamMsg.WriteShort(g_EngineFuncs.ModelIndex(strCloakNovaSprite));
            beamMsg.WriteByte(0); // Start frame.
            beamMsg.WriteByte(2); // Frame rate.
            beamMsg.WriteByte(10); // Life.
            beamMsg.WriteByte(6); // Width.
            beamMsg.WriteByte(0); // Noise.
            beamMsg.WriteByte(0); // Red.
            beamMsg.WriteByte(50); // Green.
            beamMsg.WriteByte(255); // Blue.
            beamMsg.WriteByte(255); // Brightness.
            beamMsg.WriteByte(1); // Speed.
        beamMsg.End();

        // Also create a dynamic light at the nova center.
        NetworkMessage lightMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, playerOrigin);
            lightMsg.WriteByte(TE_DLIGHT);
            lightMsg.WriteCoord(playerOrigin.x);
            lightMsg.WriteCoord(playerOrigin.y);
            lightMsg.WriteCoord(playerOrigin.z);
            lightMsg.WriteByte(uint8(m_flExplosionRadius / 10.0f)); // Radius (scaled down as DLIGHT uses different scale).
            lightMsg.WriteByte(0);   // Red.
            lightMsg.WriteByte(50); // Green.
            lightMsg.WriteByte(255);   // Blue.
            lightMsg.WriteByte(10);  // Life in 0.1s (1 second).
            lightMsg.WriteByte(100);  // Decay rate.
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
            m_flExplosionRadius, // Radius.
            CLASS_PLAYER, // Will not damage player or allies.
            DMG_SHOCK | DMG_ALWAYSGIB // Damage type and always gib.
        );
        
        // Play sound.
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_WEAPON, strCloakNovaSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);

        // Nova has finished.
        m_bNovaActive = false;
    }
}