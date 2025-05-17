// Plugin Created by Chaotic Akantor for potential use in an addon.
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
        counter = int(baseDelay * g_CurrentMapMultiplier); // Multiply the max by the map multiplier.
        delay = int(baseDelay * g_CurrentMapMultiplier); // Multiply the delay by the map multiplier.
        amount = regenAmount;
        baseAmount = regenAmount;
        maxAmount = maxAmmo;
        baseMaxAmount = maxAmmo;
        hasThreshold = useThreshold;
        threshold = thresholdValue;
    }
}

array<AmmoType@> g_AmmoTypes; // Store all ammo types in an array.

void InitializeAmmoTypes() // Initialize all ammo types at startup.
{
    // Regular ammo types.
    g_AmmoTypes.insertLast(AmmoType("health", 1, 1, 100, true, 100));
    g_AmmoTypes.insertLast(AmmoType("9mm", 2, 1, 300));
    g_AmmoTypes.insertLast(AmmoType("buckshot", 16, 1, 125));
    g_AmmoTypes.insertLast(AmmoType("357", 20, 1, 36));
    g_AmmoTypes.insertLast(AmmoType("556", 3, 1, 600));
    g_AmmoTypes.insertLast(AmmoType("m40a1", 20, 1, 25));
    g_AmmoTypes.insertLast(AmmoType("bolts", 20, 1, 30));
    g_AmmoTypes.insertLast(AmmoType("sporeclip", 30, 1, 20));
    g_AmmoTypes.insertLast(AmmoType("hornets", 2, 1, 100));
    g_AmmoTypes.insertLast(AmmoType("shock charges", 2, 1, 100));
    g_AmmoTypes.insertLast(AmmoType("uranium", 12, 1, 100));
    
    // Threshold-based ammo types (explosives, etc).
    g_AmmoTypes.insertLast(AmmoType("hand grenade", 30, 1, 10, true, 1));
    g_AmmoTypes.insertLast(AmmoType("ARgrenades", 30, 1, 10, true, 1));
    g_AmmoTypes.insertLast(AmmoType("satchel charge", 60, 1, 10, true, 1));
    g_AmmoTypes.insertLast(AmmoType("trip mine", 60, 1, 10, true, 1));
    g_AmmoTypes.insertLast(AmmoType("rockets", 60, 1, 10, true, 1));
    g_AmmoTypes.insertLast(AmmoType("snarks", 3, 1, 1, false, 0));
}

