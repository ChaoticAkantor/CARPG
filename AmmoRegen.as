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

// Sprite sheet used for all ammo icons.
const string AMMO_SPRITE_SHEET = "640hud7.spr";

// Sub-region descriptor for a single ammo icon on the sprite sheet.
class AmmoSpriteEntry
{
    string name;
    int left;
    int top;
    int width;
    int height;

    AmmoSpriteEntry(string n, int l, int t, int w = 24, int h = 24)
    {
        name = n; left = l; top = t; width = w; height = h;
    }
}

array<AmmoSpriteEntry@> g_AmmoSpriteEntries;

void InitAmmoSpriteMap()
{
    g_AmmoSpriteEntries.resize(0);
    // Coords derived from svencoop/sprites/weapon_*.txt and hud.txt.
    // All entries are on 640hud7.spr. Default size 24x24 unless noted.
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("health",          74,  24, 34, 35)); // cross icon.
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("9mm",              0,  60));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("357",             24,  60));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("ARgrenades",      48,  60));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("buckshot",        72,  60));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("bolts",           96,  60));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("rockets",        120,  60));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("556",            144,  60));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("m40a1",          168,  60));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("Hornets",         24,  84));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("Hand Grenade",    48,  84));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("Satchel Charge",  72,  84));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("Snarks",          96,  84));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("Trip Mine",      120,  84));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("shock charges",  144,  84));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("sporeclip",      168,  84));
    g_AmmoSpriteEntries.insertLast(AmmoSpriteEntry("uranium",          0,  84));
}

AmmoSpriteEntry@ GetAmmoSpriteEntry(const string& in name)
{
    for(uint i = 0; i < g_AmmoSpriteEntries.length(); i++)
        if(g_AmmoSpriteEntries[i].name == name)
            return g_AmmoSpriteEntries[i];
    return null;
}

void InitializeAmmoRegen() 
{
    InitAmmoSpriteMap();
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
    
    // Amount given, max ammo, use threshold?, threshold, willgiveweapon(doesnt seem to work), timer.
    g_AmmoTypes.insertLast(AmmoType("health", 1, 100, true, 100, false, 1.0f));
    g_AmmoTypes.insertLast(AmmoType("9mm", 1, 300, false, 0, false, 0.8f));
    g_AmmoTypes.insertLast(AmmoType("buckshot", 1, 125, false, 0, false, 8.0f));
    g_AmmoTypes.insertLast(AmmoType("357", 1, 36, false, 0, false, 12.0f));
    g_AmmoTypes.insertLast(AmmoType("556", 1, 600, false, 0, false, 1.0f));
    g_AmmoTypes.insertLast(AmmoType("m40a1", 1, 25, false, 0, false, 15.0f));
    g_AmmoTypes.insertLast(AmmoType("bolts", 1, 30, false, 0, false, 12.0f));
    g_AmmoTypes.insertLast(AmmoType("sporeclip", 1, 20, false, 0, false, 20.0f));
    g_AmmoTypes.insertLast(AmmoType("Hornets", 1, 100, false, 0, false, 1.0f));
    g_AmmoTypes.insertLast(AmmoType("shock charges", 1, 100, false, 0, false, 1.0f));
    g_AmmoTypes.insertLast(AmmoType("uranium", 1, 100, false, 0, false, 8.0f));
    
    g_AmmoTypes.insertLast(AmmoType("Hand Grenade", 1, 10, true, 1, true, 60.0f));
    g_AmmoTypes.insertLast(AmmoType("ARgrenades", 1, 10, true, 2, true, 60.0f));
    g_AmmoTypes.insertLast(AmmoType("Satchel Charge", 1, 10, true, 1, true, 120.0f));
    g_AmmoTypes.insertLast(AmmoType("Trip Mine", 1, 10, true, 1, true, 90.0f));
    g_AmmoTypes.insertLast(AmmoType("rockets", 1, 10, true, 2, true, 60.0f));
    g_AmmoTypes.insertLast(AmmoType("Snarks", 1, 15, false, 0, false, 15.0f));
    
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
            
            int skillBonus = 0;
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(!steamID.IsEmpty() && g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ rpgData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(rpgData !is null)
                    skillBonus = rpgData.GetSkillLevel(SkillID::SKILL_AMMOREGEN);
            }
            
            if(skillBonus < 1)
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
                        GiveAmmoToPlayer(pPlayer, ammoType, skillBonus);
                }
            }
        }
        
        ammoType.regenTimer += ammoType.regenIntervalMax;
        while(ammoType.regenTimer <= 0)
            ammoType.regenTimer += ammoType.regenIntervalMax;
    }
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

// Displays the ammo regen countdown for the player's active weapon.
void UpdateAmmoRegenHUD(CBasePlayer@ pPlayer)
{
    if(pPlayer is null || !pPlayer.IsAlive()) return;

    // Only show for players with the ammo regen skill invested.
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(steamID.IsEmpty() || !g_PlayerRPGData.exists(steamID)) return;
    PlayerData@ rpgData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
    if(rpgData is null || rpgData.GetSkillLevel(SkillID::SKILL_AMMOREGEN) < 1) return;

    string ammoName = GetAmmoTypeNameForActiveWeapon(pPlayer);
    if(ammoName.IsEmpty()) return;

    AmmoType@ at = GetAmmoTypeByName(ammoName);
    if(at is null) return;

    // Don't show for throwables on restricted maps.
    if(at.isExplosive && g_CurrentAmmoMapMultiplier != 1.0f) return;

    AmmoSpriteEntry@ spr = GetAmmoSpriteEntry(ammoName);
    if(spr is null) return;

    HUDNumDisplayParams params;
    params.channel     = 6;
    params.flags       = HUD_NUM_RIGHT_ALIGN | HUD_TIME_SECONDS | HUD_TIME_MILLISECONDS;
    params.spritename  = AMMO_SPRITE_SHEET;
    params.left        = spr.left;
    params.top         = spr.top;
    params.width       = spr.width;
    params.height      = spr.height;
    params.x           = 1.0;
    params.y           = 0.92;
    params.fadeinTime  = 0.0;
    params.fadeoutTime = 0.0;
    params.holdTime    = 0.2;
    params.fxTime     = 0.0;
    params.defdigits  = 1;
    params.maxdigits  = 3;
    params.value      = at.regenTimer;
    params.color1     = RGBA(0, 255, 255, 255);
    params.color2     = RGBA(255, 255, 255, 255);
    g_PlayerFuncs.HudTimeDisplay(pPlayer, params);
}

// Give ammo to player using selected method (silent or with pickup notification).
void GiveAmmoToPlayer(CBasePlayer@ pPlayer, AmmoType@ ammoType, int skillBonus = 0)
{
    if(pPlayer is null || ammoType is null)
        return;
    
    int bonus = ammoType.isExplosive ? (skillBonus / 2) : skillBonus;
    int modifiedAmount = Math.max(1, ammoType.amount + bonus);
    
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

// Called on a scheduler interval; updates the ammo regen HUD for all connected players.
void UpdateAllAmmoRegenHUDs()
{
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
            UpdateAmmoRegenHUD(pPlayer);
    }
}