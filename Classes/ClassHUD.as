/*
This file handles class HUD display.
*/

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

void UpdateClassResource() // Update the class resource HUD display for all players.
{
    // Iterate through all connected players
    for (int i = 1; i <= g_Engine.maxClients; i++)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if (pPlayer is null || !pPlayer.IsConnected())
            continue;
            
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        
        if(!g_PlayerRPGData.exists(steamID))
            continue;

        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data is null)
            continue;

        float current = 0.0f;
        float maximum = 1.0f;

        HUDTextParams params;
        params.channel = 5;
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

        string resourceName = "Ability Charge"; // Rename our energy to class specific resource name.
        string resourceInfo = "";

        PlayerClass currentClass = data.GetCurrentClass();
        ClassStats@ stats = data.GetCurrentClassStats();
        switch(currentClass)
        {
            case PlayerClass::CLASS_MEDIC:
                resourceName = "Heal Aura";
                if(g_HealingAuras.exists(steamID))
                {
                    HealingAura@ healingAura = cast<HealingAura@>(g_HealingAuras[steamID]);
                    if(healingAura !is null)
                    {
                        current = healingAura.GetAbilityCharge();
                        maximum = healingAura.GetAbilityMax();
                        
                        resourceInfo += "[Healing: " + healingAura.GetScaledHealAmount() + "% HP] ";

                        if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_MEDIC_POISON) > 0)
                            resourceInfo += "[Poison: " + int(healingAura.GetPoisonDamageAmount()) + "% HP]\n";

                        
                        if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_MEDIC_REVIVE) > 0)
                            resourceInfo += healingAura.GetReviveCooldownDisplay() + "\n";

                    }
                }
                break;

            case PlayerClass::CLASS_BERSERKER:
                resourceName = "Bloodlust";
                if(g_PlayerBloodlusts.exists(steamID))
                {
                    BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                    if(bloodlust !is null)
                    {
                        current = bloodlust.GetAbilityCharge();
                        maximum = bloodlust.GetAbilityMax();

                        resourceInfo += "[Lifesteal: " + int(bloodlust.GetScaledLifesteal() * 100) + "%] ";

                        if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_BERSERKER_DAMAGEREDUCTION) > 0)
                            resourceInfo += "[DMG Reduction: " +  int(bloodlust.GetDamageReduction(pPlayer) * 100) + "%]\n";

                        if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_BERSERKER_DAMAGEABILITYCHARGE) > 0)
                            resourceInfo += "[Bloodlust DMG Gain: " +  int(bloodlust.GetScaledDamageAbilityCharge() * 100) + "%]\n";

                        if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_BERSERKER_OVERHEAL) > 0)
                            resourceInfo += "[Overheal Limit: " + int(pPlayer.pev.max_health * bloodlust.GetScaledOverhealPercent()) + " HP]";
                    }
                }
                break;

            case PlayerClass::CLASS_ROBOMANCER:
                resourceName = "Robo Points";
                if(g_PlayerMinions.exists(steamID))
                {
                    MinionData@ minionData = cast<MinionData@>(g_PlayerMinions[steamID]);
                    if(minionData !is null)
                    {
                        current = minionData.GetAbilityCharge();
                        maximum = minionData.GetAbilityMax();
                        array<MinionInfo>@ minions = minionData.GetMinions();
                        if(minions !is null && minions.length() > 0)
                        {
                            array<CBaseEntity@> validMinions;
                            for(uint minionIndex = 0; minionIndex < minions.length(); minionIndex++)
                            {
                                CBaseEntity@ pMinion = minions[minionIndex].hMinion.GetEntity();
                                if(pMinion !is null && pMinion.pev.health > 0)
                                    validMinions.insertLast(pMinion);
                            }
                            for(uint j = 0; j < validMinions.length(); j++)
                            {
                                resourceInfo += "[Robogrunt: " + int(validMinions[j].pev.health) + " HP]\n";
                            }
                        }
                    }
                }
                break;

            case PlayerClass::CLASS_XENOMANCER:
                resourceName = "Xeno Points";
                if(g_XenologistMinions.exists(steamID))
                {
                    XenMinionData@ minionData = cast<XenMinionData@>(g_XenologistMinions[steamID]);
                    if(minionData !is null)
                    {
                        current = minionData.GetAbilityCharge();
                        maximum = minionData.GetAbilityMax();
                        array<XenMinionInfo>@ minions = minionData.GetMinions();
                        if(minions !is null && minions.length() > 0)
                        {
                            array<CBaseEntity@> validMinions;
                            for(uint minionIndex = 0; minionIndex < minions.length(); minionIndex++)
                            {
                                CBaseEntity@ pMinion = minions[minionIndex].hMinion.GetEntity();
                                if(pMinion !is null && pMinion.pev.health > 0)
                                    validMinions.insertLast(pMinion);
                            }
                            for(uint j = 0; j < validMinions.length(); j++)
                            {
                                CBaseEntity@ pMinion = validMinions[j];
                                string creatureName = "Creature";
                                string classname = pMinion.pev.classname;
                                if(classname == "monster_houndeye")         creatureName = "Houndeye";
                                else if(classname == "monster_pitdrone")    creatureName = "Pit Drone";
                                else if(classname == "monster_bullchicken") creatureName = "Bullsquid";
                                else if(classname == "monster_shocktrooper") creatureName = "Shocktrooper";
                                else if(classname == "monster_babygarg")    creatureName = "Baby Garg";
                                resourceInfo += "[" + creatureName + ": " + int(pMinion.pev.health) + " HP]\n";
                            }
                        }
                    }
                }
                break;

            case PlayerClass::CLASS_NECROMANCER:
                resourceName = "Necro Points";
                if(g_NecromancerMinions.exists(steamID))
                {
                    NecroMinionData@ minionData = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
                    if(minionData !is null)
                    {
                        current = minionData.GetAbilityCharge();
                        maximum = minionData.GetAbilityMax();
                        array<NecroMinionInfo>@ minions = minionData.GetMinions();
                        if(minions !is null && minions.length() > 0)
                        {
                            array<CBaseEntity@> validMinions;
                            array<int> validTypes;
                            for(uint minionIndex = 0; minionIndex < minions.length(); minionIndex++)
                            {
                                CBaseEntity@ pMinion = minions[minionIndex].hMinion.GetEntity();
                                if(pMinion !is null && pMinion.pev.health > 0)
                                {
                                    validMinions.insertLast(pMinion);
                                    validTypes.insertLast(minions[minionIndex].type);
                                }
                            }
                            for(uint j = 0; j < validMinions.length(); j++)
                            {
                                string zombieName = "Zombie";
                                int zombieType = validTypes[j];
                                if(zombieType >= 0 && uint(zombieType) < NECRO_NAMES.length())
                                    zombieName = NECRO_NAMES[zombieType];
                                resourceInfo += "[" + zombieName + ": " + int(validMinions[j].pev.health) + " HP]\n";
                            }
                        }
                    }
                }
                break;

            case PlayerClass::CLASS_ENGINEER:
                resourceName = "Sentry";
                if(g_PlayerSentries.exists(steamID))
                {
                    SentryData@ sentryData = cast<SentryData@>(g_PlayerSentries[steamID]);
                    if(sentryData !is null)
                    {
                        current = sentryData.GetAbilityCharge();
                        maximum = sentryData.GetAbilityMax();
                        if(sentryData.IsActive())
                        {
                            CBaseEntity@ pSentry = sentryData.GetSentryEntity();
                            if(pSentry !is null)
                            {
                                float healthPercent = (pSentry.pev.health / pSentry.pev.max_health) * 100;

                                resourceInfo += "[Sentry HP: " + int(healthPercent) + "%] ";

                                resourceInfo += "[DMG: " + int(sentryData.GetScaledDamage() * 100) + "%] ";

                                if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_ENGINEER_EXPLOSIVEAMMO) > 0)
                                    resourceInfo += "[Explosive DMG: " + int(sentryData.GetScaledExplosiveDamage() * 100) + "%]\n";

                                if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_ENGINEER_MINIHEALAURA) > 0)
                                    resourceInfo += "[Healing: " + sentryData.GetScaledHealAmount() + "% HP/s]\n";
                            }
                        }
                    }
                }
                break;

            case PlayerClass::CLASS_DEFENDER:
                resourceName = "Ice Shield";
                if(g_PlayerBarriers.exists(steamID))
                {
                    BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                    if(barrier !is null)
                    {
                        current = barrier.GetAbilityCharge();
                        maximum = barrier.GetShieldMaxHP();

                            if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_WARDEN_DAMAGEREFLECT) > 0)
                                resourceInfo += "[DMG Reflect: " + ceil(barrier.GetScaledDamageReflection() * 100) + "%] ";

                            if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_WARDEN_HPABSORB) > 0)
                                resourceInfo += "[HP Absorb: " + ceil(barrier.GetScaledHealthAbsorb() * 100) + "%]\n";
                            
                        if(barrier.IsActive())
                        {
                            if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_WARDEN_ACTIVERECHARGE) > 0)
                                resourceInfo += "[Recharge Speed: " + ceil(barrier.GetActiveRechargeRate() * 100) + "%] ";
                        }
                    }
                }
                break;

            case PlayerClass::CLASS_SHOCKTROOPER:
                resourceName = "Super Shockrifle";
                if(g_ShockRifleData.exists(steamID))
                {
                    ShockRifleData@ shockData = cast<ShockRifleData@>(g_ShockRifleData[steamID]);
                    if(shockData !is null)
                    {
                        current = shockData.GetAbilityCharge();
                        maximum = shockData.GetAbilityMax();
                        bool hasShockRifleEquipped = false;
                        CBasePlayerItem@ currentItem = pPlayer.HasNamedPlayerItem("weapon_shockrifle");

                        if(currentItem !is null && pPlayer.m_hActiveItem.GetEntity() is currentItem)
                            hasShockRifleEquipped = true;
                        resourceInfo += (hasShockRifleEquipped ? "[Equipped]" : "") + "\n";

                        if(hasShockRifleEquipped)
                            resourceInfo += "[Shockrifle DMG: " + int(shockData.GetScaledDamage() * 100) + "%]\n";
                    }
                }
                break;

            case PlayerClass::CLASS_CLOAKER:
                resourceName = "Cloak";
                if(g_PlayerCloaks.exists(steamID))
                {
                    CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
                    if(cloak !is null)
                    {
                        current = cloak.GetAbilityCharge();
                        maximum = cloak.GetAbilityMax();
                        if(cloak.IsActive())
                        {
                            if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_CLOAKER_CLOAKDAMAGE) > 0)
                                resourceInfo += "[Cloak DMG: +" + int(cloak.GetDamageMultiplier(pPlayer) * 100) + "%]\n";

                            if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_CLOAKER_CLOAKNOVADAMAGE) > 0)
                                resourceInfo += "[Nova DMG: " + int(cloak.GetNovaDamage(pPlayer)) + "]";
                        }
                    }
                }
                break;

            case PlayerClass::CLASS_VANQUISHER:
                resourceName = "Dragon's Breath";
                if(g_PlayerDragonsBreath.exists(steamID))
                {
                    DragonsBreathData@ dragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamID]);
                    if(dragonsBreath !is null)
                    {
                        current = dragonsBreath.GetAbilityCharge();
                        maximum = dragonsBreath.GetAbilityMax();
                        dragonsBreath.UpdateAmmoFromWeapon(pPlayer);
                        resourceInfo += "[Rounds: " + int(dragonsBreath.GetRounds()) + "/" + dragonsBreath.GetMaxRounds() + "] ";
                        resourceInfo += "[Cost: " + dragonsBreath.GetPerShotCost() + "]\n";
                        if(dragonsBreath.HasRounds())
                        {
                            resourceInfo += "[Explosive DMG: " + dragonsBreath.GetScaledExplosionDamage() + "] ";

                            if (stats !is null && stats.GetSkillLevel(SkillID::SKILL_VANQUISHER_FIREDAMAGE) > 0)
                                resourceInfo += "[Fire DMG: " + dragonsBreath.GetScaledFireDamage() + "/s]";
                        }
                    }
                }
                break;

            case PlayerClass::CLASS_SWARMER:
                resourceName = "Snark Swarm";
                if(g_PlayerSnarkNests.exists(steamID))
                {
                    SnarkNestData@ snarkData = cast<SnarkNestData@>(g_PlayerSnarkNests[steamID]);
                    if(snarkData !is null)
                    {
                        current = snarkData.GetAbilityCharge();
                        maximum = snarkData.GetAbilityMax();
                        resourceInfo += "[Snark Swarm Size: " + snarkData.GetSnarkCount() + "]";
                    }
                }
                break;
        }

        if(maximum <= 0.0f) continue;

        string hudText = resourceName + ": (" + int(current) + "/" + int(maximum) + ") - " + GetResourceBar(current, maximum) + "\n" + resourceInfo;
        g_PlayerFuncs.HudMessage(pPlayer, params, hudText);
    }
}
