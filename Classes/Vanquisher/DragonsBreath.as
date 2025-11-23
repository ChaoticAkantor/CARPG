dictionary g_PlayerDragonsBreath;
string strDragonsBreathActivateSound = "weapons/reload3.wav";
string strDragonsBreathImpactSound = "weapons/explode3.wav"; // Explosion sound.
string strDragonsBreathExplosionSprite = "sprites/zerogxplode.spr"; // Explosion sprite.
string strDragonsBreathExplosionCoreSprite = "sprites/explode1.spr"; // Core explosion sprite.
string strDragonsBreathFireSprite = "sprites/fire.spr"; // Fire effect.

class DragonsBreathData
{
    // Dragons breath reworked to now have a single stacking area damage component: 
    private float m_flDragonsBreathFireDamage = 3.0f; // Base damage for DoT.
    private int m_iDragonsBreathFireTicks = 10; // Number of damage over time ticks.
    private float m_flDragonsBreathFireInterval = 1.0f; // Interval in seconds between DoT ticks.
    private float m_flDragonsBreathFireDamageScaling = 0.02f; // % Damage increase of DoT per level.
    private int m_iDragonsBreathPoolBase = 15; // Base max ammo pool for Dragons Breath.
    private float m_flDragonsBreathPoolScaling = 0.06f; // % Ammo Pool size increase per level.
    private float m_flDragonsBreathRadius = 320.0f; // Radius of fire damage DoT for Dragons Breath.
    private float m_flEnergyCostPerActivation = 1.0f; // Amount of energy to use per activation.
    private float m_flRoundsFillPercentage = 1.00f; // Give % of max ammo pool per activation.
    private float m_flRoundsInPool = 0.0f; // Used to store rounds currently in pool.
    private float m_flLastToggleTime = 0.0f; // Used for last toggle time.
    private float m_flToggleCooldown = 0.10f; // Used to delay toggling to prevent spam.
    private ClassStats@ m_pStats = null;

    bool HasStats() { return m_pStats !is null; }
    bool HasRounds() { return m_flRoundsInPool > 0; }
    float GetRounds() { return m_flRoundsInPool; }
    float GetEnergyCost() { return m_flEnergyCostPerActivation; }
    void ResetRounds() { m_flRoundsInPool = 0; }
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetScaledFireDamage() // Calculate scaled fire damage.
    {
        if(m_pStats is null)
            return m_flDragonsBreathFireDamage;

        float DragonsBreathFire = 0.0f;
        DragonsBreathFire = m_flDragonsBreathFireDamage * (1.0f + (m_pStats.GetLevel() * m_flDragonsBreathFireDamageScaling));

        return DragonsBreathFire;
    }

    float GetFireDuration() { return m_iDragonsBreathFireTicks * m_flDragonsBreathFireInterval; }

    float GetRadius() { return m_flDragonsBreathRadius; }

    int GetAmmoPerPack() // Calculate number of rounds to add per pack.
    {
        int maxRounds = GetMaxRounds();
        int roundsToAdd = int(maxRounds * m_flRoundsFillPercentage);
        return Math.max(1, roundsToAdd); // Always return at least 1 round.
    }

    // Apply Dragons Breath to area.
    void ApplyDragonsBreath(CBasePlayer@ pPlayer, Vector impactPoint)
    {
        if(pPlayer is null)
            return;

        // Apply Area effect to display size of fire radius (Dyn light probably too resource intensive, change to disk or beam torus).
        // Also add dynamic light effect to entity.
        NetworkMessage fireAreaMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
            fireAreaMsg.WriteByte(TE_DLIGHT);
            fireAreaMsg.WriteCoord(impactPoint.x);
            fireAreaMsg.WriteCoord(impactPoint.y);
            fireAreaMsg.WriteCoord(impactPoint.z);
            fireAreaMsg.WriteByte(uint8(m_flDragonsBreathRadius * 0.1)); // Radius units * 10.
            fireAreaMsg.WriteByte(255); // Red.
            fireAreaMsg.WriteByte(100); // Green.
            fireAreaMsg.WriteByte(15); // Blue.
            fireAreaMsg.WriteByte(uint8(m_flDragonsBreathFireInterval * 10)); // Life * 0.1s.
            fireAreaMsg.WriteByte(uint8(m_flDragonsBreathFireInterval * 10)); // Fade speed * 1s.
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
        m_flRoundsInPool = Math.max(0.0f, m_flRoundsInPool - 1.0f);
    }

