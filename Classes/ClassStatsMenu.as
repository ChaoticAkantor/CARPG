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
    
            // Get energy stats from resource dictionary instead
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            float maxEnergy = resources !is null ? float(resources['max']) : g_flBaseMaxResource;
            float energyRegen = resources !is null ? float(resources['regen']) : g_flBaseResourceRegen;

            m_pMenu.AddItem("=== Basic Stats: ===" + "\n" +
            "Max Health: " + pPlayer.pev.max_health + " HP\n" + 
            "Max Armor: " + pPlayer.pev.armortype + " AP\n" + 
            "Max Energy: " + int(maxEnergy) + "\n" + 
            "Energy Regen: " + energyRegen + "/s\n", null);
    
            switch(m_pOwner.GetCurrentClass())
            {
                case PlayerClass::CLASS_BERSERKER:
                {
                    BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                    if(bloodlust !is null)
                    {
                        m_pMenu.AddItem("=== Berserker Stats: ===" + "\n" + 
                        "Bloodlust Life Steal: " + int(bloodlust.GetLifestealAmount() * 100) + "%\n" + 
                        "Bloodlust +DMG per 1% missing HP: " + int(bloodlust.GetDamageBonus(pPlayer) * 100) + "%\n" + 
                        "Bloodlust Cost: " + int(bloodlust.GetEnergyCost()) + "/s\n\n", null);
                    }
                    break;
                }
                case PlayerClass::CLASS_ENGINEER:
                {
                    MinionData@ minion = cast<MinionData@>(g_PlayerMinions[steamID]);
                    if(minion !is null)
                    {
                        m_pMenu.AddItem("=== Engineer Stats: ===" + "\n" + 
                        "Robot Minions Health: " + int(minion.GetScaledHealth()) + "HP\n" + 
                        "Robot Minions Damage: +" + int(minion.GetScaledDamage() * 100) + "% DMG\n\n", null);
                    }
                    break;
                }
                case PlayerClass::CLASS_XENOLOGIST:
                {
                    //m_pMenu.AddItem("=== Xenologist Stats: ===" + "\n" + 
                    //"Xen Creatures Health: " + g_flBaseXenMinionHP + " + " + int(g_flXenMinionHPBonus) + " [" + int((g_flBaseXenMinionHP + g_flXenMinionHPBonus)) + "]\n" + 
                    //"Xen Creatures Damage: +" + g_flXenMinionDMGBonus * 100 + "%\n\n", null);
                    break;
                }
                case PlayerClass::CLASS_SHOCKTROOPER:
                {
                    //m_pMenu.AddItem("=== Shocktrooper Stats: ===" + "\n" + 
                    //"Shock Rifle Battery Max Capacity: " + g_flBaseMaxResource + " + " + g_flResourceBonus + " [" + (g_flBaseMaxResource + g_flResourceBonus) + "]\n\n", null);
                    break;
                }
                case PlayerClass::CLASS_DEFENDER:
                {
                    //m_pMenu.AddItem("=== Warden Stats: ===" + "\n" + 
                    //"Ice Shield Damage Reduction: " + flBaseDamageReduction * 100 + "%\n" + 
                    //"Ice Shield Cost: " + int(flBarrierDamageToEnergyMult * 100) + "% of Damage Received\n\n", null);
                    break;
                }
                case PlayerClass::CLASS_CLOAKER:
                {
                    //m_pMenu.AddItem("=== Cloaker Stats: ===" + "\n" + 
                    //"Cloak Damage Bonus: " + g_flBaseMaxResource + " + " + g_flResourceBonus + " [" + (g_flBaseMaxResource + g_flResourceBonus) + "]\n" + 
                    //"Cloak Cost: " + flBarrierDamageToEnergyMult * 100 + "% of damage taken\n\n", null);
                    break;
                }
                case PlayerClass::CLASS_DEMOLITIONIST:
                {
                    //m_pMenu.AddItem("=== Demolitionist Stats: ===" + "\n" + 
                    //"Explosive Rounds Damage Bonus: " + flExplosiveRoundsDamageBase + " + " + flExplosiveRoundsDamageBonus + " [" + (flExplosiveRoundsDamage + flExplosiveRoundsDamageBonus) + "]\n" + 
                    //"Explosive Rounds Capacity: " + flExplosiveRoundsPoolBase + " + " + flExplosiveRoundsPoolBonus + " [" + (flExplosiveRoundsPoolBase + flExplosiveRoundsPoolBonus) + "]\n\n", null);
                    break;
                }
            }

            // Universal ammo regeneration stats.
            m_pMenu.AddItem("=== Ammo Regeneration ===", null);
            
            // Use the new data-oriented structure to display ammo stats.
            for (uint i = 0; i < g_AmmoTypes.length(); i++) 
            {
                AmmoType@ ammoType = g_AmmoTypes[i];
                
                // Skip special ammo types that belong in the explosives category.
                if (ammoType.hasThreshold && ammoType.name != "health") 
                    continue;
                    
                // Format: "9mm: 1 per 1s (max: 300)".
                string ammoInfo = ammoType.name + ": " + ammoType.amount + " per " + 
                                 (ammoType.delay * flAmmoTick) + "s" + 
                                 " (max: " + ammoType.maxAmount + ")";
                m_pMenu.AddItem(ammoInfo, null);
            }
            
            m_pMenu.AddItem("\n=== Explosives Regeneration ===", null);
            
            // Display threshold-based ammo types.
            for (uint i = 0; i < g_AmmoTypes.length(); i++) 
            {
                AmmoType@ ammoType = g_AmmoTypes[i];
                
                // Only show items with threshold.
                if (!ammoType.hasThreshold)
                    continue;

                // Skip health since it's not explosives.
                if (ammoType.name == "health")
                    continue;
                    
                string thresholdInfo = "";
                if (ammoType.threshold > 0) 
                {
                    thresholdInfo = " (max " + ammoType.threshold + ")";
                }
                
                string explosiveInfo = ammoType.name + ": " + ammoType.amount + " per " + 
                                      (ammoType.delay * flAmmoTick) + "s" + thresholdInfo;
                m_pMenu.AddItem(explosiveInfo, null);
            }
            
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