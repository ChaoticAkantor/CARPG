dictionary g_PlayerDragonsBreath;
string strDragonsBreathActivateSound = "weapons/reload3.wav";
string strDragonsBreathImpactSound = "weapons/explode3.wav"; // Explosion sound.
string strDragonsBreathExplosionSprite = "sprites/zerogxplode.spr"; // Explosion sprite.
string strDragonsBreathExplosionCoreSprite = "sprites/explode1.spr"; // Core explosion sprite.
string strDragonsBreathFireSprite = "sprites/fire.spr"; // Fire effect.

// Damage multipliers per ammo type for Dragons Breath.
float GetDragonsBreathAmmoMultiplier(const string& in ammoName)
{
    if (ammoName == "9mm")      return 1.0f;
    if (ammoName == "357")      return 2.0f;
    if (ammoName == "buckshot") return 0.33f;
    if (ammoName == "556")      return 1.0f;
    if (ammoName == "bolts")    return 2.5f;
    if (ammoName == "762")      return 2.5f;
    if (ammoName == "uranium")  return 1.5f;
    if (ammoName == "m40a1")    return 2.5f;
    return 1.0f; // Default multiplier if ammo type not found.
}

// Energy cost multipliers per ammo type for Dragons Breath activation.
float GetDragonsBreathAmmoCostMultiplier(const string& in ammoName)
{
    if (ammoName == "9mm")      return 1.0f;
    if (ammoName == "357")      return 2.0f;
    if (ammoName == "buckshot") return 1.0f; // Already set to use per pellet.
    if (ammoName == "556")      return 1.0f;
    if (ammoName == "bolts")    return 2.0f;
    if (ammoName == "762")      return 2.0f;
    if (ammoName == "uranium")  return 2.0f;
    if (ammoName == "m40a1")    return 5.0f;
    return 1.0f; // Default cost multiplier if ammo type not found.
}

class DragonsBreathData
{
    // Dragons breath shots will place a DoT effect at impact location PER shot, with no limit, that stack over each other.

    // Fire Damage over Time.
    private float m_flDragonsBreathExplosionDamageBase = 5.0f; // Base damage for explosion on impact.
    private float m_flDragonsBreathExplosionDamageScalingAtMaxLevel = 2.0f; // Damage increase modifier of explosion damage at max level.
    private float m_flDragonsBreathFireDamage = 10.0f; // Fire tick damage as percentage of total explosion damage.
    private int m_iDragonsBreathFireTicks = 3; // Number of damage over time ticks PER DoT.
    private float m_flDragonsBreathFireInterval = 1.00f; // Interval in seconds between DoT ticks.
    private float m_flDragonsBreathRadius = 20.0f * 16; // Radius of fire damage DoT for Dragons Breath.
    private float m_flEnergyCostPerActivation = 1.0f; // Amount of energy to use per activation (Filling rounds).

    // Ammo pool.
    private int m_iDragonsBreathPoolBase = 30.0f; // Base max ammo pool for Dragons Breath.
    private float m_flDragonsBreathPoolScalingAtMaxLevel = 3.0f; // Ammo Pool size increase at max level.
    private float m_flRoundsFillPercentage = 50.0f; // Percentage of max ammo pool to fill per activation.
    private float m_flRoundsInPool = 0.0f; // Used to store rounds currently in pool.

    private float m_flLastToggleTime = 0.0f; // Used for last toggle time.
    private float m_flToggleCooldown = 0.10f; // Used to delay toggling to prevent spam.
    private float m_flPreviousAmmo = 0.0f; // Used to track ammo changes.
    private string m_strCurrentAmmoName = ""; // Set per shot based on ammo type.
    private ClassStats@ m_pStats = null;

