// Plugin Created by Chaotic Akantor as ammo recovery system for CARPG.
// This file handles player ammo recovery.

float flAmmoTick = 31.0; // How long between each ammo resupply.
string g_AmmoPrefixMessage = ""; // Store prefix message to display to connecting players.

bool g_bShowAmmoPickupNotification = true; // Toggle for method of giving ammo, with or without notification and sounds.
bool g_bShowAmmoPrefixMessage = true; // Toggle for displaying prefix message in chat.

dictionary g_AmmoMapMultipliers;

float g_CurrentAmmoMapMultiplier = 1.0f;
float g_LastAmmoRegenTime = 0.0f; // Track when last ammo regen occurred.

// Define an AmmoType class to store all properties for each ammo type.
class AmmoType 
{
    string name;        // Ammo name like "9mm" or "health".
    int amount;         // Amount to regenerate each time.
    int maxAmount;      // Maximum amount player can carry.
    int baseAmount;     // Base regeneration amount (for scaling).
    int baseMaxAmount;  // Base maximum (for scaling).
    int threshold;      // Threshold for special ammo types.
    bool hasThreshold;  // Whether this ammo uses threshold logic.
    bool isExplosive;   // Whether this ammo is an explosive type (disabled if map modifier is active).
    
    AmmoType(string ammoName, int regenAmount, int maxAmmo, bool useThreshold = false, int thresholdValue = 0, bool explosive = false) 
    {
        name = ammoName;
        amount = regenAmount;
        baseAmount = regenAmount;
        maxAmount = maxAmmo;
        baseMaxAmount = maxAmmo;
        hasThreshold = useThreshold;
        threshold = thresholdValue;
        isExplosive = explosive;
    }
}

array<AmmoType@> g_AmmoTypes; // Store all ammo types in an array.

void InitializeAmmoRegen() 
{
    // Clear existing ammo types first.
    g_AmmoTypes.resize(0);
    
    // Initialize timer tracking.
    g_LastAmmoRegenTime = g_Engine.time;

    // Balance ammo resupply separately for different map series by multiplying the amount of ammo given.
    g_AmmoMapMultipliers["th_"] = 0.5f;    // They Hunger.
    g_AmmoMapMultipliers["aom_"] = 0.5f;   // Afraid of Monsters Classic.
    g_AmmoMapMultipliers["aomdc_"] = 0.5f; // Afraid of Monsters Directors-Cut.
    g_AmmoMapMultipliers["hl_"] = 0.8f;    // Half-Life Campaign.
    g_AmmoMapMultipliers["of_"] = 0.8f;    // Opposing-Force Campaign.
    g_AmmoMapMultipliers["bs_"] = 0.8f;    // Blue-Shift Campaign.

    string mapName = string(g_Engine.mapname).ToLowercase(); // Update map multiplier before creating ammo types.
    g_CurrentAmmoMapMultiplier = 1.0f; // Default multiplier.
    g_AmmoPrefixMessage = ""; // Reset message to default.
    
    dictionary@ prefixes = g_AmmoMapMultipliers;
    array<string>@ prefixKeys = prefixes.getKeys();
    
    for(uint i = 0; i < prefixKeys.length(); i++)
    {
        string prefix = prefixKeys[i].ToLowercase();
        if(mapName.Length() >= prefix.Length() && mapName.SubString(0, prefix.Length()) == prefix)
        {
            g_CurrentAmmoMapMultiplier = float(prefixes[prefixKeys[i]]);
            g_AmmoPrefixMessage = "=== CARPG Ammo Resupply: ===\nMap prefix '" + prefixKeys[i] + "' detected.\nAmmo Resupply: " + g_CurrentAmmoMapMultiplier + "x. Throwables | DISABLED.";
            g_Game.AlertMessage(at_console, g_AmmoPrefixMessage + "\n\n");
            break;
        }
    }
    
    // Initialize ammo types (all regen on same universal tick).
    g_AmmoTypes.insertLast(AmmoType("health", 50, 100, true, 100));
    g_AmmoTypes.insertLast(AmmoType("9mm", 60, 300));
    g_AmmoTypes.insertLast(AmmoType("buckshot", 8, 125));
    g_AmmoTypes.insertLast(AmmoType("357", 6, 36));
    g_AmmoTypes.insertLast(AmmoType("556", 30, 600));
    g_AmmoTypes.insertLast(AmmoType("m40a1", 4, 25));
    g_AmmoTypes.insertLast(AmmoType("bolts", 5, 30));
    g_AmmoTypes.insertLast(AmmoType("sporeclip", 1, 20));
    g_AmmoTypes.insertLast(AmmoType("Hornets", 25, 100));
    g_AmmoTypes.insertLast(AmmoType("shock charges", 15, 100));
    g_AmmoTypes.insertLast(AmmoType("uranium", 10, 100));
    
    // Threshold-based ammo types (explosives, etc).
    g_AmmoTypes.insertLast(AmmoType("Hand Grenade", 1, 10, true, 1, true));
    g_AmmoTypes.insertLast(AmmoType("ARgrenades", 1, 10, true, 2, true));
    g_AmmoTypes.insertLast(AmmoType("Satchel Charge", 1, 10, true, 1, true));
    g_AmmoTypes.insertLast(AmmoType("Trip Mine", 1, 10, true, 1, true));
    g_AmmoTypes.insertLast(AmmoType("rockets", 1, 10, true, 2, true));
    g_AmmoTypes.insertLast(AmmoType("Snarks", 5, 15, true, 15, true));
}

