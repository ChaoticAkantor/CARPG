// Our multipliers for explosive damage based on ammo type.
dictionary g_AmmoTypeDamageMultipliers = 
{
    {"9mm", 0.6f},
    {"357", 1.50f},
    {"buckshot", 0.5f},
    {"556", 0.6f},
    {"762", 1.8f},
    {"uranium", 0.8f},
    {"m40a1", 1.8f}
};

// Functions to access the damage multipliers from other files.
array<string> GetAmmoTypesForDamageMultipliers()
{
    return g_AmmoTypeDamageMultipliers.getKeys();
}

float GetAmmoTypeDamageMultiplier(const string& in ammoType)
{
    if(g_AmmoTypeDamageMultipliers.exists(ammoType))
        return float(g_AmmoTypeDamageMultipliers[ammoType]);
    return 1.0f;
}

dictionary g_PlayerExplosiveRounds;
string strExplosiveRoundsActivateSound = "weapons/reload3.wav";
string strExplosiveRoundsImpactSound = "weapons/explode3.wav"; // Explosion sound.
string strExplosiveRoundsExplosionSprite = "sprites/zerogxplode.spr"; // Explosion sprite.
string strExplosiveRoundsExplosionCoreSprite = "sprites/explode1.spr"; // Core explosion sprite.
string strExplosiveRoundsSplatterSprite = "sprites/fire.spr"; // Fire effect.

class ExplosiveRoundsData
{
    private float m_flExplosiveRoundsDamage = 5.0f;
    private float m_flExplosiveRoundsDamageScaling = 0.11f; // % Damage increase per level.
    private float m_flExplosiveRoundsPoolScaling = 0.06f; // % Pool size increase per level.
    private float m_flExplosiveRoundsRadius = 96.0f; // Radius of explosion.
    private int m_iExplosiveRoundsPoolBase = 15;
    private float m_flEnergyCostPerActivation = 1.0f;
    private float m_flRoundsFillPercentage = 1.0f; // Give % of max pool per activation.
    private float m_flRoundsInPool = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flToggleCooldown = 0.10f;
    private ClassStats@ m_pStats = null;

    bool HasStats() { return m_pStats !is null; }
    bool HasRounds() { return m_flRoundsInPool > 0; }
    float GetRounds() { return m_flRoundsInPool; }
    float GetEnergyCost() { return m_flEnergyCostPerActivation; }
    void ResetRounds() { m_flRoundsInPool = 0; }
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetScaledDamage()
    {
        if(m_pStats is null)
            return m_flExplosiveRoundsDamage;

        return m_flExplosiveRoundsDamage * (1.0f + (m_pStats.GetLevel() * m_flExplosiveRoundsDamageScaling));

    }

    float GetRadiusDamage() { return GetScaledDamage(); }
    
    int GetAmmoPerPack()
    {
        int maxRounds = GetMaxRounds();
        int roundsToAdd = int(maxRounds * m_flRoundsFillPercentage);
        return Math.max(1, roundsToAdd); // Always return at least 1 round.
    }

    float GetRadius() { return m_flExplosiveRoundsRadius; }

    void ApplyRadiusDamage(CBasePlayer@ pPlayer, Vector impactPoint, float damageMultiplier, int damageType = DMG_BLAST | DMG_BURN | DMG_SLOWBURN | DMG_TIMEBASED | DMG_ALWAYSGIB)
    {
        if(pPlayer is null)
            return;
            
        // Apply damage at the specified position.
        g_WeaponFuncs.RadiusDamage(
            impactPoint,
            pPlayer.pev,
            pPlayer.pev,
            GetScaledDamage() * damageMultiplier,
            GetRadius(),
            CLASS_PLAYER_ALLY, // Will not damage allies of player.
            damageType // Damage type - configurable via parameter.
        );
    }

    void ConsumeRound() 
    { 
        m_flRoundsInPool = Math.max(0.0f, m_flRoundsInPool - 1.0f);
    }

    int GetMaxRounds()
    {
        if(m_pStats is null)
            return m_iExplosiveRoundsPoolBase;

        return int(m_iExplosiveRoundsPoolBase * (1.0f + (m_pStats.GetLevel() * m_flExplosiveRoundsPoolScaling)));
    }

