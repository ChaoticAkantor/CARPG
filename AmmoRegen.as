// Plugin Created by Chaotic Akantor as ammo recovery system for CARPG.
// This file handles player ammo recovery.

string g_AmmoPrefixMessage = ""; // Store prefix message to display to connecting players.

float g_CurrentAmmoMapMultiplier = 1.0f;

// How often AmmoTimerTick runs.
float g_flAmmoRegenTickInterval = 1.0f;
float g_flAmmoRegenHUDUpdateInterval = 0.5f;

// Base interval between resupplies, scaled by the active map rule.
float g_flAmmoResupplyInterval = 30.0f; // Default timer before restoring ammo.
float g_flAmmoResupplyTimer = 30.0f; // Timer used for ammo restoring.
float g_flExplosiveAmmoRegenModifier = 0.5f; // Modifier to global explosive regen.
float g_flIns2CustomAmmoRegenModifier = 0.6f; // Modifier to global INS2 ammo regen when using custom ammo types.

// Define an AmmoType class to store all properties for each ammo type.
class AmmoType 
{
    string name;        // Ammo name like "9mm" or "health".
    int threshold;      // Threshold for special ammo types.
    bool hasThreshold;  // Whether this ammo uses threshold logic.
    bool isExplosive;   // Whether this ammo is an explosive type (disabled if map modifier is active).
    bool isIns2Custom;  // Whether this is an INS2 custom ammo pool.
    
    AmmoType(string ammoName, bool useThreshold = false, int thresholdValue = 0, bool explosive = false, bool ins2Custom = false)
    {
        name = ammoName;
        hasThreshold = useThreshold;
        threshold = thresholdValue;
        isExplosive = explosive;
        isIns2Custom = ins2Custom;
    }
}

array<AmmoType@> g_AmmoTypes; // Store all ammo types in an array.
dictionary g_PlayerAmmoRegenFractions;

const string AMMO_SPRITE_SHEET = "640hud7.spr";
const int AMMO_SPRITE_LEFT = 144;
const int AMMO_SPRITE_TOP = 60;
const int AMMO_SPRITE_WIDTH = 24;
const int AMMO_SPRITE_HEIGHT = 24;

