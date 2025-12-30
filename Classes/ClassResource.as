/*
This file handles class resource regeneration and HUD display.
*/

dictionary g_PlayerClassResources; // Store resources per player.
float flClassResourceRegenDelay = 1.0; // Delay between class resource regen ticks.

void RegenClassResource()
{ 
    // Iterate through all connected players.
    for (int i = 1; i <= g_Engine.maxClients; i++)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if (pPlayer is null || !pPlayer.IsConnected())
            continue;
            
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        
        // Skip if player doesn't have class resources set up.
        if (!g_PlayerClassResources.exists(steamID))
            continue;
        
        // Skip if player not found or not alive.
        if (pPlayer is null || !pPlayer.IsAlive())
            continue;
            
        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        
        if(g_PlayerRPGData.exists(steamID))
        {
            PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
            if(data !is null)
            {
                // Check for active abilities and prevent energy regen.
                bool isAuraActive = false;
                bool isBarrierActive = false;
                bool hasActiveMinions = false;
                bool hasShockRifleEquipped = false;
                bool isBloodlustActive = false;
                bool isCloakActive = false;
                bool hasSentryActive = false;

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
                
                if(g_XenologistMinions.exists(steamID))
                {
                    XenMinionData@ xenMinion = cast<XenMinionData@>(g_XenologistMinions[steamID]);
                    if(xenMinion !is null)
                        hasActiveMinions = xenMinion.IsActive();
                }
                
                if(g_NecromancerMinions.exists(steamID))
                {
                    NecroMinionData@ necroMinion = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
                    if(necroMinion !is null)
                        hasActiveMinions = necroMinion.IsActive();
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

                if(g_PlayerSentries.exists(steamID))
                {
                    SentryData@ sentry = cast<SentryData@>(g_PlayerSentries[steamID]);
                    if(sentry !is null)
                    {
                        hasSentryActive = sentry.IsActive();
                    }
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

                // Engineer Minion reserve pool.
                if(data.GetCurrentClass() == PlayerClass::CLASS_ROBOMANCER)
                {
                    if(g_PlayerMinions.exists(steamID))
                    {
                        MinionData@ minion = cast<MinionData@>(g_PlayerMinions[steamID]);
                        if(minion !is null)
                        {
                            float current = float(resources['current']);
                            float regen = float(resources['regen']);
                            
                            float maxReserve = 0.0f;  // Initialize first.
                            // Use instance reserve pool
                            maxReserve = float(resources['max']) - minion.GetReservePool();
                            
                            // Only regenerate if we have remaining reserve.
                            if(maxReserve > 0 && current < maxReserve)
                            {
                                current += regen;
                                if(current > maxReserve)
                                    current = maxReserve;
                                resources['current'] = current;
                            }
                            continue; // Skip normal regen logic.
                        }
                    }
                }

                // Xenologist Minion reserve pool.
                if(data.GetCurrentClass() == PlayerClass::CLASS_XENOMANCER)
                {
                    if(g_XenologistMinions.exists(steamID))
                    {
                        XenMinionData@ minion = cast<XenMinionData@>(g_XenologistMinions[steamID]);
                        if(minion !is null)
                        {
                            float current = float(resources['current']);
                            float regen = float(resources['regen']);
                            
                            float maxReserve = 0.0f;  // Initialize first.
                            // Use instance reserve pool
                            maxReserve = float(resources['max']) - minion.GetReservePool();
                            
                            // Only regenerate if we have remaining reserve.
                            if(maxReserve > 0 && current < maxReserve)
                            {
                                current += regen;
                                if(current > maxReserve)
                                    current = maxReserve;
                                resources['current'] = current;
                            }
                            continue; // Skip normal regen logic.
                        }
                    }
                }
                
                // Necromancer Minion reserve pool.
                if(data.GetCurrentClass() == PlayerClass::CLASS_NECROMANCER)
                {
                    if(g_NecromancerMinions.exists(steamID))
                    {
                        NecroMinionData@ minion = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
                        if(minion !is null)
                        {
                            float current = float(resources['current']);
                            float regen = float(resources['regen']);
                            
                            float maxReserve = 0.0f;  // Initialize first.
                            // Use instance reserve pool
                            maxReserve = float(resources['max']) - minion.GetReservePool();
                            
                            // Only regenerate if we have remaining reserve.
                            if(maxReserve > 0 && current < maxReserve)
                            {
                                current += regen;
                                if(current > maxReserve)
                                    current = maxReserve;
                                resources['current'] = current;
                            }
                            continue; // Skip normal regen logic.
                        }
                    }
                }

                // Skip regen if any ability is active.
                if(isAuraActive || hasActiveMinions || hasShockRifleEquipped || 
                   isBloodlustActive || isCloakActive || hasSentryActive)
                {
                    continue;
                }

                // Normal regen logic with special case for Defender.
                float current = float(resources['current']);
                float maximum = float(resources['max']);
                float regen = float(resources['regen']);

                // Special case for Defender with active barrier. Regen at a reduced rate.
                if (g_PlayerBarriers.exists(steamID))
                {
                    BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                    if (barrier !is null && barrier.IsActive() && data.GetCurrentClass() == PlayerClass::CLASS_DEFENDER)
                    {
                        regen *= barrier.GetActiveRechargePenalty(); // Apply penalty BEFORE adding to current
                    }
                }

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

string GetResourceBar(float current, float maximum, int barLength = 20)
{ 
    float ratio = current / maximum;
    string output = "[";
    
    // Calculate how many segments should be filled.
    int filledSegments = int(ratio * barLength);
    
    for(int i = 0; i < barLength; i++)
    {
        if(i < filledSegments)
            output += "|"; // Filled segment.
        else
            output += " "; // Empty segment.
    }
    
    output += "]";
    return output;
}

void UpdateClassResource() // Update the class resource hud display for all players.
{
    // Iterate through all connected players
    for (int i = 1; i <= g_Engine.maxClients; i++)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if (pPlayer is null || !pPlayer.IsConnected())
            continue;
            
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        
        // Skip if player doesn't have class resources set up.
        if (!g_PlayerClassResources.exists(steamID))
            continue;
            
        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        float current = float(resources['current']);
        float maximum = float(resources['max']);

        HUDTextParams params;
        params.channel = 5; // API says 1-4, though I'm sure it supports up to 16 actually?
        params.x = -1; // Center horizontally.
        params.y = 0.9; // Position near bottom.
        params.effect = 0; // 0: Fade in/out, 1: Credits, 2: Scan Out.
        params.fadeinTime = 0;
        params.fadeoutTime = 0;
        params.holdTime = 0.2; // How long message displays.
        params.fxTime = 0.0; // Effect time (scan effect only).

        // Primary Colour.
        params.r1 = 0;
        params.g1 = 255;
        params.b1 = 255;

        // Effect Colour.
        params.r2 = 0;
        params.g2 = 255;
        params.b2 = 255;

        string resourceName = "Energy"; // Rename our energy to class specific resource name.
        if(g_PlayerRPGData.exists(steamID))
        {
            PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
            if(data !is null)
            {
                PlayerClass currentClass = data.GetCurrentClass();
                switch(currentClass)
                {
                    case PlayerClass::CLASS_MEDIC:
                        resourceName = "Heal Aura";
                        break;
                    case PlayerClass::CLASS_BERSERKER:
                        resourceName = "Bloodlust";
                        break;
                    case PlayerClass::CLASS_ROBOMANCER:
                        resourceName = "Robo Points";
                        break;
                    case PlayerClass::CLASS_XENOMANCER:
                        resourceName = "Xeno Points";
                        break;
                    case PlayerClass::CLASS_NECROMANCER:
                        resourceName = "Necro Points";
                        break;
                    case PlayerClass::CLASS_ENGINEER:
                        resourceName = "Sentry Battery";
                        break;
                    case PlayerClass::CLASS_DEFENDER:
                        resourceName = "Ice Shield";
                        break;
                    case PlayerClass::CLASS_SHOCKTROOPER:
                        resourceName = "Shockrifle Recharger";
                        break;
                    case PlayerClass::CLASS_CLOAKER:
                        resourceName = "Cloak Battery";
                        break;
                    case PlayerClass::CLASS_VANQUISHER:
                        resourceName = "Dragon's Breath Ammo";
                        break;
                    case PlayerClass::CLASS_SWARMER:
                        resourceName = "Snark Swarm";
                        break;
                }
            }
        }

        string resourceInfo = "" + resourceName + ": (" + int(current) + "/" + int(maximum) +  ") - " + GetResourceBar(current, maximum) + "\n";

            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null)
                {
                    PlayerClass currentClass = data.GetCurrentClass();
                    switch(currentClass)
                    {
                        case PlayerClass::CLASS_ROBOMANCER:
                            if(g_PlayerMinions.exists(steamID))
                            {
                                MinionData@ minionData = cast<MinionData@>(g_PlayerMinions[steamID]);
                                if(minionData !is null)
                                {
                                    // Add individual minion health info.
                                    array<MinionInfo>@ minions = minionData.GetMinions();
                                    if(minions !is null && minions.length() > 0)
                                    {
                                        int validMinionCount = 0;
                                        
                                        // First collect all valid minions.
                                        array<CBaseEntity@> validMinions;
                                        for(uint minionIndex = 0; minionIndex < minions.length(); minionIndex++)
                                        {
                                            // First just check if entity exists without modifying the array.
                                            CBaseEntity@ pMinion = minions[minionIndex].hMinion.GetEntity();
                                            if(pMinion !is null && pMinion.pev.health > 0)
                                            {
                                                validMinions.insertLast(pMinion);
                                            }
                                        }
                                        
                                        // Now display the valid minions.
                                        for(uint j = 0; j < validMinions.length(); j++)
                                        {
                                            CBaseEntity@ pMinion = validMinions[j];
                                            validMinionCount++;
                                            
                                            // Make sure we have a valid health value.
                                            float healthFlatRobo = 0;
                                                healthFlatRobo = pMinion.pev.health;

                                            //if(healthFlatRobo is null)
                                                //healthFlatRobo = 0; // Default to 0 if health is invalid for whatever reason.

                                            // Flat HP display.
                                            resourceInfo += "[Robogrunt" + ": " + int(healthFlatRobo) + " HP]\n";
                                        }
                                    }
                                }
                            }
                            break;
                            
                        case PlayerClass::CLASS_DEFENDER:
                            if(g_PlayerBarriers.exists(steamID))
                            {
                                BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                                if(barrier !is null)
                                {
                                    bool isActive = barrier.IsActive();

                                    if (!isActive)
                                    {
                                        resourceInfo += "[Ability Recharge: 100%]\n";
                                    }
                                    else
                                    {
                                        resourceInfo += "[Ability Recharge: " + int(barrier.GetActiveRechargePenalty() * 100) + "%]\n";
                                        resourceInfo += "[DMG Reflect: " + int(barrier.GetScaledDamageReflection() * 100) + "%]";
                                    }
                                }
                            }
                            break;
                            
                        case PlayerClass::CLASS_MEDIC:
                            if(g_HealingAuras.exists(steamID))
                            {
                                HealingAura@ healingAura = cast<HealingAura@>(g_HealingAuras[steamID]);
                                if(healingAura !is null)
                                {
                                    resourceInfo += "[Healing: " + (healingAura.GetScaledHealAmount()) + "/s]\n";
                                    resourceInfo += "[Poison DMG: " + (healingAura.GetPoisonDamageAmount()) + "/s]";
                                }
                            }
                            break;

                        case PlayerClass::CLASS_SHOCKTROOPER:
                            if(g_ShockRifleData.exists(steamID))
                            {
                                ShockRifleData@ shockData = cast<ShockRifleData@>(g_ShockRifleData[steamID]);
                                if(shockData !is null)
                                {

                                // Check for shock rifle, doing this one differently incase we pick up a shock roach in the world.
                                bool hasShockRifleEquipped = false;
                                CBasePlayerItem@ currentItem = pPlayer.HasNamedPlayerItem("weapon_shockrifle");
                                
                                if(currentItem !is null && pPlayer.m_hActiveItem.GetEntity() is currentItem)
                                {
                                    hasShockRifleEquipped = true;
                                }
                                
                                // Grab ammo.
                                int ammoIndex = g_PlayerFuncs.GetAmmoIndex("shock charges");
                                int currentAmmo = pPlayer.m_rgAmmo(ammoIndex);
                                
                                resourceInfo += "[" + (hasShockRifleEquipped ? "EQUIPPED" : "STORED") + "]\n"; // Shockrifle battery.

                                if (hasShockRifleEquipped)
                                    resourceInfo += "[DMG Bonus: " + int(shockData.GetScaledDamage() * 100) + "%]\n"; // Show damage bonus whilst equipped.

                                }
                            }
                            break;

                        case PlayerClass::CLASS_BERSERKER:
                            if(g_PlayerBloodlusts.exists(steamID))
                            {
                                BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                                if(bloodlust !is null)
                                {
                                    bool isActive = bloodlust.IsActive();
                                    float lifesteal = bloodlust.GetLifestealAmount(); // Base lifesteal.
                                    float damageReduction = bloodlust.GetDamageReduction(pPlayer);
                                    
                                    resourceInfo += "[DMG Reduction: +" + int(damageReduction) + "%]\n";
                                    resourceInfo += "[Ability Charge Steal: " + int(bloodlust.GetEnergystealAmount() * 100) + "%]\n";
                                    resourceInfo += "[Lifesteal: " + int(lifesteal * 100) + "%]";
                                }
                            }
                            break;

                        case PlayerClass::CLASS_VANQUISHER:
                            if(g_PlayerDragonsBreath.exists(steamID))
                            {   
                                int rounds = 0;
                                int maxRounds = 0;

                                DragonsBreathData@ DragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamID]);
                                if(DragonsBreath !is null)
                                {
                                    rounds = int(DragonsBreath.GetRounds());
                                    maxRounds = DragonsBreath.GetMaxRounds();
                                }

                                resourceInfo += "[Dragon's Breath Rounds: (" + rounds + "/" + maxRounds + ")]\n";

                                if(DragonsBreath.HasRounds())
                                {
                                    resourceInfo += "[Incendiary DMG: " + DragonsBreath.GetScaledFireDamage() + "/s]";
                                }
                            }
                            break;

                        case PlayerClass::CLASS_CLOAKER:
                            if(g_PlayerCloaks.exists(steamID))
                            {
                                CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
                                if(cloak !is null)
                                {
                                    bool isActive = cloak.IsActive(); 
                                    if(isActive)
                                    {
                                        resourceInfo += "[Cloak DMG: +" + int(cloak.GetDamageMultiplier(pPlayer) * 100) + "%]\n";
                                        resourceInfo += "[Nova DMG: " + int(cloak.GetNovaDamage(pPlayer)) + "]";
                                    }
                                }
                            }
                            break;
                            
                    case PlayerClass::CLASS_XENOMANCER:
                        if(g_XenologistMinions.exists(steamID))
                        {
                            XenMinionData@ minionData = cast<XenMinionData@>(g_XenologistMinions[steamID]);
                            if(minionData !is null)
                            {   
                                array<XenMinionInfo>@ minions = minionData.GetMinions();
                                if(minions !is null && minions.length() > 0)
                                {
                                    int validMinionCount = 0;
                                    // First collect all valid minions.
                                    array<CBaseEntity@> validMinions;
                                    for(uint minionIndex = 0; minionIndex < minions.length(); minionIndex++)
                                    {
                                        // First just check if entity exists without modifying the array.
                                        CBaseEntity@ pMinion = minions[minionIndex].hMinion.GetEntity();
                                        if(pMinion !is null && pMinion.pev.health > 0)
                                        {
                                            validMinions.insertLast(pMinion);
                                        }
                                    }
                                
                                // Now display the valid minions.
                                for(uint j = 0; j < validMinions.length(); j++)
                                {
                                    CBaseEntity@ pMinion = validMinions[j];
                                    validMinionCount++;
                                    
                                    // Get creature type from entity classname instead of relying on arrays.
                                    string creatureName = "Creature"; // Default fallback.
                                    
                                    // Get classname directly from the entity
                                    string classname = pMinion.pev.classname;
                                    
                                    // Map classnames to readable names - more reliable than array indexes.
                                    if(classname == "monster_houndeye")
                                        creatureName = "Houndeye";
                                    else if(classname == "monster_pitdrone") 
                                        creatureName = "Pit Drone";
                                    else if(classname == "monster_bullchicken")
                                        creatureName = "Bullsquid";
                                    else if(classname == "monster_shocktrooper")
                                        creatureName = "Shocktrooper";
                                    else if(classname == "monster_babygarg")
                                        creatureName = "Baby Garg";

                                    // Make sure we have a valid health value.
                                    float healthFlatXeno = 0;
                                        healthFlatXeno = pMinion.pev.health;

                                    //if(healthFlatXeno == 0)
                                        //healthFlatXeno = 0; // Default to 0 if health is invalid for whatever reason.
                                        
                                    resourceInfo += "[" + creatureName + ": " + int(healthFlatXeno) + " HP]\n";
                                }
                            }
                        }
                    }
                    break;
                    
                    case PlayerClass::CLASS_NECROMANCER:
                        if(g_NecromancerMinions.exists(steamID))
                        {
                            NecroMinionData@ minionData = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
                            if(minionData !is null)
                            {   
                                array<NecroMinionInfo>@ minions = minionData.GetMinions();
                                if(minions !is null && minions.length() > 0)
                                {
                                    int validMinionCount = 0;
                                    
                                    // First collect all valid minions.
                                    array<CBaseEntity@> validMinions;
                                    for(uint minionIndex = 0; minionIndex < minions.length(); minionIndex++)
                                    {
                                        // First just check if entity exists without modifying the array.
                                        CBaseEntity@ pMinion = minions[minionIndex].hMinion.GetEntity();
                                        if(pMinion !is null && pMinion.pev.health > 0)
                                        {
                                            validMinions.insertLast(pMinion);
                                        }
                                    }
                                
                                // Now display the valid minions.
                                for(uint j = 0; j < validMinions.length(); j++)
                                {
                                    CBaseEntity@ pMinion = validMinions[j];
                                    validMinionCount++;
                                    
                                    // Get zombie type from stored info.
                                    string zombieName = "Zombie"; // Default fallback.
                                    
                                    // Get type from our stored information.
                                    int zombieType = minions[j].type;
                                    if(zombieType >= 0 && uint(zombieType) < NECRO_NAMES.length()) 
                                    {
                                        zombieName = NECRO_NAMES[zombieType];
                                    }

                                    // Make sure we have a valid health value.
                                    float healthFlatNecro = 0;
                                        healthFlatNecro = pMinion.pev.health;
                                        
                                    //if(healthFlatNecro is null)
                                        //healthFlatNecro = 0; // Default to 0 if health is invalid for whatever reason.
                                    
                                    resourceInfo += "[" + zombieName + ": " + int(healthFlatNecro) + " HP]\n";
                                }
                            }
                        }
                    }
                    break;     

                    case PlayerClass::CLASS_ENGINEER:
                        if(g_PlayerSentries.exists(steamID))
                        {
                            SentryData@ sentryData = cast<SentryData@>(g_PlayerSentries[steamID]);
                            if(sentryData !is null)
                            {
                                bool isActive = sentryData.IsActive();
                                if(isActive)
                                {
                                    CBaseEntity@ pSentry = sentryData.GetSentryEntity();
                                    if(pSentry !is null)
                                    {
                                        float healthPercent = (pSentry.pev.health / pSentry.pev.max_health) * 100;
                                        int healthPercentInt = int(healthPercent);
                                        resourceInfo += "[Sentry HP: " + healthPercentInt + "%]";
                                        resourceInfo += " [Healing: " + sentryData.GetScaledHealAmount() + " HP/s]\n";
                                        resourceInfo += " [Freeze Effect: " + (sentryData.GetCryoShotsSlowInverse()) + "%]\n";
                                    }
                                }
                            }
                        }
                        break;
                        
                        case PlayerClass::CLASS_SWARMER:
                            if(g_PlayerSnarkNests.exists(steamID))
                            {
                                SnarkNestData@ snarkData = cast<SnarkNestData@>(g_PlayerSnarkNests[steamID]);
                                if(snarkData !is null)
                                {
                                    int snarkCount = snarkData.GetSnarkCount();
                                    resourceInfo += "[Snark Swarm Size: " + snarkCount + "]";
                                }
                            }
                        break;
                }
            }
        }

        g_PlayerFuncs.HudMessage(pPlayer, params, resourceInfo);
    }
}