dictionary g_PlayerDragonsBreath;

class DragonsBreathBurn
{
    EHandle hTarget;
    EHandle hOwner;
    float flDamage;
    float flInterval;
    float flNextTick;
    int iTicksRemaining;
}

array<DragonsBreathBurn@> g_DragonsBreathBurns;
string strDragonsBreathActivateSound = "weapons/reload3.wav";
string strDragonsBreathImpactSound = "weapons/explode3.wav"; // Explosion sound.
string strDragonsBreathExplosionSprite = "sprites/zerogxplode.spr"; // Explosion sprite.
string strDragonsBreathFireSound = "sound/tfc/ambience/fire1.wav"; // Fire DoT sound.
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
    if (ammoName == "9mm")      return 1.0f;
    if (ammoName == "357")      return 1.0f;
    if (ammoName == "buckshot") return 0.15f; // Per pellet.
    if (ammoName == "556")      return 1.00f;
    if (ammoName == "bolts")    return 1.00f;
    //if (ammoName == "762")      return 2.00f;
    if (ammoName == "m40a1")    return 1.00f;
    if (ammoName == "uranium")  return 1.00f;
    if (ammoName == "rockets")  return 1.00f;
    if (ammoName == "sporeclip")  return 1.00f;
    if (ammoName == "ARgrenades") return 1.00f;
    if (ammoName == "shock charges") return 1.00f;
    if (ammoName == "Hornets") return 1.00f;
    return 1.0f; // Default multiplier if ammo type not found.
}

// Cost multipliers per ammo type for Dragons Breath activation.
float GetDragonsBreathAmmoCostMultiplier(const string& in ammoName)
{
    if (ammoName == "9mm")      return 1.0f;
    if (ammoName == "357")      return 2.0f;
    if (ammoName == "buckshot") return 6.0f; // One per pellet.
    if (ammoName == "556")      return 1.0f;
    if (ammoName == "bolts")    return 2.0f;
    //if (ammoName == "762")      return 2.0f;
    if (ammoName == "m40a1")    return 2.0f;
    if (ammoName == "uranium")  return 2.0f;
    if (ammoName == "rockets")  return 5.0f;
    if (ammoName == "sporeclip")   return 5.0f;
    if (ammoName == "ARgrenades") return 5.0f;
    if (ammoName == "shock charges") return 2.0f;
    if (ammoName == "Hornets") return 2.0f;
    return 1.0f; // Default cost multiplier if ammo type not found.
}

class DragonsBreathData
{
    // Ability.
    private float m_flAbilityMax = 100.0f; // Max activation charges.
    private float m_flAbilityCostPerActivation = 100.0f; // Amount of charge to use per activation (Filling rounds). Should match max for single activation only.
    private float m_flAbilityRechargeTime = 100.0f; // Seconds to fully recharge ability.
    private float m_flDragonsBreathExplosionDamageBase = 0.10f; // Radius damage as a percentage of weapon damage.
    private float m_flDragonsBreathFireDamageBase = 0.30f; // Fire damage per tick as a percentage of weapon damage.
    private int m_iDragonsBreathFireTicks = 6; // Duration of fire damage DoT for Dragons Breath.
    private float m_flDragonsBreathFireInterval = 1.00f; // Interval in seconds between DoT ticks.
    private float m_flDragonsBreathRadius = 25.0f * 16; // Radius of fire damage DoT for Dragons Breath.

    // Ammo pool.
    private int m_iDragonsBreathPoolBase = 30.0f; // Base max ammo pool for Dragons Breath.
    private float m_flRoundsFillPercentage = 100.0f; // Percentage of max ammo pool to fill per activation.
    private float m_flRoundsInPool = 0.0f; // Used to store rounds currently in pool.

    // Timers.
    private float m_flAbilityCharge = 0.0f; // Used to store current ability charge.
    private float m_flLastToggleTime = 0.0f; // Used for last toggle time.
    private float m_flToggleCooldown = 0.10f; // Used to delay toggling to prevent spam.
    private float m_flCurrentClip = 0.0f; // Used to track current clip.
    private float m_flPreviousClip = 0.0f; // Used to track previous clip.
    private int m_iPreviousAmmoIndex = 0; // Used to track ammo index for non-clip weapons.
    private int m_iPreviousAmmo = 0; // Used to track previous ammo count for non-clip weapons.
    private int m_iLastWeaponIndex = -1; // Used to detect weapon switches.
    private int m_iPendingProcs = 0; // Pending projectile procs waiting on a target hit.
    private float m_flDirectDamage = 0.0f;
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

