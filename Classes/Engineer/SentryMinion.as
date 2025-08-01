string strSentryCreate = "weapons/mine_deploy.wav";
string strSentryDestroy = "turret/tu_die.wav";

// Sentry Models
string strSentryModel = "models/sentry.mdl";
string strSentryGibs = "models/computergibs.mdl";

dictionary g_PlayerSentries;

class SentryData
{
    private EHandle m_hSentry;
    private bool m_bIsActive = false;
    private float m_flBaseHealth = 200.0; // Base health of the sentry.
    private float m_flHealthScale = 0.50; // Health scaling per level.
    private float m_flDamageScale = 0.04; // Damage scaling per level.
    private float m_flRadius = 8000.0; // Radius in which the sentry can heal players.
    private float m_flBaseHealAmount = 1.0; // Base healing per second.
    private float m_flHealScale = 0.06f; // Healing scaling per level.
    private float m_flSelfHealModifier = 3.0f; // How much the sentry's self healing is modified.
    private float m_flEnergyDrain = 1.0; // Energy drain per second.
    private float m_flDrainInterval = 1.0f; // Drain interval in seconds.
    private float m_flNextDrain = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flToggleCooldown = 1.0f;
    private float m_flNextHeal = 0.0f;
    private float m_flHealInterval = 1.0f;
    private float m_flNextVisualUpdate = 0.0f;
    private float m_flVisualUpdateInterval = 1.0f; // Time between visual updates. Same as heal rate.
    private Vector m_vAuraColor = Vector(0, 255, 0); // Green color for healing.


    private ClassStats@ m_pStats = null;

    bool IsActive() 
    { 
        // First check if we think we're active.
        if(!m_bIsActive)
            return false;
            
        // Then verify sentry exists and is alive.
        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry is null || !pSentry.IsAlive())
        {
            // Auto-cleanup if sentry is invalid.
            m_bIsActive = false;
            m_hSentry = null;
            return false;
        }

