string strHealAuraToggleSound = "tfc/items/protect3.wav"; // Aura on/off sound.
string strHealAuraActiveSound = "ambience/alien_beacon.wav"; // Aura active looping sound.
string strHealSound = "player/heartbeat1.wav"; // Aura heal hit sound.
string strHealAuraSprite = "sprites/zbeam2.spr"; // Aura sprite.
string strHealAuraEffectSprite = "sprites/cnt1.spr"; // Aura healing sprite.

// Defines for stat menu.
float g_flHealAuraBase = 10.0f; // Base heal amount.
float g_flHealAuraBonus = 0.5f; // Bonus per level, variable only used for calculation.
float g_flHealAuraRadius = 640.0f; // Radius of the aura, does not scale currently.
int g_iHealAuraDrain = 5; // Energy drain per interval.
float g_flHealAuraInterval = 1.0f; // Time between heals.

// For stat menu.
float flHealAuraHealBase = g_flHealAuraBase;
float flHealAuraHealBonus = 0.0f;

dictionary g_HealingAuras;

void CheckHealAura() 
{
    const int iMaxPlayers = g_Engine.maxClients;
    for (int i = 1; i <= iMaxPlayers; ++i) 
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if (pPlayer !is null && pPlayer.IsConnected()) 
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if (!g_HealingAuras.exists(steamID))
            {
                HealingAura aura;
                @g_HealingAuras[steamID] = aura;
            }
            HealingAura@ aura = cast<HealingAura@>(g_HealingAuras[steamID]);
            if (aura !is null)
            {
                aura.Update(pPlayer);
            }
        }
    }
}

class HealingAura 
{
    private bool m_bIsActive = false;
    private float m_flRadius = g_flHealAuraRadius; // Radius of the aura.
    private float m_flBaseHealAmount = g_flHealAuraBase; // Derived from a global variable, so that we can use it in the stat menu.
    private float m_flHealScaling = g_flHealAuraBonus; // % per level scaling.
    private float m_flHeal = 0.0f; // Total Heal amount.
    private int m_iDrainAmount = g_iHealAuraDrain;
    private float m_flLastToggleTime = 0.0f;
    private float m_flToggleCooldown = 0.5f;
    private float m_flLastHealTime = 0.0f;
    private float m_flHealInterval = 1.0f;

    private float m_flNextVisualUpdate = 0.0f;
    private float m_flVisualUpdateInterval = m_flHealInterval;
    private Vector m_vAuraColor = Vector(0, 255, 0); // Green color for healing.

    private float m_flGlowDuration = 0.25f;
    private Vector m_vGlowColor = Vector(0, 255, 0);

    private ClassStats@ m_pStats = null;

    private Vector m_vHealColor = Vector(0, 255, 0);

    private float m_flNextGlowUpdate = 0.0f;
    private float m_flGlowUpdateInterval = 0.1f;

