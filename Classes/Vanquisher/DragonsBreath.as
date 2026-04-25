dictionary g_PlayerDragonsBreath;
string strDragonsBreathActivateSound = "weapons/reload3.wav";
string strDragonsBreathImpactSound = "weapons/explode3.wav"; // Explosion sound.
string strDragonsBreathExplosionSprite = "sprites/zerogxplode.spr"; // Explosion sprite.
string strDragonsBreathFireSprite = "sprites/fire.spr"; // Fire effect.

// Ammo types that are projectile-based (proc on target hit rather than on fire).
bool IsDragonsBreathProjectileAmmo(const string& in ammoName)
{
    if (ammoName == "uranium")       return true;
    if (ammoName == "rockets")       return true;
    if (ammoName == "bolts")         return true;
    if (ammoName == "sporeclip")     return true;
    if (ammoName == "ARgrenades")    return true;
    if (ammoName == "shock charges") return true;
    if (ammoName == "Hornets")       return true;
    return false;
}

// Damage multipliers per ammo type for Dragons Breath.
float GetDragonsBreathAmmoMultiplier(const string& in ammoName)
{
    if (ammoName == "9mm")      return 1.20f;
    if (ammoName == "357")      return 2.00f;
    if (ammoName == "buckshot") return 1.00f;
    if (ammoName == "556")      return 1.40f;
    if (ammoName == "bolts")    return 2.50f;
    //if (ammoName == "762")      return 2.50f;
    if (ammoName == "m40a1")    return 2.50f;
    if (ammoName == "uranium")  return 2.00f;
    if (ammoName == "rockets")  return 3.00f;
    if (ammoName == "sporeclip")  return 3.00f;
    if (ammoName == "ARgrenades") return 3.00f;
    if (ammoName == "shock charges") return 2.00f;
    if (ammoName == "Hornets") return 1.50f;
    return 1.0f; // Default multiplier if ammo type not found.
}

// Cost multipliers per ammo type for Dragons Breath activation.
float GetDragonsBreathAmmoCostMultiplier(const string& in ammoName)
{
    if (ammoName == "9mm")      return 1.0f;
    if (ammoName == "357")      return 3.0f;
    if (ammoName == "buckshot") return 6.0f; // One per pellet.
    if (ammoName == "556")      return 1.0f;
    if (ammoName == "bolts")    return 3.0f;
    //if (ammoName == "762")      return 3.0f;
    if (ammoName == "m40a1")    return 3.0f;
    if (ammoName == "uranium")  return 3.0f;
    if (ammoName == "rockets")  return 5.0f;
    if (ammoName == "sporeclip")   return 3.0f;
    if (ammoName == "ARgrenades") return 5.0f;
    if (ammoName == "shock charges") return 5.0f;
    if (ammoName == "Hornets") return 5.0f;
    return 1.0f; // Default cost multiplier if ammo type not found.
}

class DragonsBreathData
{
    // Dragons breath shots will place a DoT effect at impact location PER shot, with no limit, that stack over each other.

    // Fire Damage over Time.
    private float m_flAbilityMax = 1.0f; // Max activation charges.
    private float m_flAbilityRechargeTime = 60.0f; // Seconds to fully recharge all charges from empty.
    private float m_flDragonsBreathExplosionDamageBase = 1.0f; // Base damage for explosion on impact.
    private int m_iDragonsBreathFireTicks = 3; // Number of damage over time ticks PER DoT.
    private float m_flDragonsBreathFireInterval = 1.00f; // Interval in seconds between DoT ticks.
    private float m_flDragonsBreathRadius = 25.0f * 16; // Radius of fire damage DoT for Dragons Breath.
    private float m_flEnergyCostPerActivation = 1.0f; // Amount of energy to use per activation (Filling rounds).

    // Ammo pool.
    private int m_iDragonsBreathPoolBase = 30.0f; // Base max ammo pool for Dragons Breath.
    private float m_flRoundsFillPercentage = 50.0f; // Percentage of max ammo pool to fill per activation.
    private float m_flRoundsInPool = 0.0f; // Used to store rounds currently in pool.

    // Timers.
    private float m_flAbilityCharge = 0.0f;
    private float m_flLastToggleTime = 0.0f; // Used for last toggle time.
    private float m_flToggleCooldown = 0.10f; // Used to delay toggling to prevent spam.
    private float m_flCurrentClip = 0.0f; // Used to track current clip.
    private float m_flPreviousClip = 0.0f; // Used to track previous clip.
    private int m_iLastWeaponIndex = -1; // Used to detect weapon switches.
    private int m_iPendingProcs = 0; // Pending projectile procs waiting on a target hit.
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
    bool HasPendingProcs() { return m_iPendingProcs > 0; }
    float GetRounds() { return m_flRoundsInPool; }
    float GetEnergyCost() { return m_flEnergyCostPerActivation; }
    float GetPerShotCost() { return GetDragonsBreathAmmoCostMultiplier(m_strCurrentAmmoName); }
    void ResetRounds() { m_flRoundsInPool = 0; }
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    float GetAbilityCharge() { return m_flAbilityCharge; }
    float GetAbilityMax() { return m_flAbilityMax; }
    void FillAbilityCharge() { m_flAbilityCharge = GetAbilityMax(); }