        return true;
    }
    bool HasStats() { return m_pStats !is null; }
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    CBaseEntity@ GetSentryEntity()
    {
        return m_hSentry.GetEntity();
    }

    void ToggleSentry(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
            return;

        m_flLastToggleTime = currentTime;

        if(m_bIsActive)
        {
            DestroySentry(pPlayer);
            return;
        }

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;

        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        float current = float(resources['current']);
        float maximum = float(resources['max']);

        // Only allow sentry to be deployed at maximum battery.
        if(current < maximum)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry is not charged!\n");
            return;
        }

        SpawnSentry(pPlayer);
    }

    private void SpawnSentry(CBasePlayer@ pPlayer)
    {
        Vector vecSrc = pPlayer.GetGunPosition();
        Vector spawnForward, spawnRight, spawnUp;
        g_EngineFuncs.AngleVectors(pPlayer.pev.v_angle, spawnForward, spawnRight, spawnUp);
        
        vecSrc = vecSrc + (spawnForward * 64);
        vecSrc.z -= 32;

        float scaledHealth = GetScaledHealth();
        
        dictionary keys;
        keys["origin"] = vecSrc.ToString();
        keys["angles"] = Vector(0, pPlayer.pev.angles.y, 0).ToString();
        keys["targetname"] = "_sentry_" + pPlayer.entindex();
        keys["displayname"] = string(pPlayer.pev.netname) + "'s Sentry";
        keys["health"] = string(scaledHealth);
        keys["scale"] = "1"; // Size of the sentry.
        keys["friendly"] = "1"; // Force friendly.
        keys["spawnflag"] = "33"; // 32 (active) + 1 (START_ON) combined
        keys["triggercondition"] = "1"; // Force trigger condition to See Player, Mad at player.
        keys["is_player_ally"] = "1";

        CBaseEntity@ pSentry = g_EntityFuncs.CreateEntity("monster_sentry", keys, true);
        if(pSentry !is null)
        {
            pSentry.pev.renderfx = kRenderFxGlowShell;
            pSentry.pev.rendermode = kRenderNormal;
            pSentry.pev.renderamt = 1;
            pSentry.pev.rendercolor = Vector(20, 255, 20); // Bright green.

            g_EntityFuncs.DispatchSpawn(pSentry.edict());

            //@pSentry.pev.owner = @pPlayer.edict(); // Try set sentry owner to player.

            m_hSentry = EHandle(pSentry);
            m_bIsActive = true;
            
            g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_WEAPON, strSentryCreate, 1.0f, ATTN_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry deployed!\n");
        }
    }

    void DestroySentry(CBasePlayer@ pPlayer)
    {
        if(!m_bIsActive)
            return;

        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry !is null)
        {
            pSentry.Killed(pPlayer.pev, GIB_ALWAYS);
            g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_WEAPON, strSentryDestroy, 1.0f, ATTN_NORM);
            
            // Drain all energy when manually destroyed.
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerClassResources.exists(steamID))
            {
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                resources['current'] = 0.0f;
            }
        }

        m_bIsActive = false;
        m_hSentry = null;
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry destroyed!\n");
    }

    void Update(CBasePlayer@ pPlayer)
    {
        if(!m_bIsActive || pPlayer is null)
            return;

        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry is null || !pSentry.IsAlive())
        {
            m_bIsActive = false;
            m_hSentry = null;

            // If sentry died naturally, drain all current energy.
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerClassResources.exists(steamID))
            {
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                resources['current'] = 0.0f;
            }
            return;
        }

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(g_PlayerClassResources.exists(steamID))
        {
            float currentTime = g_Engine.time;
            if(currentTime >= m_flNextDrain)
            {
                m_flNextDrain = currentTime + m_flDrainInterval;
                
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                float current = float(resources['current']);
                float drainAmount = GetEnergyDrain();
                
                // Only drain if we have energy
                if(current > 0)
                {
                    // Don't let it go below 0
                    if(current - drainAmount < 0)
                        drainAmount = current;
                        
                    current -= drainAmount;
                    resources['current'] = current;
                    
                    UpdateVisualEffect(pPlayer);

                    // Only heal if we have energy
                    if(current > 0)
                    {
                        SentryHeal(pSentry);
                    }
                }
                
                // Destroy sentry if out of energy
                if(current <= 0)
                {
                    DestroySentry(pPlayer);
                    return;
                }

                // Check if sentry has gained a frag.
                if(pSentry.pev.frags > 0)
                {
                    // Add frag to player.
                    pPlayer.pev.frags += 1;
                    // Reset sentry's frag counter.
                    pSentry.pev.frags = 0;
                }
            }
        }
    }

    float GetScaledHealAmount()
    {
        if(!HasStats() || m_pStats is null)
            return m_flBaseHealAmount;

        float level = float(m_pStats.GetLevel());
        float healAmount = m_flBaseHealAmount * (1.0f + (level * m_flHealScale));

        return healAmount;
    }

    float GetHealAmount()
    {
        return GetScaledHealAmount();
    }

    private void SentryHeal(CBaseEntity@ pSentry)
    {
        float currentTime = g_Engine.time;
        if(currentTime < m_flNextHeal)
            return;
            
        m_flNextHeal = currentTime + m_flHealInterval;
        float healAmount = GetHealAmount();

        // The sentry will heal itself also (silently).
        if(pSentry.pev.health < pSentry.pev.max_health)
        {
            // Sentry heals itself for twice the heal amount.
            pSentry.pev.health = Math.min(pSentry.pev.health + (healAmount * m_flSelfHealModifier), pSentry.pev.max_health);

            ApplyHealEffect(pSentry);
        }

        for(int i = 1; i <= g_Engine.maxClients; i++)
        {
            CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex(i);
            if(pTarget !is null && pTarget.IsConnected() && pTarget.IsAlive())
            {
                float distance = (pTarget.pev.origin - pSentry.pev.origin).Length();
                if(distance <= m_flRadius)
                {
                    if(pTarget.pev.health < pTarget.pev.max_health)
                    {
                        pTarget.pev.health = Math.min(pTarget.pev.health + healAmount, pTarget.pev.max_health);

                        ApplyHealEffect(pTarget); // Do heal effect.

                        // Play heal sound later possibly.
                    }
                }
            }
        }
    }

    private void ApplyHealEffect(CBaseEntity@ target)
    {
        if(target is null)
            return;

        Vector pos = target.pev.origin;
        Vector mins = pos - Vector(16, 16, 0);
        Vector maxs = pos + Vector(16, 16, 64);

        // Bubbles Effect.
        NetworkMessage aura2msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            aura2msg.WriteByte(TE_BUBBLES);
            aura2msg.WriteCoord(mins.x);
            aura2msg.WriteCoord(mins.y);
            aura2msg.WriteCoord(mins.z);
            aura2msg.WriteCoord(maxs.x);
            aura2msg.WriteCoord(maxs.y);
            aura2msg.WriteCoord(maxs.z);
            aura2msg.WriteCoord(80.0f); // Height of the bubble effect
            aura2msg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraEffectSprite));
            aura2msg.WriteByte(18); // Count
            aura2msg.WriteCoord(6.0f); // Speed
            aura2msg.End();
    }

    private void UpdateVisualEffect(CBasePlayer@ pPlayer)
    {
        if (!m_bIsActive || pPlayer is null)
            return;
            
        float currentTime = g_Engine.time;
        if(currentTime < m_flNextVisualUpdate)
            return;

        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry is null)
            return;
        
        m_flNextVisualUpdate = currentTime + m_flVisualUpdateInterval;

        Vector pos = pSentry.pev.origin;
        Vector mins = pos - Vector(16, 16, 0);
        Vector maxs = pos + Vector(16, 16, 64);
        
        // Beam cylinder effect.
        NetworkMessage auramsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, pos);
            auramsg.WriteByte(TE_BEAMCYLINDER);
            auramsg.WriteCoord(pos.x);
            auramsg.WriteCoord(pos.y);
            auramsg.WriteCoord(pos.z);
            auramsg.WriteCoord(pos.x);
            auramsg.WriteCoord(pos.y);
            auramsg.WriteCoord(pos.z + 24); // Height.
            auramsg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraSprite));
            auramsg.WriteByte(0); // Starting frame.
            auramsg.WriteByte(16); // Frame rate.
            auramsg.WriteByte(5); // Life.
            auramsg.WriteByte(32); // Width.
            auramsg.WriteByte(0); // Noise.
            auramsg.WriteByte(int(m_vAuraColor.x));
            auramsg.WriteByte(int(m_vAuraColor.y));
            auramsg.WriteByte(int(m_vAuraColor.z));
            auramsg.WriteByte(128); // Brightness.
            auramsg.WriteByte(0); // Scroll speed.
            auramsg.End();

        // Bubbles Effect.
        NetworkMessage aura2msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            aura2msg.WriteByte(TE_BUBBLES);
            aura2msg.WriteCoord(mins.x);
            aura2msg.WriteCoord(mins.y);
            aura2msg.WriteCoord(mins.z);
            aura2msg.WriteCoord(maxs.x);
            aura2msg.WriteCoord(maxs.y);
            aura2msg.WriteCoord(maxs.z);
            aura2msg.WriteCoord(80.0f); // Height of the bubble effect
            aura2msg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraEffectSprite));
            aura2msg.WriteByte(18); // Count
            aura2msg.WriteCoord(6.0f); // Speed
            aura2msg.End();
    }

    // Required getter methods for stats menu.
    float GetScaledHealth()
    {
        if(m_pStats is null)
            return m_flBaseHealth;

        return m_flBaseHealth * (1.0f + (m_pStats.GetLevel() * m_flHealthScale));
    }

    float GetHealRadius()
    {
        if(!HasStats() || m_pStats is null)
            return m_flRadius;

        float radius = m_flRadius;

        return radius;
    }

    float GetEnergyDrain()
    {
        if(!HasStats() || m_pStats is null)
            return m_flEnergyDrain;

        float drain = m_flEnergyDrain;

        return drain;
    }

    float GetScaledDamage()
    {
        if(m_pStats is null)
            return 1.0f;

        return 1.0f + (m_pStats.GetLevel() * m_flDamageScale);
    }
}

void CheckSentries()
{   
    for(int i = 1; i <= g_Engine.maxClients; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            
            if(!g_PlayerSentries.exists(steamID))
            {
                SentryData data;
                @g_PlayerSentries[steamID] = data;
            }

            SentryData@ sentry = cast<SentryData@>(g_PlayerSentries[steamID]);
            if(sentry !is null)
            {
                if(g_PlayerRPGData.exists(steamID))
                {
                    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                    if(data !is null && data.GetCurrentClass() != PlayerClass::CLASS_ENGINEER)
                    {
                        if(sentry.IsActive())
                            sentry.DestroySentry(pPlayer);
                        continue;
                    }
                    else if(!sentry.HasStats())
                    {
                        sentry.Initialize(data.GetCurrentClassStats());
                    }
                }

                sentry.Update(pPlayer);
            }
        }
    }
}