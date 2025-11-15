// Plugin Created by Chaotic Akantor as ammo recovery system for CARPG.
// This file handles player ammo recovery.

float flAmmoTick = 1.0; // How long between each ammo regen tick.

// Add at the top of the file with other globals
dictionary g_MapPrefixMultipliers;
float g_CurrentMapMultiplier = 1.0f;

// Define an AmmoType class to store all properties for each ammo type.
class AmmoType 
{
    string name;        // Ammo name like "9mm" or "health".
    int counter;        // Current counter for regeneration.
    int delay;          // Base delay between regenerations.
    int amount;         // Amount to regenerate each time.
    int maxAmount;      // Maximum amount player can carry.
    int baseAmount;     // Base regeneration amount (for scaling).
    int baseMaxAmount;  // Base maximum (for scaling).
    int threshold;      // Threshold for special ammo types.
    bool hasThreshold;  // Whether this ammo uses threshold logic.
    
    AmmoType(string ammoName, int baseDelay, int regenAmount, int maxAmmo, bool useThreshold = false, int thresholdValue = 0) 
    {
        name = ammoName;
        counter = int(baseDelay * g_CurrentMapMultiplier);
        delay = int(baseDelay * g_CurrentMapMultiplier);
        amount = regenAmount;
        baseAmount = regenAmount;
        maxAmount = maxAmmo;
        baseMaxAmount = maxAmmo;
        hasThreshold = useThreshold;
        threshold = thresholdValue;
    }
}

array<AmmoType@> g_AmmoTypes; // Store all ammo types in an array.

void InitializeAmmoRegen() 
{
    // Clear existing ammo types first
    g_AmmoTypes.resize(0);

    // Balance ammo regeneration seperately for different map series by mulitplying the timer values.
    g_MapPrefixMultipliers["th"] = 5.0f;    // They Hunger.
    g_MapPrefixMultipliers["aom"] = 5.0f;   // Afraid of Monsters Classic.
    g_MapPrefixMultipliers["aomdc"] = 5.0f; // Afraid of Monsters Directors-Cut.
    g_MapPrefixMultipliers["hl"] = 3.0f;    // Half-Life Campaign.
    g_MapPrefixMultipliers["of"] = 3.0f;    // Opposing-Force Campaign.
    g_MapPrefixMultipliers["bs"] = 3.0f;    // Blue-Shift Campaign.
    // Add more prefixes as needed.

    string mapName = string(g_Engine.mapname).ToLowercase(); // Update map multiplier before creating ammo types.
    g_CurrentMapMultiplier = 1.0f; // Default multiplier.
    
    dictionary@ prefixes = g_MapPrefixMultipliers;
    array<string>@ prefixKeys = prefixes.getKeys();
    
    for(uint i = 0; i < prefixKeys.length(); i++)
    {
        string prefix = prefixKeys[i].ToLowercase();
        if(mapName.Length() >= prefix.Length() && mapName.SubString(0, prefix.Length()) == prefix)
        {
            g_CurrentMapMultiplier = float(prefixes[prefixKeys[i]]);
            g_Game.AlertMessage(at_console, "=== CARPG: ===\nMap prefix - '" + prefixKeys[i] + "' detected. Ammo regen multiplier set to " + g_CurrentMapMultiplier + "x.\n");
            break;
        }
    }
    
    // Initialize ammo types with current map multiplier.
    g_AmmoTypes.insertLast(AmmoType("health", 1, 5, 100, true, 100));
    g_AmmoTypes.insertLast(AmmoType("9mm", 1, 1, 300));
    g_AmmoTypes.insertLast(AmmoType("buckshot", 12, 1, 125));
    g_AmmoTypes.insertLast(AmmoType("357", 16, 1, 36));
    g_AmmoTypes.insertLast(AmmoType("556", 2, 1, 600));
    g_AmmoTypes.insertLast(AmmoType("m40a1", 20, 1, 25));
    g_AmmoTypes.insertLast(AmmoType("bolts", 25, 1, 30));
    g_AmmoTypes.insertLast(AmmoType("sporeclip", 30, 1, 20));
    g_AmmoTypes.insertLast(AmmoType("Hornets", 3, 1, 100));
    g_AmmoTypes.insertLast(AmmoType("shock charges", 3, 1, 100));
    g_AmmoTypes.insertLast(AmmoType("uranium", 10, 1, 100));
    
    // Threshold-based ammo types (explosives, etc).
    g_AmmoTypes.insertLast(AmmoType("Hand Grenade", 60, 1, 10, true, 1));
    g_AmmoTypes.insertLast(AmmoType("ARgrenades", 60, 1, 10, true, 1));
    g_AmmoTypes.insertLast(AmmoType("Satchel Charge", 120, 1, 10, true, 1));
    g_AmmoTypes.insertLast(AmmoType("Trip Mine", 120, 1, 10, true, 1));
    g_AmmoTypes.insertLast(AmmoType("rockets", 90, 1, 10, true, 1));
    g_AmmoTypes.insertLast(AmmoType("Snarks", 30, 1, 15, true, 1));
}