void AmmoTimerTick()
{
    g_LastAmmoRegenTime = g_Engine.time; // Update last regen time.
    
    const int iMaxPlayers = g_Engine.maxClients;
    for(int playerIndex = 1; playerIndex <= iMaxPlayers; ++playerIndex)
    {   
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(playerIndex);
        if(pPlayer is null || !pPlayer.IsAlive() || !pPlayer.IsConnected())
            continue;

        // Process ammo regeneration for all ammo types on every tick.
        for(uint ammoIndex = 0; ammoIndex < g_AmmoTypes.length(); ammoIndex++)
        {
            AmmoType@ ammoType = g_AmmoTypes[ammoIndex];
            if(ammoType is null)
                continue;
            
            // Skip explosives if map modifier is active
            if(ammoType.isExplosive && g_CurrentAmmoMapMultiplier != 1.0f)
                continue;
                
            int gameAmmoIndex = g_PlayerFuncs.GetAmmoIndex(ammoType.name);
            if(gameAmmoIndex >= 0)
            {
                // Ensure player has explosive weapon even if ammo is full.
                string weaponName = GetWeaponNameFromAmmoType(ammoType.name);
                if(!weaponName.IsEmpty())
                {
                    EnsurePlayerHasExplosiveWeapon(pPlayer, weaponName);
                }
                
                int currentAmmo = pPlayer.m_rgAmmo(gameAmmoIndex);
                
                if(currentAmmo < ammoType.maxAmount)
                {
                    bool canRegenerate = true;
                    if(ammoType.hasThreshold && currentAmmo > ammoType.threshold)
                        canRegenerate = false;
                    
                    if(canRegenerate)
                    {
                        // Add ammo.
                        GiveAmmoToPlayer(pPlayer, ammoType);
                    }
                }
            }
        }
    }
}

// Get remaining time until next ammo regen tick (for HUD display).
float GetTimeUntilNextAmmoRegen()
{
    if(g_LastAmmoRegenTime <= 0.0f)
        return flAmmoTick; // Return base.
        
    float timeSinceLastRegen = g_Engine.time - g_LastAmmoRegenTime;
    float timeRemaining = flAmmoTick - timeSinceLastRegen;
    return Math.max(0.0f, timeRemaining);
}

// Give certain weapons if player is missing them, or they cannot be used (Only throwables).
string GetWeaponNameFromAmmoType(string ammoName)
{
    if(ammoName == "Hand Grenade")
        return "weapon_handgrenade";
    else if(ammoName == "Satchel Charge")
        return "weapon_satchel";
    else if(ammoName == "Trip Mine")
        return "weapon_tripmine";
    else if(ammoName == "Snarks")
        return "weapon_snark";
    
    return ""; // Not an explosive or not supported.
}

