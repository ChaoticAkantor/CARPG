string strBloodlustStartSound = "garg/gar_pain1.wav";
string strBloodlustEndSound = "player/breathe2.wav";
string strBloodlustHitSound = "debris/bustflesh1.wav";
string strBloodlustActiveSound = "player/heartbeat1.wav";
string strBloodlustSprite = "sprites/saveme.spr";

const Vector BLOODLUST_COLOR = Vector(255, 0, 0); // Red glow.

dictionary g_PlayerBloodlusts;

class BloodlustData
{
    private bool m_bActive = false;
    private float m_flBloodlustEnergyDrainInterval = 0.5f; // Interval to remove energy.
    private float m_flBloodlustEnergyCost = 1.0f; // Energy drain per interval.
    private float m_flBaseDamageBonus = 0.50f; // Base damage increase at lowest health.
    private float m_flDamageBonusPerLevel = 0.05f; // Bonus damage scaling per level.
    private float m_flBaseDamageLifesteal = 0.25f; // % Base damage dealt returned as health, reduced when bloodlust is not active.
    private float m_flLifestealPerLevel = 0.02f; // % Increase lifesteal per level.
    private float m_flEnergysteal = 0.05f; // % Energy steal, doubled when bloodlust is not active.
    private float m_flToggleCooldownBloodlust = 0.5f; // Cooldown between toggles.
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private ClassStats@ m_pStats = null;

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }
    
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetEnergyCost() { return m_flBloodlustEnergyCost; }
    float GetEnergySteal() { return (m_flEnergysteal * 100); }
    float GetLowHPDMGBonus() { return (m_flDamageBonusPerLevel * m_pStats.GetLevel()) * 100; }

    float GetDamageBonus(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return 0.0f;
            
        float bonus = m_flBaseDamageBonus;
        
        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();
            bonus *= (1.0f + (level * m_flDamageBonusPerLevel));
        }
        
        // Calculate missing health percentage.
        float maxHealth = pPlayer.pev.max_health;
        float missingHealth = maxHealth - pPlayer.pev.health;
        float missingHealthPercent = (missingHealth / maxHealth) * 100.0f;
        
        if(!m_bActive)
            return bonus * (missingHealthPercent / 100.0f); // Apply bonus per % of missing health (1:1 ratio) when bloodlust is not active.
        else
            return bonus * (missingHealthPercent / 50.0f); // Apply bonus per % of missing health (2:1 ratio) when bloodlust is active.
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
            // Check energy - require FULL energy to activate.
            if(g_PlayerClassResources.exists(steamID))
            {
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                if(resources !is null)
                {
                    float currentEnergy = float(resources['current']);
                    float maxEnergy = float(resources['max']);
                    
                    if(currentEnergy < maxEnergy)
                    {
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Bloodlust Recharging...\n");
                        return;
                    }
                }
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
            DeactivateBloodlust(pPlayer);
        }
        
        m_flLastToggleTime = currentTime;
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
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastDrainTime >= m_flBloodlustEnergyDrainInterval) // Interval for energy drain.
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerClassResources.exists(steamID))
            {
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                if(resources !is null)
                {
                    float current = float(resources['current']);
                    current -= m_flBloodlustEnergyCost; // Energy Drain.
                    
                    if(current <= 0)
                    {
                        current = 0;
                        DeactivateBloodlust(pPlayer); // Deactivate if we run out of energy.
                    }
                    
                    resources['current'] = current;
                }
            }

            m_flLastDrainTime = currentTime;
        }
    }

    float GetLifestealAmount()
    {
        float baseAmount = m_flBaseDamageLifesteal;
        
        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();

            // If bloodlust is active, double the lifesteal.
            if(!m_bActive)
                baseAmount *= (1.0f + (level * m_flLifestealPerLevel));
            else
                baseAmount *= (1.0f + (level * m_flLifestealPerLevel)) * 2.0f;
        }
            
        return baseAmount;
    }

    float GetEnergystealAmount()
    {
        float baseAmount = m_flEnergysteal;
        
        // Check if bloodlust is active, double the energy steal.
        if(m_bActive)
            baseAmount *= 2.0f;

        //if(m_pStats !is null)
        //{
        //    int level = m_pStats.GetLevel();
        //    baseAmount *= (1.0f + (level * m_flEnergysteal));
        //}
            
        return baseAmount;
    }

    float ProcessLifesteal(CBasePlayer@ pPlayer, float damageDealt)
    {
        if(pPlayer is null)
            return 0.0f;

        if(m_pStats is null)
            return 0.0f;

        if(!pPlayer.IsAlive())
        {
            DeactivateBloodlust(pPlayer);
            return 0.0f;
        }

        float flLifestealMult = GetLifestealAmount();
        float flHealAmount = damageDealt * flLifestealMult;

        pPlayer.pev.health = Math.min(pPlayer.pev.health + flHealAmount, pPlayer.pev.max_health);
        
        ApplyLifestealEffect(pPlayer); // Visual effect for healing from lifesteal.
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBloodlustHitSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);

        return flHealAmount;
    }

    float ProcessEnergySteal(CBasePlayer@ pPlayer, float damageDealt)
    {
        if(pPlayer is null)
            return 0.0f;

        // Check for valid stats
        if(m_pStats is null)
            return 0.0f;

        // Check if player died
        if(!pPlayer.IsAlive())
        {
            DeactivateBloodlust(pPlayer);
            return 0.0f;
        }

        float flEnergyStealMult = GetEnergystealAmount();
        float flGainAmount = damageDealt * flEnergyStealMult;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerClassResources.exists(steamID))
            {
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                if(resources !is null)
                {
                    float flCurrentEnergy = float(resources['current']);
                    float flMaxEnergy = float(resources['max']);

                    flCurrentEnergy = Math.min(flCurrentEnergy + flGainAmount, flMaxEnergy); // Add energy to variable, but don't exceed max.

                    resources['current'] = flCurrentEnergy; // Add back to energy.
                }
            }

        return flGainAmount;
    }

    void ApplyLifestealEffect(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;

        Vector pos = pPlayer.pev.origin;
        Vector mins = pos - Vector(16, 16, 0);
        Vector maxs = pos + Vector(16, 16, 64);

        NetworkMessage bubbleMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
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
        NetworkMessage msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
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