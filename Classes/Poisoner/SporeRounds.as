// Sounds and sprites.
string strSporeRoundsActivateSound = "weapons/reload3.wav";
string strSporeRoundsImpactSound = "weapons/splauncher_impact.wav"; // Actual spore grenade impact sound.
string strSporeRoundsExplosionSprite = "sprites/spore_exp_01.spr"; // Actual spore explosion sprite.
string strSporeRoundsExplosionCoreSprite = "sprites/spore_exp_c_01.spr"; // Core explosion sprite.
string strSporeRoundsGlowSprite = "sprites/glow01.spr"; // Glow effect.
string strSporeRoundsSplatterSprite = "sprites/tinyspit.spr"; // Splatter effect.

dictionary g_AmmoTypeDamageMultipliers = // Our multipliers for spore damage based on ammo type.
{
    {"9mm", 1.15f},
    {"357", 1.0f},
    {"buckshot", 0.8f},
    {"bolts", 1.0f},
    {"556", 1.0f},
    {"762", 1.0f},
    {"uranium", 1.0f},
    {"m40a1", 1.0f}
};

dictionary g_PlayerSporeRounds;

class SporeRoundsData
{
    private float m_flSporeRoundsDamage = 6.0f;
    private float m_flSporeRoundsDamageScaling = 0.1f; // % Damage increase per level.
    private float m_flSporeRoundsPoolScaling = 0.06f; // % Pool size increase per level.
    private float m_flSporeRoundsRadius = 96.0f; // Radius of explosion.
    private int m_iSporeRoundsPoolBase = 30;
    private float m_flEnergyCostPerActivation = 1.0f;
    private float m_flRoundsFillPercentage = 0.33f; // Fill 33% of max pool per activation
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
            return m_flSporeRoundsDamage;

