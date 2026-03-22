// Plugin Created by Chaotic Akantor as ammo recovery system for CARPG.
// This file handles player ammo recovery.

string g_AmmoPrefixMessage = ""; // Store prefix message to display to connecting players.

bool g_bAmmoGive = false; // Toggle whether to give ammo directly (notification and sounds), or modify ammo directly instead (no notifications).
// WARNING: Currently giving explosives directly causes an M16 to be given to the player when AR grenades are given.
// Explosives need to be given silently to avoid this.

dictionary g_AmmoMapMultipliers;

float g_CurrentAmmoMapMultiplier = 1.0f;

// How often AmmoTimerTick runs.
float g_flAmmoRegenTickInterval = 0.1f;

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
    float regenIntervalBase; // Baseline seconds between resupply (from constructor; map scaling applied on init).
    float regenIntervalMax;  // Effective seconds between resupply after map scaling.
    float regenTimer;        // Countdown in seconds (decremented by g_flAmmoRegenTickInterval).
    
    AmmoType(string ammoName, int regenAmount, int maxAmmo, bool useThreshold = false, int thresholdValue = 0, bool explosive = false, float regenIntervalSeconds = 30.0f) 
    {
        name = ammoName;
        amount = regenAmount;
        baseAmount = regenAmount;
        maxAmount = maxAmmo;
        baseMaxAmount = maxAmmo;
        hasThreshold = useThreshold;
        threshold = thresholdValue;
        isExplosive = explosive;
        regenIntervalBase = regenIntervalSeconds;
        regenIntervalMax = regenIntervalSeconds;
        regenTimer = regenIntervalSeconds;
    }
}

array<AmmoType@> g_AmmoTypes; // Store all ammo types in an array.

void InitializeAmmoRegen() 
{
    // Clear existing ammo types first.
    g_AmmoTypes.resize(0);

    g_AmmoMapMultipliers["th_"] = 10.0f;    // They Hunger.
    g_AmmoMapMultipliers["aom_"] = 10.0f;   // Afraid of Monsters Classic.
    g_AmmoMapMultipliers["aomdc_"] = 10.0f; // Afraid of Monsters Directors-Cut.
    g_AmmoMapMultipliers["hl_"] = 2.0f;    // Half-Life Campaign.
    g_AmmoMapMultipliers["of_"] = 2.0f;    // Opposing-Force Campaign.
    g_AmmoMapMultipliers["bs_"] = 2.0f;    // Blue-Shift Campaign.

    string mapName = string(g_Engine.mapname).ToLowercase(); // Update map multiplier before creating ammo types.
    g_CurrentAmmoMapMultiplier = 1.0f; // Default.
    g_AmmoPrefixMessage = ""; // Reset message to default.
    
    dictionary@ prefixes = g_AmmoMapMultipliers;
    array<string>@ prefixKeys = prefixes.getKeys();
    
    for(uint i = 0; i < prefixKeys.length(); i++)
    {
        string prefix = prefixKeys[i].ToLowercase();
        if(mapName.Length() >= prefix.Length() && mapName.SubString(0, prefix.Length()) == prefix)
        {
            g_CurrentAmmoMapMultiplier = float(prefixes[prefixKeys[i]]);
            g_AmmoPrefixMessage = "\n=== CARPG Ammo Resupply: ===\nMap prefix '" + prefixKeys[i] + "' detected.\nAmmo Regen: " + g_CurrentAmmoMapMultiplier + "x. | Throwables DISABLED.";
            g_Game.AlertMessage(at_console, g_AmmoPrefixMessage + "\n\n");
            break;
        }
    }
    
    // Amount given, max ammo, use threshold? threshold, willgiveweapon(doesnt seem to work), timer.
    g_AmmoTypes.insertLast(AmmoType("health", 1, 100, true, 100, false, 0.5f));
    g_AmmoTypes.insertLast(AmmoType("9mm", 1, 300, false, 0, false, 0.5f));
    g_AmmoTypes.insertLast(AmmoType("buckshot", 1, 125, false, 0, false, 6.0f));
    g_AmmoTypes.insertLast(AmmoType("357", 1, 36, false, 0, false, 8.0f));
    g_AmmoTypes.insertLast(AmmoType("556", 1, 600, false, 0, false, 0.8f));
    g_AmmoTypes.insertLast(AmmoType("m40a1", 1, 25, false, 0, false, 10.0f));
    g_AmmoTypes.insertLast(AmmoType("bolts", 1, 30, false, 0, false, 10.0f));
    g_AmmoTypes.insertLast(AmmoType("sporeclip", 1, 20, false, 0, false, 20.0f));
    g_AmmoTypes.insertLast(AmmoType("Hornets", 1, 100, false, 0, false, 0.5f));
    g_AmmoTypes.insertLast(AmmoType("shock charges", 1, 100, false, 0, false, 1.0f));
    g_AmmoTypes.insertLast(AmmoType("uranium", 1, 100, false, 0, false, 5.0f));
    
    g_AmmoTypes.insertLast(AmmoType("Hand Grenade", 1, 10, true, 1, true, 30.0f));
    g_AmmoTypes.insertLast(AmmoType("ARgrenades", 1, 10, true, 2, true, 45.0f));
    g_AmmoTypes.insertLast(AmmoType("Satchel Charge", 1, 10, true, 1, true, 120.0f));
    g_AmmoTypes.insertLast(AmmoType("Trip Mine", 1, 10, true, 1, true, 90.0f));
    g_AmmoTypes.insertLast(AmmoType("rockets", 1, 10, true, 2, true, 60.0f));
    g_AmmoTypes.insertLast(AmmoType("Snarks", 1, 15, false, 0, false, 45.0f));
    
    float m = g_CurrentAmmoMapMultiplier;
    if(m < 0.001f)
        m = 1.0f;
    for(uint si = 0; si < g_AmmoTypes.length(); si++)
    {
        AmmoType@ at = g_AmmoTypes[si];
        if(at is null)
            continue;
        at.regenIntervalMax = at.regenIntervalBase * m;
        at.regenTimer = at.regenIntervalMax;
    }
}

