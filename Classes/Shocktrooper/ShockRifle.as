string strShockrifleEquipSound = "weapons/shock_draw.wav";

dictionary g_ShockRifleData;

class ShockRifleData 
{
    // Shocktrooper ability scaling values.
    private float m_flDamageScaleAtMaxLevel = 3.00f; // Damage modifier for shockrifle at max level.
    private float m_flShockroachAmmoToHealthModifier = 5.0f; // Multiplier for shockroach health based on remaining ammo when deployed.
    private float m_flShockroachDefaultMaxCapacity = 100.0f; // Default max ammo capacity for shock rifle.
    private float m_flShockroachMaxCapacityAtMaxLevel = 250.0f; // Max ammo capacity for shock rifle at max level.
    // Currently a dropped shockroach does nothing but be a decoy, needs a better idea to replace it.

    // Timers.
    private float m_flCooldown = 10.0f; // SHOULD NOT BE CHANGED. To account for ingame delay before being allowed to collect another shockroach.
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
            return m_flShockroachDefaultMaxCapacity; // Base max ammo if no stats.

        float maxAmmo = m_flShockroachDefaultMaxCapacity; // Default max ammo.
            
        int level = m_pStats.GetLevel();
        float ammoPerLevel = m_flShockroachMaxCapacityAtMaxLevel  / g_iMaxLevel;
        maxAmmo += ammoPerLevel * level;

        return maxAmmo;
    }

    float GetShockroachHealth(CBasePlayer@ pPlayer)
    {
        if (pPlayer is null)
            return 100.0f; // Return base health if no player reference.

        if(m_pStats is null)
            return 100.0f; // Return base health without scaling if no stats.

        float ShockroachHealth = 100.0f; // Start with base health.

        // Get ammo index and current ammo.
        int ammoIndex = g_PlayerFuncs.GetAmmoIndex("shock charges");
        int currentAmmo = pPlayer.m_rgAmmo(ammoIndex); // Get current ammo remaining.

        ShockroachHealth *= m_flShockroachAmmoToHealthModifier * (float(currentAmmo) / 100); // Scale health based on remaining ammo.

        return ShockroachHealth;
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
        
        // If player has shock rifle and is holding it, handle stowing it.
        if(pWeapon !is null && pPlayer.m_hActiveItem.GetEntity() is pWeapon)
        {
            // Check cooldown only when attempting to stow.
            if(timeSinceLastUse < m_flCooldown)
            {
                float remainingCooldown = m_flCooldown - timeSinceLastUse;
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Shock Rifle on cooldown: " + int(remainingCooldown + 0.5) + "s\n");
                return;
            }

            /*
            // Sync player's energy with remaining ammo.
            float currentEnergy = float(resources['current']);
            float maxEnergy = float(resources['max']);
            currentEnergy = Math.min(currentEnergy + (currentAmmo), maxEnergy); // Restore half remaining battery into energy from held rifle.
            resources['current'] = currentEnergy;
            */
            
            // Force remove the weapon.
            g_EntityFuncs.Remove(pWeapon);

            // Spawn a friendly shockroach with health based on remaining ammo.
            SpawnShockroach(pPlayer);
            
            //g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "STORED: 50%% Battery Recovered (+" + currentAmmo + ")\n");
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_ITEM, strShockrifleEquipSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            
            m_flLastUseTime = 0.0f;
            return;
        }
        else if(pWeapon !is null) // If player has shock rifle but isn't holding it, do nothing.
        {
            //g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "You must be holding a Shock Rifle to stow it.\n");
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

    void SpawnShockroach(CBasePlayer@ pPlayer)
        {
            if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
                return;

            Vector vecSrc = pPlayer.GetGunPosition();
            Vector spawnForward, spawnRight, spawnUp;
            g_EngineFuncs.AngleVectors(pPlayer.pev.v_angle, spawnForward, spawnRight, spawnUp);
            
            vecSrc = vecSrc + (spawnForward * 64);
            vecSrc.z -= 32;

            float scaledHealth = GetShockroachHealth(pPlayer);
            
            dictionary keys;
            keys["origin"] = vecSrc.ToString();
            keys["angles"] = Vector(0, pPlayer.pev.angles.y, 0).ToString();
            keys["targetname"] = "_minion_" + pPlayer.entindex();
            keys["displayname"] = "Super Shockroach";
            keys["health"] = string(GetShockroachHealth(pPlayer));
            keys["scale"] = "1";
            keys["friendly"] = "1";
            keys["spawnflags"] = "16384";
            keys["is_player_ally"] = "1";
            keys["skin"] = "2";

            CBaseEntity@ pShockroachMinion = g_EntityFuncs.CreateEntity("monster_shockroach", keys, true);
            if(pShockroachMinion !is null)
            {   
                // Apply glow effect before dispatch.
                ApplyMinionGlow(pShockroachMinion);

                g_EntityFuncs.DispatchSpawn(pShockroachMinion.edict()); // Dispatch the entity.

                // Stuff to set after dispatch.
                //@pShockroachMinion.pev.owner = @pPlayer.edict(); // Set owner to spawning player.
                //pShockroachMinion.pev.solid = SOLID_NOT;

                g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_STATIC, strShockrifleEquipSound, 1.0f, ATTN_NORM);
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Shockroach deployed!\n");
            }
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