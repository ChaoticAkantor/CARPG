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

            m_pMenu.AddItem(BaseStatsText, null);
    
            switch(m_pOwner.GetCurrentClass())
            {
                case PlayerClass::CLASS_MEDIC:
                {
                    HealingAura@ healingAura = cast<HealingAura@>(g_HealingAuras[steamID]);
                    if(healingAura !is null)
                    {
                        string MedicStatsText = "=== Heal Aura: ===" + "\n" + 
                            "Healing: " + int(healingAura.GetScaledHealAmount()) + " HP/s\n" + 
                            "Poison Damage: " + int(healingAura.GetPoisonDamageAmount()) + "/s\n" +
                            "Radius: " + int(healingAura.GetHealingRadius() / 16) + "ft\n" + 
                            "Ally Revival Duration Cost: " + int(healingAura.GetEnergyCostRevive()) + "s\n";

                        m_pMenu.AddItem(MedicStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_BERSERKER:
                {
                    BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                    if(bloodlust !is null)
                    {
                        string BerserkerStatsText = "=== Bloodlust (Passive): ===" + "\n" +
                        "Damage Reduction as HP Reduces: " + int(bloodlust.GetDamageReductionMax()) + "%\n" +
                        "Ability Charge Steal: " + int(bloodlust.GetEnergySteal()) + "%\n" +
                        "Lifesteal: " + int(bloodlust.GetLifestealAmount() * 100) + "%\n";
                        
                        BerserkerStatsText += "=== Bloodlust (Active): ===" + "\n" +
                        "Damage Reduction as HP Reduces: " + int(bloodlust.GetDamageReductionMax() * 2) + "%\n" +
                        "Ability Charge Steal: " + int(bloodlust.GetEnergySteal() * 2) + "%\n" +
                        "Lifesteal: " + int(bloodlust.GetLifestealAmount() * 100 * 2) + "%\n";

                        m_pMenu.AddItem(BerserkerStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_ROBOMANCER:
                {
                    MinionData@ roboMinion = cast<MinionData@>(g_PlayerMinions[steamID]);
                    if(roboMinion !is null)
                    {
                        string EngineerStatsText = "=== Robogrunts: ===" + "\n" + 
                        "Health: " + int(roboMinion.GetScaledHealth()) + " HP\n" + 
                        "Damage Bonus: " + int(roboMinion.GetScaledDamage() * 100) + "%\n";

                        m_pMenu.AddItem(EngineerStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_XENOMANCER:
                {
                    XenMinionData@ xenMinion = cast<XenMinionData@>(g_XenologistMinions[steamID]);
                    if(xenMinion !is null)
                    {
                        string XenologistStatsText = "=== Xen Creatures: ===" + "\n" + 
                        "Health: " + int(xenMinion.GetScaledHealth()) + " HP\n" + 
                        "Damage Bonus: " + int(xenMinion.GetScaledDamage() * 100) + "%\n" +
                        "Minion Lifesteal (Minion and Player): " + int(xenMinion.GetLifestealPercent() * 100) + "%\n";

                        XenologistStatsText += "\n";

                        m_pMenu.AddItem(XenologistStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_NECROMANCER:
                {
                    NecroMinionData@ necroMinion = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
                    if(necroMinion !is null)
                    {
                        string NecromancerStatsText = "=== Zombies: ===" + "\n" + 
                        "Health: " + int(necroMinion.GetScaledHealth()) + " HP\n" + 
                        "Damage Bonus: " + int(necroMinion.GetScaledDamage() * 100) + "%\n" +
                        "Minion Lifesteal (Minion and Player): " + int(necroMinion.GetLifestealPercent() * 100) + "%\n";

                        NecromancerStatsText += "\n";

                        m_pMenu.AddItem(NecromancerStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_SHOCKTROOPER:
                {
                    ShockRifleData@ shockRifle = cast<ShockRifleData@>(g_ShockRifleData[steamID]);
                    if(shockRifle !is null)
                    {
                        string ShocktrooperStatsText = "=== Shockroach Rifle: ===" + "\n" + 
                            "Capacity: " + int(maxEnergy) + "\n" +
                            "Damage Bonus: " + int((shockRifle.GetScaledDamage() - 1.0f) * 100) + "%\n";

                        m_pMenu.AddItem(ShocktrooperStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_DEFENDER:
                {
                    BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                    if(barrier !is null)
                    {
                        string DefenderStatsText = "=== Ice Shield: ===" + "\n" + 
                            "Max Durability: " + int(maxEnergy) + " HP\n" + 
                            "Damage Reflect: " + int(barrier.GetScaledDamageReflection() * 100) + "%\n" +
                            "Damage Reflect Freeze Effect: " + barrier.GetBarrierReflectFreezeInverse() + "%\n" +
                            "Damage Reflect Freeze Duration: " + barrier.GetBarrierReflectFreezeDuration() + "s\n" +
                            "Ability Recharge Rate whilst active: " + (energyRegen * barrier.GetActiveRechargePenalty()) + "/s\n";

                        m_pMenu.AddItem(DefenderStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_CLOAKER:
                {
                    CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
                    if(cloak !is null)
                    {
                        string CloakerStatsText = "=== Cloak: ===" + "\n" +  
                            "Cloak Damage Bonus: +" + int((cloak.GetDamageBonus() - 1.0f) * 100) + "%\n" +
                            "Shock Nova Damage: " + int(cloak.GetNovaDamage(pPlayer)) + "\n" +
                            "Shock Nova Radius: " + int(cloak.GetNovaRadius() / 16) + "ft\n";

                        // Show perk 1.
                        if(cloak.GetStats().HasUnlockedPerk1())
                            CloakerStatsText += "Shock Nova AP Steal: " + int(cloak.GetAPStealPercent() * 100) + "%\n";

                        m_pMenu.AddItem(CloakerStatsText, null);
                    }
                }
                break;
                case PlayerClass::CLASS_VANQUISHER:
                {
                    DragonsBreathData@ DragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamID]);
                    if(DragonsBreath !is null)
                    {
                        // Display the base damage first.
                        string VanquisherStatsText = "=== Dragon's Breath Ammo: ===" + "\n" + 
                            "Fire Damage: " + DragonsBreath.GetScaledFireDamage() + "/s\n" +
                            "Fire Duration: " + int(DragonsBreath.GetFireDuration()) + "s\n" +
                            "Fire Radius: " + int(DragonsBreath.GetRadius() / 16) + "ft\n";
                        
                        VanquisherStatsText += "\nMax Ammo Capacity: " + int(DragonsBreath.GetMaxRounds()) + "\n" +
                        "Ammo per Pack: " + DragonsBreath.GetAmmoPerPack() + "\n\n";

                        m_pMenu.AddItem(VanquisherStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_ENGINEER:
                {
                    SentryData@ sentry = cast<SentryData@>(g_PlayerSentries[steamID]);
                    if(sentry !is null)
                    {
                        string EngineerStatsText = "=== Sentry Turret: ===\n";
                            EngineerStatsText += "Health: " + int(sentry.GetScaledHealth()) + " HP\n";
                            EngineerStatsText += "Healing Buff: " + sentry.GetHealAmount() + " HP/s\n\n";
                            EngineerStatsText += "Damage Bonus: " + int(sentry.GetScaledDamage() * 100) + "%\n";
                            EngineerStatsText += "Cryo Damage Bonus: " + int(sentry.GetCryoShotsDamageMult() * 10) + "%\n";
                            EngineerStatsText += "Freeze Effect: " + (sentry.GetCryoShotsSlowInverse()) + "%\n";

                        m_pMenu.AddItem(EngineerStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_SWARMER:
                {
                    SnarkNestData@ snarkNest = cast<SnarkNestData@>(g_PlayerSnarkNests[steamID]);
                    if(snarkNest !is null)
                    {
                        string SwarmerStatsText = "=== Snark Swarm: ===" + "\n" + 
                            "Snark Health: " + int(snarkNest.GetScaledHealth()) + " HP\n" +
                            "Snark Damage Multiplier: " + int(snarkNest.GetScaledDamage() * 100 + 100) + "%\n" +
                            "Snark Swarm Size: " + snarkNest.GetSnarkCount() + "\n";

                        m_pMenu.AddItem(SwarmerStatsText, null);
                    }
                }
            }
            
            /* - Commented out for now whilst I decide how to deal with this info later.
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