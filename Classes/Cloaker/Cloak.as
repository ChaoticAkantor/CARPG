string strCloakActivateSound = "player/hud_nightvision.wav";
string strCloakActiveSound = "ambience/alien_twow.wav";

const Vector CLOAK_COLOR = Vector(50, 50, 50); // R G B

dictionary g_PlayerCloaks;

class CloakData
{
    private bool m_bActive = false;
    private float m_flCloakEnergyCostPerShot = 50.0f; // Energy drain per shot.
    private float m_flCloakEnergyDrainInterval = 0.1f; // Energy drain interval.
    private float m_flCloakToggleCooldown = 0.5f; // Cooldown between toggles.
    private float m_flBaseDrainRate = 1.0f; // Base drain rate.
    private float m_flBaseDamageBonus = 1.0f; // Base % damage increase.
    private float m_flDamageBonusPerLevel = 0.02f; // Bonus % per level.

    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flLastEnergyConsumed = 0.0f;
    private ClassStats@ m_pStats = null;

    bool IsActive() { return m_bActive; }
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    float GetDamageBonus() { return m_flBaseDamageBonus * (1.0f + m_pStats.GetLevel() * m_flDamageBonusPerLevel); }
    float GetEnergyCost () { return m_flBaseDrainRate; }
    float GetEnergyCostPerShot() { return m_flCloakEnergyCostPerShot; }

    float GetDamageMultiplier(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || m_flLastEnergyConsumed <= 0)
            return 1.0f;
                
        // Get total potential damage bonus based on level.
        float totalPossibleBonus = m_flBaseDamageBonus; // First set it to base.
        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();
            totalPossibleBonus *= (1.0f + (level * m_flDamageBonusPerLevel)); // Now multiply by level bonus.
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
                    // Activate
                    if(float(resources['current']) < (float(resources['max']))) // Cloak needs to be fully charged between uses.
                    {
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Cloak recharging...\n");
                        return;
                    }

                    m_bActive = true;
                    m_flLastDrainTime = currentTime;
                    
                    // Set initial energy value for damage calculation.
                    m_flLastEnergyConsumed = float(resources['current']);
                    
                    // Visual effects
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
        
        // Reset visual effects.
        pPlayer.pev.rendermode = kRenderNormal;
        pPlayer.pev.renderfx = kRenderFxNone;
        pPlayer.pev.renderamt = 255;  // Fully visible.
        
        // Reset AI targeting.
        pPlayer.pev.flags &= ~FL_NOTARGET;
        
        // Stop looping sound and play deactivation sound.
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strCloakActiveSound, 0.0f, ATTN_NORM, SND_STOP);
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strCloakActivateSound, 1.0f, ATTN_NORM, 0, PITCH_LOW);    
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Cloak Disabled!\n");
        
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

    void DrainEnergyFromShot(CBasePlayer@ pPlayer)
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
                
                current -= m_flCloakEnergyCostPerShot; // Reduce energy when shooting.
                
                // End cloak if energy runs out.
                if(current <= 0)
                {
                    current = 0;
                    DeactivateCloak(pPlayer);
                }
                
                resources['current'] = current;
            }
        }
    }
}