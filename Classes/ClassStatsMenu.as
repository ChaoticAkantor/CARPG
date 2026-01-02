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
            string BaseStatsText = "=== Basic Stats: ===\n";
                BaseStatsText += "Max Health: " + int(pPlayer.pev.max_health) + " HP\n";
                BaseStatsText += "Max Armor: " + int(pPlayer.pev.armortype) + " AP\n";
                BaseStatsText += "Ability Duration/Charges: " + int(maxEnergy) + "\n";
                BaseStatsText += "Ability Recharge Rate: " + energyRegen + "/s\n\n";

            m_pMenu.AddItem(BaseStatsText, null);

            // Display class-specific stats.
            switch(m_pOwner.GetCurrentClass())
            {
                case PlayerClass::CLASS_MEDIC:
                {
                    HealingAura@ healingAura = cast<HealingAura@>(g_HealingAuras[steamID]);
                    if(healingAura !is null)
                    {
                        string MedicStatsText = "=== Heal Aura: ===" + "\n"; 
                        MedicStatsText += "Healing: " + healingAura.GetScaledHealAmount() + " HP/s\n";
                        MedicStatsText += "Poison Damage: " + healingAura.GetPoisonDamageAmount() + "/s\n";
                        MedicStatsText += "Radius: " + healingAura.GetHealingRadius() + "u\n";
                        MedicStatsText += "Ally Revival Duration Cost: " + healingAura.GetEnergyCostRevive() + "s\n";

                        m_pMenu.AddItem(MedicStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_BERSERKER:
                {
                    BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                    if(bloodlust !is null)
                    {
                        string BerserkerStatsText = "=== Bloodlust (Passive): ===" + "\n";
                        BerserkerStatsText += "Damage Reduction as HP Reduces: " + bloodlust.GetDamageReductionMax() + "%\n";
                        BerserkerStatsText += "Ability Charge Steal: " + bloodlust.GetEnergySteal() + "%\n";
                        BerserkerStatsText += "Lifesteal: " + bloodlust.GetLifestealAmount() * 100 + "%\n";
                        BerserkerStatsText += "AP Steal (when at full HP): " + bloodlust.GetLifestealAmount() * 100 * 0.5 + "%\n\n";

                        BerserkerStatsText += "=== Bloodlust (Active): ===" + "\n";
                        BerserkerStatsText += "Damage Reduction as HP Reduces: " + bloodlust.GetDamageReductionMax() * 2 + "%\n";
                        BerserkerStatsText += "Ability Charge Steal: " + bloodlust.GetEnergySteal() * 2 + "%\n";
                        BerserkerStatsText += "Lifesteal: " + bloodlust.GetLifestealAmount() * 100 * 2 + "%\n";
                        BerserkerStatsText += "AP Steal (when at full HP): " + bloodlust.GetLifestealAmount() * 100 + "%\n\n";

                        m_pMenu.AddItem(BerserkerStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_ROBOMANCER:
                {
                    MinionData@ roboMinion = cast<MinionData@>(g_PlayerMinions[steamID]);
                    if(roboMinion !is null)
                    {
                        string EngineerStatsText = "=== Robogrunts: ===" + "\n"; 
                        EngineerStatsText += "Health: " + int(roboMinion.GetScaledHealth()) + " HP\n"; 
                        EngineerStatsText += "Damage: " + roboMinion.GetScaledDamage() * 100 + "%\n";
                        EngineerStatsText += "Health Regen: " + roboMinion.GetMinionRegen() * 100 + "%\n";

                        m_pMenu.AddItem(EngineerStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_XENOMANCER:
                {
                    XenMinionData@ xenMinion = cast<XenMinionData@>(g_XenologistMinions[steamID]);
                    if(xenMinion !is null)
                    {
                        string XenologistStatsText = "=== Xen Creatures: ===" + "\n"; 
                        XenologistStatsText += "Health: " + int(xenMinion.GetScaledHealth()) + " HP\n";
                        XenologistStatsText += "Damage: " + xenMinion.GetScaledDamage() * 100 + "%\n";
                        XenologistStatsText += "Health Regen: " + xenMinion.GetMinionRegen() * 100 + "%\n";
                        XenologistStatsText += "Minion Lifesteal (Minion and Player): " + xenMinion.GetLifestealPercent() * 100 + "%\n";

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
                        string NecromancerStatsText = "=== Zombies: ===" + "\n"; 
                        NecromancerStatsText += "Health: " + int(necroMinion.GetScaledHealth()) + " HP\n";
                        NecromancerStatsText += "Damage: " + necroMinion.GetScaledDamage() * 100 + "%\n";
                        NecromancerStatsText += "Health Regen: " + necroMinion.GetMinionRegen() * 100 + "%\n";
                        NecromancerStatsText += "Minion Lifesteal (Minion and Player): " + necroMinion.GetLifestealPercent() * 100 + "%\n";

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
                        string ShocktrooperStatsText = "=== Shockroach Rifle: ===" + "\n"; 
                            ShocktrooperStatsText += "Capacity: " + int(maxEnergy) + "\n";
                            ShocktrooperStatsText += "Damage Bonus: " + shockRifle.GetScaledDamage() * 100 + "%\n";

                        m_pMenu.AddItem(ShocktrooperStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_DEFENDER:
                {
                    BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                    if(barrier !is null)
                    {
                        string DefenderStatsText = "=== Ice Shield: ===" + "\n";
                            DefenderStatsText += "Max Durability: " + int(maxEnergy) + " HP\n";
                            DefenderStatsText += "Damage Reflect: " + barrier.GetScaledDamageReflection() * 100 + "%\n";
                            DefenderStatsText += "Damage Reflect Freeze Effect: " + barrier.GetBarrierReflectFreezeInverse() + "%\n";
                            DefenderStatsText += "Damage Reflect Freeze Duration: " + barrier.GetBarrierReflectFreezeDuration() + "s\n";
                            DefenderStatsText += "Ability Recharge Rate whilst active: " + (energyRegen * barrier.GetActiveRechargePenalty()) + "/s\n";

                        m_pMenu.AddItem(DefenderStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_CLOAKER:
                {
                    CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
                    if(cloak !is null)
                    {
                        string CloakerStatsText = "=== Cloak: ===" + "\n"; 
                            CloakerStatsText += "Cloak Damage Bonus: +" + cloak.GetDamageMultiplierTotal() * 100 + "%\n";
                            CloakerStatsText += "Shock Nova Damage: " + cloak.GetNovaDamage(pPlayer) + "\n";
                            CloakerStatsText += "Shock Nova Radius: " + cloak.GetNovaRadius() + "u\n";
                            CloakerStatsText += "Shock Nova AP Steal (HP if AP disabled): " + cloak.GetAPStealPercent() * 100 + "%\n";

                        m_pMenu.AddItem(CloakerStatsText, null);
                    }
                }
                break;
                case PlayerClass::CLASS_VANQUISHER:
                {
                    DragonsBreathData@ DragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamID]);
                    if(DragonsBreath !is null)
                    {
                        string VanquisherStatsText = "=== Dragon's Breath Ammo: ===" + "\n"; 
                            VanquisherStatsText += "Fire DoT Damage: " + DragonsBreath.GetScaledFireDamage() + "/s\n";
                            VanquisherStatsText += "Fire DoT Duration: " + DragonsBreath.GetFireDuration() + "s\n";
                            VanquisherStatsText += "Fire DoT Radius: " + DragonsBreath.GetRadius() + "u\n";
                        
                        VanquisherStatsText += "\nMax Ammo Capacity: " + int(DragonsBreath.GetMaxRounds()) + "\n";
                        VanquisherStatsText += "Ammo Pool Refill: " + DragonsBreath.GetAmmoRefillPercent() + "% (" + DragonsBreath.GetAmmoPerPack() + " rounds)\n\n";

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
                            EngineerStatsText += "Team Regeneration: " + sentry.GetScaledHealAmount() + " HP/s\n\n";
                            EngineerStatsText += "Damage Bonus: " + sentry.GetScaledDamage() * 100 + "%\n";
                            EngineerStatsText += "Cryo Damage Bonus: " + sentry.GetCryoShotsDamageMult() * 100 + "%\n";
                            EngineerStatsText += "Freeze Effect: " + sentry.GetCryoShotsSlowInverse() + "%\n";

                        m_pMenu.AddItem(EngineerStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_SWARMER:
                {
                    SnarkNestData@ snarkNest = cast<SnarkNestData@>(g_PlayerSnarkNests[steamID]);
                    if(snarkNest !is null)
                    {
                        string SwarmerStatsText = "=== Snark Swarm: ===" + "\n"; 
                            SwarmerStatsText += "Health: " + int(snarkNest.GetScaledHealth()) + " HP\n";
                            SwarmerStatsText += "Damage Bonus: " + snarkNest.GetScaledDamage() * 100 + "%\n";
                            SwarmerStatsText += "Swarm Size: " + snarkNest.GetSnarkCount() + "\n";
                            SwarmerStatsText += "Lifesteal (Player): " + snarkNest.GetLifestealPercent() * 100 + "%\n\n";

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

// For opening class stats menu to see class stats and attributes.
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