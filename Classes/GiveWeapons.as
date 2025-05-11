/* This file handles the helper functions for giving weapons to players based on their class.
must be careful with what weapons are given, as not only can it break map balance, 
some weapon models/sounds/sprites might not be precached for that map or globaly.
*/

// Define weapon lists per class. Class will instantly receive these weapons when they change to it.
dictionary g_ClassWeapons = {
    {PlayerClass::CLASS_MEDIC, array<string> = {
        "weapon_medkit",
    }},
    {PlayerClass::CLASS_ENGINEER, array<string> = {
        "weapon_pipewrench",
    }},
    {PlayerClass::CLASS_DEMOLITIONIST, array<string> = {
        "weapon_satchel",
        "weapon_handgrenade",
    }}
};

// Helper function to give out weapons.
void GiveClassWeapons(CBasePlayer@ pPlayer, PlayerClass pClass)
{
    if(pPlayer is null || !g_ClassWeapons.exists(pClass))
        return;
        
    array<string>@ weapons = cast<array<string>@>(g_ClassWeapons[pClass]);
    if(weapons !is null)
    {
        for(uint i = 0; i < weapons.length(); i++)
        {
            if(weapons[i].Length() > 0 && !HasWeapon(pPlayer, weapons[i]))
                pPlayer.GiveNamedItem(weapons[i]);
        }
    }
}

bool HasWeapon(CBasePlayer@ pPlayer, string weaponName)
{
    if(pPlayer is null)
        return false;
        
    CBasePlayerItem@ pItem = pPlayer.HasNamedPlayerItem(weaponName);
    return pItem !is null;
}