// Constants for the ability
const float flCloakEnergyCostPerShot = 25.0f; // Energy drain per shot.
const float flCloakToggleCooldown = 0.5f; // Cooldown between toggles.
const float flBaseDrainRate = 1.0f; // Base drain rate when standing still.
const float flMovementDrainMultiplier = 3.0f; // How much more it drains when moving at max speed.
const float flMaxMovementSpeed = 320.0f; // Maximum movement speed to scale drain against.

const float flBaseDamageBonus = 0.50f;      // Base % damage increase.
const float flDamageBonusPerLevel = 0.02f;   // Bonus % per level.

float g_flDamageBonusBase = flBaseDamageBonus * 100.0f;  // For stats menu.
float g_flDamageBonus = 0.0f;               // For stats menu.

const Vector CLOAK_COLOR = Vector(50, 50, 50); // R G B

const string strCloakActivateSound = "player/hud_nightvision.wav";
const string strCloakActiveSound = "ambience/alien_twow.wav";

dictionary g_PlayerCloaks;

class CloakData
{
    private bool m_bActive = false;
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flLastEnergyConsumed = 0.0f;
    private ClassStats@ m_pStats = null;

    bool IsActive() { return m_bActive; }
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetDamageMultiplier(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || m_flLastEnergyConsumed <= 0)
            return 1.0f;
                
        // Get total potential damage bonus based on level
        float totalPossibleBonus = flBaseDamageBonus;
        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();
            totalPossibleBonus += (level * flDamageBonusPerLevel);
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
                
                // Update stats menu
                g_flDamageBonus = actualBonus * 100.0f;
                g_flDamageBonusBase = flBaseDamageBonus * 100.0f;
                
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
        if(currentTime - m_flLastToggleTime < flCloakToggleCooldown)
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
                    if(float(resources['current']) <= 0)
                    {
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Energy too low!\n");
                        return;
                    }

                    m_bActive = true;
                    m_flLastDrainTime = currentTime;
                    
                    // Set initial energy value for damage calculation
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
                        message.WriteShort(50);  // radius
                        message.WriteByte(1);   // particle color
                        message.WriteByte(3);    // duration (in 0.1 sec)
                    message.End();
                    
                    // AI targeting
                    pPlayer.pev.flags |= FL_NOTARGET;
                    
                    // Sounds - activation and loop
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strCloakActivateSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strCloakActiveSound, 0.5f, ATTN_NORM, SND_FORCE_LOOP);
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Cloak Enabled!\n");
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
        
        // Reset AI targeting
        pPlayer.pev.flags &= ~FL_NOTARGET;
        
        // Stop looping sound and play deactivation sound
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strCloakActiveSound, 0.0f, ATTN_NORM, SND_STOP);
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strCloakActivateSound, 1.0f, ATTN_NORM, 0, PITCH_LOW);    
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Cloak Disabled!\n");
        
        m_flLastEnergyConsumed = 0.0f;
    }

    void Update(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        // Deactivate if player is dead
        if(!pPlayer.IsAlive())
        {
            DeactivateCloak(pPlayer);
            return;
        }

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastDrainTime >= 0.5f)
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerClassResources.exists(steamID))
            {
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                if(resources !is null)
                {
                    float finalDrain = flBaseDrainRate;  // Default to base drain when crouching, no matter the movement speed.
                    
                    // Only calculate movement drain if not crouching
                    if((pPlayer.pev.flags & FL_DUCKING) == 0)
                    {
                        Vector velocity = pPlayer.pev.velocity;
                        float speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y);
                        float speedRatio = Math.min(1.0f, speed / flMaxMovementSpeed);
                        
                        float drainMultiplier = 1.0f + (speedRatio * (flMovementDrainMultiplier - 1.0f));
                        finalDrain = flBaseDrainRate * drainMultiplier;
                    }
                    
                    // Apply drain and update last energy consumed for damage scaling.
                    float current = float(resources['current']);
                    m_flLastEnergyConsumed = current;
                    current -= finalDrain;
                    
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
                // Store current energy for damage scaling
                float current = float(resources['current']);
                m_flLastEnergyConsumed = current;
                
                // Consume all energy.
                resources['current'] = 0;
                DeactivateCloak(pPlayer);
            }
        }
    }
}