    float GetScaledAbilityRecharge()
    {
        if (m_pStats is null)
            return SKILL_ABILITYRECHARGE; // Return base if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_ABILITYRECHARGE);
        float rechargeBonus = SKILL_ABILITYRECHARGE * skillLevel; // Bonus ability recharge speed based on skill level.

        return rechargeBonus + 1.0f;
    }

    void RechargeAbility()
    {
        if (m_flAbilityCharge >= m_flAbilityMax)
            return;

        float rechargeRate = m_flAbilityMax / m_flAbilityRechargeTime * GetScaledAbilityRecharge();
        m_flAbilityCharge += rechargeRate * flSchedulerInterval;
        if (m_flAbilityCharge > m_flAbilityMax)
            m_flAbilityCharge = m_flAbilityMax;
    }

    void Update(CBasePlayer@ pPlayer)
    {
        RechargeAbility();

        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pPlayer.m_hActiveItem.GetEntity());
        if(pWeapon is null)
        {
            m_iLastWeaponIndex = -1;
            return;
        }

        UpdateAmmoFromWeapon(pPlayer);

        int currentClip = pWeapon.m_iClip;
        int currentWeaponIdx = pWeapon.entindex();

        // Reset tracking on weapon switch or first run.
        if(currentWeaponIdx != m_iLastWeaponIndex)
        {
            m_iLastWeaponIndex = currentWeaponIdx;
            m_flPreviousClip = float(currentClip);
            m_iPendingProcs = 0; // Discard orphaned projectile procs on weapon switch.
            return;
        }

        if(HasRounds() && currentClip < int(m_flPreviousClip))
        {
            int ammoConsumed = int(m_flPreviousClip) - currentClip;
            for(int i = 0; i < ammoConsumed; i++)
            {
                if(!HasRounds()) break;
                if(IsProjectileAmmo(m_strCurrentAmmoName))
                {
                    m_iPendingProcs++;
                    ConsumeRound(); // Round is spent on fire; proc fires on impact.
                }
                else
                {
                    ProcExplosionForShot(pPlayer);
                }
            }
        }

