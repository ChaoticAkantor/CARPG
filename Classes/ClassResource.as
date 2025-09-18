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
                BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                if(data.GetCurrentClass() == PlayerClass::CLASS_DEFENDER && isBarrierActive)
                {
                    regen *= 0.50f; // 50% regeneration rate when active. Scales from total ability regen time.
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
    float segmentSize = 1.0f / barLength;
    string output = "[";
    
    // Simple filled/empty segment display.
    for(int i = 0; i < barLength; i++)
    {
        float segmentThreshold = segmentSize * (i + 1);
        if(ratio >= segmentThreshold)
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
        
        // Skip if player doesn't have class resources set up
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
                        resourceName = "Dragon's Breath Ammo Pack";
                        break;
                    case PlayerClass::CLASS_SWARMER:
                        resourceName = "Snark Swarms";
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
                                            float healthFlat = pMinion.pev.health;
                                            if(healthFlat <= 0)
                                                healthFlat = 0; // Default to 0 if health is invalid.

                                            // Flat HP display.
                                            int healthFlatInt = int(healthFlat);
                                            resourceInfo += "[Robogrunt" + ": " + healthFlatInt + " HP]\n";
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
                                    resourceInfo += "[Ability Recharge: " + (isActive ? "" + int(barrier.GetActiveRechargePenalty() * 100) + "%]\n" : "100%]\n");

                                    if(isActive)
                                    {
                                        resourceInfo += "[Damage Reflect: " + int(barrier.GetScaledDamageReflection() * 100) + "%]";
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
                                    bool isActive = healingAura.IsActive();
                                    if(isActive)
                                    {
                                        resourceInfo += "[Heal: " + int(healingAura.GetScaledHealAmount()) + "HP/s]\n";
                                        resourceInfo += "[Poison: " + int(healingAura.GetPoisonDamageAmount()) + "/s]";
                                    }
                                }
                            }
                            break;

                        case PlayerClass::CLASS_SHOCKTROOPER:
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
                            
                            resourceInfo += "[" + (hasShockRifleEquipped ? "EQUIPPED" : "STORED") + "]"; // Shockrifle battery.
                            break;
                        }

                        case PlayerClass::CLASS_BERSERKER:
                            if(g_PlayerBloodlusts.exists(steamID))
                            {
                                BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                                if(bloodlust !is null)
                                {
                                    bool isActive = bloodlust.IsActive();
                                    float lifesteal = bloodlust.GetLifestealAmount() * 100; // Base lifesteal.
                                    float dmgBonus = bloodlust.GetDamageBonus(pPlayer) * 100;
                                    
                                    //resourceInfo += "[" + (isActive ? " ON " : " OFF ") + "]";
                                    resourceInfo += " [DMG Bonus: +" + int(dmgBonus) + "%]\n";

                                    if (isActive)
                                    {
                                        resourceInfo += " [Lifesteal: " + int(lifesteal) + "%]";
                                    }

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
                                    resourceInfo += "[Fire Damage: " + DragonsBreath.GetScaledFireDamage() + "/s]";
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
                                        resourceInfo += "[Damage Bonus: +" + int((cloak.GetDamageMultiplier(pPlayer) - 1.0f) * 100) + "%]\n";
                                        resourceInfo += "[Nova Damage: " + int(cloak.GetNovaDamage(pPlayer)) + "]";
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
                                    
                                    // Make sure we have a valid health value.
                                    float healthFlat = pMinion.pev.health;
                                    if(healthFlat <= 0)
                                        healthFlat = 1; // Default to 1 if health is invalid.
                                    
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
                                        
                                    int healthFlatInt = int(healthFlat);
                                    resourceInfo += "[" + creatureName + ": " + healthFlatInt + " HP]\n";
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
                                    
                                    // Make sure we have a valid health value.
                                    float healthFlat = pMinion.pev.health;
                                    if(healthFlat <= 0)
                                        healthFlat = 1; // Default to 1 if health is invalid.
                                    
                                    // Get zombie type from stored info.
                                    string zombieName = "Zombie"; // Default fallback.
                                    
                                    // Get type from our stored information.
                                    int zombieType = minions[j].type;
                                    if(zombieType >= 0 && uint(zombieType) < NECRO_NAMES.length()) {
                                        zombieName = NECRO_NAMES[zombieType];
                                    }
                                    
                                    int healthFlatInt = int(healthFlat);
                                    resourceInfo += "[" + zombieName + ": " + healthFlatInt + " HP]\n";
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
                                        resourceInfo += "[Sentry HP: " + healthPercentInt + "%]\n";
                                        resourceInfo += " [Healing: " + sentryData.GetScaledHealAmount() + " HP/s]";
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
                                    resourceInfo += "[Snarks Per Swarm: " + snarkCount + "]";
                                }
                            }
                        break;
                }
            }
        }

        g_PlayerFuncs.HudMessage(pPlayer, params, resourceInfo);
    }
}