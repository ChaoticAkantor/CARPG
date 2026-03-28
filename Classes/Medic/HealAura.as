string strHealAuraToggleSound = "tfc/items/protect3.wav"; // Aura on/off sound.
string strHealAuraActiveSound = "ambience/alien_beacon.wav"; // Aura active looping sound.
string strHealSound = "player/heartbeat1.wav"; // Aura heal hit sound.
string strReviveSound = "items/suitchargeok1.wav"; // Aura revive sound.
string strHealAuraSprite = "sprites/zbeam6.spr"; // Aura sprite.
string strHealAuraEffectSprite = "sprites/saveme.spr"; // Aura healing sprite.
string strHealAuraPoisonEffectSprite = "sprites/tinyspit.spr"; // Poison damage sprite for enemies.
string strPoisonSound = "bullchicken/bc_spithit1.wav"; // Sound played when poison damages an enemy.

// Class names to skip during revival.
array<string> g_SkipRevivalClassNames = 
{
    "squadmaker",
    "monster_scientist_dead",
    "monster_barney_dead",
    "monster_hevsuit_dead",
    "monster_hgrunt_dead",
    "monster_human_grunt_ally_dead",
    "monster_otis_dead",
    "monster_scientist_dead"

};

// Matches CARPG CheckHealAura scheduler interval (ReviveTimerTick decrements per step).
const float flHealAuraSchedulerInterval = 0.1f;

string FormatHealAuraSecondsForHud(float t)
{
    t = Math.max(0.0f, t);
    int tenthsTotal = int(t * 10.0f + 0.5f);
    int whole = tenthsTotal / 10;
    int frac = tenthsTotal % 10;
    return "" + whole + "." + frac + "s";
}

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
                aura.ReviveTimerTick();
            }
        }
    }
}

class HealingAura 
{
    // Healing Aura.
    private bool m_bIsActive = false;
    private float m_flHealingRadius = 60.0f * 16; // // Radius of the healing aura (ft converted to units).
    private float m_flBaseHealAmount = 10.0f; // Base health restored, as a percentage of max health.
    private float m_flHealScalingAtMaxLevel = 2.0f; // Healing modifier at max level.
    private float m_flHealAuraReviveHealthPercent = 1.00f; // Health percent to revive at.
    private float m_flHealAuraReviveCooldown = 10.0f; // Minimum cooldown for revive at max level.
    private float m_flPoisonDamagePercent = 0.5f; // Modifier for poison damage dealt to enemies, scales from healing amount.
    private float m_flHealAuraInterval = 1.0f; // Time between heals/damage tick.

    // Energy costs.
    private int m_iDrainAmount = 1.0f; // Energy drained per interval tick.

    // Score bonuses.
    private int m_iHealFragBonus = 2; // Frags awarded for healing once.
    private int m_iReviveFragBonusPlayer = 6; // Frags awarded for reviving a player once.
    private int m_iReviveFragBonusMonster = 3; // Frags awarded for reviving an allied monster once.
    

    // Timers.
    private float m_flLastToggleTime = 0.0f;
    private float m_flToggleCooldown = 0.5f;
    private float m_flLastHealTime = 0.0f;
    private float m_flLastPoisonTime = 0.0f;
    private float m_flHealInterval = 1.0f;
    private float m_flCurrentReviveCooldown = 0.0f;
    private float m_flReviveGracePeriod = 1.0f;
    private float m_flReviveGraceEndTime = 0.0f;

    // Visual and vectors.
    private float m_flNextVisualUpdate = 0.0f;
    private float m_flVisualUpdateInterval = m_flHealAuraInterval; // Time between visual updates. Same as heal rate.
    private Vector m_vAuraColor = Vector(0, 255, 0); // Green color for healing.
    private float m_flGlowDuration = 0.25f;
    private Vector m_vGlowColor = Vector(0, 255, 0);

    private ClassStats@ m_pStats = null;

    private Vector m_vHealColor = Vector(0, 255, 0);
    private Vector m_vPoisonColor = Vector(0, 255, 0); // Poison color for enemies.