void AmmoTimerTick()
{
    const int iMaxPlayers = g_Engine.maxClients;
    for(int playerIndex = 1; playerIndex <= iMaxPlayers; ++playerIndex)
    {   
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(playerIndex);
        if(pPlayer is null || !pPlayer.IsAlive() || !pPlayer.IsConnected())
            continue;

        // Process ammo regeneration using global settings.
        for(uint ammoIndex = 0; ammoIndex < g_AmmoTypes.length(); ammoIndex++)
        {
            AmmoType@ ammoType = g_AmmoTypes[ammoIndex];
            if(ammoType is null)
                continue;
                
            // Decrease counter.
            ammoType.counter--;
            
            if(ammoType.counter < 0)
            {
                int gameAmmoIndex = g_PlayerFuncs.GetAmmoIndex(ammoType.name);
                if(gameAmmoIndex >= 0)
                {
                    int currentAmmo = pPlayer.m_rgAmmo(gameAmmoIndex);
                    
                    if(currentAmmo < ammoType.maxAmount)
                    {
                        bool canRegenerate = true;
                        if(ammoType.hasThreshold && currentAmmo > ammoType.threshold)
                            canRegenerate = false;
                        
                        if(canRegenerate)
                        {
                            // Add exactly amount (no multiplication).
                            pPlayer.m_rgAmmo(gameAmmoIndex, currentAmmo + ammoType.amount);
                        }
                    }
                }
                
                // Reset counter with scaled delay.
                ammoType.counter = ammoType.delay;
            }
        }
    }
}

// Adjust ammo regen rates based on player class (using player-specific array).
void AdjustAmmoForPlayerClass(CBasePlayer@ pPlayer, array<AmmoType@>@ playerAmmoTypes) 
{
    if(pPlayer is null || playerAmmoTypes is null)
        return;
        
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(steamID.IsEmpty() || !g_PlayerRPGData.exists(steamID))
        return;
        
    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
    if(data is null)
        return;
    
    PlayerClass currentClass = data.GetCurrentClass();
    
    ClassStats@ stats = data.GetCurrentClassStats();
    if(stats is null)
        return;
        
    int classLevel = stats.GetLevel();
    
    // Apply class-specific ammo regen passives.
    switch(currentClass) 
    {
        case PlayerClass::CLASS_MEDIC:
        {
            AmmoType@ healthAmmo = GetAmmoTypeByNameFromArray(playerAmmoTypes, "health");
            if(healthAmmo !is null) 
            {
                healthAmmo.amount = 1 + (classLevel / 2);
                healthAmmo.threshold = 100 + (classLevel * 5);
            }
            break;
        }

        case PlayerClass::CLASS_SHOCKTROOPER:
        {
            AmmoType@ shockAmmo = GetAmmoTypeByNameFromArray(playerAmmoTypes, "shock charges");
            if(shockAmmo !is null) 
            {
                shockAmmo.amount += 1;
            }
            break;
        }

        case PlayerClass::CLASS_CLOAKER:
        {
            AmmoType@ sniperAmmo = GetAmmoTypeByNameFromArray(playerAmmoTypes, "m40a1");
            if(sniperAmmo !is null) 
            {
                sniperAmmo.amount += 1;
            }

            AmmoType@ tripmineAmmo = GetAmmoTypeByNameFromArray(playerAmmoTypes, "trip mine");
            if(tripmineAmmo !is null) 
            {
                tripmineAmmo.threshold = 10;
            }
            
            AdjustAmmoDelay(playerAmmoTypes, "m40a1", 25, classLevel, 0.2f);
            AdjustAmmoDelay(playerAmmoTypes, "Trip Mine", 120, classLevel, 0.5f);

            break;
        }
            
        case PlayerClass::CLASS_VANQUISHER:
        {
            // Adjust explosive ammo capacities.
            AmmoType@ grenadeAmmo = GetAmmoTypeByNameFromArray(playerAmmoTypes, "Hand Grenade");
            if(grenadeAmmo !is null) 
            {
                grenadeAmmo.threshold = 15;
            }

            AmmoType@ satchelAmmo = GetAmmoTypeByNameFromArray(playerAmmoTypes, "Satchel Charge");
            if(satchelAmmo !is null) 
            {
                satchelAmmo.threshold = 7;
            }
            
            AmmoType@ rocketAmmo = GetAmmoTypeByNameFromArray(playerAmmoTypes, "rockets");
            if(rocketAmmo !is null) 
            {
                rocketAmmo.threshold = 15;
            }

            // Use helper for all delay adjustments.
            AdjustAmmoDelay(playerAmmoTypes, "hand grenade", 60, classLevel, 0.3f);
            AdjustAmmoDelay(playerAmmoTypes, "satchel charge", 120, classLevel, 0.5f);
            AdjustAmmoDelay(playerAmmoTypes, "rockets", 90, classLevel, 0.5f);
            break;
        }
    }
}

// Helper function to find ammo by name in a specific array.
AmmoType@ GetAmmoTypeByNameFromArray(array<AmmoType@>@ ammoArray, string name) 
{
    if(ammoArray is null)
        return null;
        
    for (uint i = 0; i < ammoArray.length(); i++) 
    {
        if(i >= ammoArray.length() || ammoArray[i] is null)
            continue;
            
        if (ammoArray[i].name == name)
            return ammoArray[i];
    }
    return null;
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

// Helper to adjust ammo delay based on player level.
void AdjustAmmoDelay(array<AmmoType@>@ playerAmmoTypes, string ammoName, int baseDelay, int classLevel, float reductionFactor) 
{
    AmmoType@ ammoType = GetAmmoTypeByNameFromArray(playerAmmoTypes, ammoName);
    if(ammoType !is null) {
        int newDelay = Math.max(1, baseDelay - int(classLevel * reductionFactor));
        ammoType.delay = newDelay;
    }
}