        m_flPreviousClip = float(currentClip);
    }

    float GetScaledExplosionDamage() // Calculate scaled explosion damage.
    {
        if(m_pStats is null)
            return m_flDragonsBreathExplosionDamageBase;

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_VANQUISHER_EXPLOSIVEDAMAGE);
        float skillPower = SKILL_VANQUISHER_EXPLOSIVEDAMAGE;
        float modifier = skillPower * skillLevel; // Explosion damage scales from skill level.
        float dragonsBreathPower = m_flDragonsBreathExplosionDamageBase + modifier;

        dragonsBreathPower *= GetDragonsBreathAmmoMultiplier(m_strCurrentAmmoName); // Apply ammo type multiplier.

        return dragonsBreathPower;
    }

    float GetScaledFireDamage() // Calculate scaled fire damage.
    {
        if(m_pStats is null)
            return 0.0f; // No skill, no fire damage.

        float dragonsBreathFire = 0.0f;
        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_VANQUISHER_FIREDAMAGE);
        float skillPower = SKILL_VANQUISHER_FIREDAMAGE;
        float modifier = skillPower * skillLevel; // Fire damage percentage scales from skill level.

        dragonsBreathFire = GetScaledExplosionDamage() * modifier; // Dot damage is a percentage of explosion damage.

        return dragonsBreathFire;
    }

    float GetScaledFireDuration() // Calculate scaled fire duration.
    {
        if(m_pStats is null)
            return m_iDragonsBreathFireTicks * m_flDragonsBreathFireInterval; // Return base duration if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_VANQUISHER_FIREDURATION);
        float skillPower = SKILL_VANQUISHER_FIREDURATION;
        float modifier = m_iDragonsBreathFireTicks + (skillPower * skillLevel); // Fire duration increase scales from skill level.

        return modifier * m_flDragonsBreathFireInterval; // Total duration is modified ticks multiplied by interval.
    }

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
            fireAreaMsg.WriteByte(uint8(GetScaledFireDuration() * 10)); // Life * 0.1s.
            fireAreaMsg.WriteByte(uint8(GetScaledFireDuration() * 10)); // Fade speed * 1s.
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
        for(int firetick = 0; firetick < GetScaledFireDuration(); firetick++)
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

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_VANQUISHER_AMMOPOOL);
        float skillPower = SKILL_VANQUISHER_AMMOPOOL;
        float modifier = m_iDragonsBreathPoolBase * (1.0f + skillPower * skillLevel); // Ammo pool size increase based on skill level.

        return int(modifier);
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

        float energyCost = GetEnergyCost();
        if(m_flAbilityCharge < energyCost)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Need " + energyCost + " Charge!\n");
            return;
        }

        int roundsToAdd = GetAmmoPerPack();
        
        int oldRoundsInPool = int(m_flRoundsInPool);
        m_flRoundsInPool = Math.min(m_flRoundsInPool + roundsToAdd, float(GetMaxRounds()));
        int actualAdded = int(m_flRoundsInPool) - oldRoundsInPool;

        m_flAbilityCharge = Math.max(0.0f, m_flAbilityCharge - energyCost); // Deduct energy cost.

        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strDragonsBreathActivateSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "+" + actualAdded + " Dragon's Breath Rounds\n");

        m_flLastToggleTime = 0.0f;
    }

    void ProcPendingAtTarget(CBasePlayer@ pPlayer, Vector targetPos)
    {
        if(m_iPendingProcs <= 0)
            return;

        m_iPendingProcs--; // Decrement before firing to prevent recursion.
        FireExplosionVisuals(pPlayer, targetPos, 10);
        ApplyDragonsBreath(pPlayer, targetPos);
    }

    private bool IsProjectileAmmo(const string&in ammoName)
    {
        return IsDragonsBreathProjectileAmmo(ammoName);
    }

    private void ProcExplosionForShot(CBasePlayer@ pPlayer)
    {
        if(m_strCurrentAmmoName == "buckshot")
        {
            const int SHOTGUN_PELLETS = 6;
            for(int p = 0; p < SHOTGUN_PELLETS; p++)
            {
                Vector impactPoint = GetAimImpact(pPlayer, true);
                FireExplosionVisuals(pPlayer, impactPoint, 6);
                ApplyDragonsBreath(pPlayer, impactPoint);
            }
            ConsumeRound();
        }
        else
        {
            Vector impactPoint = GetAimImpact(pPlayer, false);
            FireExplosionVisuals(pPlayer, impactPoint, 10);
            ApplyDragonsBreath(pPlayer, impactPoint);
            ConsumeRound();
        }
    }

    private Vector GetAimImpact(CBasePlayer@ pPlayer, bool bSpread)
    {
        Vector vecSrc = pPlayer.GetGunPosition();
        Math.MakeVectors(pPlayer.pev.v_angle);
        Vector vecAiming = g_Engine.v_forward;

        if(bSpread)
            vecAiming = vecAiming + Vector(Math.RandomFloat(-0.05f, 0.05f), Math.RandomFloat(-0.05f, 0.05f), Math.RandomFloat(-0.05f, 0.05f));

        TraceResult tr;
        g_Utility.TraceLine(vecSrc, vecSrc + vecAiming * 8192, dont_ignore_monsters, pPlayer.edict(), tr);

        if(tr.pHit !is null && g_EntityFuncs.Instance(tr.pHit) !is null)
            return tr.vecEndPos - (vecAiming * 2);

        return tr.vecEndPos;
    }

    private void FireExplosionVisuals(CBasePlayer@ pPlayer, Vector impactPoint, int scale)
    {
        g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_STATIC, strDragonsBreathImpactSound, 0.6f, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong(-5, 5), 0, true, impactPoint);

        NetworkMessage msgExp(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
            msgExp.WriteByte(TE_SPRITE);
            msgExp.WriteCoord(impactPoint.x);
            msgExp.WriteCoord(impactPoint.y);
            msgExp.WriteCoord(impactPoint.z);
            msgExp.WriteShort(g_EngineFuncs.ModelIndex(strDragonsBreathExplosionSprite));
            msgExp.WriteByte(scale);
            msgExp.WriteByte(180);
        msgExp.End();
    }
}

void UpdateDragonsBreath()
{
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer is null || !pPlayer.IsConnected())
            continue;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerRPGData.exists(steamID))
            continue;

        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data is null || data.GetCurrentClass() != PlayerClass::CLASS_VANQUISHER)
            continue;

        if(!g_PlayerDragonsBreath.exists(steamID))
        {
            DragonsBreathData db;
            db.Initialize(data.GetCurrentClassStats());
            @g_PlayerDragonsBreath[steamID] = db;
        }

        DragonsBreathData@ db = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamID]);
        if(db !is null)
            db.Update(pPlayer);
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
        DMG_BURN | DMG_SLOWBURN | DMG_ALWAYSGIB // Damage type (Fire for DoT and stacking).
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
        DMG_BURN | DMG_SLOWBURN | DMG_ALWAYSGIB // Damage type.
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
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("9mm"))           return "9mm";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("357"))           return "357";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("buckshot"))      return "buckshot";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("556"))           return "556";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("bolts"))         return "bolts";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("rockets"))       return "rockets";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("uranium"))       return "uranium";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("m40a1"))         return "m40a1";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("sporeclip"))     return "sporeclip";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("ARgrenades"))    return "ARgrenades";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("shock charges")) return "shock charges";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("Hornets"))       return "Hornets";
    return "";
}