    void UpdateAmmoFromWeapon(CBasePlayer@ pPlayer) // Update ammo name from player's active weapon for HUD display.
    {
        if(pPlayer is null) return;
        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pPlayer.m_hActiveItem.GetEntity());
        if(pWeapon is null) return;
        int ammoType = pWeapon.PrimaryAmmoIndex();
        if(ammoType != -1)
            m_strCurrentAmmoName = GetAmmoName(ammoType);
    }

    bool HasStats() { return m_pStats !is null; }
    bool HasRounds() { return m_flRoundsInPool > 0; }
    float GetRounds() { return m_flRoundsInPool; }
    float GetEnergyCost() { return m_flEnergyCostPerActivation; }
    float GetPerShotCost() { return GetDragonsBreathAmmoCostMultiplier(m_strCurrentAmmoName); }
    float GetDotCount() { return m_iDragonsBreathFireTicks; }
    void ResetRounds() { m_flRoundsInPool = 0; }
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetScaledExplosionDamage() // Calculate scaled explosion damage.
    {
        if(m_pStats is null)
            return m_flDragonsBreathExplosionDamageBase;

        float level = m_pStats.GetLevel();
        float damagePerLevel = m_flDragonsBreathExplosionDamageScalingAtMaxLevel / g_iMaxLevel;
        float dragonsBreathExplosion = m_flDragonsBreathExplosionDamageBase * (1.0f + (damagePerLevel * level));
        dragonsBreathExplosion *= GetDragonsBreathAmmoMultiplier(m_strCurrentAmmoName); // Apply ammo type multiplier.

        return dragonsBreathExplosion;
    }

    float GetScaledFireDamage() // Calculate scaled fire damage.
    {
        if(m_pStats is null)
            return m_flDragonsBreathFireDamage;

        float dragonsBreathFire = 0.0f;
        
        dragonsBreathFire = GetScaledExplosionDamage() / 100 * m_flDragonsBreathFireDamage; // Dot damage is a percentage of explosion damage.

        return dragonsBreathFire;
    }

    float GetFireDuration() { return m_iDragonsBreathFireTicks * m_flDragonsBreathFireInterval; } // Get fire DoT duration.

    float GetFireInterval() { return m_flDragonsBreathFireInterval; } // Get fire DoT tick interval.

    float GetRadius() { return m_flDragonsBreathRadius; } // Get fire DoT radius.

    float GetAmmoRefillPercent() { return m_flRoundsFillPercentage; } // Get refill percentage.

    int GetAmmoPerPack() // Calculate number of rounds to add per pack.
    {
        if(m_pStats is null)
            return m_iDragonsBreathPoolBase; // If no stats, return base.

        int maxRounds = GetMaxRounds();
        int roundsToAdd = int(maxRounds * (m_flRoundsFillPercentage / 100));
        return Math.max(1, roundsToAdd); // Always return at least 1 round.
    }

    // Apply Dragons Breath to area.
    void ApplyDragonsBreath(CBasePlayer@ pPlayer, Vector impactPoint)
    {
        if(pPlayer is null)
            return;

        // Apply dynamic light for flash effect.
        NetworkMessage fireAreaMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
            fireAreaMsg.WriteByte(TE_DLIGHT);
            fireAreaMsg.WriteCoord(impactPoint.x);
            fireAreaMsg.WriteCoord(impactPoint.y);
            fireAreaMsg.WriteCoord(impactPoint.z);
            fireAreaMsg.WriteByte(uint8(GetRadius() * 0.1)); // Radius units * 10.
            fireAreaMsg.WriteByte(255); // Red.
            fireAreaMsg.WriteByte(100); // Green.
            fireAreaMsg.WriteByte(15); // Blue.
            fireAreaMsg.WriteByte(uint8(GetFireDuration() * 10)); // Life * 0.1s.
            fireAreaMsg.WriteByte(uint8(GetFireInterval() * 10)); // Fade speed * 1s.
            fireAreaMsg.End();

        ApplyDragonsBreathFire(pPlayer, impactPoint); // Apply damage over time fire at location.

        // Apply burning visual effect.
        //pTarget.pev.renderfx = kRenderFxGlowShell;
        //pTarget.pev.rendermode = kRenderNormal;
        //pTarget.pev.rendercolor = Vector(255, 100, 10); // Orange glow
        //pTarget.pev.renderamt = 20;
    }

    // Apply damage over time effect at hit location.
    void ApplyDragonsBreathFire(CBasePlayer@ pPlayer, Vector impactPoint)
    {
        if(pPlayer is null)
        return;

        // Apply burning visual effect.
        //pTarget.pev.renderfx = kRenderFxGlowShell;
        //pTarget.pev.rendermode = kRenderNormal;
        //pTarget.pev.rendercolor = Vector(255, 100, 10); // Orange glow.
        //pTarget.pev.renderamt = 10;

        // First apply explosion at impact.
        ApplyExplosionDamage(pPlayer.entindex(), impactPoint);

        // Schedule DoT ticks at fire location.
        for(int firetick = 0; firetick < m_iDragonsBreathFireTicks; firetick++)
        {
            g_Scheduler.SetTimeout("ApplyFireDamage", m_flDragonsBreathFireInterval * firetick, pPlayer.entindex(), impactPoint);
        }

        // Remove damage glow on hurt enemies after a short delay.
        //g_Scheduler.SetTimeout("EffectRemoveFireDamageGlow", 0.2, pTarget.entindex());
    }

    void ConsumeRound() 
    { 
        m_flRoundsInPool = Math.max(0.0f, m_flRoundsInPool - 1.0f * GetPerShotCost()); // Consume rounds based on ammo type cost multiplier.
    }

    int GetMaxRounds()
    {
        if(m_pStats is null)
            return m_iDragonsBreathPoolBase;

        float level = m_pStats.GetLevel();
        float poolPerLevel = m_flDragonsBreathPoolScalingAtMaxLevel / g_iMaxLevel;
        return int(m_iDragonsBreathPoolBase * (1.0f + (poolPerLevel * level)));
    }

    void ActivateDragonsBreath(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
            return;

        if(m_flRoundsInPool >= GetMaxRounds())
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Dragon's Breath Rounds full!\n");
            return;
        }

        string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamId))
            return;

        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamId]);
        float current = float(resources['current']);

        float energyCost = GetEnergyCost();
        if(current < energyCost)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Need " + int(energyCost) + " Dragon's Breath Ammo Pack!\n");
            return;
        }

        int roundsToAdd = GetAmmoPerPack();
        
        int oldRoundsInPool = int(m_flRoundsInPool);
        m_flRoundsInPool = Math.min(m_flRoundsInPool + roundsToAdd, float(GetMaxRounds()));
        int actualAdded = int(m_flRoundsInPool) - oldRoundsInPool;

        resources['current'] = Math.max(0, current - energyCost); // Deduct energy cost (scaled by ammo type).

        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strDragonsBreathActivateSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "+" + actualAdded + " Dragon's Breath Rounds\n");

        m_flLastToggleTime = 0.0f;
    }

    void FireDragonsBreathRound(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon)
    {
        if(pPlayer is null || pWeapon is null || !HasRounds())
            return;
            
        int ammoType = -1; // Initialize with invalid index.
        if(pWeapon !is null)
        {
            ammoType = pWeapon.PrimaryAmmoIndex();
        }

        if(ammoType == -1)
            return;

        string ammoName = GetAmmoName(ammoType);
        string weaponName = pWeapon.GetClassname();

        m_strCurrentAmmoName = ammoName; // Store ammo type for damage scaling.

        if(ammoName == "buckshot") // Special handling for specific ammo types.
        {
            const int SHOTGUN_PELLETS = 6;
            
            for(int i = 0; i < SHOTGUN_PELLETS; i++)
            {
                Vector angles = pPlayer.pev.v_angle;
                Math.MakeVectors(angles);
                Vector vecAiming = g_Engine.v_forward;
                
                // Shotgun spread pattern.
                Vector spread = Vector(
                    Math.RandomFloat(-0.05, 0.05),
                    Math.RandomFloat(-0.05, 0.05),
                    Math.RandomFloat(-0.05, 0.05)
                );
                vecAiming = vecAiming + spread;

                Vector vecSrc = pPlayer.GetGunPosition();
                Vector vecEnd = vecSrc + vecAiming * 8192; // Increased range for better accuracy.

                TraceResult tr;
                g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr);
                
                // If we hit something, use that as the impact point
                Vector impactPoint = tr.vecEndPos;
                
                // If we hit an entity, make sure the explosion happens at the surface.
                if (tr.pHit !is null) 
                {
                    CBaseEntity@ hitEntity = g_EntityFuncs.Instance(tr.pHit);
                    if (hitEntity !is null) 
                    {
                        // Adjust the impact point to be slightly in front of the hit surface.
                        impactPoint = tr.vecEndPos - (vecAiming * 2);
                    }
                }

                // Always play the explosion sound for each shotgun pellet.
                g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_STATIC, strDragonsBreathImpactSound, 0.5f, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-5, 5), 0, true, impactPoint);
                
                // Create smaller explosion effects for shotgun pellets.
                // 1. Main explosion sprite.
                NetworkMessage msgExp(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
                msgExp.WriteByte(TE_SPRITE);
                msgExp.WriteCoord(impactPoint.x);
                msgExp.WriteCoord(impactPoint.y);
                msgExp.WriteCoord(impactPoint.z);
                msgExp.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathExplosionSprite));
                msgExp.WriteByte(6); // Smaller scale for shotgun.
                msgExp.WriteByte(180); // Brightness.
                msgExp.End();
                
                // 2. Core explosion sprite
                NetworkMessage msgCore(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
                msgCore.WriteByte(TE_SPRITE);
                msgCore.WriteCoord(impactPoint.x);
                msgCore.WriteCoord(impactPoint.y);
                msgCore.WriteCoord(impactPoint.z);
                msgCore.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathExplosionCoreSprite));
                msgCore.WriteByte(4); // Smaller scale for shotgun.
                msgCore.WriteByte(180); // Brightness.
                msgCore.End();
                
                // 4. Sprite trail burst effect for shotgun.
                // Create endpoints with impact point as the start point.
                Vector startPoint = impactPoint;
                Vector endPoint = impactPoint;
                
                // End point moves outward from impact in a random direction.
                endPoint.x = startPoint.x + Math.RandomFloat(-25, 25);
                endPoint.y = startPoint.y + Math.RandomFloat(-25, 25);
                endPoint.z = startPoint.z + Math.RandomFloat(5, 20); // Bias upward.
                
                // Create sprite trail effect.
                NetworkMessage msgTrail(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
                msgTrail.WriteByte(TE_SPRITETRAIL);
                msgTrail.WriteCoord(startPoint.x);
                msgTrail.WriteCoord(startPoint.y);
                msgTrail.WriteCoord(startPoint.z);
                msgTrail.WriteCoord(endPoint.x);
                msgTrail.WriteCoord(endPoint.y);
                msgTrail.WriteCoord(endPoint.z);
                msgTrail.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathFireSprite));
                msgTrail.WriteByte(3);  // Count - fewer sprites for smaller effect.
                msgTrail.WriteByte(2);  // Life in 0.1's.
                msgTrail.WriteByte(1);  // Scale in 0.1's.
                msgTrail.WriteByte(15); // Velocity along vector in 10's.
                msgTrail.WriteByte(10); // Random velocity in 10's.
                msgTrail.End();

                ApplyDragonsBreath(pPlayer, impactPoint); // Apply radius damage using default damage types.

                ConsumeRound(); // Moved inside loop to consume 1 round per pellet for shotgun type.
            }
        }
        else if(weaponName == "weapon_m16" && ammoName == "556")
        {
            const int BURST_SHOTS = 3;
            const float BURST_DELAY = 0.085f;
            const float currentTime = g_Engine.time;
            
            for(int i = 0; i < BURST_SHOTS; i++)
            {
                Vector vecSrc = pPlayer.GetGunPosition();
                Vector angles = pPlayer.pev.v_angle;
                Math.MakeVectors(angles);
                Vector vecAiming = g_Engine.v_forward;
                
                // Add slight spread for burst fire.
                Vector burstSpread = Vector(
                    Math.RandomFloat(-0.05, 0.05),
                    Math.RandomFloat(-0.05, 0.05),
                    Math.RandomFloat(-0.05, 0.05)
                );
                vecAiming = vecAiming + burstSpread;
                
                Vector vecEnd = vecSrc + (vecAiming * 8192); // Increased range.

                TraceResult tr;
                g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr);
                
                // If we hit something, use that as the impact point.
                Vector impactPoint = tr.vecEndPos;
                
                // If we hit an entity, make sure the explosion happens at the surface.
                if (tr.pHit !is null) 
                {
                    CBaseEntity@ hitEntity = g_EntityFuncs.Instance(tr.pHit);
                    if (hitEntity !is null) 
                    {
                        // Adjust the impact point to be slightly in front of the hit surface.
                        impactPoint = tr.vecEndPos - (vecAiming * 2);
                    }
                }
                
                // IMPORTANT: Always play the explosion sound for each M16 burst round.
                g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_STATIC, strDragonsBreathImpactSound, 0.5f, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-10, 10), 0, true, impactPoint);
                
                // Create very small explosion effects for burst fire.
                // 1. Main explosion sprite.
                NetworkMessage msgExp(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
                msgExp.WriteByte(TE_SPRITE);
                msgExp.WriteCoord(impactPoint.x);
                msgExp.WriteCoord(impactPoint.y);
                msgExp.WriteCoord(impactPoint.z);
                msgExp.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathExplosionSprite));
                msgExp.WriteByte(4); // Smaller scale for burst fire.
                msgExp.WriteByte(160); // Brightness.
                msgExp.End();
                
                // 2. Core explosion sprite.
                NetworkMessage msgCore(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
                msgCore.WriteByte(TE_SPRITE);
                msgCore.WriteCoord(impactPoint.x);
                msgCore.WriteCoord(impactPoint.y);
                msgCore.WriteCoord(impactPoint.z);
                msgCore.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathExplosionCoreSprite));
                msgCore.WriteByte(3); // Smaller scale for burst fire.
                msgCore.WriteByte(160); // Brightness.
                msgCore.End();
                
                // 4. Just 1 sprite trail effect for M16 burst (very small).
                // Create endpoints with impact point as the start point.
                Vector startPoint = impactPoint;
                Vector endPoint = impactPoint;
                
                // End point moves outward from impact in a random direction.
                endPoint.x = startPoint.x + Math.RandomFloat(-15, 15);
                endPoint.y = startPoint.y + Math.RandomFloat(-15, 15);
                endPoint.z = startPoint.z + Math.RandomFloat(3, 15); // Bias upward.
                
                // Create sprite trail effect.
                NetworkMessage msgTrail(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
                msgTrail.WriteByte(TE_SPRITETRAIL);
                msgTrail.WriteCoord(startPoint.x);
                msgTrail.WriteCoord(startPoint.y);
                msgTrail.WriteCoord(startPoint.z);
                msgTrail.WriteCoord(endPoint.x);
                msgTrail.WriteCoord(endPoint.y);
                msgTrail.WriteCoord(endPoint.z);
                msgTrail.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathFireSprite));
                msgTrail.WriteByte(3);  // Count.
                msgTrail.WriteByte(1);  // Life in 0.1's.
                msgTrail.WriteByte(1);  // Scale in 0.1's.
                msgTrail.WriteByte(10); // Velocity along vector in 10's.
                msgTrail.WriteByte(5);  // Random velocity in 10's.
                msgTrail.End();

                ApplyDragonsBreath(pPlayer, impactPoint); // Apply radius damage using default damage types.

                ConsumeRound();
            }
        }
        else
        {
            Vector vecSrc = pPlayer.GetGunPosition(); // Get player's gun position.

            // Get player's view angles and convert to aim vector.
            Vector angles = pPlayer.pev.v_angle;
            Math.MakeVectors(angles);
            Vector vecAiming = g_Engine.v_forward;

            Vector vecEnd = vecSrc + (vecAiming * 8192); // Increased range for better accuracy.

            TraceResult tr;
            // Use a more precise tracing method
            g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr);
            
            // If we hit something, use that as the impact point.
            Vector impactPoint = tr.vecEndPos;
            
            // If we hit an entity, make sure the explosion happens at the surface.
            if (tr.pHit !is null) 
            {
                CBaseEntity@ hitEntity = g_EntityFuncs.Instance(tr.pHit);
                if (hitEntity !is null) 
                {
                    // Adjust the impact point to be slightly in front of the hit surface.
                    impactPoint = tr.vecEndPos - (vecAiming * 2);   
                }
            }

            // Play impact sound.
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_STATIC, strDragonsBreathImpactSound, 0.6f, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-3, 3), 0, true, impactPoint);
            
            // Create explosion effects.
            // 1. Main explosion sprite.
            NetworkMessage msgExp(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
            msgExp.WriteByte(TE_SPRITE);
            msgExp.WriteCoord(impactPoint.x);
            msgExp.WriteCoord(impactPoint.y);
            msgExp.WriteCoord(impactPoint.z);
            msgExp.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathExplosionSprite));
            msgExp.WriteByte(10); // Scale.
            msgExp.WriteByte(200); // Brightness.
            msgExp.End();
            
            // 2. Core explosion sprite.
            NetworkMessage msgCore(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
            msgCore.WriteByte(TE_SPRITE);
            msgCore.WriteCoord(impactPoint.x);
            msgCore.WriteCoord(impactPoint.y);
            msgCore.WriteCoord(impactPoint.z);
            msgCore.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathExplosionCoreSprite));
            msgCore.WriteByte(8); // Scale.
            msgCore.WriteByte(200); // Brightness.
            msgCore.End();
            
            // 4. Sprite trail burst effect for fire.
            // Create endpoints with impact point as the start point.
            Vector startPoint = impactPoint;
            Vector endPoint = impactPoint;
            
            // End point moves outward from impact in a random direction.
            endPoint.x = startPoint.x + Math.RandomFloat(-50, 50);
            endPoint.y = startPoint.y + Math.RandomFloat(-50, 50);
            endPoint.z = startPoint.z + Math.RandomFloat(20, 50); // Bias upward.
            
            // Create sprite trail effect.
            NetworkMessage msgTrail(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
            msgTrail.WriteByte(TE_SPRITETRAIL);
            msgTrail.WriteCoord(startPoint.x);
            msgTrail.WriteCoord(startPoint.y);
            msgTrail.WriteCoord(startPoint.z);
            msgTrail.WriteCoord(endPoint.x);
            msgTrail.WriteCoord(endPoint.y);
            msgTrail.WriteCoord(endPoint.z);
            msgTrail.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathFireSprite));
            msgTrail.WriteByte(3);  // Count - more sprites for a denser burst.
            msgTrail.WriteByte(5);   // Life in 0.1's.
            msgTrail.WriteByte(2);   // Scale in 0.1's.
            msgTrail.WriteByte(25);  // Velocity along vector in 10's.
            msgTrail.WriteByte(15);  // Random velocity in 10's - higher for more spread.
            msgTrail.End();

            // Apply dragons breath to area.
            ApplyDragonsBreath(pPlayer, impactPoint); // Apply dragons breath.

            ConsumeRound();
        }
    }
}

