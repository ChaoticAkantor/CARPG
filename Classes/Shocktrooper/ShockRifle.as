string strShockrifleEquipSound = "weapons/shock_draw.wav";

dictionary g_ShockRifleData;

class ShockRifleData 
{
    private ClassStats@ m_pStats = null;
    private float m_flLastUseTime = 0.0f;
    private float m_flCooldown = 10.0f; // To account for ingame delay before being allowed to collect another shockroach.
    private float m_flDamageScalePerLevel = 0.03f; // Damage increase % for shockrifle per level.

    bool HasStats() { return m_pStats !is null; }    
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    
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
            
            // Get ammo index and current ammo.
            int ammoIndex = g_PlayerFuncs.GetAmmoIndex("shock charges");
            int currentAmmo = pPlayer.m_rgAmmo(ammoIndex) / 2; // Use half of the current remaining ammo as energy.
            
            // Sync player's energy with remaining ammo.
            float currentEnergy = float(resources['current']);
            float maxEnergy = float(resources['max']);
            currentEnergy = Math.min(currentEnergy + (currentAmmo), maxEnergy); // Restore half remaining battery into energy from held rifle.
            resources['current'] = currentEnergy;
            
            // Force remove the weapon.
            g_EntityFuncs.Remove(pWeapon);
            
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "STORED: 50%% Battery Recovered (+" + currentAmmo + ")\n");
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_ITEM, strShockrifleEquipSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            
            m_flLastUseTime = flCurrentTime;
            return;
        }
        // If player has shock rifle but isn't holding it, do nothing.
        else if(pWeapon !is null)
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
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Shock Rifle equip cooldown: " + int(remainingCooldown + 0.5) + "s\n");
            return;
        }

        // Use ALL current energy for the shock rifle.
        int energyToUse = int(currentEnergy);
        resources['current'] = 0; // Set energy to zero.
        
        // Give the weapon
        pPlayer.GiveNamedItem("weapon_shockrifle");
        
        // Set ammo to the amount of energy we just used.
        int ammoIndex = g_PlayerFuncs.GetAmmoIndex("shock charges");
        pPlayer.m_rgAmmo(ammoIndex, energyToUse);
        
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

    float GetScaledDamage()
    {
        if(m_pStats is null)
            return 1.0f;
            
        float damageBonus = m_pStats.GetLevel() * m_flDamageScalePerLevel;
        return 1.0f + damageBonus;
    }
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