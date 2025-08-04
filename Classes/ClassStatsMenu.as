namespace Menu
{
    final class StatsMenu
    {
        private CTextMenu@ m_pMenu;
        private PlayerData@ m_pOwner;
        private ClassStats@ m_pStats;
        
        StatsMenu(PlayerData@ owner)
        {
            @m_pOwner = owner;
        }
        
        void Show(CBasePlayer@ pPlayer)
        {
            if(pPlayer is null) 
                return;
                
            @m_pStats = m_pOwner.GetCurrentClassStats();
            if(m_pStats is null)
                return;
                
            @m_pMenu = CTextMenu(TextMenuPlayerSlotCallback(this.MenuCallback));

            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            ClassDefinition@ def = cast<ClassDefinition@>(g_ClassDefinitions[m_pOwner.GetCurrentClass()]);
    
            int level = m_pStats.GetLevel();
            string title = m_pOwner.GetClassName(m_pOwner.GetCurrentClass()) + "\n";
            title += "Lvl: " + level + " | " + "XP: (" + m_pStats.GetCurrentLevelXP() + "/" + m_pStats.GetNeededXP() + ")\n\n";
            m_pMenu.SetTitle(title);
    
            // Get energy stats from resource dictionary, fallback to class definition if missing.
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            float maxEnergy = def !is null ? def.GetPlayerEnergy(level) : 100.0f;
            float energyRegen = def !is null ? def.GetPlayerEnergyRegen(level, maxEnergy) : 0.0f;
            if(resources !is null)
            {
                if(resources.exists('max'))
                    maxEnergy = float(resources['max']);
                if(resources.exists('regen'))
                    energyRegen = float(resources['regen']);
            }

            // Display basic stats.
            string BaseStatsText = "=== Basic Stats: ===\n" +
                "Max Health: " + int(pPlayer.pev.max_health) + " HP\n" + 
                "Max Armor: " + int(pPlayer.pev.armortype) + " AP\n" + 
                "Ability Duration/Charges: " + int(maxEnergy) + "\n" + 
                "Ability Recharge Rate: " + energyRegen + "/s\n\n";

                BaseStatsText += "=== Class Perks: ===\n";
            
                // Display perks based on class and level
                switch(m_pOwner.GetCurrentClass())
                {
                    case PlayerClass::CLASS_MEDIC:
                    {
                        if(m_pStats.GetLevel() >= 10)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 10 >\n";

                        if(m_pStats.GetLevel() >= 20)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 20 >\n";

                        if(m_pStats.GetLevel() >= 30)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 30 >\n\n";
                        break;
                    }
                    case PlayerClass::CLASS_BERSERKER:
                    {
                        if(m_pStats.GetLevel() >= 10)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 10 >\n";

                        if(m_pStats.GetLevel() >= 20)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 20 >\n";

                        if(m_pStats.GetLevel() >= 30)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 30 >\n\n";
                        break;
                    }
                    case PlayerClass::CLASS_ROBOMANCER:
                    {
                        if(m_pStats.GetLevel() >= 10)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 10 >\n";

                        if(m_pStats.GetLevel() >= 20)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 20 >\n";

                        if(m_pStats.GetLevel() >= 30)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 30 >\n\n";
                        break;
                    }
                    case PlayerClass::CLASS_XENOMANCER:
                    {
                        if(m_pStats.GetLevel() >= 10)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 10 >\n";

                        if(m_pStats.GetLevel() >= 20)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 20 >\n";

                        if(m_pStats.GetLevel() >= 30)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 30 >\n\n";
                        break;
                    }
                    case PlayerClass::CLASS_SHOCKTROOPER:
                    {
                        if(m_pStats.GetLevel() >= 10)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 10 >\n";

                        if(m_pStats.GetLevel() >= 20)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 20 >\n";

                        if(m_pStats.GetLevel() >= 30)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 30 >\n\n";
                        break;
                    }
                    case PlayerClass::CLASS_DEFENDER:
                    {
                        if(m_pStats.GetLevel() >= g_iPerk1LvlReq)
                            BaseStatsText += "Reflective Ice - Ice Shield reflects 50% of damage to attacker.\n";
                        else
                            BaseStatsText += "Reflective Ice - < LOCKED - Lv. 10 >\n";

                        if(m_pStats.GetLevel() >= g_iPerk2LvlReq)
                            BaseStatsText += "Frosted - WIP.\n";
                        else
                            BaseStatsText += "Frosted - < LOCKED - Lv. 20 >\n";

                        if(m_pStats.GetLevel() >= g_iPerk3LvlReq)
                            BaseStatsText += "N/A - WIP.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 30 >\n\n";
                        break;
                    }
                    case PlayerClass::CLASS_CLOAKER:
                    {
                        if(m_pStats.GetLevel() >= 10)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 10 >\n";

                        if(m_pStats.GetLevel() >= 20)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 20 >\n";

                        if(m_pStats.GetLevel() >= 30)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 30 >\n\n";
                        break;
                    }
                    case PlayerClass::CLASS_POISONER:
                    {
                        if(m_pStats.GetLevel() >= 10)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 10 >\n";

                        if(m_pStats.GetLevel() >= 20)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 20 >\n";

                        if(m_pStats.GetLevel() >= 30)
                            BaseStatsText += "N/A.\n";
                        else
                            BaseStatsText += "< LOCKED - Lv. 30 >\n\n";
                        break;
                    }
                    case PlayerClass::CLASS_ENGINEER:
                    {
                        if(m_pStats.GetLevel() >= g_iPerk1LvlReq)
                            BaseStatsText += "N/A - \n";
                        else
                            BaseStatsText += "N/A - < LOCKED - Lv. 10 >\n";

                        if(m_pStats.GetLevel() >= g_iPerk2LvlReq)
                            BaseStatsText += "N/A - \n";
                        else
                            BaseStatsText += "N/A - < LOCKED - Lv. 20 >\n";

                        if(m_pStats.GetLevel() >= g_iPerk3LvlReq)
                            BaseStatsText += "AP Sentry Ammo - Sentry bullets penetrate armor.\n";
                        else
                            BaseStatsText += "AP Sentry Ammo - < LOCKED - Lv. 30 >\n\n";
                        break;
                    }
                }

            m_pMenu.AddItem(BaseStatsText, null);
    
            switch(m_pOwner.GetCurrentClass())
            {
                case PlayerClass::CLASS_MEDIC:
                {
                    HealingAura@ healingAura = cast<HealingAura@>(g_HealingAuras[steamID]);
                    if(healingAura !is null)
                    {
                        string MedicStatsText = "=== Heal Aura Stats: ===" + "\n" + 
                            "Restoration: " + int(healingAura.GetScaledHealAmount()) + " HP/s\n" + 
                            "Radius: " + int(healingAura.GetHealingRadius() / 16) + "ft\n" + 
                            "Revive Cost: " + int(healingAura.GetEnergyCostRevive()) + "/s\n" +
                            "Poison Damage: " + int(healingAura.GetPoisonDamageAmount()) + "/s\n\n";

                        m_pMenu.AddItem(MedicStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_BERSERKER:
                {
                    BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                    if(bloodlust !is null)
                    {
                        string BerserkerStatsText = "=== Bloodlust Stats: ===" + "\n" +
                        "Ability Charge Steal: " + int(bloodlust.GetEnergySteal()) + "%\n" +
                        "Lifesteal: " + int(bloodlust.GetLifestealAmount() * 100) + "%\n" + 
                        "Health scaling DMG Bonus: " + int(bloodlust.GetLowHPDMGBonus()) + "%\n\n";

                        m_pMenu.AddItem(BerserkerStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_ROBOMANCER:
                {
                    MinionData@ roboMinion = cast<MinionData@>(g_PlayerMinions[steamID]);
                    if(roboMinion !is null)
                    {
                        string EngineerStatsText = "=== Robogrunt Stats: ===" + "\n" + 
                        "Health: " + int(roboMinion.GetScaledHealth()) + "HP\n" + 
                        "Damage: " + int(roboMinion.GetScaledDamage() * 100 + 100) + "%\n\n";

                        m_pMenu.AddItem(EngineerStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_XENOMANCER:
                {
                    XenMinionData@ xenMinion = cast<XenMinionData@>(g_XenologistMinions[steamID]);
                    if(xenMinion !is null)
                    {
                        string XenologistStatsText = "=== Creature Stats: ===" + "\n" + 
                        "Health: " + int(xenMinion.GetScaledHealth()) + " HP\n" + 
                        "Damage: " + int(xenMinion.GetScaledDamage() * 100 + 100) + "%\n\n";

                        m_pMenu.AddItem(XenologistStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_SHOCKTROOPER:
                {
                    ShockRifleData@ shockRifle = cast<ShockRifleData@>(g_ShockRifleData[steamID]);
                    if(shockRifle !is null)
                    {
                        string ShocktrooperStatsText = "=== Shockroach Stats: ===" + "\n" + 
                            "Battery Capacity: " + int(maxEnergy) + "\n" +
                            "Damage: " + int((shockRifle.GetScaledDamage() - 1.0f) * 100 + 100) + "%\n\n";

                        m_pMenu.AddItem(ShocktrooperStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_DEFENDER:
                {
                    BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                    if(barrier !is null)
                    {
                        string DefenderStatsText = "=== Ice Shield Stats: ===" + "\n" + 
                            "Durability: " + int(maxEnergy) + " HP\n" + 
                            "Damage Reduction: " + int(barrier.GetBaseDamageReduction() * 100) + "%\n" +
                            "Active Recharge Rate: " + (energyRegen * 0.5) + "/s\n\n";

                        m_pMenu.AddItem(DefenderStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_CLOAKER:
                {
                    CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
                    if(cloak !is null)
                    {
                        string CloakerStatsText = "=== Cloak Stats: ===" + "\n" +  
                            "Battery Cost Per Shot: " + int(cloak.GetEnergyCostPerShot()) + "\n" +
                            "Damage Bonus at 100% Battery: " + int(cloak.GetDamageBonus() * 100 + 100) + "%\n\n";

                        m_pMenu.AddItem(CloakerStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_POISONER:
                {
                    SporeRoundsData@ sporeRounds = cast<SporeRoundsData@>(g_PlayerSporeRounds[steamID]);
                    if(sporeRounds !is null)
                    {
                        string DemolitionistStatsText = "=== Spore Ammo Stats: ===" + "\n" + 
                            "Radius Damage: " + int(sporeRounds.GetScaledDamage()) + "%\n" + 
                            "Max Ammo Capacity: " + int(sporeRounds.GetMaxRounds()) + "\n" +
                            "Ammo Per Pack: " + int(sporeRounds.GetAmmoPerPack()) + "\n\n";

                        m_pMenu.AddItem(DemolitionistStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_ENGINEER:
                {
                    SentryData@ sentry = cast<SentryData@>(g_PlayerSentries[steamID]);
                    if(sentry !is null)
                    {
                        string EngineerStatsText = "=== Sentry Stats: ===" + "\n" + 
                            "Health: " + int(sentry.GetScaledHealth()) + " HP\n" +
                            "Damage: " + int(sentry.GetScaledDamage() * 100 + 100) + "%\n" + 
                            "Heal: " + sentry.GetHealAmount() + " HP/s\n\n";

                        m_pMenu.AddItem(EngineerStatsText, null);
                    }
                    break;
                }
            }
            
            /* - Commented out for now whilst I decide how to deal with this info later.
            // Universal ammo regeneration stats.
            m_pMenu.AddItem("=== Ammo Regeneration ===", null);
            
            // Use the new data-oriented structure to display ammo stats.
            for (uint i = 0; i < g_AmmoTypes.length(); i++) 
            {
                AmmoType@ ammoType = g_AmmoTypes[i];
                
                // Skip special ammo types that belong in the spores category.
                if (ammoType.hasThreshold && ammoType.name != "health") 
                    continue;
                    
                // Format: "9mm: 1 per 1s (max: 300)".
                string ammoInfo = ammoType.name + ": " + ammoType.amount + " per " + 
                                 (ammoType.delay * flAmmoTick) + "s" + 
                                 " (max: " + ammoType.maxAmount + ")";
                m_pMenu.AddItem(ammoInfo, null);
            }
            
            m_pMenu.AddItem("\n=== Spores Regeneration ===", null);
            
            // Display threshold-based ammo types.
            for (uint i = 0; i < g_AmmoTypes.length(); i++) 
            {
                AmmoType@ ammoType = g_AmmoTypes[i];
                
                // Only show items with threshold.
                if (!ammoType.hasThreshold)
                    continue;

                // Skip health since it's not spores.
                if (ammoType.name == "health")
                    continue;
                    
                string thresholdInfo = "";
                if (ammoType.threshold > 0) 
                {
                    thresholdInfo = " (max " + ammoType.threshold + ")";
                }
                
                string sporeInfo = ammoType.name + ": " + ammoType.amount + " per " + 
                                      (ammoType.delay * flAmmoTick) + "s" + thresholdInfo;
                m_pMenu.AddItem(sporeInfo, null);
            }
            */
            
            m_pMenu.Register();
            m_pMenu.Open(0, 0, pPlayer);
        }
        
        private void MenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item)
        {
            // Menu closes automatically when no selection is made.
        }
    }
}

void ShowClassStats(CBasePlayer@ pPlayer)
{
    if(pPlayer is null)
        return;

    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(!g_PlayerRPGData.exists(steamID))
        return;

    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
    if(data is null)
        return;

    Menu::StatsMenu statsMenu(data);
    statsMenu.Show(pPlayer);
}