void EffectRemoveFireDamageGlow(int entityIndex) // Used to explicitly remove glow effect from damage effects.
{   
    // Must use g_EntityFuncs.Instance as AngelScript can't safely pass entity handles to scheduled functions apparently.
    CBaseEntity@ entity = g_EntityFuncs.Instance(entityIndex);
    if(entity !is null)
    {
        entity.pev.renderfx = kRenderFxNone; // Reset renderfx to none.
        entity.pev.rendermode = kRenderNormal; // Reset rendermode to normal.
        entity.pev.renderamt = 255; // Reset render amount to normal.
        entity.pev.rendercolor = Vector(255, 255, 255); // Reset render colour to normal.
    }
}

void ApplyFireDamage(int playerIdx, Vector impactPoint)
{
    CBasePlayer@ pPlayer = cast<CBasePlayer@>(g_EntityFuncs.Instance(playerIdx));
    if(pPlayer is null)
    return;

    // Get the player's steam ID to find their dragons breath instance.
    string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(!g_PlayerDragonsBreath.exists(steamId))
        return;
        
    // Get the player's dragons breath data.
    DragonsBreathData@ dragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamId]);
    if(dragonsBreath is null)
        return;

    // Apply damage over time at location, with effects.
    g_WeaponFuncs.RadiusDamage(
        impactPoint,
        pPlayer.pev,
        pPlayer.pev,
        dragonsBreath.GetScaledFireDamage(), // Damage per tick.
        dragonsBreath.GetRadius(), // Radius.
        CLASS_PLAYER, // Will not damage player or allies.
        DMG_GENERIC | DMG_BURN | DMG_ALWAYSGIB // Damage type (Fire for DoT and stacking).
    );

    Vector startPoint = impactPoint;
    Vector endPoint = impactPoint;

    // End point moves outward from impact in a random direction.
    endPoint.x = startPoint.x + Math.RandomFloat(-50, 50);
    endPoint.y = startPoint.y + Math.RandomFloat(-50, 50);
    endPoint.z = startPoint.z + Math.RandomFloat(20, 50); // Bias upward.

    // Create sprite trail effect to show fire damage tick (temporary, will change later).
    NetworkMessage msgFireArea(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
    msgFireArea.WriteByte(TE_SPRITETRAIL);
    msgFireArea.WriteCoord(startPoint.x);
    msgFireArea.WriteCoord(startPoint.y);
    msgFireArea.WriteCoord(startPoint.z);
    msgFireArea.WriteCoord(endPoint.x);
    msgFireArea.WriteCoord(endPoint.y);
    msgFireArea.WriteCoord(endPoint.z);
    msgFireArea.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathFireSprite));
    msgFireArea.WriteByte(2);  // Count - more sprites for a denser burst.
    msgFireArea.WriteByte(3);   // Life in 0.1's.
    msgFireArea.WriteByte(1);   // Scale in 0.1's.
    msgFireArea.WriteByte(25);  // Velocity along vector in 10's.
    msgFireArea.WriteByte(50);  // Random velocity in 10's - higher for more spread.
    msgFireArea.End();

    // Fire DoT Beam Cylinder Effect.
    NetworkMessage fireRadiusMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
    fireRadiusMsg.WriteByte(TE_BEAMCYLINDER);
    fireRadiusMsg.WriteCoord(impactPoint.x);
    fireRadiusMsg.WriteCoord(impactPoint.y);
    fireRadiusMsg.WriteCoord(impactPoint.z);
    fireRadiusMsg.WriteCoord(impactPoint.x);
    fireRadiusMsg.WriteCoord(impactPoint.y);
    fireRadiusMsg.WriteCoord(impactPoint.z + dragonsBreath.GetRadius()); // Height.
    fireRadiusMsg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraSprite)); // Again borrowing heal beam sprite, for now.
    fireRadiusMsg.WriteByte(0); // Starting frame.
    fireRadiusMsg.WriteByte(0); // Frame rate (no effect).
    fireRadiusMsg.WriteByte(uint8(dragonsBreath.GetFireInterval() * 10)); // Life * 0.1s (make life match duration of effect).
    fireRadiusMsg.WriteByte(16); // Width.
    fireRadiusMsg.WriteByte(0); // Noise.
    fireRadiusMsg.WriteByte(255); //R. Orange colour.
    fireRadiusMsg.WriteByte(100); // G.
    fireRadiusMsg.WriteByte(0); // B.
    fireRadiusMsg.WriteByte(30); // Brightness.
    fireRadiusMsg.WriteByte(0); // Scroll speed (no effect).
    fireRadiusMsg.End();
}