    void RecordDirectDamage(CBasePlayer@ pPlayer, float flDamage, int bitsDamageType)
    {
        if(pPlayer is null || flDamage <= 0.0f || (bitsDamageType & (DMG_BLAST | DMG_BURN | DMG_SLOWBURN)) != 0)
            return;

        UpdateAmmoFromWeapon(pPlayer);
        if(!IsProjectileAmmo(m_strCurrentAmmoName))
            m_flDirectDamage = Math.max(m_flDirectDamage, flDamage);
    }

    bool HasStats() { return m_pStats !is null; }
    bool HasRounds() { return m_flRoundsInPool > 0; }
    bool HasPendingProcs() { return m_iPendingProcs > 0; }
    float GetRounds() { return m_flRoundsInPool; }
    float GetAbilityCost() { return m_flAbilityCostPerActivation; }
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
        float directDamageThisUpdate = m_flDirectDamage;
        m_flDirectDamage = 0.0f;

        int currentClip = pWeapon.m_iClip;
        int currentWeaponIdx = pWeapon.entindex();
        int maxClip = pWeapon.iMaxClip();
        int ammoTypeIdx = pWeapon.PrimaryAmmoIndex();

        // Reset tracking on weapon switch or first run.
        if(currentWeaponIdx != m_iLastWeaponIndex)
        {
            m_iLastWeaponIndex = currentWeaponIdx;
            m_flPreviousClip = float(currentClip);
            m_iPreviousAmmoIndex = ammoTypeIdx;
            m_iPreviousAmmo = 0;
            if(ammoTypeIdx >= 0)
                m_iPreviousAmmo = pPlayer.m_rgAmmo(ammoTypeIdx);
            m_iPendingProcs = 0; // Discard orphaned projectile procs on weapon switch.
            return;
        }

        int ammoConsumed = 0;

        // Detect ammo consumption based on weapon type.
        if(currentClip != -1 && maxClip != -1 || ammoTypeIdx == -1)
        {
            // Clip-based weapon - track clip changes.
            if(HasRounds() && currentClip < int(m_flPreviousClip))
            {
                ammoConsumed = int(m_flPreviousClip) - currentClip;
            }
            m_flPreviousClip = float(currentClip);
        }
        else if(currentClip == -1 && maxClip == -1 && ammoTypeIdx >= 0)
        {
            // Non-clip weapon - track ammo index changes.
            // When ammo is consumed, the count value decreases.
            int currentAmmo = pPlayer.m_rgAmmo(ammoTypeIdx);
            
            if(m_iPreviousAmmoIndex == ammoTypeIdx)
            {
                if(HasRounds() && currentAmmo < m_iPreviousAmmo)
                {
                    ammoConsumed = m_iPreviousAmmo - currentAmmo;
                }
            }
            
            m_iPreviousAmmo = currentAmmo;
            m_iPreviousAmmoIndex = ammoTypeIdx;
        }