    bool IsActive() { return m_bIsActive; }
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    
    void ToggleAura(CBasePlayer@ pPlayer)
    {
        if (pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if (currentTime - m_flLastToggleTime < m_flToggleCooldown)
            return;

        m_bIsActive = !m_bIsActive;
        string message = m_bIsActive ? "Healing Aura Activated!\n" : "Healing Aura Deactivated!\n";
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, message);

        if (m_bIsActive) 
        {
            ApplyGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strHealAuraToggleSound, 1.0, ATTN_NORM, SND_FORCE_SINGLE, PITCH_NORM);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strHealAuraActiveSound, 0.5f, ATTN_NORM, SND_FORCE_LOOP);
        }
        else
        {
            RemoveAuraGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strHealAuraActiveSound, 0.0f, ATTN_NORM, SND_STOP);
        }

        m_flLastToggleTime = currentTime;
    }
    
    void ResetAura(CBasePlayer@ pPlayer)
    {
        if(m_bIsActive)
        {
            m_bIsActive = false;
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strHealAuraActiveSound, 0.0f, ATTN_NORM, SND_STOP);
            UpdateVisualEffect(pPlayer);
        }
        m_flLastToggleTime = 0.0f;
        m_flLastHealTime = 0.0f;
        m_flNextVisualUpdate = 0.0f;
    }

    void Update(CBasePlayer@ pPlayer) 
    {
        if (pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
        {
            if(m_bIsActive) 
            {
                m_bIsActive = false;
                UpdateVisualEffect(pPlayer);
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Healing Aura Deactivated!\n");
                g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strHealAuraActiveSound, 0.0f, ATTN_NORM, SND_STOP);
            }
            return;
        }

        if (m_pStats is null)
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if (g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if (data !is null && data.GetCurrentClass() == PlayerClass::CLASS_MEDIC)
                {
                    @m_pStats = data.GetCurrentClassStats();
                }
            }
        }

        // Update healing bonus for stats menu
        GetScaledHealAmount();

        if (m_bIsActive) 
        {
            ProcessHealing(pPlayer);
            UpdateVisualEffect(pPlayer);
            
            // Update activator's glow effect
            float currentTime = g_Engine.time;
            if (currentTime >= m_flNextGlowUpdate)
            {
                ApplyGlow(pPlayer);
                m_flNextGlowUpdate = currentTime + m_flGlowUpdateInterval;
            }
        }
    }

    private void UpdateVisualEffect(CBasePlayer@ pPlayer)
    {
        if (!m_bIsActive || pPlayer is null)
            return;
            
        float currentTime = g_Engine.time;
        if (currentTime < m_flNextVisualUpdate)
            return;
        
        m_flNextVisualUpdate = currentTime + m_flVisualUpdateInterval;
        
        Vector origin = pPlayer.pev.origin;
        NetworkMessage msg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            msg.WriteByte(TE_BEAMCYLINDER);
            msg.WriteCoord(origin.x);
            msg.WriteCoord(origin.y);
            msg.WriteCoord(origin.z);
            msg.WriteCoord(origin.x);
            msg.WriteCoord(origin.y);
            msg.WriteCoord(origin.z + m_flRadius);
            msg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraSprite));
            msg.WriteByte(0); // Starting frame of sprite.
            msg.WriteByte(0); // Frame rate - Has no effect.
            msg.WriteByte(10); // Life.
            msg.WriteByte(30); // Width.
            msg.WriteByte(0); // Noise - Has no effect.
            msg.WriteByte(uint8(m_vAuraColor.x)); // Red.
            msg.WriteByte(uint8(m_vAuraColor.y)); // Green.
            msg.WriteByte(uint8(m_vAuraColor.z)); // Blue.
            msg.WriteByte(150); // Alpha.
            msg.WriteByte(0); // Speed.
        msg.End();
    }

    private void ProcessHealing(CBasePlayer@ pPlayer) 
    {
        float currentTime = g_Engine.time;
        if (currentTime - m_flLastHealTime < m_flHealInterval)
            return;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;
            
        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        int current = int(resources['current']);
        
        if(current < m_iDrainAmount)
        {
            m_bIsActive = false;
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Healing Aura Deactivated!\n");
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strHealAuraActiveSound, 0.0f, ATTN_NORM, SND_STOP);
            RemoveAuraGlow(pPlayer);
            return;
        }

        current -= m_iDrainAmount;
        resources['current'] = current;

        m_flLastHealTime = currentTime;

        // Check if we have enough energy for potential revival.
        int reviveCost = m_iDrainAmount * 2;
        
        Vector playerOrigin = pPlayer.pev.origin;
        CBaseEntity@ pEntity = null;
        while((@pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, playerOrigin, m_flRadius, "*", "classname")) !is null)
        {
            // Check for dead players first.
            if(!pEntity.IsAlive())
            {
                // Only attempt revival if we have enough energy.
                if(current >= reviveCost)
                {
                    bool canRevive = false;
                    if(pEntity.IsPlayer())
                    {
                        canRevive = true;  // Always try to revive players.
                    }
                    else
                    {
                        // Check if monster is friendly before attempting revival.
                        CBaseMonster@ pMonster = cast<CBaseMonster@>(pEntity);
                        canRevive = (pMonster !is null && pMonster.IsPlayerAlly());
                    }

                    if(canRevive)
                    {
                        if(pEntity.IsPlayer())
                        {
                            CBasePlayer@ pTarget = cast<CBasePlayer@>(pEntity);
                            if(pTarget !is null)
                                pTarget.Revive();
                        }
                        else
                        {
                            // Revival for NPCs.
                            CBaseMonster@ pMonster = cast<CBaseMonster@>(pEntity);
                            if(pMonster !is null)
                            {
                                pMonster.Revive(); // Cbasemonster revival.
                                pMonster.pev.health = pMonster.pev.max_health * 0.5; // Set health to 50%.
                            }
                        }
                        
                        current -= reviveCost; // Revival cost.
                        resources['current'] = current;
                        
                        pPlayer.pev.frags += 5; // Award frags for reviving.
                        ApplyHealEffect(pEntity);
                        g_SoundSystem.EmitSoundDyn(pEntity.edict(), CHAN_ITEM, strHealSound, 1.0f, ATTN_NORM, SND_FORCE_SINGLE, PITCH_NORM);
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, pEntity.IsPlayer() ? "Revived " + pEntity.pev.netname + "!\n" : "Revived " + pEntity.pev.classname + "!\n");
                        continue;
                    }
                }
            }

            // Skip if dead or at full health.
            if(!pEntity.IsAlive() || pEntity.pev.health >= pEntity.pev.max_health)
                continue;

            // Check if target is friendly.
            if(pEntity.IsPlayer())
            {
                // Always heal other players.
                CBasePlayer@ pTarget = cast<CBasePlayer@>(pEntity);
                if(pTarget is null)
                    continue;
            }
            else
            {
                // Only heal friendly NPCs.
                CBaseMonster@ pMonster = cast<CBaseMonster@>(pEntity);
                if(pMonster is null || !pMonster.IsPlayerAlly())
                    continue;
            }

            float healAmount = GetScaledHealAmount();
            
            if(!pEntity.IsPlayer())
                healAmount *= 2.0f; // NPC's get healing modifier.

            // Process healing, effects and sounds.
            if(pEntity.pev.health < pEntity.pev.max_health)
            {
                pEntity.pev.health = Math.min(pEntity.pev.health + healAmount, pEntity.pev.max_health);
                pPlayer.pev.frags += 2; // Award frags for healing.
                
                ApplyHealEffect(pEntity);
                g_SoundSystem.EmitSoundDyn(pEntity.edict(), CHAN_ITEM, strHealSound, 0.6f, ATTN_NORM, SND_FORCE_SINGLE, PITCH_NORM);
            }
        }
    }

    private float GetScaledHealAmount()
    {
        if (m_pStats is null)
            return m_flBaseHealAmount;
            
        int level = m_pStats.GetLevel();
        m_flHeal = m_flBaseHealAmount + (float(level) * m_flHealScaling);
        flHealAuraHealBonus = m_flBaseHealAmount + (float(level) * m_flHealScaling) - flHealAuraHealBase; // For stat menu.
        return m_flHeal;
    }

    private void ApplyHealEffect(CBaseEntity@ target)
    {
        if(target is null)
            return;

        Vector origin = target.pev.origin;
        origin.z += 32; // Offset to center of entity.
        
        Vector endPoint = origin;
        endPoint.z += 10; // Trail moves upward.

        // Create sprite trail effect
        NetworkMessage msg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            msg.WriteByte(TE_SPRITETRAIL);
            msg.WriteCoord(origin.x);
            msg.WriteCoord(origin.y);
            msg.WriteCoord(origin.z);
            msg.WriteCoord(endPoint.x);
            msg.WriteCoord(endPoint.y);
            msg.WriteCoord(endPoint.z);
            msg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraEffectSprite));
            msg.WriteByte(8);  // Count.
            msg.WriteByte(3);  // Life in 0.1's.
            msg.WriteByte(1);  // Scale in 0.1's.
            msg.WriteByte(15); // Velocity along vector in 10's.
            msg.WriteByte(5);  // Random velocity in 10's.
        msg.End();
    }

    private void ApplyGlow(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;
            
        // Apply glow shell.
        pPlayer.pev.renderfx = kRenderFxGlowShell;
        pPlayer.pev.rendermode = kRenderNormal;
        pPlayer.pev.renderamt = 3; // Shell thickness.
        pPlayer.pev.rendercolor = m_vAuraColor;

        // Add dynamic light
        NetworkMessage msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            msg.WriteByte(TE_DLIGHT);
            msg.WriteCoord(pPlayer.pev.origin.x);
            msg.WriteCoord(pPlayer.pev.origin.y);
            msg.WriteCoord(pPlayer.pev.origin.z);
            msg.WriteByte(15); // Radius.
            msg.WriteByte(int(m_vAuraColor.x));
            msg.WriteByte(int(m_vAuraColor.y));
            msg.WriteByte(int(m_vAuraColor.z));
            msg.WriteByte(1); // Life in 0.1s.
            msg.WriteByte(0); // Decay rate.
        msg.End();
    }

    private void RemoveAuraGlow(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;
        
        pPlayer.pev.renderfx = kRenderFxNone;
        pPlayer.pev.rendermode = kRenderNormal;
        pPlayer.pev.renderamt = 255;
        pPlayer.pev.rendercolor = Vector(255, 255, 255);
    }
}

dictionary g_GlowResetData;

class GlowData
{
    int renderFX;
    int renderMode;
    Vector renderColor;
    float renderAmt;
}

// Reset glow function.
void ResetGlow(string targetId)
{
    if(!g_GlowResetData.exists(targetId))
        return;
        
    CBaseEntity@ target = g_EntityFuncs.Instance(atoi(targetId));
    if(target is null)
        return;
        
    GlowData@ data = cast<GlowData@>(g_GlowResetData[targetId]);
    if(data !is null)
    {
        target.pev.renderfx = data.renderFX;
        target.pev.rendermode = data.renderMode;
        target.pev.rendercolor = data.renderColor;
        target.pev.renderamt = data.renderAmt;
    }
    
    g_GlowResetData.delete(targetId);
}