        return m_flSporeRoundsDamage * (1.0f + (m_pStats.GetLevel() * m_flSporeRoundsDamageScaling));

    }

    float GetRadiusDamage() { return GetScaledDamage(); }

    float GetAmmoPerPack() { return m_flRoundsFillPercentage; }

    float GetRadius() { return m_flSporeRoundsRadius; }

    void ApplyRadiusDamage(CBasePlayer@ pPlayer, Vector impactPoint, float damageMultiplier, int damageType = DMG_POISON | DMG_BLAST)
    {
        if(pPlayer is null)
            return;
            
        // Apply damage at the specified position
        g_WeaponFuncs.RadiusDamage(
            impactPoint,
            pPlayer.pev,
            pPlayer.pev,
            GetScaledDamage() * damageMultiplier,
            GetRadius(),
            CLASS_PLAYER_ALLY, // Will not damage allies of player.
            damageType // Damage type - configurable via parameter
        );
    }

    void ConsumeRound() 
    { 
        m_flRoundsInPool = Math.max(0.0f, m_flRoundsInPool - 1.0f);
    }

    int GetMaxRounds()
    {
        if(m_pStats is null)
            return m_iSporeRoundsPoolBase;

        return int(m_iSporeRoundsPoolBase * (1.0f + (m_pStats.GetLevel() * m_flSporeRoundsPoolScaling)));
    }

    void ActivateSporeRounds(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
            return;

        if(m_flRoundsInPool >= GetMaxRounds())
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Spore Rounds full!\n");
            return;
        }

        string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamId))
            return;

        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamId]);
        float current = float(resources['current']);

        if(current < m_flEnergyCostPerActivation)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Need " + int(m_flEnergyCostPerActivation) + " Spore Ammo Pack!\n");
            return;
        }

        // Calculate rounds to add based on percentage of max pool.
        int maxRounds = GetMaxRounds();
        int roundsToAdd = int(maxRounds * m_flRoundsFillPercentage);
        roundsToAdd = Math.max(1, roundsToAdd); // Always add at least 1 round.
        
        int oldRoundsInPool = int(m_flRoundsInPool);
        m_flRoundsInPool = Math.min(m_flRoundsInPool + roundsToAdd, float(maxRounds));
        int actualAdded = int(m_flRoundsInPool) - oldRoundsInPool;

        resources['current'] = Math.max(0, current - m_flEnergyCostPerActivation); // Deduct fixed energy cost.

        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strSporeRoundsActivateSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "+" + actualAdded + " Spore Rounds\n");

        m_flLastToggleTime = currentTime;
    }

    void FireSporeRounds(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon)
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
                
                // Use more realistic shotgun spread pattern
                Vector spread = Vector(
                    Math.RandomFloat(-0.1, 0.1),
                    Math.RandomFloat(-0.1, 0.1),
                    Math.RandomFloat(-0.1, 0.1)
                );
                vecAiming = vecAiming + spread;

                Vector vecSrc = pPlayer.GetGunPosition();
                Vector vecEnd = vecSrc + vecAiming * 8192; // Increased range for better accuracy

                TraceResult tr;
                g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr);
                
                // If we hit something, use that as the impact point
                Vector impactPoint = tr.vecEndPos;
                
                // If we hit an entity, make sure the explosion happens at the surface
                if (tr.pHit !is null) {
                    CBaseEntity@ hitEntity = g_EntityFuncs.Instance(tr.pHit);
                    if (hitEntity !is null) {
                        // Adjust the impact point to be slightly in front of the hit surface
                        impactPoint = tr.vecEndPos - (vecAiming * 2);
                    }
                }

                // Play impact sound (quieter for shotgun pellets)
                g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_WEAPON, strSporeRoundsImpactSound, 0.5f, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-5, 5), 0, true, impactPoint);
                
                // Create smaller spore grenade-like effects for shotgun pellets
                // 1. Main explosion sprite (spore_exp_01) - smaller scale
                NetworkMessage msgExp(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msgExp.WriteByte(TE_SPRITE);
                msgExp.WriteCoord(impactPoint.x);
                msgExp.WriteCoord(impactPoint.y);
                msgExp.WriteCoord(impactPoint.z);
                msgExp.WriteShort(g_EngineFuncs.ModelIndex(strSporeRoundsExplosionSprite));
                msgExp.WriteByte(6); // Smaller scale for shotgun
                msgExp.WriteByte(180); // Brightness
                msgExp.End();
                
                // 2. Core explosion sprite (spore_exp_c_01) - smaller scale
                NetworkMessage msgCore(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msgCore.WriteByte(TE_SPRITE);
                msgCore.WriteCoord(impactPoint.x);
                msgCore.WriteCoord(impactPoint.y);
                msgCore.WriteCoord(impactPoint.z);
                msgCore.WriteShort(g_EngineFuncs.ModelIndex(strSporeRoundsExplosionCoreSprite));
                msgCore.WriteByte(4); // Smaller scale for shotgun
                msgCore.WriteByte(180); // Brightness
                msgCore.End();
                
                // 3. Small glow effect (glow01)
                NetworkMessage msgGlow(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msgGlow.WriteByte(TE_GLOWSPRITE);
                msgGlow.WriteCoord(impactPoint.x);
                msgGlow.WriteCoord(impactPoint.y);
                msgGlow.WriteCoord(impactPoint.z);
                msgGlow.WriteShort(g_EngineFuncs.ModelIndex(strSporeRoundsGlowSprite));
                msgGlow.WriteByte(2); // Life
                msgGlow.WriteByte(1); // Scale
                msgGlow.WriteByte(180); // Brightness
                msgGlow.End();
                
                // 4. Sprite trail burst effect for shotgun pellet splatter (smaller)
                // Create endpoints with impact point as the start point
                Vector startPoint = impactPoint;
                Vector endPoint = impactPoint;
                
                // End point moves outward from impact in a random direction
                endPoint.x = startPoint.x + Math.RandomFloat(-25, 25);
                endPoint.y = startPoint.y + Math.RandomFloat(-25, 25);
                endPoint.z = startPoint.z + Math.RandomFloat(5, 20); // Bias upward
                
                // Create sprite trail effect
                NetworkMessage msgTrail(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
                msgTrail.WriteByte(TE_SPRITETRAIL);
                msgTrail.WriteCoord(startPoint.x);
                msgTrail.WriteCoord(startPoint.y);
                msgTrail.WriteCoord(startPoint.z);
                msgTrail.WriteCoord(endPoint.x);
                msgTrail.WriteCoord(endPoint.y);
                msgTrail.WriteCoord(endPoint.z);
                msgTrail.WriteShort(g_EngineFuncs.ModelIndex(strSporeRoundsSplatterSprite));
                msgTrail.WriteByte(8);  // Count - fewer sprites for smaller effect
                msgTrail.WriteByte(2);  // Life in 0.1's
                msgTrail.WriteByte(1);  // Scale in 0.1's
                msgTrail.WriteByte(15); // Velocity along vector in 10's
                msgTrail.WriteByte(10); // Random velocity in 10's
                msgTrail.End();

                ApplyRadiusDamage(pPlayer, impactPoint, damageMultiplier); // Apply radius damage.
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
                
                // Add slight spread for burst fire
                Vector burstSpread = Vector(
                    Math.RandomFloat(-0.05, 0.05),
                    Math.RandomFloat(-0.05, 0.05),
                    Math.RandomFloat(-0.05, 0.05)
                );
                vecAiming = vecAiming + burstSpread;
                
                Vector vecEnd = vecSrc + (vecAiming * 8192); // Increased range

                TraceResult tr;
                g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr);
                
                // If we hit something, use that as the impact point
                Vector impactPoint = tr.vecEndPos;
                
                // If we hit an entity, make sure the explosion happens at the surface
                if (tr.pHit !is null) {
                    CBaseEntity@ hitEntity = g_EntityFuncs.Instance(tr.pHit);
                    if (hitEntity !is null) {
                        // Adjust the impact point to be slightly in front of the hit surface
                        impactPoint = tr.vecEndPos - (vecAiming * 2);
                    }
                }

                // Play impact sound (quieter for burst fire)
                g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_WEAPON, strSporeRoundsImpactSound, 0.4f, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-10, 10), 0, true, impactPoint);
                
                // Create very small spore grenade-like effects for burst fire
                // 1. Main explosion sprite (spore_exp_01) - smaller scale
                NetworkMessage msgExp(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msgExp.WriteByte(TE_SPRITE);
                msgExp.WriteCoord(impactPoint.x);
                msgExp.WriteCoord(impactPoint.y);
                msgExp.WriteCoord(impactPoint.z);
                msgExp.WriteShort(g_EngineFuncs.ModelIndex(strSporeRoundsExplosionSprite));
                msgExp.WriteByte(4); // Smaller scale for burst fire
                msgExp.WriteByte(160); // Brightness
                msgExp.End();
                
                // 2. Core explosion sprite (spore_exp_c_01) - smaller scale
                NetworkMessage msgCore(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msgCore.WriteByte(TE_SPRITE);
                msgCore.WriteCoord(impactPoint.x);
                msgCore.WriteCoord(impactPoint.y);
                msgCore.WriteCoord(impactPoint.z);
                msgCore.WriteShort(g_EngineFuncs.ModelIndex(strSporeRoundsExplosionCoreSprite));
                msgCore.WriteByte(3); // Smaller scale for burst fire
                msgCore.WriteByte(160); // Brightness
                msgCore.End();
                
                // 3. Tiny glow effect (glow01)
                NetworkMessage msgGlow(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                msgGlow.WriteByte(TE_GLOWSPRITE);
                msgGlow.WriteCoord(impactPoint.x);
                msgGlow.WriteCoord(impactPoint.y);
                msgGlow.WriteCoord(impactPoint.z);
                msgGlow.WriteShort(g_EngineFuncs.ModelIndex(strSporeRoundsGlowSprite));
                msgGlow.WriteByte(1); // Life
                msgGlow.WriteByte(1); // Scale
                msgGlow.WriteByte(160); // Brightness
                msgGlow.End();
                
                // 4. Just 1 sprite trail effect for M16 burst (very small)
                // Create endpoints with impact point as the start point
                Vector startPoint = impactPoint;
                Vector endPoint = impactPoint;
                
                // End point moves outward from impact in a random direction
                endPoint.x = startPoint.x + Math.RandomFloat(-15, 15);
                endPoint.y = startPoint.y + Math.RandomFloat(-15, 15);
                endPoint.z = startPoint.z + Math.RandomFloat(3, 15); // Bias upward
                
                // Create sprite trail effect
                NetworkMessage msgTrail(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
                msgTrail.WriteByte(TE_SPRITETRAIL);
                msgTrail.WriteCoord(startPoint.x);
                msgTrail.WriteCoord(startPoint.y);
                msgTrail.WriteCoord(startPoint.z);
                msgTrail.WriteCoord(endPoint.x);
                msgTrail.WriteCoord(endPoint.y);
                msgTrail.WriteCoord(endPoint.z);
                msgTrail.WriteShort(g_EngineFuncs.ModelIndex(strSporeRoundsSplatterSprite));
                msgTrail.WriteByte(3);  // Count
                msgTrail.WriteByte(1);  // Life in 0.1's
                msgTrail.WriteByte(1);  // Scale in 0.1's
                msgTrail.WriteByte(10); // Velocity along vector in 10's
                msgTrail.WriteByte(5);  // Random velocity in 10's
                msgTrail.End();

                ApplyRadiusDamage(pPlayer, impactPoint, damageMultiplier, DMG_POISON | DMG_BLAST); // Apply radius damage.

                ConsumeRound();
            }
        }
        else
        {
            Vector vecSrc = pPlayer.GetGunPosition(); // Get player's gun position.

            // Get player's view angles and convert to aim vector
            Vector angles = pPlayer.pev.v_angle;
            Math.MakeVectors(angles);
            Vector vecAiming = g_Engine.v_forward;

            Vector vecEnd = vecSrc + (vecAiming * 8192); // Increased range for better accuracy

            TraceResult tr;
            // Use a more precise tracing method
            g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr);
            
            // If we hit something, use that as the impact point
            Vector impactPoint = tr.vecEndPos;
            
            // If we hit an entity, make sure the explosion happens at the surface
            if (tr.pHit !is null) {
                CBaseEntity@ hitEntity = g_EntityFuncs.Instance(tr.pHit);
                if (hitEntity !is null) {
                    // Adjust the impact point to be slightly in front of the hit surface
                    impactPoint = tr.vecEndPos - (vecAiming * 2);
                }
            }

            // Play impact sound
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_WEAPON, strSporeRoundsImpactSound, 0.7f, ATTN_NORM, 0, PITCH_NORM, 0, true, impactPoint);
            
            // Create spore grenade-like explosion effects
            // 1. Main explosion sprite (spore_exp_01)
            NetworkMessage msgExp(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            msgExp.WriteByte(TE_SPRITE);
            msgExp.WriteCoord(impactPoint.x);
            msgExp.WriteCoord(impactPoint.y);
            msgExp.WriteCoord(impactPoint.z);
            msgExp.WriteShort(g_EngineFuncs.ModelIndex(strSporeRoundsExplosionSprite));
            msgExp.WriteByte(10); // Scale
            msgExp.WriteByte(200); // Brightness
            msgExp.End();
            
            // 2. Core explosion sprite (spore_exp_c_01)
            NetworkMessage msgCore(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            msgCore.WriteByte(TE_SPRITE);
            msgCore.WriteCoord(impactPoint.x);
            msgCore.WriteCoord(impactPoint.y);
            msgCore.WriteCoord(impactPoint.z);
            msgCore.WriteShort(g_EngineFuncs.ModelIndex(strSporeRoundsExplosionCoreSprite));
            msgCore.WriteByte(8); // Scale
            msgCore.WriteByte(200); // Brightness
            msgCore.End();
            
            // 3. Glow effect (glow01)
            NetworkMessage msgGlow(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            msgGlow.WriteByte(TE_GLOWSPRITE);
            msgGlow.WriteCoord(impactPoint.x);
            msgGlow.WriteCoord(impactPoint.y);
            msgGlow.WriteCoord(impactPoint.z);
            msgGlow.WriteShort(g_EngineFuncs.ModelIndex(strSporeRoundsGlowSprite));
            msgGlow.WriteByte(3); // Life
            msgGlow.WriteByte(2); // Scale
            msgGlow.WriteByte(200); // Brightness
            msgGlow.End();
            
            // 4. Sprite trail burst effect for splatter
            // Create endpoints with impact point as the start point
            Vector startPoint = impactPoint;
            Vector endPoint = impactPoint;
            
            // End point moves outward from impact in a random direction
            endPoint.x = startPoint.x + Math.RandomFloat(-50, 50);
            endPoint.y = startPoint.y + Math.RandomFloat(-50, 50);
            endPoint.z = startPoint.z + Math.RandomFloat(20, 50); // Bias upward
            
            // Create sprite trail effect
            NetworkMessage msgTrail(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
            msgTrail.WriteByte(TE_SPRITETRAIL);
            msgTrail.WriteCoord(startPoint.x);
            msgTrail.WriteCoord(startPoint.y);
            msgTrail.WriteCoord(startPoint.z);
            msgTrail.WriteCoord(endPoint.x);
            msgTrail.WriteCoord(endPoint.y);
            msgTrail.WriteCoord(endPoint.z);
            msgTrail.WriteShort(g_EngineFuncs.ModelIndex(strSporeRoundsSplatterSprite));
            msgTrail.WriteByte(16);  // Count - more sprites for a denser burst
            msgTrail.WriteByte(3);   // Life in 0.1's
            msgTrail.WriteByte(3);   // Scale in 0.1's
            msgTrail.WriteByte(25);  // Velocity along vector in 10's
            msgTrail.WriteByte(15);  // Random velocity in 10's - higher for more spread
            msgTrail.End();

            // Apply radius damage with poison and blast damage
            ApplyRadiusDamage(pPlayer, impactPoint, damageMultiplier, DMG_POISON | DMG_BLAST); // Apply radius damage.

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
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("bolts")) return "bolts";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("556")) return "556";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("762")) return "762";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("uranium")) return "uranium";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("m40a1")) return "m40a1";
    return "";
}