void AmmoTimerTick()
{
    const int iMaxPlayers = g_Engine.maxClients;
    
    for(uint ammoIndex = 0; ammoIndex < g_AmmoTypes.length(); ammoIndex++)
    {
        AmmoType@ ammoType = g_AmmoTypes[ammoIndex];
        if(ammoType is null)
            continue;
        
        ammoType.regenTimer -= g_flAmmoRegenTickInterval;
        
        if(ammoType.regenTimer > 0)
            continue;
        
        // Map series that disable throwables: do not resupply; reschedule with carryover.
        if(ammoType.isExplosive && g_CurrentAmmoMapMultiplier != 1.0f)
        {
            ammoType.regenTimer += ammoType.regenIntervalMax;
            while(ammoType.regenTimer <= 0)
                ammoType.regenTimer += ammoType.regenIntervalMax;
            continue;
        }
        
        for(int playerIndex = 1; playerIndex <= iMaxPlayers; ++playerIndex)
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(playerIndex);
            if(pPlayer is null || !pPlayer.IsAlive() || !pPlayer.IsConnected())
                continue;
            
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
                        GiveAmmoToPlayer(pPlayer, ammoType);
                }
            }
        }
        
        ammoType.regenTimer += ammoType.regenIntervalMax;
        while(ammoType.regenTimer <= 0)
            ammoType.regenTimer += ammoType.regenIntervalMax;
    }
}

// One decimal place for HUD (matches typical tick granularity).
string FormatAmmoRegenSecondsForHud(float t)
{
    t = Math.max(0.0f, t);
    int tenthsTotal = int(t * 10.0f + 0.5f);
    int whole = tenthsTotal / 10;
    int frac = tenthsTotal % 10;
    return "" + whole + "." + frac + "s";
}

// Map engine ammo index to CARPG ammo type name (must match g_AmmoTypes entries).
string GetAmmoTypeNameForGameAmmoIndex(int gameAmmoIndex)
{
    if(gameAmmoIndex < 0)
        return "";
    
    for(uint i = 0; i < g_AmmoTypes.length(); i++)
    {
        AmmoType@ at = g_AmmoTypes[i];
        if(at is null)
            continue;
        if(g_PlayerFuncs.GetAmmoIndex(at.name) == gameAmmoIndex)
            return at.name;
    }
    return "";
}

string GetAmmoTypeNameForActiveWeapon(CBasePlayer@ pPlayer)
{
    if(pPlayer is null || !pPlayer.IsAlive())
        return "";
    
    CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pPlayer.m_hActiveItem.GetEntity());
    if(pWeapon is null)
        return "";
    
    return GetAmmoTypeNameForGameAmmoIndex(pWeapon.PrimaryAmmoIndex());
}

// HUD line for the resupply timer matching the active weapon's primary ammo type.
string GetAmmoRegenHudLine(CBasePlayer@ pPlayer)
{
    string name = GetAmmoTypeNameForActiveWeapon(pPlayer);
    if(name.Length() == 0)
        return "";
    
    AmmoType@ at = GetAmmoTypeByName(name);
    if(at is null)
        return "";
    
    if(at.isExplosive && g_CurrentAmmoMapMultiplier != 1.0f)
        return "Throwables resupply: DISABLED\n";
    
    return "Ammo Regen: " + "(" + at.name + ") " + FormatAmmoRegenSecondsForHud(at.regenTimer) + "\n";
}

// Give ammo to player using selected method (silent or with pickup notification).
void GiveAmmoToPlayer(CBasePlayer@ pPlayer, AmmoType@ ammoType)
{
    if(pPlayer is null || ammoType is null)
        return;
    
    int modifiedAmount = Math.max(1, ammoType.amount);
    
    if(g_bAmmoGive)
    {
        // Give ammo with pickup notification (shows on HUD).
        pPlayer.GiveAmmo(modifiedAmount, ammoType.name, ammoType.baseMaxAmount);
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