    int GetMaxRounds()
    {
        if(m_pStats is null)
            return m_iDragonsBreathPoolBase;

        return int(m_iDragonsBreathPoolBase * (1.0f + (m_pStats.GetLevel() * m_flDragonsBreathPoolScaling)));
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

        if(current < m_flEnergyCostPerActivation)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Need " + int(m_flEnergyCostPerActivation) + " Dragon's Breath Ammo Pack!\n");
            return;
        }

        int roundsToAdd = GetAmmoPerPack();
        
        int oldRoundsInPool = int(m_flRoundsInPool);
        m_flRoundsInPool = Math.min(m_flRoundsInPool + roundsToAdd, float(GetMaxRounds()));
        int actualAdded = int(m_flRoundsInPool) - oldRoundsInPool;

        resources['current'] = Math.max(0, current - m_flEnergyCostPerActivation); // Deduct fixed energy cost.

        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strDragonsBreathActivateSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "+" + actualAdded + " Dragon's Breath Rounds\n");

        m_flLastToggleTime = currentTime;
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

        if(ammoName == "buckshot") // Special handling for specific ammo types.
        {
            const int SHOTGUN_PELLETS = 6;
            
            for(int i = 0; i < SHOTGUN_PELLETS; i++)
            {
                Vector angles = pPlayer.pev.v_angle;
                Math.MakeVectors(angles);
                Vector vecAiming = g_Engine.v_forward;
                
                // Use more realistic shotgun spread pattern.
                Vector spread = Vector(
                    Math.RandomFloat(-0.1, 0.1),
                    Math.RandomFloat(-0.1, 0.1),
                    Math.RandomFloat(-0.1, 0.1)
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

                // IMPORTANT: Always play the explosion sound for each shotgun pellet.
                g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_STATIC, strDragonsBreathImpactSound, 0.5f, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-5, 5), 0, true, impactPoint);
                
                // Create smaller explosion effects for shotgun pellets.
                // 1. Main explosion sprite.
                NetworkMessage msgExp(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msgExp.WriteByte(TE_SPRITE);
                msgExp.WriteCoord(impactPoint.x);
                msgExp.WriteCoord(impactPoint.y);
                msgExp.WriteCoord(impactPoint.z);
                msgExp.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathExplosionSprite));
                msgExp.WriteByte(6); // Smaller scale for shotgun.
                msgExp.WriteByte(180); // Brightness.
                msgExp.End();
                
                // 2. Core explosion sprite
                NetworkMessage msgCore(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
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
                NetworkMessage msgExp(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msgExp.WriteByte(TE_SPRITE);
                msgExp.WriteCoord(impactPoint.x);
                msgExp.WriteCoord(impactPoint.y);
                msgExp.WriteCoord(impactPoint.z);
                msgExp.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathExplosionSprite));
                msgExp.WriteByte(4); // Smaller scale for burst fire.
                msgExp.WriteByte(160); // Brightness.
                msgExp.End();
                
                // 2. Core explosion sprite.
                NetworkMessage msgCore(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
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
            NetworkMessage msgExp(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            msgExp.WriteByte(TE_SPRITE);
            msgExp.WriteCoord(impactPoint.x);
            msgExp.WriteCoord(impactPoint.y);
            msgExp.WriteCoord(impactPoint.z);
            msgExp.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathExplosionSprite));
            msgExp.WriteByte(10); // Scale.
            msgExp.WriteByte(200); // Brightness.
            msgExp.End();
            
            // 2. Core explosion sprite.
            NetworkMessage msgCore(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
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
            msgTrail.WriteByte(10);   // Life in 0.1's.
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
        DMG_POISON | DMG_ALWAYSGIB // Damage type (Poison for DoT and stacking).
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
    msgFireArea.WriteByte(3);  // Count - more sprites for a denser burst.
    msgFireArea.WriteByte(10);   // Life in 0.1's.
    msgFireArea.WriteByte(2);   // Scale in 0.1's.
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