// Check if player has the explosive weapon, give them one if not.
void EnsurePlayerHasExplosiveWeapon(CBasePlayer@ pPlayer, string weaponName)
{
    if(pPlayer is null || weaponName.IsEmpty())
        return;
    
    // Check if player already has this weapon.
    bool hasWeapon = false;
    for(int i = 0; i < 10; i++)
    {
        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pPlayer.m_rgpPlayerItems(i));
        if(pWeapon !is null && pWeapon.GetClassname() == weaponName)
        {
            hasWeapon = true;
            break;
        }
    }
    
    // If they don't have it, give it to them.
    if(!hasWeapon)
    {
        CBaseEntity@ pEntity = g_EntityFuncs.Create(weaponName, pPlayer.GetOrigin(), g_vecZero, true);
        if(pEntity !is null)
        {
            CBasePlayerItem@ pItem = cast<CBasePlayerItem@>(pEntity);
            if(pItem !is null)
            {
                // Remove spawn flags to prevent respawning
                pEntity.pev.spawnflags = 0;
                pPlayer.AddPlayerItem(pItem);
            }
        }
    }
}

// Give ammo to player using selected method (silent or with pickup notification).
void GiveAmmoToPlayer(CBasePlayer@ pPlayer, AmmoType@ ammoType)
{
    if(pPlayer is null || ammoType is null)
        return;
    
    // Apply map multiplier to ammo amount
    int modifiedAmount = int(float(ammoType.amount) * g_CurrentAmmoMapMultiplier);
    if(modifiedAmount <= 0)
        modifiedAmount = 1; // Ensure at least 1 ammo is given
    
    if(g_bShowAmmoPickupNotification)
    {
        // Give ammo with pickup notification (shows on HUD).
        pPlayer.GiveAmmo(modifiedAmount, ammoType.name, ammoType.maxAmount);
    }
    else
    {
        // Silent ammo addition (no pickup notification).
        int gameAmmoIndex = g_PlayerFuncs.GetAmmoIndex(ammoType.name);
        if(gameAmmoIndex >= 0)
        {
            int currentAmmo = pPlayer.m_rgAmmo(gameAmmoIndex);
            pPlayer.m_rgAmmo(gameAmmoIndex, currentAmmo + modifiedAmount);
        }
    }
}

// Adjust ammo regen rates based on player class (using global array only).
void AdjustAmmoForPlayerClass(CBasePlayer@ pPlayer) 
{
    if(pPlayer is null)
        return;
        
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(steamID.IsEmpty() || !g_PlayerRPGData.exists(steamID))
        return;
        
    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
    if(data is null)
        return;
    
    ClassStats@ stats = data.GetCurrentClassStats();
    if(stats is null)
        return;
        
    int classLevel = stats.GetLevel();
    
    // Apply class-specific ammo regen passives (amounts only).
    switch(data.GetCurrentClass()) 
    {
        case PlayerClass::CLASS_MEDIC:
        {
            AmmoType@ healthAmmo = GetAmmoTypeByName("health");
            if(healthAmmo !is null) 
            {
                healthAmmo.amount = 1 + (classLevel / 2);
                healthAmmo.threshold = 100 + (classLevel * 2);
            }
            break;
        }

        /*case PlayerClass::CLASS_SHOCKTROOPER:
        {
            AmmoType@ shockAmmo = GetAmmoTypeByName("shock charges");
            if(shockAmmo !is null) 
            {
                shockAmmo.amount += 1;
            }
            break;
        }

        case PlayerClass::CLASS_CLOAKER:
        {
            AmmoType@ sniperAmmo = GetAmmoTypeByName("m40a1");
            if(sniperAmmo !is null) 
            {
                sniperAmmo.amount += 1;
            }

            AmmoType@ tripmineAmmo = GetAmmoTypeByName("Trip Mine");
            if(tripmineAmmo !is null) 
            {
                tripmineAmmo.threshold = 10;
            }
            break;
        }
        */
    }
}

// Helper function to find ammo by name.
AmmoType@ GetAmmoTypeByName(string name) 
{
    for (uint i = 0; i < g_AmmoTypes.length(); i++) 
    {
        if (g_AmmoTypes[i].name == name)
            return g_AmmoTypes[i];
    }
    return null;
}