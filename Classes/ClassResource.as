/*
This file handles class specific resource, recovery and hud.
*/

dictionary g_PlayerClassResources; // Store resources per player

// Base values for stat menu.
const float flBaseResource = 0.0;
const float flBaseResourceMax = 100.0;
const float flBaseResourceRegen = 1.0;

float flClassResourceRegenDelay = 1.0; // Delay between class resource regen ticks.

void RegenClassResource()
{ 
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        // Check if player exists, is connected AND is alive
        if(pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            
            // Initialize resource if not exists
            if(!g_PlayerClassResources.exists(steamID))
            {
                dictionary resources = {
                    {'current', flBaseResource},
                    {'max', flBaseResourceMax},
                    {'regen', flBaseResourceRegen}
                };
                g_PlayerClassResources[steamID] = resources;
            }
            
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null)
                {
                    // Check for active abilities that prevent regen
                    bool isAuraActive = false;
                    bool isBarrierActive = false;
                    bool hasActiveMinions = false;
                    bool hasShockRifleEquipped = false;
                    bool isBloodlustActive = false;
                    bool isCloakActive = false;

                    if(g_HealingAuras.exists(steamID))
                    {
                        HealingAura@ aura = cast<HealingAura@>(g_HealingAuras[steamID]);
                        if(aura !is null)
                            isAuraActive = aura.IsActive();
                    }

                    if(g_PlayerBarriers.exists(steamID))
                    {
                        BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                        if(barrier !is null)
                            isBarrierActive = barrier.IsActive();
                    }

                    if(g_PlayerMinions.exists(steamID))
                    {
                        MinionData@ minion = cast<MinionData@>(g_PlayerMinions[steamID]);
                        if(minion !is null)
                            hasActiveMinions = minion.IsActive();
                    }

                    if(g_PlayerBloodlusts.exists(steamID))
                    {
                        BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                        if(bloodlust !is null)
                            isBloodlustActive = bloodlust.IsActive();
                    }

                    if(g_PlayerCloaks.exists(steamID))
                    {
                        CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
                        if(cloak !is null)
                            isCloakActive = cloak.IsActive();
                    }

                    // Shocktrooper Shock Rifle.
                    if(data.GetCurrentClass() == PlayerClass::CLASS_SHOCKTROOPER)
                    {
                        CBasePlayerItem@ currentItem = pPlayer.HasNamedPlayerItem("weapon_shockrifle");
                        
                        if(currentItem !is null && pPlayer.m_hActiveItem.GetEntity() is currentItem)
                        {
                            hasShockRifleEquipped = true;
                        }
                    }

                    // Skip regen if any ability is active.
                    if(isAuraActive || isBarrierActive || hasActiveMinions || 
                       hasShockRifleEquipped || isBloodlustActive || isCloakActive)
                        continue;

                    // Normal regen logic
                    float current = float(resources['current']);
                    float maximum = float(resources['max']);
                    float regen = float(resources['regen']);

                    if(current < maximum)
                    {
                        current += regen;
                        if(current > maximum)
                            current = maximum;
                        resources['current'] = current;
                    }
                }
            }
        }
    }
}

// Add this helper function near the top of the file
string GetResourceBar(float current, float maximum, int barLength = 20)
{
    float ratio = current / maximum;
    float realpos = ratio * barLength;
    string output = "[";
    
    // Our progress
    for(int i = 0; i < barLength; i++)
    {
        if(i <= realpos)
            output += "|";
        else
            output += "-";
    }
    
    output += "]";
    return output;
}

