/*
This file handles class resource regeneration and HUD display.
*/

dictionary g_PlayerClassResources; // Store resources per player.
float flClassResourceRegenDelay = 1.0; // Delay between class resource regen ticks.

void RegenClassResource()
{ 
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            continue;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
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
                if(data.GetCurrentClass() == PlayerClass::CLASS_XENOLOGIST)
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

                // Skip regen if any ability is active.
                if(isAuraActive || hasActiveMinions || hasShockRifleEquipped || 
                   isBloodlustActive || isCloakActive || hasSentryActive)
                {
                    continue;
                }

                // Normal regen logic with special case for Defender
                float current = float(resources['current']);
                float maximum = float(resources['max']);
                float regen = float(resources['regen']);

                // Special case for Defender with active barrier. Regen at a reduced rate.
                BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                if(data.GetCurrentClass() == PlayerClass::CLASS_DEFENDER && isBarrierActive)
                {
                    if(barrier.HasStats() && barrier.GetStats().GetLevel() >= g_iPerk2LvlReq) // Defender Frosted perk.
                        regen *= 0.50f; // 50% regeneration rate when active instead if we meet the level requirement.
                    else
                        regen *= 0.25f; // Otherwise 25% regeneration rate when active.
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

string GetResourceBar(float current, float maximum, int barLength = 30)
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
                        case PlayerClass::CLASS_ROBOMANCER:
                            resourceName = "Robot Reserve";
                            break;
                        case PlayerClass::CLASS_ENGINEER:
                            resourceName = "Sentry Battery";
                            break;
                        case PlayerClass::CLASS_DEFENDER:
                            resourceName = "Ice Shield";
                            break;
                        case PlayerClass::CLASS_MEDIC:
                            resourceName = "Healing Aura";
                            break;
                        case PlayerClass::CLASS_SHOCKTROOPER:
                            resourceName = "Shockrifle Battery";
                            break;
                        case PlayerClass::CLASS_BERSERKER:
                            resourceName = "Bloodlust";
                            break;
                        case PlayerClass::CLASS_CLOAKER:
                            resourceName = "Cloak Battery";
                            break;
                        case PlayerClass::CLASS_DEMOLITIONIST:
                            resourceName = "Ammo Pack";
                            break;
                        case PlayerClass::CLASS_XENOLOGIST:
                            resourceName = "Creature Reserve";
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
                                    // Show the robot count.
                                    resourceInfo += "[Robogrunts: " + minionData.GetMinionCount() + "]";
                                    
                                    // Add individual minion health info.
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
                                    resourceInfo += "[" + (isActive ? " 50% Recovery " : " 100% Recovery ") + "] ";
                                }
                            }
                            break;
                            
                        case PlayerClass::CLASS_MEDIC:
                            if(g_HealingAuras.exists(steamID))
                            {
                                HealingAura@ healingAura = cast<HealingAura@>(g_HealingAuras[steamID]);
                                if(healingAura !is null)
                                {
                                    float HealAmount = healingAura.GetScaledHealAmount();

                                    bool isActive = healingAura.IsActive();
                                    if(isActive)
                                    {
                                        resourceInfo += "[Heal: " + int(HealAmount) + "HP/s]";
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
                            
                            resourceInfo += "[Shock Rifle: " + (hasShockRifleEquipped ? " EQUIPPED" : " STORED") + "] "; // Shockrifle battery.
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
                                    resourceInfo += " [DMG Bonus: +" + int(dmgBonus) + "%]";

                                    if (isActive)
                                    {
                                        resourceInfo += " [Lifesteal: " + int(lifesteal) + "%]";
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
                                    if(isActive)
                                    {
                                        float damageBonus = (cloak.GetDamageMultiplier(pPlayer) - 1.0f) * 100;
                                        resourceInfo += "[Damage Bonus: +" + int(damageBonus) + "%]";
                                    }
                                }
                            }
                            break;
                            
                        case PlayerClass::CLASS_XENOLOGIST:
                            if(g_XenologistMinions.exists(steamID))
                            {
                                XenMinionData@ minionData = cast<XenMinionData@>(g_XenologistMinions[steamID]);
                                if(minionData !is null)
                                {
                                    resourceInfo += "[Creatures: " + minionData.GetMinionCount() + "]";
                                    
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
                                            }
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
                                            resourceInfo += "[Sentry HP: " + int(healthPercent) + "%]";
                                            resourceInfo += " [Regeneration Buff: " + sentryData.GetScaledHealAmount() + " HP/s]";
                                        }
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