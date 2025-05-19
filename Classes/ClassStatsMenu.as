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
            
            int level = m_pStats.GetLevel();
            string title = m_pOwner.GetClassName(m_pOwner.GetCurrentClass()) + "\n";
            title += "Lvl: " + level + " | " + "XP: (" + m_pStats.GetCurrentLevelXP() + "/" + m_pStats.GetNeededXP() + ")\n\n";
            m_pMenu.SetTitle(title);
            
            m_pMenu.AddItem("=== Basic Stats: ===" + "\n" +
            "Health: " + g_flBaseMaxHP + " + " + int(g_flHPBonus) + " [" + (g_flBaseMaxHP + g_flHPBonus) + "]\n" + 
            "Armor: " + g_flBaseMaxAP + " + " + int(g_flAPBonus) + " [" + (g_flBaseMaxAP + g_flAPBonus) + "]\n" + 
            "Energy: " + g_flBaseMaxResource + " + " + int(g_flResourceBonus) + " [" + (g_flBaseMaxResource + g_flResourceBonus) + "]\n" + 
            "Energy Regen: " + g_flBaseResourceRegen + " + " + int(g_flResourceRegenBonus) + " [" + (g_flBaseResourceRegen + g_flResourceRegenBonus) + "/sec]\n", null);
            
            switch(m_pOwner.GetCurrentClass())
            {
                case PlayerClass::CLASS_MEDIC:
                {
                    m_pMenu.AddItem("=== Medic Stats: ===" + "\n" + 
                    "Heal Aura Healing: " + flHealAuraHealBase + " HP/s + " + flHealAuraHealBonus + " HP/s [" + (flHealAuraHealBase + flHealAuraHealBonus) + " HP/s]\n" + 
                    "Heal Aura Cost: " + g_iHealAuraDrain + "/s" + 
                    "Medkit Capacity: " + g_flMedkitCapacity + " + " + g_flMedkitCapacityBonus + " [" + (g_flMedkitCapacity + g_flMedkitCapacityBonus) + "]\n" + 
                    "Medkit Recharge: " + g_flMedkitRecharge + " + " + g_flMedkitRechargeBonus + " [" + (g_flMedkitRecharge + g_flMedkitRechargeBonus) + " HP/s]\n\n", null);
                    break;
                }
                case PlayerClass::CLASS_BERSERKER:
                {
                    m_pMenu.AddItem("=== Berserker Stats: ===" + "\n" + 
                    "Bloodlust Life Steal: " + g_flBaseMaxResource + "% + " + g_flResourceBonus + "% [" + (g_flBaseMaxResource + g_flResourceBonus) + "%]\n" + 
                    "Bloodlust HP Buff: " + flBloodlustOverhealBase * 100 + "% + " + flBloodlustOverhealBonus * 100 + "% [" + ((flBloodlustOverhealBase * 100) + (flBloodlustOverhealBonus * 100)) + "%]\n" + 
                    "Bloodlust Cost: " + flBloodlustEnergyCost + " per 0.5s\n\n", null);
                    break;
                }
                case PlayerClass::CLASS_ENGINEER:
                {
                    m_pMenu.AddItem("=== Engineer Stats: ===" + "\n" + 
                    "Robot Minions Health: " + g_flBaseMinionHP + " + " + int(g_flMinionHPBonus) + " [" + int((g_flBaseMinionHP + g_flMinionHPBonus)) + "]\n" + 
                    "Robot Minions Damage: +" + g_flMinionDMGBonus * 100 + "%\n\n", null);
                    break;
                }
                case PlayerClass::CLASS_XENOLOGIST:
                {
                    m_pMenu.AddItem("=== Xenologist Stats: ===" + "\n" + 
                    "Xen Creatures Health: " + g_flBaseXenMinionHP + " + " + int(g_flXenMinionHPBonus) + " [" + int((g_flBaseXenMinionHP + g_flXenMinionHPBonus)) + "]\n" + 
                    "Xen Creatures Damage: +" + g_flXenMinionDMGBonus * 100 + "%\n\n", null);
                    break;
                }
                case PlayerClass::CLASS_SHOCKTROOPER:
                {
                    m_pMenu.AddItem("=== Shocktrooper Stats: ===" + "\n" + 
                    "Shock Rifle Battery Max Capacity: " + g_flBaseMaxResource + " + " + g_flResourceBonus + " [" + (g_flBaseMaxResource + g_flResourceBonus) + "]\n\n", null);
                    break;
                }
                case PlayerClass::CLASS_DEFENDER:
                {
                    m_pMenu.AddItem("=== Warden Stats: ===" + "\n" + 
                    "Ice Shield Damage Reduction: " + flBaseDamageReduction * 100 + "%\n" + 
                    "Ice Shield Cost: " + int(flBarrierDamageToEnergyMult * 100) + "% of Damage Received\n\n", null);
                    break;
                }
                case PlayerClass::CLASS_CLOAKER:
                {
                    m_pMenu.AddItem("=== Cloaker Stats: ===" + "\n" + 
                    "Cloak Damage Bonus: WIP" + g_flBaseMaxResource + " + " + g_flResourceBonus + " [" + (g_flBaseMaxResource + g_flResourceBonus) + "]\n" + 
                    "Cloak Cost: WIP" + flBarrierDamageToEnergyMult * 100 + "% of damage taken\n\n", null);
                    break;
                }
                case PlayerClass::CLASS_DEMOLITIONIST:
                {
                    m_pMenu.AddItem("=== Demolitionist Stats: ===" + "\n" + 
                    "Explosive Rounds Damage Bonus: " + flExplosiveRoundsDamageBase + " + " + flExplosiveRoundsDamageBonus + " [" + (flExplosiveRoundsDamage + flExplosiveRoundsDamageBonus) + "]\n" + 
                    "Explosive Rounds Capacity: " + flExplosiveRoundsPoolBase + " + " + flExplosiveRoundsPoolBonus + " [" + (flExplosiveRoundsPoolBase + flExplosiveRoundsPoolBonus) + "]\n\n", null);
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