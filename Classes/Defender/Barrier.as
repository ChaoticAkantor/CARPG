string strBarrierToggleSound = "debris/glass2.wav";
string strBarrierHitSound = "debris/glass1.wav";
string strBarrierBreakSound = "debris/impact_glass.wav";
string strBarrierActiveSound = "ambience/alien_powernode.wav";

const Vector BARRIER_COLOR = Vector(130, 200, 255); // R G B

dictionary g_PlayerBarriers; // Dictionary to store player Barrier data.

class BarrierData
{
    private bool m_bActive = false;
    private float m_flBaseDamageReduction = 1.00f; // Base damage reduction.
    private float m_flToggleCooldown = 0.5f; // 1 second cooldown between toggles.
    private float m_flBarrierDamageToEnergyMult = 0.25f; // Damage taken to energy drain factor. % damage dealt to shield, lower = better.
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private ClassStats@ m_pStats = null;
    private float m_flNextGlowUpdate = 0.0f;
    private float m_flGlowUpdateInterval = 0.1f;

    private float m_flRefundAmount = 0.0f;
    private float m_flRefundTimeLeft = 0.0f;
    private float m_flStoredEnergy = 0.0f;
    private float REFUND_TIME = 5.0f;
    private float REFUND_INTERVAL = 1.0f; // 1 tick per second.

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
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
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
            if(float(resources['current']) < (float(resources['max']))) // Only allow Barrier to be used when it's full.
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield recharging...\n");
                return;
            }

            // Activate.
            m_bActive = true;
            m_flLastDrainTime = currentTime;
            ApplyGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierToggleSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.5f, ATTN_NORM, SND_FORCE_LOOP);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield On!\n");
        }
        else
        {
            StartResourceRefund(pPlayer); // Start refund.

            // Deactivate Manually.
            m_bActive = false;
            RemoveGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.0f, ATTN_NORM, SND_STOP);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierBreakSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Shattered!\n");
            EffectBarrierShatter(pPlayer.pev.origin);
        }

        m_flLastToggleTime = currentTime;
    }

    float GetDamageReduction()
    {
        if(m_pStats is null)
            return 0.0f;
            
        return m_flBaseDamageReduction; // Now always 100% damage reduction.
    }

    void Update(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        if(!pPlayer.IsAlive()) // Deactivate if player dies.
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

        // Handle normal drain.
        if(currentTime - m_flLastDrainTime >= 1.0f)
        {
            // Drain energy every second.
            float newEnergy = currentEnergy;
            
            if(newEnergy <= 0)
            {
                resources['current'] = 0;
                ToggleBarrier(pPlayer); // Deactivate if we run out of energy.
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
        
        // Drain energy proportional to damage blocked.
        float energyCost = (blockedDamage * m_flBarrierDamageToEnergyMult); // Damage taken to energy drain scale factor.
        current -= energyCost;
        
        if(current <= 0)
        {
            current = 0;
            DeactivateBarrier(pPlayer);
        }
        
        resources['current'] = current;
    }

    void DeactivateBarrier(CBasePlayer@ pPlayer)
    {
        if(m_bActive)
        {
            m_bActive = false;
            RemoveGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.0f, ATTN_NORM, SND_STOP); // Stop looping sound here too.
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierBreakSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Shattered!\n");
            EffectBarrierShatter(pPlayer.pev.origin);
        }
    }

    private void ApplyGlow(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;
        
        // Apply glow shell
        pPlayer.pev.renderfx = kRenderFxGlowShell;
        pPlayer.pev.rendermode = kRenderNormal;
        pPlayer.pev.rendercolor = BARRIER_COLOR;
        pPlayer.pev.renderamt = 5; // Thickness.
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

    private void EffectBarrierShatter(Vector origin)
    {
        NetworkMessage breakMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, origin);
            breakMsg.WriteByte(TE_BREAKMODEL);
            breakMsg.WriteCoord(origin.x);
            breakMsg.WriteCoord(origin.y);
            breakMsg.WriteCoord(origin.z);
            breakMsg.WriteCoord(5); // Size
            breakMsg.WriteCoord(5); // Size
            breakMsg.WriteCoord(5); // Size
            breakMsg.WriteCoord(0); // Gib vel pos Forward/Back
            breakMsg.WriteCoord(0); // Gib vel pos Left/Right
            breakMsg.WriteCoord(5); // Gib vel pos Up/Down
            breakMsg.WriteByte(25); // Gib random speed and direction
            breakMsg.WriteShort(g_EngineFuncs.ModelIndex(strRobogruntModelChromegibs));
            breakMsg.WriteByte(15); // Count
            breakMsg.WriteByte(10); // Lifetime
            breakMsg.WriteByte(1); // Sound Flags
            breakMsg.End();
    }

    private void EffectBarrierToggle(Vector origin)
    {
        NetworkMessage breakMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, origin);
            breakMsg.WriteByte(TE_BREAKMODEL);
            breakMsg.WriteCoord(origin.x);
            breakMsg.WriteCoord(origin.y);
            breakMsg.WriteCoord(origin.z);
            breakMsg.WriteCoord(3); // Size
            breakMsg.WriteCoord(3); // Size
            breakMsg.WriteCoord(3); // Size
            breakMsg.WriteCoord(0); // Gib vel pos Forward/Back
            breakMsg.WriteCoord(0); // Gib vel pos Left/Right
            breakMsg.WriteCoord(0); // Gib vel pos Up/Down
            breakMsg.WriteByte(10); // Gib random speed and direction
            breakMsg.WriteShort(g_EngineFuncs.ModelIndex(strRobogruntModelChromegibs));
            breakMsg.WriteByte(3); // Count
            breakMsg.WriteByte(10); // Lifetime
            breakMsg.WriteByte(1); // Sound Flags
            breakMsg.End();
    }

    void StartResourceRefund(CBasePlayer@ pPlayer)
    {
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;
            
        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        m_flRefundAmount = float(resources['current']); // Store current energy
        resources['current'] = 0; // Empty energy
        
        if(m_flRefundAmount > 0)
        {
            float refundPerTick = m_flRefundAmount / REFUND_TIME;
            g_Scheduler.SetInterval("BarrierRefund", REFUND_INTERVAL, int(REFUND_TIME), steamID, refundPerTick);
        }
    }
}

void BarrierRefund(string steamID, float refundAmount)
{
    if(!g_PlayerClassResources.exists(steamID))
        return;
        
    dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
    if(resources !is null)
    {
        float current = float(resources['current']);
        float maxEnergy = float(resources['max']);
        resources['current'] = Math.min(current + refundAmount, maxEnergy);
    }
}