void InitializeAmmoRegen() 
{
    // Clear existing ammo types first.
    g_AmmoTypes.resize(0);

    g_CurrentAmmoMapMultiplier = g_iCARPGCurrentMapMode == CARPG_MAP_BALANCED ? g_flCARPGAmmoMultiplier : 1.0f;
    g_AmmoPrefixMessage = ""; // Reset message to default.
    if(g_iCARPGCurrentMapMode == CARPG_MAP_BALANCED)
    {
        g_AmmoPrefixMessage = "=== CARPG Ammo Regen: ===\nMap rule '" + g_szCARPGMatchedMapPattern
            + "' detected.\nAmmo Regen: " + g_CurrentAmmoMapMultiplier + "x slower | Throwables regen DISABLED";
        g_Game.AlertMessage(at_console, g_AmmoPrefixMessage + "\n\n");
    }
    
    // Ammo type, use threshold?, threshold, explosive?, INS2 custom?
    g_AmmoTypes.insertLast(AmmoType("health"));
    g_AmmoTypes.insertLast(AmmoType("9mm"));
    g_AmmoTypes.insertLast(AmmoType("buckshot"));
    g_AmmoTypes.insertLast(AmmoType("357"));
    g_AmmoTypes.insertLast(AmmoType("556"));
    g_AmmoTypes.insertLast(AmmoType("m40a1"));
    g_AmmoTypes.insertLast(AmmoType("bolts"));
    g_AmmoTypes.insertLast(AmmoType("sporeclip"));
    g_AmmoTypes.insertLast(AmmoType("Hornets"));
    g_AmmoTypes.insertLast(AmmoType("shock charges"));
    g_AmmoTypes.insertLast(AmmoType("uranium"));
    
    g_AmmoTypes.insertLast(AmmoType("Hand Grenade", true, 1, true));
    g_AmmoTypes.insertLast(AmmoType("ARgrenades", true, 2, true));
    g_AmmoTypes.insertLast(AmmoType("Satchel Charge", true, 1, true));
    g_AmmoTypes.insertLast(AmmoType("Trip Mine", true, 1, true));
    g_AmmoTypes.insertLast(AmmoType("rockets", true, 2, true));
    g_AmmoTypes.insertLast(AmmoType("Snarks"));

    // INS2 custom ammo pools.
    g_AmmoTypes.insertLast(AmmoType("ins2_12x70buckball", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_12x70buckshot", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_303brit", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_357magnum", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_4.6x30mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_40mm_rocket", false, 0, true, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_40x46mm", false, 0, true, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_44magnum", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_455brit", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_45acp", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_5.45x39mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_5.56x45mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_50ae", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_7.62x25mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_7.62x33mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_7.62x39mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_7.62x51mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_7.62x54mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_7.62x63mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_7.63x25mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_7.92x33mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_7.92x57mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_88mm_rocket", false, 0, true, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_9x18mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_9x19mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_9x39mm", false, 0, false, true));
    g_AmmoTypes.insertLast(AmmoType("ins2_napalm", false, 0, false, true));

    g_flAmmoResupplyTimer = GetAmmoResupplyInterval();
    g_PlayerAmmoRegenFractions.deleteAll();
}

float GetAmmoResupplyInterval()
{
    float mapMultiplier = g_CurrentAmmoMapMultiplier;
    if(mapMultiplier < 0.001f)
        mapMultiplier = 1.0f;

    return Math.max(g_flAmmoRegenTickInterval, g_flAmmoResupplyInterval * mapMultiplier);
}

int GetAmmoRegenAmount(AmmoType@ ammoType, int maxAmmo, int skillLevel, const string& in steamID)
{
    if(ammoType is null || maxAmmo <= 0 || skillLevel < 1 || steamID.IsEmpty())
        return 0;

    string progressKey = steamID + ":" + ammoType.name;
    float fractionalProgress = 0.0f;
    g_PlayerAmmoRegenFractions.get(progressKey, fractionalProgress);

    float resupplyAmount = float(maxAmmo) * SKILL_BASIC_AMMOREGEN * float(skillLevel);
    if(ammoType.isIns2Custom)
        resupplyAmount *= Math.max(0.0f, g_flIns2CustomAmmoRegenModifier);

    if(ammoType.isExplosive)
        resupplyAmount *= Math.max(0.0f, g_flExplosiveAmmoRegenModifier);

    float totalAmount = resupplyAmount + fractionalProgress;
    int wholeAmount = int(totalAmount);
    
    g_PlayerAmmoRegenFractions[progressKey] = totalAmount - float(wholeAmount);
    return wholeAmount;
}

int GetClassAmmoRegenBonus(PlayerData@ rpgData, AmmoType@ ammoType)
{
    if(rpgData is null || ammoType is null || ammoType.name != "health"
        || rpgData.GetCurrentClass() != PlayerClass::CLASS_MEDIC)
        return 0;

    ClassStats@ stats = rpgData.GetCurrentClassStats();
    return (stats is null) ? 0 : 1 + (stats.GetLevel() / 2);
}

void AmmoTimerTick()
{
    if(IsCARPGDisabledOnCurrentMap())
        return;

    g_flAmmoResupplyTimer -= g_flAmmoRegenTickInterval;
    if(g_flAmmoResupplyTimer > 0.0f)
        return;

    const int iMaxPlayers = g_Engine.maxClients;
    
    for(uint ammoIndex = 0; ammoIndex < g_AmmoTypes.length(); ammoIndex++)
    {
        AmmoType@ ammoType = g_AmmoTypes[ammoIndex];
        if(ammoType is null)
            continue;

        // Map rules that disable throwables skip their resupply.
        if(ammoType.isExplosive && g_CurrentAmmoMapMultiplier != 1.0f)
            continue;

        int gameAmmoIndex = g_PlayerFuncs.GetAmmoIndex(ammoType.name);
        if(gameAmmoIndex < 0)
            continue;
        
        for(int playerIndex = 1; playerIndex <= iMaxPlayers; ++playerIndex)
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(playerIndex);
            if(pPlayer is null || !pPlayer.IsAlive() || !pPlayer.IsConnected())
                continue;
            
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(steamID.IsEmpty() || !g_PlayerRPGData.exists(steamID))
                continue;

            PlayerData@ rpgData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
            if(rpgData is null)
                continue;

            int skillLevel = rpgData.GetSkillLevel(SkillID::SKILL_BASIC_AMMOREGEN);
            if(skillLevel < 1)
                continue;

            int maxAmmo = pPlayer.GetMaxAmmo(gameAmmoIndex);
            if(maxAmmo <= 0)
                continue;

            int currentAmmo = pPlayer.m_rgAmmo(gameAmmoIndex);
            if(currentAmmo >= maxAmmo)
                continue;

            if(ammoType.hasThreshold && currentAmmo > ammoType.threshold)
                continue;

            int resupplyAmount = GetAmmoRegenAmount(ammoType, maxAmmo, skillLevel, steamID);
            resupplyAmount += GetClassAmmoRegenBonus(rpgData, ammoType);

            if(resupplyAmount > 0)
                GiveAmmoToPlayer(pPlayer, resupplyAmount, gameAmmoIndex, maxAmmo);
        }
    }

    float resupplyInterval = GetAmmoResupplyInterval();
    g_flAmmoResupplyTimer += resupplyInterval;

    while(g_flAmmoResupplyTimer <= 0.0f)
        g_flAmmoResupplyTimer += resupplyInterval;
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
    if(IsCARPGDisabledOnCurrentMap() || pPlayer is null || !pPlayer.IsAlive()) return;

    // Only show for players with the ammo regen skill invested.
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(steamID.IsEmpty() || !g_PlayerRPGData.exists(steamID)) return;
    PlayerData@ rpgData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
    if(rpgData is null || rpgData.GetSkillLevel(SkillID::SKILL_BASIC_AMMOREGEN) < 1) return;

    string ammoName = GetAmmoTypeNameForActiveWeapon(pPlayer);
    if(ammoName.IsEmpty()) return;

    AmmoType@ at = GetAmmoTypeByName(ammoName);
    if(at is null) return;

    // Don't show for throwables on restricted maps.
    if(at.isExplosive && g_CurrentAmmoMapMultiplier != 1.0f) return;

    HUDNumDisplayParams params;
    params.channel     = 6;
    params.flags       = HUD_NUM_RIGHT_ALIGN | HUD_TIME_SECONDS;
    params.spritename  = AMMO_SPRITE_SHEET;
    params.left        = AMMO_SPRITE_LEFT;
    params.top         = AMMO_SPRITE_TOP;
    params.width       = AMMO_SPRITE_WIDTH;
    params.height      = AMMO_SPRITE_HEIGHT;
    int ammoHUDPosition = rpgData.GetHUDPositionIndex(CARPG_HUD_AMMO);
    params.x           = GetCARPGHUDPositionX(CARPG_HUD_AMMO, ammoHUDPosition);
    params.y           = GetCARPGHUDPositionY(CARPG_HUD_AMMO, ammoHUDPosition);
    params.fadeinTime  = 0.0;
    params.fadeoutTime = 0.0;
    params.holdTime    = g_flAmmoRegenTickInterval; // Hold for two ticks to avoid flicker.
    params.effect      = HUD_EFFECT_RAMP_DOWN;
    params.fxTime     = 1.0;
    params.defdigits  = 1;
    params.maxdigits  = 3;
    params.value      = g_flAmmoResupplyTimer;
    Vector ammoHUDColor = GetCARPGHUDColorValue(rpgData.GetHUDColorIndex(CARPG_HUD_AMMO));
    params.color1     = RGBA(uint8(ammoHUDColor.x), uint8(ammoHUDColor.y), uint8(ammoHUDColor.z), 255);
    params.color2     = RGBA(255, 255, 255, 255);
    g_PlayerFuncs.HudTimeDisplay(pPlayer, params);
}

// Give ammo to player using selected method (silent or with pickup notification).
void GiveAmmoToPlayer(CBasePlayer@ pPlayer, int amount, int gameAmmoIndex, int maxAmmo)
{
    if(IsCARPGDisabledOnCurrentMap() || pPlayer is null || amount <= 0 || gameAmmoIndex < 0 || maxAmmo <= 0)
        return;
    
    int currentAmmo = pPlayer.m_rgAmmo(gameAmmoIndex);
    int remainingCapacity = maxAmmo - currentAmmo;
    if(remainingCapacity <= 0)
        return;

    int modifiedAmount = Math.min(amount, remainingCapacity);
    
    // Silent ammo addition (no pickup notification).
    pPlayer.m_rgAmmo(gameAmmoIndex, currentAmmo + modifiedAmount);
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
    if(IsCARPGDisabledOnCurrentMap())
        return;

    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
            UpdateAmmoRegenHUD(pPlayer);
    }
}