void UpdateClassResource() 
{
    for(int i = 1; i <= g_Engine.maxClients; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(!g_PlayerClassResources.exists(steamID))
                continue;

            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            float current = float(resources['current']);
            float maximum = float(resources['max']);

            HUDTextParams params;
            params.channel = 5;
            params.x = -1; // Center horizontally
            params.y = 0.85; // Position near bottom
            params.effect = 6; // 0: Normal text (no effect), 1: Fade in/out, 2: Flickering credits, 3: Write out (scan out), 4: Write out (scan right to left), 5: Write out (scan left to right), 6: Shimmer/vibrate.
            params.fadeinTime = 0;
            params.fadeoutTime = 0;
            params.holdTime = 0.5;
            params.fxTime = 2.0;

            // Primary Colour.
            params.r1 = 0;
            params.g1 = 255;
            params.b1 = 150;

            // Effect Colour.
            params.r2 = 0;
            params.g2 = 255;
            params.b2 = 255;

            string resourceName = "Energy"; // Rename energy to class specific resource name.
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null)
                {
                    PlayerClass currentClass = data.GetCurrentClass();
                    switch(currentClass)
                    {
                        case PlayerClass::CLASS_ENGINEER:
                            resourceName = "Power Reserve";
                            break;
                        case PlayerClass::CLASS_DEFENDER:
                            resourceName = "Barrier";
                            break;
                        case PlayerClass::CLASS_MEDIC:
                            resourceName = "Healing Aura";
                            break;
                        case PlayerClass::CLASS_SHOCKTROOPER:
                            resourceName = "Shock Charges";
                            break;
                        case PlayerClass::CLASS_BERSERKER:
                            resourceName = "Bloodlust";
                            break;
                        case PlayerClass::CLASS_CLOAKER:
                            resourceName = "Cloak";
                            break;
                        case PlayerClass::CLASS_DEMOLITIONIST:
                            resourceName = "Ordnance";
                            break;
                    }
                }
            }

            //string resourceInfo = "[" + resourceName + ": (" + int(current) + "/" + int(maximum) + ")] \n";
            string resourceInfo = "" + resourceName + ": (" + int(current) + "/" + int(maximum) +  ") - " + GetResourceBar(current, maximum) + "\n";
            //string resourceInfo = "" + resourceName + ": " + GetResourceBar(current, maximum) + " - (" + int(current) + "/" + int(maximum) + ")\n"; // Original.

            // Add additional class-specific info here later
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null)
                {
                    PlayerClass currentClass = data.GetCurrentClass();
                    switch(currentClass)
                    {
                        case PlayerClass::CLASS_ENGINEER:
                            if(g_PlayerMinions.exists(steamID))
                            {
                                MinionData@ minionData = cast<MinionData@>(g_PlayerMinions[steamID]);
                                if(minionData !is null)
                                {
                                    // Show just the count without max
                                    resourceInfo += "[Robots: " + minionData.GetMinionCount() + "]";
                                    
                                    // Add individual minion health info
                                    array<EHandle>@ minions = minionData.GetMinions();
                                    if(minions !is null && minions.length() > 0)
                                    {
                                        resourceInfo += "\n";
                                        for(uint minionIndex = 0; minionIndex < minions.length(); minionIndex++)
                                        {
                                            CBaseEntity@ pMinion = minions[minionIndex].GetEntity();
                                            if(pMinion !is null)
                                            {
                                                float healthPercent = (pMinion.pev.health / pMinion.pev.max_health) * 100;
                                                resourceInfo += "[" + int(healthPercent) + "%] ";
                                                //resourceInfo += "[" + (minionIndex + 1) + ": " + int(healthPercent) + "%] "; // Original.
                                            }
                                        }
                                    }
                                }
                            }
                            break;
                            
                        case PlayerClass::CLASS_DEFENDER:
                            if(g_PlayerBarriers.exists(steamID))
                            {
                                BarrierData@ barrierData = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                                if(barrierData !is null)
                                {
                                    bool isActive = barrierData.IsActive();
                                    resourceInfo += "[" + (isActive ? "ON" : "OFF") + "] ";
                                    
                                    //if(isActive)
                                    //{
                                        float reduction = barrierData.GetDamageReduction() * 100;
                                        resourceInfo += "[DR: " + int(reduction) + "%]";
                                    //}
                                }
                            }
                            break;
                            
                        case PlayerClass::CLASS_MEDIC:
                            if(g_HealingAuras.exists(steamID))
                            {
                                HealingAura@ healingAura = cast<HealingAura@>(g_HealingAuras[steamID]);
                                if(healingAura !is null)
                                {
                                    bool isActive = healingAura.IsActive();
                                    
                                    resourceInfo += "[" + (isActive ? "ON" : "OFF") + "]";
                                }
                            }
                            break;

                        case PlayerClass::CLASS_SHOCKTROOPER:
                        {
                            // Check for shock rifle
                            bool hasShockRifleEquipped = false;
                            CBasePlayerItem@ currentItem = pPlayer.HasNamedPlayerItem("weapon_shockrifle");
                            
                            if(currentItem !is null && pPlayer.m_hActiveItem.GetEntity() is currentItem)
                            {
                                hasShockRifleEquipped = true;
                            }
                            
                            // We can also lookup ammo count for additional info
                            int ammoIndex = g_PlayerFuncs.GetAmmoIndex("shock charges");
                            int currentAmmo = pPlayer.m_rgAmmo(ammoIndex);
                            
                            resourceInfo += "[Shock Rifle: " + (hasShockRifleEquipped ? "EQUIPPED" : "STOWED") + "] ";
                            if(hasShockRifleEquipped)
                            {
                                //resourceInfo += "[Charges: " + currentAmmo + "]";
                            }
                            break;
                        }

                        case PlayerClass::CLASS_BERSERKER:
                            if(g_PlayerBloodlusts.exists(steamID))
                            {
                                BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                                if(bloodlust !is null)
                                {
                                    bool isActive = bloodlust.IsActive();
                                    resourceInfo += "[" + (isActive ? "ON" : "OFF") + "] ";
                                    
                                    if(isActive)
                                    {
                                        float lifesteal = bloodlust.GetLifestealAmount(false) * 100;
                                        resourceInfo += "[Lifesteal: " + int(lifesteal) + "% + " + ((flBloodlustOverhealBase * 100) + (flBloodlustOverhealBonus * 100)) + "% AP to HP]";
                                    }
                                }
                            }
                            break;

                        case PlayerClass::CLASS_DEMOLITIONIST:
                        {
                            int rounds = 0;
                            int maxRounds = 0;
                            
                            if(g_PlayerExplosiveRounds.exists(steamID))
                            {
                                ExplosiveRoundsData@ explosiveRounds = cast<ExplosiveRoundsData@>(g_PlayerExplosiveRounds[steamID]);
                                if(explosiveRounds !is null)
                                {
                                    rounds = int(explosiveRounds.GetRounds());
                                    maxRounds = explosiveRounds.GetMaxRounds();
                                }
                            }
                            
                            resourceInfo += "[Explosive Rounds: (" + rounds + "/" + maxRounds + ")]";
                            break;
                        }

                        case PlayerClass::CLASS_CLOAKER:
                            if(g_PlayerCloaks.exists(steamID))
                            {
                                CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
                                if(cloak !is null)
                                {
                                    bool isActive = cloak.IsActive();
                                    resourceInfo += "[" + (isActive ? "ON" : "OFF") + "] ";
                                    
                                    if(isActive)
                                    {
                                        float damageBonus = (cloak.GetDamageMultiplier(pPlayer) - 1.0f) * 100;
                                        resourceInfo += "[Damage Bonus: +" + int(damageBonus) + "%]";
                                    }
                                }
                            }
                            break;
                    }
                }
            }

            g_PlayerFuncs.HudMessage(pPlayer, params, resourceInfo);
        }
    }
}