void ApplyExplosionDamage(int playerIdx, Vector impactPoint)
{
    CBasePlayer@ pPlayer = cast<CBasePlayer@>(g_EntityFuncs.Instance(playerIdx));
    if(pPlayer is null)
    return;

    // Get the player's steam ID to find their dragons breath instance.
    string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(!g_PlayerDragonsBreath.exists(steamId))
        return;
        
    // Get the player's dragons breath data.
    DragonsBreathData@ dragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamId]);
    if(dragonsBreath is null)
        return;

    // Apply damage over time at location, with effects.
    g_WeaponFuncs.RadiusDamage(
        impactPoint,
        pPlayer.pev,
        pPlayer.pev,
        dragonsBreath.GetScaledExplosionDamage(), // Damage per explosion (scaled by level and ammo type).
        dragonsBreath.GetRadius(), // Radius.
        CLASS_PLAYER, // Will not damage player or allies.
        DMG_BLAST | DMG_BURN | DMG_ALWAYSGIB // Damage type.
    );

    Vector startPoint = impactPoint;
    Vector endPoint = impactPoint;

    // End point moves outward from impact in a random direction.
    //endPoint.x = startPoint.x + Math.RandomFloat(-50, 50);
    //endPoint.y = startPoint.y + Math.RandomFloat(-50, 50);
    //endPoint.z = startPoint.z + Math.RandomFloat(20, 50); // Bias upward.

    // Create sprite trail effect to show explosive damage (temporary, will change later).
    NetworkMessage msgFireArea(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
    msgFireArea.WriteByte(TE_SPRITETRAIL);
    msgFireArea.WriteCoord(impactPoint.x);
    msgFireArea.WriteCoord(impactPoint.y);
    msgFireArea.WriteCoord(impactPoint.z);
    msgFireArea.WriteCoord(impactPoint.x);
    msgFireArea.WriteCoord(impactPoint.y);
    msgFireArea.WriteCoord(impactPoint.z);
    msgFireArea.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathFireSprite));
    msgFireArea.WriteByte(5);  // Count - more sprites for a denser burst.
    msgFireArea.WriteByte(2);   // Life in 0.1's.
    msgFireArea.WriteByte(3);   // Scale in 0.1's.
    msgFireArea.WriteByte(25);  // Velocity along vector in 10's.
    msgFireArea.WriteByte(50);  // Random velocity in 10's - higher for more spread.
    msgFireArea.End();
}

// Helper function to get ammo name from index.
string GetAmmoName(int ammoType)
{
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("9mm")) return "9mm";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("357")) return "357";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("buckshot")) return "buckshot";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("556")) return "556";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("uranium")) return "uranium";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("m40a1")) return "m40a1";
    return "";
}