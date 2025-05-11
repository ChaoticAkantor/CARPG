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
            
            m_pMenu.AddItem("Health: " + g_flBaseMaxHP + " + " + g_flHPBonus + " [" + (g_flBaseMaxHP + g_flHPBonus) + "]", null);
            m_pMenu.AddItem("Armor: " + g_flBaseMaxAP + " + " + g_flAPBonus + " [" + (g_flBaseMaxAP + g_flAPBonus) + "]", null);
            m_pMenu.AddItem("Energy: " + g_flBaseMaxResource + " + " + g_flResourceBonus + " [" + (g_flBaseMaxResource + g_flResourceBonus) + "]", null);       
            m_pMenu.AddItem("Energy Regen: " + g_flBaseResourceRegen + " + " + g_flResourceRegenBonus + " [" + (g_flBaseResourceRegen + g_flResourceRegenBonus) + "/sec]\n", null);
            
            switch(m_pOwner.GetCurrentClass())
            {
                case PlayerClass::CLASS_MEDIC:
                {
                    m_pMenu.AddItem("=== Medic: ===", null);
                    m_pMenu.AddItem("Heal Aura Power: " + g_flHealAuraBase + " + " + g_flHealAuraBonus + " [" + (g_flHealAuraBase + g_flHealAuraBonus) + " HP/sec]", null);
                    m_pMenu.AddItem("Heal Aura Cost: " + g_iHealAuraDrain + " /sec", null);
                    m_pMenu.AddItem("Medkit Capacity: " + g_flMedkitCapacity + " + " + g_flMedkitCapacityBonus + " [" + (g_flMedkitCapacity + g_flMedkitCapacityBonus) + "]", null);
                    m_pMenu.AddItem("Medkit Recharge: " + g_flMedkitRecharge + " + " + g_flMedkitRechargeBonus + " [" + (g_flMedkitRecharge + g_flMedkitRechargeBonus) + " HP/sec]", null);
                    // Need to add other scaling stats here.
                    break;
                }
                case PlayerClass::CLASS_BERSERKER:
                {
                    m_pMenu.AddItem("=== Berskerker ===", null);
                    m_pMenu.AddItem("Bloodlust Life Steal: " + g_flBaseMaxResource + "% + " + g_flResourceBonus + "% [" + (g_flBaseMaxResource + g_flResourceBonus) + "%]", null);
                    m_pMenu.AddItem("Bloodlust Add AP as Temporary HP whilst active: " + flBloodlustOverhealBase * 100 + "% + " + flBloodlustOverhealBonus * 100 + "% [" + ((flBloodlustOverhealBase * 100) + (flBloodlustOverhealBonus * 100)) + "%]\n", null);
                    m_pMenu.AddItem("Bloodlust Cost: " + flBloodlustEnergyCost + " per 0.5s", null);
                    break;
                }
                case PlayerClass::CLASS_ENGINEER:
                {
                    m_pMenu.AddItem("=== Engineer: ===", null);
                    m_pMenu.AddItem("Robot Minions Health: " + g_flBaseMinionHP + " + " + int(g_flMinionHPBonus) + " [" + int((g_flBaseMinionHP + g_flMinionHPBonus)) + "]", null);
                    //m_pMenu.AddItem("Damage: " + g_flBaseMinionDMG + " + " + g_flMinionDMGBonus + " [" + (g_flBaseMinionDMG + g_flMinionDMGBonus) + "]", null); // Damage is non-functional.
                    break;
                }
                case PlayerClass::CLASS_SHOCKTROOPER:
                {
                    m_pMenu.AddItem("=== Shocktrooper: ===", null);
                    m_pMenu.AddItem("Shock Rifle Recharger Max Capacity: " + g_flBaseMaxResource + " + " + g_flResourceBonus + " [" + (g_flBaseMaxResource + g_flResourceBonus) + "]\n", null);
                    break;
                }
                case PlayerClass::CLASS_DEFENDER:
                {
                    m_pMenu.AddItem("=== Defender: ===", null);
                    m_pMenu.AddItem("Barrier Damage Reduction: " + flBaseDamageReduction * 100 + "% + " + g_flDamageReductionBonus * 100 + "% [" + ((flBaseDamageReduction * 100) + (g_flDamageReductionBonus * 100)) + "%]\n", null);
                    m_pMenu.AddItem("Barrier Health: " + g_flBaseMaxResource + " + " + g_flResourceBonus + " [" + (g_flBaseMaxResource + g_flResourceBonus) + "]\n", null);
                    m_pMenu.AddItem("Barrier Cost: " + flBarrierDamageToEnergyMult * 100 + "% of damage taken\n", null);
                    break;
                }
                case PlayerClass::CLASS_DEMOLITIONIST:
                {
                    m_pMenu.AddItem("=== Demolitionist: ===", null);
                    m_pMenu.AddItem("Explosive Rounds Damage: " + flExplosiveRoundsDamageBase + " + " + flExplosiveRoundsDamageBonus + " [" + (flExplosiveRoundsDamage + flExplosiveRoundsDamageBonus) + "]\n", null);
                    m_pMenu.AddItem("Explosive Rounds Capacity: " + flExplosiveRoundsPoolBase + " + " + flExplosiveRoundsPoolBonus + " [" + (flExplosiveRoundsPoolBase + flExplosiveRoundsPoolBonus) + "]\n", null);
                    break;
                }
            }

            // Universal ammo regeneration stats
            m_pMenu.AddItem("=== Ammo Regeneration ===", null);
            
            // Use the new data-oriented structure to display ammo stats
            for (uint i = 0; i < g_AmmoTypes.length(); i++) 
            {
                AmmoType@ ammoType = g_AmmoTypes[i];
                
                // Skip special ammo types that belong in the explosives category
                if (ammoType.hasThreshold && ammoType.name != "health") 
                    continue;
                    
                // Format: "9mm: 1 per 1s (max: 300)"
                string ammoInfo = ammoType.name + ": " + ammoType.amount + " per " + 
                                 (ammoType.delay * flAmmoTick) + "s" + 
                                 " (max: " + ammoType.maxAmount + ")";
                m_pMenu.AddItem(ammoInfo, null);
            }
            
            m_pMenu.AddItem("\n=== Explosives Regeneration ===", null);
            
            // Display threshold-based ammo types
            for (uint i = 0; i < g_AmmoTypes.length(); i++) 
            {
                AmmoType@ ammoType = g_AmmoTypes[i];
                
                // Only show items with threshold
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
            // Menu closes automatically when no selection is made
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