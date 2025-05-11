string strBarrierToggleSound = "debris/metal1.wav";
string strBarrierHitSound = "debris/metal6.wav";
string strBarrierBreakSound = "debris/metal3.wav";

// Defines for stat menu
const float flBaseDamageReduction = 0.75f; // Base damage reduction.
const float flDamageReductionPerLevel = 0.005f; // Damage reduction scaling per level.
const float flEnergyDrainPerSecond = 0.0f; // Energy drain per second while active.
const float flToggleCooldown = 0.5f; // 1 second cooldown between toggles
const float flBarrierDamageToEnergyMult = 0.15f; // Damage taken to energy drain scale factor.
float g_flDamageReductionBonus = 0.0f; // Used for stat menu.

const Vector BARRIER_COLOR = Vector(150, 150, 150); // R G B

dictionary g_PlayerBarriers; // Dictionary to store player Barrier data.

dictionary g_BarrierGlowData; // Stores glow data for players with Barrier active.

class BarrierData
{
    private bool m_bActive = false;
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private ClassStats@ m_pStats = null;
    private float m_flNextGlowUpdate = 0.0f;
    private float m_flGlowUpdateInterval = 0.1f;

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }
    
    void Initialize(ClassStats@ stats)
    {
        @m_pStats = stats;
    }

    void ToggleBarrier(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < flToggleCooldown)
        {
            //g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Barrier on cooldown!\n");
            return;
        }

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;
            
        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);

        if(!m_bActive)
        {
            // Check energy.
            if(float(resources['current']) < flEnergyDrainPerSecond)
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Barrier is Broken!\n");
                return;
            }

            // Activate.
            m_bActive = true;
            m_flLastDrainTime = currentTime;
            ApplyGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierToggleSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Barrier Activated!\n");
        }
        else
        {
            // Deactivate.
            m_bActive = false;
            RemoveGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierToggleSound, 1.0f, ATTN_NORM, 0, PITCH_LOW);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Barrier Deactivated!\n");
        }

        m_flLastToggleTime = currentTime;
    }

    float GetDamageReduction()
    {
        if(m_pStats is null)
            return 0.0f;
            
        int level = m_pStats.GetLevel();
        g_flDamageReductionBonus = (level * flDamageReductionPerLevel); // Get damage reduction bonus for stat menu.

        return flBaseDamageReduction + (level * flDamageReductionPerLevel);
    }

    void Update(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        // Deactivate if player is dead
        if(!pPlayer.IsAlive())
        {
            DeactivateBarrier(pPlayer);
            return;
        }

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;
        
        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        float currentEnergy = float(resources['current']);
        
        float currentTime = g_Engine.time;
        if(currentTime - m_flLastDrainTime >= 1.0f)
        {
            // Drain energy every second
            float newEnergy = currentEnergy - flEnergyDrainPerSecond;
            
            if(newEnergy <= 0)
            {
                resources['current'] = 0;
                ToggleBarrier(pPlayer); // Deactivate if we run out of energy
                return;
            }
            
            resources['current'] = newEnergy;
            m_flLastDrainTime = currentTime;
        }

        // Update glow effect
        if(currentTime >= m_flNextGlowUpdate)
        {
            ApplyGlow(pPlayer);
            m_flNextGlowUpdate = currentTime + m_flGlowUpdateInterval;
        }
    }

    void DrainEnergy(CBasePlayer@ pPlayer, float blockedDamage)
    {
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;

        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        float current = float(resources['current']);
        
        // Drain energy proportional to damage blocked
        float energyCost = (blockedDamage * flBarrierDamageToEnergyMult); // Damage taken to energy drain scale factor.
        current -= energyCost;
        
        if(current <= 0)
        {
            current = 0;
            ToggleBarrier(pPlayer);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Barrier Destroyed!\n");
        }
        
        resources['current'] = current;
    }

    void DeactivateBarrier(CBasePlayer@ pPlayer)
    {
        if(m_bActive)
        {
            m_bActive = false;
            RemoveGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierBreakSound, 1.0f, ATTN_NORM, 0, PITCH_LOW);
        }
    }

    private void ApplyGlow(CBaseEntity@ target)
    {
        if(target is null)
            return;
                
        string targetId = "" + target.entindex();
        if(!g_BarrierGlowData.exists(targetId))
        {
            GlowData data;
            data.renderFX = target.pev.renderfx;
            data.renderMode = target.pev.rendermode;
            data.renderColor = target.pev.rendercolor;
            data.renderAmt = target.pev.renderamt;
            @g_BarrierGlowData[targetId] = data;
        }
        
        // Apply glow shell
        target.pev.renderfx = kRenderFxGlowShell;
        target.pev.rendermode = kRenderNormal;
        target.pev.rendercolor = BARRIER_COLOR;
        target.pev.renderamt = 4;

        // Add dynamic light
        NetworkMessage msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            msg.WriteByte(TE_DLIGHT);
            msg.WriteCoord(target.pev.origin.x);
            msg.WriteCoord(target.pev.origin.y);
            msg.WriteCoord(target.pev.origin.z);
            msg.WriteByte(15); // Radius
            msg.WriteByte(int(BARRIER_COLOR.x));
            msg.WriteByte(int(BARRIER_COLOR.y));
            msg.WriteByte(int(BARRIER_COLOR.z));
            msg.WriteByte(1); // Life in 0.1s
            msg.WriteByte(0); // Decay rate
        msg.End();
    }

    private void RemoveGlow(CBaseEntity@ target)
    {
        if(target is null)
            return;
                
        string targetId = "" + target.entindex();
        ResetBarrierGlow(targetId);
    }

    private void ResetBarrierGlow(string targetId)
    {
        if(g_BarrierGlowData.exists(targetId))
        {
            CBaseEntity@ target = g_EntityFuncs.Instance(atoi(targetId));
            if(target !is null)
            {
                GlowData@ data = cast<GlowData@>(g_BarrierGlowData[targetId]);
                target.pev.renderfx = data.renderFX;
                target.pev.rendermode = data.renderMode;
                target.pev.rendercolor = data.renderColor;
                target.pev.renderamt = data.renderAmt;
            }
            g_BarrierGlowData.delete(targetId);
        }
    }
}