    bool IsActive() { return m_bIsActive; }
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    float GetHealingRadius() { return m_flHealingRadius; }
    float GetEnergyCost() { return m_iDrainAmount; }

    float GetReviveCooldown()
    { 
        if (m_pStats is null)
            return m_flHealAuraReviveCooldown; // Return base if no stats.

        float cooldown = m_flHealAuraReviveCooldown; // Start at minimum.

        int level = m_pStats.GetLevel();
        float cooldownPerLevel = m_flHealAuraReviveCooldown / g_iMaxLevel;
        cooldown += cooldownPerLevel * (g_iMaxLevel * 1.5 - level);

        return cooldown; 
    }

    float GetReviveCooldownRemaining() { return m_flCurrentReviveCooldown; }

    string GetReviveCooldownDisplay()
    {
        float maxCd = GetReviveCooldown();
        if(m_flCurrentReviveCooldown > 0.0f)
            return "[Revive: " + FormatHealAuraSecondsForHud(m_flCurrentReviveCooldown) + "]\n";
        return "[Revive: (Ready)]\n";
    }

    float GetPoisonDamageAmount()
    {
        return GetScaledHealAmount() * m_flPoisonDamagePercent;
    }

    float GetScaledHealAmount()
    {
        if (m_pStats is null)
            return m_flBaseHealAmount; // Return base if no stats.

        float healAmount = m_flBaseHealAmount; // Set base heal amount.
            
        int level = m_pStats.GetLevel();
        float bonusPerLevel = (m_flHealScalingAtMaxLevel * m_flBaseHealAmount) / g_iMaxLevel;
        healAmount += bonusPerLevel * level;

        return healAmount;
    }
    
    void ToggleAura(CBasePlayer@ pPlayer)
    {
        if (pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if (currentTime - m_flLastToggleTime < m_flToggleCooldown)
            return;

        if (!m_bIsActive)
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if (!g_PlayerClassResources.exists(steamID))
                return;
                
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            if (resources is null)
                return;

            float current = float(resources['current']);
            float maximum = float(resources['max']);
            
            // Check energy - require FULL energy to activate.
            //if (current < maximum)
            //{
                //g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Healing Aura Recharging...\n");
                //return;
            //}
        }

        m_bIsActive = !m_bIsActive;
        string message = m_bIsActive ? "Healing Aura On!\n" : "Healing Aura Off!\n";
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

        m_flLastToggleTime = 0.0f;
    }
    
    void DeactivateAura(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;

        if(m_bIsActive)
        {
            m_bIsActive = false;
            RemoveAuraGlow(pPlayer);
        }
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
        m_flReviveGraceEndTime = 0.0f;
    }