    void ActivateExplosiveRounds(CBasePlayer@ pPlayer)
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

        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strExplosiveRoundsActivateSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "+" + actualAdded + " Dragon's Breath Rounds\n");

        m_flLastToggleTime = currentTime;
    }

    void FireExplosiveRounds(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon)
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
        float damageMultiplier = 1.0f; // Default multiplier, incase ammo type is invalid or unasigned in array.
        
        if(g_AmmoTypeDamageMultipliers.exists(ammoName))
        {
            damageMultiplier = float(g_AmmoTypeDamageMultipliers[ammoName]);
        }

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
                g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_WEAPON, strExplosiveRoundsImpactSound, 0.5f, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-5, 5), 0, true, impactPoint);
                
                // Create smaller explosion effects for shotgun pellets.
                // 1. Main explosion sprite.
                NetworkMessage msgExp(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msgExp.WriteByte(TE_SPRITE);
                msgExp.WriteCoord(impactPoint.x);
                msgExp.WriteCoord(impactPoint.y);
                msgExp.WriteCoord(impactPoint.z);
                msgExp.WriteShort(g_EngineFuncs.ModelIndex(strExplosiveRoundsExplosionSprite));
                msgExp.WriteByte(6); // Smaller scale for shotgun.
                msgExp.WriteByte(180); // Brightness.
                msgExp.End();
                
                // 2. Core explosion sprite
                NetworkMessage msgCore(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msgCore.WriteByte(TE_SPRITE);
                msgCore.WriteCoord(impactPoint.x);
                msgCore.WriteCoord(impactPoint.y);
                msgCore.WriteCoord(impactPoint.z);
                msgCore.WriteShort(g_EngineFuncs.ModelIndex(strExplosiveRoundsExplosionCoreSprite));
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
                msgTrail.WriteShort(g_EngineFuncs.ModelIndex(strExplosiveRoundsSplatterSprite));
                msgTrail.WriteByte(3);  // Count - fewer sprites for smaller effect.
                msgTrail.WriteByte(2);  // Life in 0.1's.
                msgTrail.WriteByte(1);  // Scale in 0.1's.
                msgTrail.WriteByte(15); // Velocity along vector in 10's.
                msgTrail.WriteByte(10); // Random velocity in 10's.
                msgTrail.End();

                ApplyRadiusDamage(pPlayer, impactPoint, damageMultiplier); // Apply radius damage using default damage types.
            }

            ConsumeRound();
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
                if (tr.pHit !is null) {
                    CBaseEntity@ hitEntity = g_EntityFuncs.Instance(tr.pHit);
                    if (hitEntity !is null) {
                        // Adjust the impact point to be slightly in front of the hit surface.
                        impactPoint = tr.vecEndPos - (vecAiming * 2);
                    }
                }
                
                // IMPORTANT: Always play the explosion sound for each M16 burst round.
                g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_WEAPON, strExplosiveRoundsImpactSound, 0.5f, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-10, 10), 0, true, impactPoint);
                
                // Create very small explosion effects for burst fire.
                // 1. Main explosion sprite.
                NetworkMessage msgExp(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msgExp.WriteByte(TE_SPRITE);
                msgExp.WriteCoord(impactPoint.x);
                msgExp.WriteCoord(impactPoint.y);
                msgExp.WriteCoord(impactPoint.z);
                msgExp.WriteShort(g_EngineFuncs.ModelIndex(strExplosiveRoundsExplosionSprite));
                msgExp.WriteByte(4); // Smaller scale for burst fire.
                msgExp.WriteByte(160); // Brightness.
                msgExp.End();
                
                // 2. Core explosion sprite.
                NetworkMessage msgCore(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msgCore.WriteByte(TE_SPRITE);
                msgCore.WriteCoord(impactPoint.x);
                msgCore.WriteCoord(impactPoint.y);
                msgCore.WriteCoord(impactPoint.z);
                msgCore.WriteShort(g_EngineFuncs.ModelIndex(strExplosiveRoundsExplosionCoreSprite));
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
                
                // Create sprite trail effect
                NetworkMessage msgTrail(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
                msgTrail.WriteByte(TE_SPRITETRAIL);
                msgTrail.WriteCoord(startPoint.x);
                msgTrail.WriteCoord(startPoint.y);
                msgTrail.WriteCoord(startPoint.z);
                msgTrail.WriteCoord(endPoint.x);
                msgTrail.WriteCoord(endPoint.y);
                msgTrail.WriteCoord(endPoint.z);
                msgTrail.WriteShort(g_EngineFuncs.ModelIndex(strExplosiveRoundsSplatterSprite));
                msgTrail.WriteByte(3);  // Count.
                msgTrail.WriteByte(1);  // Life in 0.1's.
                msgTrail.WriteByte(1);  // Scale in 0.1's.
                msgTrail.WriteByte(10); // Velocity along vector in 10's.
                msgTrail.WriteByte(5);  // Random velocity in 10's.
                msgTrail.End();

                ApplyRadiusDamage(pPlayer, impactPoint, damageMultiplier); // Apply radius damage using default damage types.

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
            if (tr.pHit !is null) {
                CBaseEntity@ hitEntity = g_EntityFuncs.Instance(tr.pHit);
                if (hitEntity !is null) {
                    // Adjust the impact point to be slightly in front of the hit surface.
                    impactPoint = tr.vecEndPos - (vecAiming * 2);
                }
            }

            // Play impact sound.
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_WEAPON, strExplosiveRoundsImpactSound, 0.6f, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-3, 3), 0, true, impactPoint);
            
            // Create explosion effects.
            // 1. Main explosion sprite.
            NetworkMessage msgExp(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            msgExp.WriteByte(TE_SPRITE);
            msgExp.WriteCoord(impactPoint.x);
            msgExp.WriteCoord(impactPoint.y);
            msgExp.WriteCoord(impactPoint.z);
            msgExp.WriteShort(g_EngineFuncs.ModelIndex(strExplosiveRoundsExplosionSprite));
            msgExp.WriteByte(10); // Scale.
            msgExp.WriteByte(200); // Brightness.
            msgExp.End();
            
            // 2. Core explosion sprite.
            NetworkMessage msgCore(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            msgCore.WriteByte(TE_SPRITE);
            msgCore.WriteCoord(impactPoint.x);
            msgCore.WriteCoord(impactPoint.y);
            msgCore.WriteCoord(impactPoint.z);
            msgCore.WriteShort(g_EngineFuncs.ModelIndex(strExplosiveRoundsExplosionCoreSprite));
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
            
            // Create sprite trail effect
            NetworkMessage msgTrail(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
            msgTrail.WriteByte(TE_SPRITETRAIL);
            msgTrail.WriteCoord(startPoint.x);
            msgTrail.WriteCoord(startPoint.y);
            msgTrail.WriteCoord(startPoint.z);
            msgTrail.WriteCoord(endPoint.x);
            msgTrail.WriteCoord(endPoint.y);
            msgTrail.WriteCoord(endPoint.z);
            msgTrail.WriteShort(g_EngineFuncs.ModelIndex(strExplosiveRoundsSplatterSprite));
            msgTrail.WriteByte(3);  // Count - more sprites for a denser burst.
            msgTrail.WriteByte(2);   // Life in 0.1's.
            msgTrail.WriteByte(2);   // Scale in 0.1's.
            msgTrail.WriteByte(25);  // Velocity along vector in 10's.
            msgTrail.WriteByte(15);  // Random velocity in 10's - higher for more spread.
            msgTrail.End();

            // Apply radius damage with default damage types
            ApplyRadiusDamage(pPlayer, impactPoint, damageMultiplier); // Apply radius damage.

            ConsumeRound();
        }
    }
}

// Helper function to get ammo name from index.
string GetAmmoName(int ammoType)
{
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("9mm")) return "9mm";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("357")) return "357";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("buckshot")) return "buckshot";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("556")) return "556";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("762")) return "762";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("uranium")) return "uranium";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("m40a1")) return "m40a1";
    return "";
}