void AmmoTimerTick() // Think.
{
    const int iMaxPlayers = g_Engine.maxClients;
    for (int playerIndex = 1; playerIndex <= iMaxPlayers; ++playerIndex) 
    {   
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(playerIndex);
        if (pPlayer is null || !pPlayer.IsAlive() || !pPlayer.IsConnected())
            continue;

        // Create temporary copies of ammo types for this player.
        array<AmmoType@> playerAmmoTypes;
        for (uint i = 0; i < g_AmmoTypes.length(); i++) 
        {
            if(i >= g_AmmoTypes.length() || g_AmmoTypes[i] is null)
                continue;
                
            AmmoType@ original = g_AmmoTypes[i];
            AmmoType@ copy = AmmoType(original.name, original.delay, original.amount, original.maxAmount, 
                                      original.hasThreshold, original.threshold);
            playerAmmoTypes.insertLast(copy);
        }
        
        // Adjust ammo for this player's class (using the copies).
        AdjustAmmoForPlayerClass(pPlayer, playerAmmoTypes);

        // Process ammo regeneration using player-specific settings.
        for (uint ammoIndex = 0; ammoIndex < playerAmmoTypes.length(); ammoIndex++) 
        {
            if(ammoIndex >= playerAmmoTypes.length() || playerAmmoTypes[ammoIndex] is null || 
               ammoIndex >= g_AmmoTypes.length() || g_AmmoTypes[ammoIndex] is null)
                continue;
                
            AmmoType@ ammoType = playerAmmoTypes[ammoIndex];
            
            // Get the original counter from global ammo type.
            ammoType.counter = g_AmmoTypes[ammoIndex].counter;
            
            // Decrease counter.
            g_AmmoTypes[ammoIndex].counter--;
            
            // Check if it's time to regenerate
            if (g_AmmoTypes[ammoIndex].counter < 0) 
            {
                int gameAmmoIndex = g_PlayerFuncs.GetAmmoIndex(ammoType.name);
                if (gameAmmoIndex >= 0) // Make sure ammo type is valid.
                {
                    // Double-check player is still valid.
                    if(pPlayer is null || !pPlayer.IsAlive())
                        continue;
                        
                    int currentAmmo = pPlayer.m_rgAmmo(gameAmmoIndex);
                    
                    // Check ammo limits.
                    if (currentAmmo < ammoType.maxAmount) 
                    {
                        // Check threshold if needed.
                        bool canRegenerate = true;
                        if (ammoType.hasThreshold && currentAmmo > ammoType.threshold)
                            canRegenerate = false;
                        
                        if (canRegenerate) 
                        {
                            pPlayer.m_rgAmmo(gameAmmoIndex, currentAmmo + ammoType.amount);
                        }
                    }
                }
                
                // Reset counter in the global array.
                g_AmmoTypes[ammoIndex].counter = g_AmmoTypes[ammoIndex].delay;
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
            
            AdjustAmmoDelay(playerAmmoTypes, "m40a1", 20, classLevel, 0.2f);
            AdjustAmmoDelay(playerAmmoTypes, "trip mine", 60, classLevel, 0.5f);

            break;
        }
            
        case PlayerClass::CLASS_DEMOLITIONIST:
        {
            // Adjust explosive ammo capacities.
            AmmoType@ grenadeAmmo = GetAmmoTypeByNameFromArray(playerAmmoTypes, "hand grenade");
            if(grenadeAmmo !is null) 
            {
                grenadeAmmo.threshold = 15;
            }
            
            AmmoType@ satchelAmmo = GetAmmoTypeByNameFromArray(playerAmmoTypes, "satchel charge");
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
            AdjustAmmoDelay(playerAmmoTypes, "hand grenade", 30, classLevel, 0.25f);
            AdjustAmmoDelay(playerAmmoTypes, "satchel charge", 60, classLevel, 0.5f);
            AdjustAmmoDelay(playerAmmoTypes, "rockets", 60, classLevel, 0.5f);
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

void InitializeMapMultipliers()
{
    // Balance ammo regeneration seperately for different map series by mulitplying the timer values.
    g_MapPrefixMultipliers["sc_"] = 1.0f;    // Sven Co-op.
    g_MapPrefixMultipliers["th_"] = 4.0f;    // They Hunger Ep1-3.
    g_MapPrefixMultipliers["aom_"] = 4.0f;   // Afraid of Monsters Classic.
    g_MapPrefixMultipliers["aomdc_"] = 4.0f; // Afraid of Monsters Directors-Cut.
    g_MapPrefixMultipliers["hl_"] = 2.0f;    // Half-Life Campaign.
    g_MapPrefixMultipliers["of"] = 2.0f;    // Opposing-Force Campaign.
    g_MapPrefixMultipliers["bs"] = 2.0f;    // Blue-Shift Campaign.
    // Add more prefixes as needed
}

void UpdateMapMultiplier()
{
    string mapName = string(g_Engine.mapname).ToLowercase();
    g_CurrentMapMultiplier = 1.0f; // Default multiplier.
    
    dictionary@ prefixes = g_MapPrefixMultipliers;
    array<string>@ prefixKeys = prefixes.getKeys();
    
    for(uint i = 0; i < prefixKeys.length(); i++)
    {
        string prefix = prefixKeys[i].ToLowercase();
        if(mapName.Length() >= prefix.Length() && mapName.SubString(0, prefix.Length()) == prefix) // Check if map name starts with this prefix.
        {
            g_CurrentMapMultiplier = float(prefixes[prefixKeys[i]]);
            g_Game.AlertMessage(at_console, "CARPG: Map prefix - " + prefixKeys[i] + " detected. Ammo regen multiplier set to " + g_CurrentMapMultiplier + "\n");
            break;
        }
    }
}