        if(HasRounds() && ammoConsumed > 0)
        {
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
                    ProcExplosionForShot(pPlayer, directDamageThisUpdate);
                }
            }
        }
    }

    float GetScaledExplosionDamagePercent()
    {
        int skillLevel = 0;
        if(m_pStats !is null)
            skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_FIREBUG_EXPLOSIVEDAMAGE);

        return m_flDragonsBreathExplosionDamageBase * (1.0f + SKILL_FIREBUG_EXPLOSIVEDAMAGE * skillLevel);
    }

    float GetScaledExplosionDamage(float flDirectDamage)
    {
        return flDirectDamage * GetScaledExplosionDamagePercent() * GetDragonsBreathAmmoMultiplier(m_strCurrentAmmoName);
    }

    float GetScaledFireDamagePercent()
    {
        int skillLevel = 0;
        if(m_pStats !is null)
            skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_FIREBUG_FIREDAMAGE);

        float fireDamagePercent = m_flDragonsBreathFireDamageBase * (1.0f +SKILL_FIREBUG_FIREDAMAGE * skillLevel);
        //return fireDamagePercent * GetDragonsBreathAmmoMultiplier(m_strCurrentAmmoName);
        return fireDamagePercent;
    }

    float GetScaledFireDamage(float flDirectDamage)
    {
        return flDirectDamage * GetScaledFireDamagePercent();
    }

    float GetScaledFireDuration() // Calculate scaled fire duration.
    {
        if(m_pStats is null)
            return m_iDragonsBreathFireTicks * m_flDragonsBreathFireInterval; // Return base duration if no stats.

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_FIREBUG_FIREDURATION);
        float modifier = 1.0f + (SKILL_FIREBUG_FIREDURATION * skillLevel);
        float baseDuration = m_iDragonsBreathFireTicks * m_flDragonsBreathFireInterval;

        return baseDuration * modifier;
    }

    float GetFireInterval() { return m_flDragonsBreathFireInterval; } // Get fire DoT tick interval.

    float GetFireRadius() { return m_flDragonsBreathRadius; } // Get fire DoT radius.

    float GetAmmoRefillPercent() { return m_flRoundsFillPercentage; } // Get refill percentage.

    int GetAmmoPerPack() // Calculate number of rounds to add per pack.
    {
        if(m_pStats is null)
            return m_iDragonsBreathPoolBase; // If no stats, return base.

        int maxRounds = GetMaxRounds();
        int roundsToAdd = int(maxRounds * (m_flRoundsFillPercentage / 100));
        return Math.max(1, roundsToAdd); // Always return at least 1 round.
    }

    // Apply one blast and ignite each eligible enemy in its radius.
    void ApplyDragonsBreath(CBasePlayer@ pPlayer, Vector impactPoint, float flDirectDamage)
    {
        if(pPlayer is null)
            return;

        // Apply dynamic light for flash effect.
        NetworkMessage fireAreaMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
            fireAreaMsg.WriteByte(TE_DLIGHT);
            fireAreaMsg.WriteCoord(impactPoint.x);
            fireAreaMsg.WriteCoord(impactPoint.y);
            fireAreaMsg.WriteCoord(impactPoint.z);
            fireAreaMsg.WriteByte(16); // Radius units * 10.
            fireAreaMsg.WriteByte(255); // Red.
            fireAreaMsg.WriteByte(100); // Green.
            fireAreaMsg.WriteByte(15); // Blue.
            fireAreaMsg.WriteByte(uint8(1)); // Life * 0.1s.
            fireAreaMsg.WriteByte(uint8(1)); // Fade speed * 1s.
            fireAreaMsg.End();

        ApplyExplosionDamage(pPlayer.entindex(), impactPoint, flDirectDamage);
        ApplyDragonsBreathFire(pPlayer, impactPoint, flDirectDamage);
    }

    // Apply a single tracked burn to each enemy in the area.
    void ApplyDragonsBreathFire(CBasePlayer@ pPlayer, Vector impactPoint, float flDirectDamage)
    {
        if(pPlayer is null)
            return;

        float fireDamage = GetScaledFireDamage(flDirectDamage);
        float fireInterval = GetFireInterval();
        int fireTicks = int(GetScaledFireDuration() / fireInterval + 0.5f);
        if(fireDamage <= 0.0f || fireTicks <= 0)
            return;

        float fireRadius = GetFireRadius();
        CBaseEntity@ pEntity = null;
        while((@pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, impactPoint, fireRadius + 256.0f, "*", "classname")) !is null)
        {
            CBaseMonster@ pMonster = cast<CBaseMonster@>(pEntity);
            if(pMonster is null || !pMonster.IsAlive() || pMonster.IRelationship(pPlayer) == R_AL)
                continue;

            Vector targetMins = pMonster.pev.origin + pMonster.pev.mins;
            Vector targetMaxs = pMonster.pev.origin + pMonster.pev.maxs;
            Vector closestPoint;
            closestPoint.x = Math.max(targetMins.x, Math.min(targetMaxs.x, impactPoint.x));
            closestPoint.y = Math.max(targetMins.y, Math.min(targetMaxs.y, impactPoint.y));
            closestPoint.z = Math.max(targetMins.z, Math.min(targetMaxs.z, impactPoint.z));
            if((closestPoint - impactPoint).Length() > fireRadius)
                continue;

            if(StartDragonsBreathBurn(pMonster, pPlayer, fireDamage, fireInterval, fireTicks))
                ShowDragonsBreathBurn(pMonster);
        }
    }

    void ConsumeRound() 
    { 
        m_flRoundsInPool = Math.max(0.0f, m_flRoundsInPool - 1.0f * GetPerShotCost()); // Consume rounds based on ammo type cost multiplier.
    }

    int GetMaxRounds()
    {
        if(m_pStats is null)
            return m_iDragonsBreathPoolBase;

        int skillLevel = m_pStats.GetSkillLevel(SkillID::SKILL_FIREBUG_AMMOPOOL);
        float skillPower = SKILL_FIREBUG_AMMOPOOL;
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

        float abilityCost = GetAbilityCost();
        if(m_flAbilityCharge < abilityCost)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Need " + abilityCost + " Charge!\n");
            return;
        }

        int roundsToAdd = GetAmmoPerPack();
        
        int oldRoundsInPool = int(m_flRoundsInPool);
        m_flRoundsInPool = Math.min(m_flRoundsInPool + roundsToAdd, float(GetMaxRounds()));
        int actualAdded = int(m_flRoundsInPool) - oldRoundsInPool;

        m_flAbilityCharge = Math.max(0.0f, m_flAbilityCharge - abilityCost); // Deduct ability cost.

        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strDragonsBreathActivateSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "+" + actualAdded + " Dragon's Breath Rounds\n");

        m_flLastToggleTime = 0.0f;
    }

    void ProcPendingAtTarget(CBasePlayer@ pPlayer, Vector targetPos, float flDirectDamage)
    {
        if(m_iPendingProcs <= 0)
            return;

        m_iPendingProcs--; // Decrement before firing to prevent recursion.
        FireExplosionVisuals(pPlayer, targetPos, 10);
        ApplyDragonsBreath(pPlayer, targetPos, flDirectDamage);
    }

    private bool IsProjectileAmmo(const string&in ammoName)
    {
        return IsDragonsBreathProjectileAmmo(ammoName);
    }

    private void ProcExplosionForShot(CBasePlayer@ pPlayer, float flDirectDamage)
    {
        if(m_strCurrentAmmoName == "buckshot")
        {
            const int SHOTGUN_PELLETS = 6;
            for(int p = 0; p < SHOTGUN_PELLETS; p++)
            {
                Vector impactPoint = GetAimImpact(pPlayer, true);
                FireExplosionVisuals(pPlayer, impactPoint, 6);
                ApplyDragonsBreath(pPlayer, impactPoint, flDirectDamage);
            }
            ConsumeRound();
        }
        else
        {
            Vector impactPoint = GetAimImpact(pPlayer, false);
            FireExplosionVisuals(pPlayer, impactPoint, 10);
            ApplyDragonsBreath(pPlayer, impactPoint, flDirectDamage);
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
            msgExp.WriteShort(GetModelIndex(strDragonsBreathExplosionSprite));
            msgExp.WriteByte(scale);
            msgExp.WriteByte(180);
        msgExp.End();
    }
}

