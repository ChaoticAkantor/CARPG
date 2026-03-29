string strShockrifleEquipSound = "weapons/shock_draw.wav";
string strShockLightningSound = "tor/tor-staff-discharge.wav";
string strShockLightningSprite = "sprites/lgtning.spr"; // Chain lightning bolt visual.

dictionary g_ShockRifleData;

class ShockRifleData 
{
    // Shocktrooper ability scaling values.
    private float m_flDamageScaleAtMaxLevel = 3.00f; // Damage modifier for shockrifle at max level.
    private float m_flShockroachMaxCapacityAtMaxLevel = 150.0f; // Extra max ammo capacity for shock rifle at max level.
    private float m_flLightningStrikePercent = 0.50f; // Percent of dealt damage applied as radius damage.
    private float m_flLightningStrikeRadius = 100.0f * 16.0f; // Radius of the area strike in units.
    private bool  m_bLightningActive = false; // Re-entrancy guard: prevents RadiusDamage from triggering another strike on nearby enemies.

    // Timers.
    private float m_flCooldown = 10.0f; // To account for ingame delay before being allowed to collect another shockroach.
    private float m_flLastUseTime = 0.0f; // Stores last use time.

    private ClassStats@ m_pStats = null;

    bool HasStats() { return m_pStats !is null; }    
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    
    float GetScaledDamage()
    {
        if(m_pStats is null)
            return 1.0f; // Normal damage if no stats.

        float shockrifleDamage = 1.0f; // Default damage multiplier.
            
        int level = m_pStats.GetLevel();
        float damagePerLevel = m_flDamageScaleAtMaxLevel / g_iMaxLevel;
        shockrifleDamage += damagePerLevel * level;

        return shockrifleDamage;
    }

    float GetScaledMaxAmmo()
    {
        if(m_pStats is null)
            return 100.0f; // Base max ammo if no stats.

        float maxAmmo = 100.0f; // Default max ammo.
            
        int level = m_pStats.GetLevel();
        float ammoPerLevel = m_flShockroachMaxCapacityAtMaxLevel  / g_iMaxLevel;
        maxAmmo += ammoPerLevel * level;

        return maxAmmo;
    }


    void EquipShockRifle(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !HasStats()) 
            return;

