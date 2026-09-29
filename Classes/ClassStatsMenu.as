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

            // Display basic stats.
            string BaseStatsText = "=== Basic Stats: ===\n";
                BaseStatsText += "Max Health: " + int(pPlayer.pev.max_health) + " HP\n";
                BaseStatsText += "Max Armor: " + int(pPlayer.pev.armortype) + " AP\n";

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
                        MedicStatsText += "Healing: " + healingAura.GetScaledHealAmount() + "% HP\n";
                        MedicStatsText += "Poison Damage: " + healingAura.GetPoisonDamageAmount() + "% HP\n";
                        MedicStatsText += "Radius: " + healingAura.GetHealingRadius() / 16 + "ft\n";
                        MedicStatsText += "Revive Cooldown: " + healingAura.GetReviveCooldown() + "s\n";

                        m_pMenu.AddItem(MedicStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_VAMPIRE:
                {
                    BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                    if(bloodlust !is null)
                    {
                        string VampireStatsText = "=== Bloodlust (Passive): ===" + "\n";
                        VampireStatsText += "Damage Reduction Max (50% HP): " + bloodlust.GetDamageReductionMax() + "%\n";
                        VampireStatsText += "Bloodlust Gain from Damage: " + bloodlust.GetEnergySteal() + "%\n";
                        VampireStatsText += "Lifesteal: " + bloodlust.GetLifestealAmount() * 100 + "%\n";
                        VampireStatsText += "Max HP (Overheal): " + (pPlayer.pev.max_health * bloodlust.GetOverhealPercentFlat()) + " HP\n\n";

                        VampireStatsText += "=== Bloodlust (Active): ===" + "\n";
                        VampireStatsText += "Damage Reduction Max (50% HP): " + bloodlust.GetDamageReductionMax() * 2 + "%\n";
                        VampireStatsText += "Bloodlust Gain from Damage: " + bloodlust.GetEnergySteal() * 2 + "%\n";
                        VampireStatsText += "Lifesteal: " + bloodlust.GetLifestealAmount() * 100 * 2 + "%\n";
                        VampireStatsText += "Max HP (Overheal): " + ((pPlayer.pev.max_health * bloodlust.GetOverhealPercentFlat()) * 2) + " HP\n\n";

                        m_pMenu.AddItem(VampireStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_ROBOMANCER:
                {
                    MinionData@ roboMinion = cast<MinionData@>(g_PlayerMinions[steamID]);
                    if(roboMinion !is null)
                    {
                        string EngineerStatsText = "=== Robogrunts: ===" + "\n"; 
                        EngineerStatsText += "Robogrunt Base Health: " + int(roboMinion.GetScaledHealth()) + " HP\n"; 
                        EngineerStatsText += "Robogrunt Damage: " + roboMinion.GetScaledDamage() * 100 + "%\n";
                        EngineerStatsText += "Robogrunt Auto-Repair: " + roboMinion.GetMinionRegen() + "%\n";

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
                        XenologistStatsText += "Creature Base Health: " + int(xenMinion.GetScaledHealth()) + " HP\n";
                        XenologistStatsText += "Creature Damage: " + xenMinion.GetScaledDamage() * 100 + "%\n";
                        XenologistStatsText += "Creature Health Regen: " + xenMinion.GetMinionRegen() + "%\n";
                        XenologistStatsText += "Creature Lifesteal (Minion and Player): " + xenMinion.GetLifestealPercent() * 100 + "%\n";

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
                        NecromancerStatsText += "Zombie Base Health: " + int(necroMinion.GetScaledHealth()) + " HP\n";
                        NecromancerStatsText += "Zombie Damage: " + necroMinion.GetScaledDamage() * 100 + "%\n";
                        NecromancerStatsText += "Zombie Health Regen: " + necroMinion.GetMinionRegen() + "%\n";
                        NecromancerStatsText += "Zombie Lifesteal (Minion and Player): " + necroMinion.GetLifestealPercent() * 100 + "%\n";

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
                            ShocktrooperStatsText += "Max Capacity: " + shockRifle.GetScaledMaxAmmo() + "\n";
                            ShocktrooperStatsText += "Damage Bonus: " + shockRifle.GetScaledDamage() * 100 + "%\n";

                        m_pMenu.AddItem(ShocktrooperStatsText, null);
                    }
                    break;
                }
                case PlayerClass::CLASS_FROSTGUARD:
                {
                    BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                    if(barrier !is null)
                    {
                        string FrostguardStatsText = "=== Ice Shield: ===" + "\n";
                            FrostguardStatsText += "Max Durability: " + int(barrier.GetScaledShieldMaxHP()) + " HP\n";
                            FrostguardStatsText += "Damage Reflect: " + barrier.GetScaledDamageReflection() * 100 + "%\n";
                            FrostguardStatsText += "Health Absorb: " + barrier.GetScaledHealthAbsorb() * 100 + "%\n";
                            //FrostguardStatsText += "Active Recharge Speed: " + (barrier.GetScaledRechargeSpeed()) + "/s\n";
                            FrostguardStatsText += "Deactivation Cost: " + int(barrier.GetBarrierDeactivateEnergyCost() * 100) + "%\n";

                        m_pMenu.AddItem(FrostguardStatsText, null);
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
                            CloakerStatsText += "Shock Nova Lifesteal: " + cloak.GetHPStealPercent() * 100 + "%\n";

                        m_pMenu.AddItem(CloakerStatsText, null);
                    }
                }
                break;
                case PlayerClass::CLASS_FIREBUG:
                {
                    DragonsBreathData@ DragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamID]);
                    if(DragonsBreath !is null)
                    {
                        string FirebugStatsText = "=== Dragon's Breath Ammo (Current Weapon): ===" + "\n";
                            FirebugStatsText += "Explosive Damage: " + formatFloat(DragonsBreath.GetScaledExplosionDamagePercent() * 100.0f, "f", 0, 1) + "% of weapon damage.\n";
                            FirebugStatsText += "Fire Damage: " + formatFloat(DragonsBreath.GetScaledFireDamagePercent() * 100.0f, "f", 0, 2) + "% per tick\n";
                            FirebugStatsText += "Fire Duration: " + DragonsBreath.GetFireDuration() + "s\n";
                            FirebugStatsText += "Fire Radius: " + DragonsBreath.GetRadius() / 16 + "ft\n";
                        
                        FirebugStatsText += "\nMax Ammo Capacity: " + int(DragonsBreath.GetMaxRounds()) + "\n";
                        FirebugStatsText += "Refill: " + DragonsBreath.GetAmmoRefillPercent() + "% (" + DragonsBreath.GetAmmoPerPack() + " rounds)\n\n";

                        m_pMenu.AddItem(FirebugStatsText, null);
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
                            EngineerStatsText += "Healing: " + sentry.GetScaledHealAmount() + "% HP\n";
                            EngineerStatsText += "Heal Radius: " + sentry.GetHealRadius() / 16 + "ft\n";
                            EngineerStatsText += "Sentry Damage: " + sentry.GetScaledDamage() * 100 + "%\n";

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