    void Update(CBasePlayer@ pPlayer) 
    {
        if (pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
        {
            if(m_bIsActive) 
            {
                m_bIsActive = false;
                UpdateVisualEffect(pPlayer);
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Healing Aura Off!\n");
                g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strHealAuraActiveSound, 0.0f, ATTN_NORM, SND_STOP);
                RemoveAuraGlow(pPlayer);
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

        if (m_bIsActive) 
        {
            ProcessHealing(pPlayer);
            ProcessPoisonDamage(pPlayer);
            UpdateVisualEffect(pPlayer);
        }
    }

    private void ProcessPoisonDamage(CBasePlayer@ pPlayer)
    {
        // Only apply poison damage if healing aura is active.
        if (!m_bIsActive)
            return;

        float currentTime = g_Engine.time;
        if (currentTime - m_flLastPoisonTime < m_flHealInterval)
            return;

        Vector playerOrigin = pPlayer.pev.origin;
        
        // Apply poison damage to entities in radius, checking relationship first.
        CBaseEntity@ pEntity = null;
        while((@pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, playerOrigin, m_flHealingRadius, "*", "classname")) !is null)
        {
            // Skip the aura owner.
            if (pEntity is pPlayer)
                continue;

            // Only damage entities that are NOT allies.
            CBaseMonster@ pMonster = cast<CBaseMonster@>(pEntity);
            if (pMonster !is null && pMonster.IsAlive())
            {
                // Check relationship to ensure we won't damage allies.
                int relationship = pMonster.IRelationship(pPlayer);
                if (relationship != R_AL) // Only poison them if NOT an ally of the player.
                {
                    float poisonDamage = GetPoisonDamageAmount() * pMonster.pev.max_health / 100; // Poison damage scales with target's max health.

                    pMonster.TakeDamage(pPlayer.pev, pPlayer.pev, poisonDamage, DMG_ACID);
                    ApplyPoisonEffect(pMonster);
                    g_SoundSystem.EmitSoundDyn(pMonster.edict(), CHAN_ITEM, strPoisonSound, 0.5f, ATTN_NORM, SND_FORCE_SINGLE);
                }
            }
        }

        m_flLastPoisonTime = currentTime; 
    }

    private void ApplyPoisonEffect(CBaseEntity@ target)
    {
        if(target is null)
            return;

        Vector origin = target.pev.origin;
        origin.z += 16; // Offset to center of entity.

        Vector endPoint = origin;
        endPoint.z += 10; // Trail moves upward.

        // Create sprite trail effect.
        NetworkMessage msg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            msg.WriteByte(TE_SPRITETRAIL);
            msg.WriteCoord(origin.x);
            msg.WriteCoord(origin.y);
            msg.WriteCoord(origin.z);
            msg.WriteCoord(endPoint.x);
            msg.WriteCoord(endPoint.y);
            msg.WriteCoord(endPoint.z);
            msg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraPoisonEffectSprite));
            msg.WriteByte(3);   // Count.
            msg.WriteByte(1);   // Life in 0.1's.
            msg.WriteByte(3);   // Scale in 0.1's.
            msg.WriteByte(15);  // Velocity along vector in 10's.
            msg.WriteByte(10);  // Random velocity in 10's.
            msg.End();
    }

    private void UpdateVisualEffect(CBasePlayer@ pPlayer)
    {
        if (!m_bIsActive || pPlayer is null)
            return;
            
        float currentTime = g_Engine.time;
        if (currentTime < m_flNextVisualUpdate)
            return;
        
        m_flNextVisualUpdate = currentTime + m_flVisualUpdateInterval;

        Vector pos = pPlayer.pev.origin;
        Vector mins = pos - Vector(16, 16, 0);
        Vector maxs = pos + Vector(16, 16, 64);
        
        // Aura Beam Cylinder Effect.
        NetworkMessage auramsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
            auramsg.WriteByte(TE_BEAMCYLINDER);
            auramsg.WriteCoord(pos.x);
            auramsg.WriteCoord(pos.y);
            auramsg.WriteCoord(pos.z);
            auramsg.WriteCoord(pos.x);
            auramsg.WriteCoord(pos.y);
            auramsg.WriteCoord(pos.z + m_flHealingRadius); // Height.
            auramsg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraSprite));
            auramsg.WriteByte(0); // Starting frame.
            auramsg.WriteByte(0); // Frame rate (no effect).
            auramsg.WriteByte(uint8(m_flHealAuraInterval * 10)); // Life * 0.1s (make life match duration).
            auramsg.WriteByte(32); // Width.
            auramsg.WriteByte(0); // Noise (No effect).
            auramsg.WriteByte(int(m_vAuraColor.x));
            auramsg.WriteByte(int(m_vAuraColor.y));
            auramsg.WriteByte(int(m_vAuraColor.z));
            auramsg.WriteByte(128); // Brightness.
            auramsg.WriteByte(0); // Scroll speed (no effect).
            auramsg.End();

        // Heal Bubbles Effect.
        NetworkMessage aura2msg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
            aura2msg.WriteByte(TE_BUBBLES);
            aura2msg.WriteCoord(mins.x);
            aura2msg.WriteCoord(mins.y);
            aura2msg.WriteCoord(mins.z);
            aura2msg.WriteCoord(maxs.x);
            aura2msg.WriteCoord(maxs.y);
            aura2msg.WriteCoord(maxs.z);
            aura2msg.WriteCoord(80.0f); // Height of the bubble effect.
            aura2msg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraEffectSprite));
            aura2msg.WriteByte(18); // Count.
            aura2msg.WriteCoord(6.0f); // Speed.
            aura2msg.End();
    }

    void ReviveTimerTick()
    {
        float t = g_Engine.time;
        if(m_flReviveGraceEndTime > 0.0f && t >= m_flReviveGraceEndTime)
        {
            m_flCurrentReviveCooldown = GetReviveCooldown();
            m_flReviveGraceEndTime = 0.0f;
        }

        if(m_flCurrentReviveCooldown <= 0.0f)
            return;
        m_flCurrentReviveCooldown -= flHealAuraSchedulerInterval;
        if(m_flCurrentReviveCooldown < 0.0f)
            m_flCurrentReviveCooldown = 0.0f;
    }

    private void ReviveGrace(float currentTime)
    {
        if(m_flReviveGraceEndTime <= currentTime)
            m_flReviveGraceEndTime = currentTime + m_flReviveGracePeriod;
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
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Healing Aura Off!\n");
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strHealAuraActiveSound, 0.0f, ATTN_NORM, SND_STOP);
            RemoveAuraGlow(pPlayer);
            return;
        }

        current -= m_iDrainAmount;
        resources['current'] = current;

        m_flLastHealTime = currentTime;
        
        Vector playerOrigin = pPlayer.pev.origin;
        CBaseEntity@ pEntity = null;
        while((@pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, playerOrigin, m_flHealingRadius, "*", "classname")) !is null)
        {
            // Skip classnames in the skip list.
            string classname = pEntity.GetClassname();
            bool shouldSkip = false;
            for(uint i = 0; i < g_SkipRevivalClassNames.length(); i++)
            {
                if(classname == g_SkipRevivalClassNames[i])
                {
                    shouldSkip = true;
                    break;
                }
            }
            if(shouldSkip)
                continue;

            // Check for dead entities.
            if(!pEntity.IsAlive())
            {
                if(m_flCurrentReviveCooldown > 0.0f)
                    continue;

                if(pEntity.IsPlayer())
                {
                    CBasePlayer@ pTarget = cast<CBasePlayer@>(pEntity);
                    if(pTarget !is null)
                    {
                        pTarget.Revive(); // Do Player specific revival.
                        pTarget.pev.health = pTarget.pev.max_health * m_flHealAuraReviveHealthPercent; // Revive at % of max health.
                        pPlayer.pev.frags += m_iReviveFragBonusPlayer; // Award frags for reviving a player.
                        ApplyReviveEffect(pEntity);
                        g_SoundSystem.EmitSoundDyn(pEntity.edict(), CHAN_ITEM, strReviveSound, 1.0f, ATTN_NORM, SND_FORCE_SINGLE, PITCH_NORM);
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Revived " + pEntity.pev.netname + "!\n");
                        ReviveGrace(currentTime); // Grace period to allow multiple revives for one activation.
                    }
                }
                else
                {
                    CBaseMonster@ pMonster = cast<CBaseMonster@>(pEntity);
                    if(pMonster !is null)
                    {
                        int relationship = pMonster.IRelationship(pPlayer);
                        if(relationship == R_AL) // R_AL = Ally relationship.
                        {
                            pMonster.Revive();
                            pMonster.pev.health = pMonster.pev.max_health * m_flHealAuraReviveHealthPercent;
                            pPlayer.pev.frags += m_iReviveFragBonusMonster; // Award frags for reviving a monster.
                            ApplyReviveEffect(pEntity);
                            g_SoundSystem.EmitSoundDyn(pEntity.edict(), CHAN_ITEM, strReviveSound, 1.0f, ATTN_NORM, SND_FORCE_SINGLE, PITCH_NORM);
                            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Revived " + pMonster.GetClassname() + "!\n");
                            ReviveGrace(currentTime); // Grace period to allow multiple revives for one activation.
                        }
                    }
                }
                continue;
            }

            bool shouldHeal = false;

            // Always heal players.
            if(pEntity.IsPlayer())
            {
                shouldHeal = true;
            }
            else
            {
                CBaseMonster@ pMonster = cast<CBaseMonster@>(pEntity);
                if(pMonster !is null)
                {
                    // Check relationship instead of IsPlayerAlly.
                    int relationship = pMonster.IRelationship(pPlayer);
                    if(relationship == R_AL) // R_AL = Ally relationship.
                    {
                        shouldHeal = true;
                    }
                }
            }
            
            // Skip if not determined as friendly.
            if(!shouldHeal)
            {
                // Only apply poison to actual enemies.
                if(!pEntity.IsPlayer())
                {
                    CBaseMonster@ pMonster = cast<CBaseMonster@>(pEntity);
                    if(pMonster !is null)
                    {
                        int relationship = pMonster.IRelationship(pPlayer);
                        if(relationship != R_AL) // Only poison if NOT an ally
                        {
                            ApplyPoisonEffect(pEntity);
                        }
                    }
                }
                continue;
            }
                
            // Skip if at full health.
            if(pEntity.pev.health >= pEntity.pev.max_health)
                continue;

            float healAmount = GetScaledHealAmount() * pEntity.pev.max_health / 100; // Heal amount scaled with max health.
            
            if(!pEntity.IsPlayer())
                healAmount *= 2.0f; // NPC healing modifier.

            // Process healing, effects and sounds.
            pEntity.pev.health = Math.min(pEntity.pev.health + healAmount, pEntity.pev.max_health);
            pPlayer.pev.frags += m_iHealFragBonus; // Award frags for healing.
            
            ApplyHealEffect(pEntity);
            g_SoundSystem.EmitSoundDyn(pEntity.edict(), CHAN_ITEM, strHealSound, 0.6f, ATTN_NORM, SND_FORCE_SINGLE, PITCH_NORM);
        }
    }

    private void ApplyHealEffect(CBaseEntity@ target)
    {
        if(target is null)
            return;

        Vector origin = target.pev.origin;
        origin.z += 32; // Offset to center of entity.
        
        Vector endPoint = origin;
        endPoint.z += 10; // Trail moves upward.

        // Create sprite trail effect.
        NetworkMessage msg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            msg.WriteByte(TE_SPRITETRAIL);
            msg.WriteCoord(origin.x);
            msg.WriteCoord(origin.y);
            msg.WriteCoord(origin.z);
            msg.WriteCoord(endPoint.x);
            msg.WriteCoord(endPoint.y);
            msg.WriteCoord(endPoint.z);
            msg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraEffectSprite));
            msg.WriteByte(10);  // Count.
            msg.WriteByte(2);  // Life in 0.1's.
            msg.WriteByte(5);  // Scale in 0.1's.
            msg.WriteByte(15); // Velocity along vector in 10's.
            msg.WriteByte(5);  // Random velocity in 10's.
        msg.End();
    }

    private void ApplyReviveEffect(CBaseEntity@ target)
    {
        if(target is null)
            return;

        Vector origin = target.pev.origin;
        origin.z += 32; // Offset to center of entity.
        
        Vector endPoint = origin;
        endPoint.z += 10; // Trail moves upward.

        // Create sprite trail effect.
        NetworkMessage msg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            msg.WriteByte(TE_SPRITETRAIL);
            msg.WriteCoord(origin.x);
            msg.WriteCoord(origin.y);
            msg.WriteCoord(origin.z);
            msg.WriteCoord(endPoint.x);
            msg.WriteCoord(endPoint.y);
            msg.WriteCoord(endPoint.z);
            msg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraEffectSprite));
            msg.WriteByte(5);  // Count.
            msg.WriteByte(3);  // Life in 0.1's.
            msg.WriteByte(20);  // Scale in 0.1's.
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