        string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamId))
            return;
            
        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamId]);
        if(resources is null)
            return;

        float flCurrentTime = g_Engine.time;
        float timeSinceLastUse = flCurrentTime - m_flLastUseTime;
        
        // Fix cooldown timer if it somehow exceeds our limit.
        if(timeSinceLastUse > m_flCooldown)
            timeSinceLastUse = m_flCooldown;
            
        // Check if player already has shock rifle.
        CBasePlayerItem@ pItem = pPlayer.HasNamedPlayerItem("weapon_shockrifle");
        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pItem);
        
        // If player has shock rifle and is holding it, handle dropping it as a shockroach.
        if(pWeapon !is null && pPlayer.m_hActiveItem.GetEntity() is pWeapon)
        {
            int ammoIndex = g_PlayerFuncs.GetAmmoIndex("shock charges");
            int currentAmmo = pPlayer.m_rgAmmo(ammoIndex); // Get current shock charge ammo.
            float flcurrentAmmo = float(currentAmmo) / 100.0f; // Convert to float for energy calculation (1 ammo = 0.01 energy).
            float flMaxAmmo = GetScaledMaxAmmo() / 100.0f; // Max ammo scaled by level (also converted to energy scale).

            // Refund half of remaining battery into energy.
            float currentEnergy = float(resources['current']);
            float maxEnergy = float(resources['max']);
            currentEnergy = Math.min(currentEnergy + (flcurrentAmmo / 2), maxEnergy); // Refund half remaining ammo as ability charge.
            resources['current'] = currentEnergy;
            
            // Force remove the weapon.
            g_EntityFuncs.Remove(pWeapon);
            
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "(+" + currentAmmo + ") Battery Recovered\n");
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_ITEM, strShockrifleEquipSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            
            m_flLastUseTime = 0.0f;
            return;
        }
        else if(pWeapon !is null) // If player has shock rifle but isn't holding it, do nothing.
        {
            return;
        }

        // Create new shock rifle - first check energy.
        float currentEnergy = float(resources['current']);
        float maxEnergy = float(resources['max']);
        if(currentEnergy < maxEnergy)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Shock Rifle recharging...\n");
            return;
        }
        
        // Now check cooldown since we have enough energy.
        if(timeSinceLastUse < m_flCooldown)
        {
            float remainingCooldown = m_flCooldown - timeSinceLastUse;
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Shock Rifle equip cooldown: " + int(remainingCooldown) + "s\n");
            return;
        }

        // Set energy to zero.
        resources['current'] = 0;

        // Get max ammo based on level.
        int ammotoGive = int(GetScaledMaxAmmo());
        
        // Give the weapon.
        pPlayer.GiveNamedItem("weapon_shockrifle");
        
        // Set scaled max capacity and give the ammo.
        int ammoIndex = g_PlayerFuncs.GetAmmoIndex("shock charges");
        pPlayer.m_rgAmmo(ammoIndex, ammotoGive);
        
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Shock Rifle equipped!\n");
        g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_WEAPON, strShockrifleEquipSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
        
        m_flLastUseTime = flCurrentTime;
    }

    void RemoveShockRifle(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;
            
        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pPlayer.HasNamedPlayerItem("weapon_shockrifle"));
        if(pWeapon !is null)
            g_EntityFuncs.Remove(pWeapon);
    }

    // Called from MonsterTakeDamage after the damage multiplier is applied.
    // Fires a lightning bolt from the sky above the target and deals area damage.
    void ApplyLightningStrike(CBasePlayer@ pAttacker, CBaseEntity@ pVictim, float flDealtDamage)
    {
        if(pAttacker is null || pVictim is null || flDealtDamage <= 0.0f)
            return;

        if(m_bLightningActive)
            return;

        Vector hitPos    = pVictim.pev.origin;
        float  strikeDmg = flDealtDamage * m_flLightningStrikePercent;
        int    sprIdx    = g_EngineFuncs.ModelIndex(strShockLightningSprite);
        Vector skyPos    = Vector(hitPos.x, hitPos.y, hitPos.z + 2048);

        // Lightning bolt from the sky down to the target.
        NetworkMessage bolt(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, hitPos);
            bolt.WriteByte(TE_LIGHTNING);
            bolt.WriteCoord(skyPos.x);
            bolt.WriteCoord(skyPos.y);
            bolt.WriteCoord(skyPos.z);
            bolt.WriteCoord(hitPos.x);
            bolt.WriteCoord(hitPos.y);
            bolt.WriteCoord(hitPos.z);
            bolt.WriteByte(10);   // Life * 0.1s.
            bolt.WriteByte(50);   // Width.
            bolt.WriteByte(80);  // Amplitude.
            bolt.WriteShort(sprIdx);
        bolt.End();

        // Dynamic light at the impact point.
        NetworkMessage dlight(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, hitPos);
            dlight.WriteByte(TE_DLIGHT);
            dlight.WriteCoord(hitPos.x);
            dlight.WriteCoord(hitPos.y);
            dlight.WriteCoord(hitPos.z);
            dlight.WriteByte(int(m_flLightningStrikeRadius)); // Radius.
            dlight.WriteByte(0); // R
            dlight.WriteByte(150); // G
            dlight.WriteByte(255); // B
            dlight.WriteByte(5);  // Life * 0.1s.
            dlight.WriteByte(10);   // Decay per 0.1s.
        dlight.End();

        m_bLightningActive = true; // Enable recursion guard.

        // Radius damage.
        g_WeaponFuncs.RadiusDamage(hitPos, pAttacker.pev, pAttacker.pev, strikeDmg, m_flLightningStrikeRadius, CLASS_PLAYER, DMG_SHOCK | DMG_ALWAYSGIB);
        
        // Play explosion sound.
        g_SoundSystem.EmitSound(pAttacker.edict(), CHAN_ITEM, strShockLightningSound, 1.0f, ATTN_NORM);

        m_bLightningActive = false; // Disable recursion guard.
    }
}

void ApplyMinionGlow(CBaseEntity@ pShockroachMinion)
{
    if(pShockroachMinion is null)
        return;
            
    // Apply the glowing effect.
    pShockroachMinion.pev.renderfx = kRenderFxGlowShell; // Effect.
    pShockroachMinion.pev.rendermode = kRenderNormal; // Render mode.
    pShockroachMinion.pev.renderamt = 1; // Shell thickness.
    pShockroachMinion.pev.rendercolor = Vector(0, 100, 250); // Blue.
}

void CheckWeaponsShockRifle()
{
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() != PlayerClass::CLASS_SHOCKTROOPER)
                {
                    // Remove shock rifle if player switches class.
                    CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pPlayer.HasNamedPlayerItem("weapon_shockrifle"));
                    if(pWeapon !is null)
                        g_EntityFuncs.Remove(pWeapon);
                }
            }
        }
    }
}