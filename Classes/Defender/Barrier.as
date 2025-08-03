string strBarrierToggleSound = "debris/glass2.wav";
string strBarrierHitSound = "debris/glass1.wav";
string strBarrierBreakSound = "debris/bustglass2.wav";
string strBarrierActiveSound = "ambience/alien_powernode.wav";

const Vector BARRIER_COLOR = Vector(130, 200, 255); // R G B

dictionary g_PlayerBarriers; // Dictionary to store player Barrier data.

class BarrierData
{
    private ClassStats@ m_pStats = null;
    private bool m_bActive = false;
    private float m_flBaseDamageReduction = 1.00f; // Base damage reduction.
    private float m_flToggleCooldown = 0.5f; // 1 second cooldown between toggles.
    private float m_flBarrierDamageToEnergyMult = 1.0f; // Damage taken to energy drain factor. % damage dealt to shield, lower = tougher shield.
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flGlowUpdateInterval = 0.1f;

    private float m_flRefundAmount = 0.0f;
    private float m_flRefundTimeLeft = 0.0f;
    private float m_flStoredEnergy = 0.0f;
    private float m_flRefundTime = 5.0f; // Time to refund energy, total / this.
    private float m_flRefundInterval = 1.0f; // Intervals to give refunded energy.
    private float m_flLastRefundStartTime = 0.0f; // Track when the last refund started

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }
    ClassStats@ GetStats() {return m_pStats;}
    float GetBaseDamageReduction() { return m_flBaseDamageReduction; }
    float GetDamageToEnergyMultiplier() { return m_flBarrierDamageToEnergyMult; }
    
    void Initialize(ClassStats@ stats)
    {
        @m_pStats = stats;
    }

    void ToggleBarrier(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
        {
            return;
        }

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Barrier on cooldown!\n");
            return;
        }

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
        {
            return;
        }
            
        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        if(resources is null)
        {
            return;
        }

        if(!m_bActive)
        {
            // Check energy - require FULL energy to activate
            float currentEnergy = float(resources['current']);
            float maxEnergy = float(resources['max']);
            
            if(currentEnergy < maxEnergy)
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield recharging...\n");
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
            StartResourceRefund(pPlayer); // Start refund.

            // Deactivate Manually.
            m_bActive = false;
            ToggleGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.0f, ATTN_NORM, SND_STOP, 100);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierBreakSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Refunded!\n"); // MANUALLY SHATTERED.
            EffectBarrierShatter(pPlayer.pev.origin);
        }

        m_flLastToggleTime = currentTime;
    }

    float GetDamageReduction()
    {
        if(m_pStats is null)
            return 0.0f;
            
        return m_flBaseDamageReduction; // Now always 100% damage reduction to player.
    }

    void Update(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        ToggleGlow(pPlayer); // Handle glow state.

        if(!pPlayer.IsAlive()) // Deactivate if player dies.
        {
            DeactivateBarrier(pPlayer);
            ToggleGlow(pPlayer);
            return;
        }

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;
    
        // Energy is only drained when taking damage, handled in DrainEnergy method
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

    void DeactivateBarrier(CBasePlayer@ pPlayer) // Called when DESTROYED, NOT MANUALLY DEACTIVATED.
    {
        if(m_bActive)
        {
            m_bActive = false;
            ToggleGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.0f, ATTN_NORM, SND_STOP, 100); // Stop looping sound here too.
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierBreakSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Shattered!\n"); // SHATTERED - DESTROYED.
            EffectBarrierShatter(pPlayer.pev.origin);
        }
        
        // Cancel any ongoing refunds
        if(pPlayer !is null)
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            CancelRefunds(steamID);
        }
    }
    
    bool IsRefundValid(float startTime)
    {
        return startTime >= m_flLastRefundStartTime;
    }
    
    void CancelRefunds(string steamID)
    {
        // Update the last refund start time to invalidate any current refunds
        m_flLastRefundStartTime = g_Engine.time + 0.1f; // Add a small buffer to ensure all new refunds have a newer timestamp
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
        
        // Update the refund start time
        m_flLastRefundStartTime = g_Engine.time;
        
        if(m_flRefundAmount > 0)
        {
            float refundPerTick = m_flRefundAmount / m_flRefundTime;
            g_Scheduler.SetInterval("BarrierRefund", m_flRefundInterval, int(m_flRefundTime), steamID, refundPerTick, m_flLastRefundStartTime);
        }
    }
}

void BarrierRefund(string steamID, float refundAmount, float startTime)
{
    // Check if this refund is still valid
    if(g_PlayerBarriers.exists(steamID))
    {
        BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
        if(barrier !is null && barrier.IsRefundValid(startTime))
        {
            // Check if the player is still playing as Defender
            if(g_PlayerRPGData.exists(steamID))
            {        
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_DEFENDER)
                {
                    if(g_PlayerClassResources.exists(steamID))
                    {
                        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                        if(resources !is null)
                        {
                            float current = float(resources['current']);
                            float maxEnergy = float(resources['max']);
                            resources['current'] = Math.min(current + refundAmount, maxEnergy);
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we get here, the refund should be canceled
    g_Scheduler.RemoveTimer(g_Scheduler.GetCurrentFunction());
}