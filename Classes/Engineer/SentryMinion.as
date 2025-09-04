string strSentryCreate = "weapons/mine_deploy.wav";
string strSentryRecall = "turret/tu_die.wav";

// Sentry Models.
string strSentryModel = "models/sentry.mdl";
string strSentryGibs = "models/computergibs.mdl";

// Sentry Sounds.
string strSentryFire = "weapons/hks_hl3.wav";
string strSentryPing = "turret/tu_ping.wav";
string strSentryActive = "turret/tu_active2.wav";
string strSentryDie = "turret/tu_die3.wav";
string strSentryDeploy = "turret/tu_deploy.wav";
string strSentrySpinUp = "turret/tu_spinup.wav";
string strSentrySpinDown = "turret/tu_spindown.wav";
string strSentrySearch = "turret/tu_search.wav";
string strSentryAlert = "turret/tu_alert.wav";

dictionary g_PlayerSentries;

class SentryData
{
    private EHandle m_hSentry;
    private bool m_bActive = false;
    private float m_flBaseHealth = 1000.0; // Base health of the sentry. Sentry seems to take considerably more damage, so health must scale very high!
    private float m_flHealthScale = 0.10; // Health scaling % per level.
    private float m_flDamageScale = 0.10; // Damage scaling % per level.
    private float m_flRadius = 8000.0; // Radius in which the sentry can heal players.
    private float m_flBaseHealAmount = 1.0; // Base healing per second.
    private float m_flHealScale = 0.18f; // Heal scaling % per level.
    private float m_flSelfHealModifier = 10.0f; // Sentry self-healing multiplier.
    private float m_flEnergyDrain = 1.0; // Energy drain per interval.
    private float m_flDrainInterval = 1.0f; // Energy drain interval in seconds.
    private float m_flRecallEnergyCost = 0.0f; // Energy % cost to recall.
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
        if(!m_bActive)
            return false;
        
        // Check if the handle is valid
        if(!m_hSentry.IsValid())
        {
            m_bActive = false;
            return false;
        }
            