void UpdateDragonsBreath()
{
    UpdateDragonsBreathBurns();

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
        if(data is null || data.GetCurrentClass() != PlayerClass::CLASS_FIREBUG)
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

bool StartDragonsBreathBurn(CBaseEntity@ pTarget, CBasePlayer@ pOwner, float flDamage, float flInterval, int iTicks)
{
    if(pTarget is null || pOwner is null || flDamage <= 0.0f || iTicks <= 0)
        return false;

    for(int i = int(g_DragonsBreathBurns.length()) - 1; i >= 0; i--)
    {
        DragonsBreathBurn@ burn = g_DragonsBreathBurns[i];
        CBaseEntity@ existingTarget = burn.hTarget.GetEntity();
        if(existingTarget is null || !existingTarget.IsAlive() || burn.iTicksRemaining <= 0)
        {
            g_DragonsBreathBurns.removeAt(i);
            continue;
        }

        if(existingTarget is pTarget)
        {
            burn.iTicksRemaining = iTicks;
            burn.flNextTick = g_Engine.time + burn.flInterval;
            return true;
        }
    }

    DragonsBreathBurn@ burn = DragonsBreathBurn();
    burn.hTarget = EHandle(pTarget);
    burn.hOwner = EHandle(pOwner);
    burn.flDamage = flDamage;
    burn.flInterval = flInterval;
    burn.flNextTick = g_Engine.time + flInterval;
    burn.iTicksRemaining = iTicks;
    g_DragonsBreathBurns.insertLast(burn);
    return true;
}

void ShowDragonsBreathBurn(CBaseEntity@ pTarget)
{
    if(pTarget is null)
        return;

    Vector targetMins = pTarget.pev.origin + pTarget.pev.mins;
    Vector targetMaxs = pTarget.pev.origin + pTarget.pev.maxs;
    NetworkMessage bubbles(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pTarget.pev.origin);
        bubbles.WriteByte(TE_BUBBLES);
        bubbles.WriteCoord(targetMins.x);
        bubbles.WriteCoord(targetMins.y);
        bubbles.WriteCoord(targetMins.z);
        bubbles.WriteCoord(targetMaxs.x);
        bubbles.WriteCoord(targetMaxs.y);
        bubbles.WriteCoord(targetMaxs.z);
        bubbles.WriteCoord(80.0f); // Height of bubble effect.
        bubbles.WriteShort(GetModelIndex(strDragonsBreathFireSprite));
        bubbles.WriteByte(10); // Count.
        bubbles.WriteCoord(6.0f); // Speed.
    bubbles.End();
}

void UpdateDragonsBreathBurns()
{
    float currentTime = g_Engine.time;
    CBaseEntity@ pWorld = g_EntityFuncs.Instance(0);

    for(int i = int(g_DragonsBreathBurns.length()) - 1; i >= 0; i--)
    {
        DragonsBreathBurn@ burn = g_DragonsBreathBurns[i];
        CBaseEntity@ pTarget = burn.hTarget.GetEntity();
        CBaseEntity@ pOwner = burn.hOwner.GetEntity();
        CBaseMonster@ pMonster = cast<CBaseMonster@>(pTarget);

        if(pMonster is null || !pMonster.IsAlive() || burn.iTicksRemaining <= 0)
        {
            g_DragonsBreathBurns.removeAt(i);
            continue;
        }

        if(currentTime < burn.flNextTick)
            continue;

        if(pOwner !is null && pMonster.IRelationship(pOwner) == R_AL)
        {
            g_DragonsBreathBurns.removeAt(i);
            continue;
        }

        CBaseEntity@ attacker = pOwner is null ? pWorld : pOwner;
        if(attacker !is null)
        {
            pMonster.TakeDamage(attacker.pev, attacker.pev, burn.flDamage, DMG_BURN);
            ShowDragonsBreathBurn(pMonster);
        }

        burn.iTicksRemaining--;
        if(burn.iTicksRemaining <= 0)
            g_DragonsBreathBurns.removeAt(i);
        else
            burn.flNextTick = currentTime + burn.flInterval;
    }
}

void ApplyExplosionDamage(int playerIdx, Vector impactPoint, float flDirectDamage)
{
    CBasePlayer@ pPlayer = cast<CBasePlayer@>(g_EntityFuncs.Instance(playerIdx));
    if(pPlayer is null)
        return;

    string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(!g_PlayerDragonsBreath.exists(steamId))
        return;

    DragonsBreathData@ dragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamId]);
    if(dragonsBreath is null)
        return;

    g_WeaponFuncs.RadiusDamage(
        impactPoint,
        pPlayer.pev,
        pPlayer.pev,
        dragonsBreath.GetScaledExplosionDamage(flDirectDamage),
        dragonsBreath.GetFireRadius(),
        CLASS_PLAYER,
        DMG_BLAST
    );

    NetworkMessage msgFireArea(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, impactPoint);
        msgFireArea.WriteByte(TE_SPRITETRAIL);
        msgFireArea.WriteCoord(impactPoint.x);
        msgFireArea.WriteCoord(impactPoint.y);
        msgFireArea.WriteCoord(impactPoint.z);
        msgFireArea.WriteCoord(impactPoint.x);
        msgFireArea.WriteCoord(impactPoint.y);
        msgFireArea.WriteCoord(impactPoint.z);
        msgFireArea.WriteShort(GetModelIndex(strDragonsBreathFireSprite));
        msgFireArea.WriteByte(2);
        msgFireArea.WriteByte(1);
        msgFireArea.WriteByte(5);
        msgFireArea.WriteByte(50);
        msgFireArea.WriteByte(50);
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