        // Then verify sentry exists and is alive.
        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry is null || !pSentry.IsAlive())
        {
            m_bActive = false; // Skill is "inactive" if sentry doesnt exist or is dead.
            return false;
        }

        return true;
    }
    
    bool HasStats() { return m_pStats !is null; }
    ClassStats@ GetStats() { return m_pStats; }
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

    if(m_bActive)
    {
        DestroySentry(pPlayer);
        return;
    }

    // Check energy requirements for deployment.
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(!g_PlayerClassResources.exists(steamID))
        return;

    dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
    float current = float(resources['current']);
    float maximum = float(resources['max']);

    // Check energy - require FULL energy to activate.
    if(current < maximum)
    {
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry Recharging...\n");
        return;
    }

    SpawnSentry(pPlayer);
}

    void ApplyMinionGlow(CBaseEntity@ pMinion)
    {
        if(pMinion is null)
            return;

        // Apply the glowing effect.
        pMinion.pev.renderfx = kRenderFxGlowShell;
        pMinion.pev.rendermode = kRenderNormal;
        pMinion.pev.renderamt = 1;
        pMinion.pev.rendercolor = Vector(0, 255, 150); // Light Green.
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
        keys["spawnflags"] = "32"; // 32 (ACTIVE).
        keys["is_player_ally"] = "1"; // Force ally with player.

        CBaseEntity@ pSentry = g_EntityFuncs.CreateEntity("monster_sentry", keys, true);
        if(pSentry !is null)
        {
            ApplyMinionGlow(pSentry); // Apply glow effect before dispatch.

            g_EntityFuncs.DispatchSpawn(pSentry.edict()); // Dispatch the spawn.

            @pSentry.pev.owner = @pPlayer.edict(); // Set player as owner to stop collision.

            // Sentry won't wake unless touched or damaged, regardless of spawnflags. Gently encourage it.
            pSentry.TakeDamage(pPlayer.pev, pPlayer.pev, 0.0f, DMG_GENERIC);

            m_hSentry = EHandle(pSentry);

            g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_WEAPON, strSentryCreate, 1.0f, ATTN_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry Deployed!\n");

            m_bActive = true;
        }
    }

    void DestroySentry(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry !is null)
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            
            // Handle different destroy conditions.
            if(pSentry.pev.health <= 0)
            {
                // Remove all energy if killed by damage.
                if(g_PlayerClassResources.exists(steamID))
                {
                    dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                    resources['current'] = 0.0f;
                }
                g_EntityFuncs.Remove(pSentry);
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry Recalled!\n");
            }
            else
            {
                // Manual destruction - apply recall cost.
                if(g_PlayerClassResources.exists(steamID))
                {
                    dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                    float current = float(resources['current']);
                    float recallCost = current * m_flRecallEnergyCost; // Get recall cost as percentage of current total.
                    resources['current'] = current - recallCost;
                }
                
                //pSentry.Killed(pPlayer.pev, GIB_NEVER);
                g_EntityFuncs.Remove(pSentry); // Remove the sentry entity.
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sentry Recalled!\n");
                g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_WEAPON, strSentryRecall, 1.0f, ATTN_NORM);
            }
        }

        m_bActive = false;
        m_hSentry = null;
    }
    
    // Reset function to clean up any active sentries
    void Reset()
    {
        // Find the player index
        int playerIndex = -1;
        CBasePlayer@ pPlayer = null;
        
        if(m_hSentry.IsValid())
        {
            CBaseEntity@ pSentry = m_hSentry.GetEntity();
            if(pSentry !is null && pSentry.pev.owner !is null)
            {
                @pPlayer = cast<CBasePlayer@>(g_EntityFuncs.Instance(pSentry.pev.owner));
            }
        }
        
        // If we couldn't find the player from the sentry, try to find from stats
        if(pPlayer is null && m_pStats !is null)
        {
            for(int i = 1; i <= g_Engine.maxClients; i++)
            {
                CBasePlayer@ tempPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if(tempPlayer !is null && tempPlayer.IsConnected())
                {
                    string steamID = g_EngineFuncs.GetPlayerAuthId(tempPlayer.edict());
                    PlayerData@ playerData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                    if(playerData !is null && playerData.GetCurrentClassStats() is m_pStats)
                    {
                        @pPlayer = tempPlayer;
                        break;
                    }
                }
            }
        }
        
        if(pPlayer !is null)
        {
            DestroySentry(pPlayer);
        }
        else
        {
            // If we can't find the player, just remove the sentry directly
            // After a map change, the entity reference may be invalid
            g_Game.AlertMessage(at_console, "CARPG: Engineer Reset - Clearing sentry reference\n");
            
            if(m_hSentry.IsValid())
            {
                CBaseEntity@ pSentry = m_hSentry.GetEntity();
                if(pSentry !is null)
                {
                    g_EntityFuncs.Remove(pSentry);
                }
            }
            
            m_bActive = false;
            m_hSentry = null;
        }
    }

    void Update(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry is null || !pSentry.IsAlive())
        {
            DestroySentry(pPlayer);
            return;
        }

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(g_PlayerClassResources.exists(steamID))
        {
            float currentTime = g_Engine.time;
            
            SentryHeal(pSentry);
            UpdateVisualEffect(pPlayer);
            
            // Handle energy drain.
            if(currentTime >= m_flNextDrain)
            {
                m_flNextDrain = currentTime + m_flDrainInterval;
                
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                float current = float(resources['current']);
                float drainAmount = GetEnergyDrain();
                
                if(current > 0)
                {
                    if(current - drainAmount < 0)
                        drainAmount = current;
                    
                    current -= drainAmount;
                    resources['current'] = current;

                    if(current <= 0)
                    {
                        DestroySentry(pPlayer);
                        return;
                    }
                }

                // Handle frag transfer.
                if(pSentry.pev.frags > 0)
                {
                    pPlayer.pev.frags += 1;
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

        // The sentry should include itself when healing.
        if(pSentry.pev.health < pSentry.pev.max_health)
        {
            // Sentry self-healing is modified.
            pSentry.pev.health = Math.min(pSentry.pev.health + (healAmount * m_flSelfHealModifier), pSentry.pev.max_health);
        }

        ApplyRegenEffect(pSentry); // Do regen effect on sentry.

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
                    }

                    ApplyRegenEffect(pTarget); // Do regen effect on players.
                }
            }
        }
    }

    private void ApplyRegenEffect(CBaseEntity@ target)
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
        if (!m_bActive || pPlayer is null)
            return;
            
        float currentTime = g_Engine.time;
        if(currentTime < m_flNextVisualUpdate)
            return;

        CBaseEntity@ pSentry = m_hSentry.GetEntity();
        if(pSentry is null)
            return;
        
        m_flNextVisualUpdate = currentTime + m_flVisualUpdateInterval;

        // Ensure glow effect is maintained.
        ApplyMinionGlow(pSentry);

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

        // Return just the multiplier part, not including the base 1.0f, since that gets added in the MonsterTakeDamage hook.
        return (m_pStats.GetLevel() * m_flDamageScale);
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
                // Check for invalid entity references first
                if(sentry.IsActive())
                {
                    // Check if sentry entity is valid (this will reset active state if not)
                    if(!sentry.IsActive())
                    {
                        g_Game.AlertMessage(at_console, "CARPG: Found invalid Engineer sentry for player " + steamID + ", clearing reference\n");
                    }
                }
                
                // Check if player switched class
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