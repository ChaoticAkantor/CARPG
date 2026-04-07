/*
This is our Debug Menu file, for easy debugging of plugin features and cheats.
*/
namespace Menu
{
    final class DebugMenu
    {
        private CTextMenu@ m_pMenu;
        
        void ShowDebugMenu(CBasePlayer@ pPlayer) 
        {
            if(pPlayer is null) return;
            
            @m_pMenu = CTextMenu(TextMenuPlayerSlotCallback(this.MenuCallback));
            m_pMenu.SetTitle("Admin Debug Menu\n");
            
            m_pMenu.AddItem("Add 1000 XP\n", any(0));
            m_pMenu.AddItem("Set Max Level\n", any(1));
            m_pMenu.AddItem("Reset Level\n", any(2));
            m_pMenu.AddItem("Fill Class Resource\n", any(3));
            m_pMenu.AddItem("Toggle God Mode\n", any(4));
            
            m_pMenu.Register();
            m_pMenu.Open(0, 0, pPlayer);
        }
        
        private void MenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item) 
        {
            if(item !is null && pPlayer !is null) 
            {
                int choice;
                item.m_pUserData.retrieve(choice);
                string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

                if(!IsAdmin(steamID))
                    return;

                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null)
                {
                    ClassStats@ stats = data.GetClassStats(data.GetCurrentClass());
                    
                    if(choice == 0 && stats !is null)
                    {
                        stats.AddXP(1000, pPlayer, data);
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "Added 1000 XP to current class.\n");
                    }
                    else if(choice == 1 && stats !is null)
                    {
                        stats.SetLevel(g_iMaxLevel);
                        data.CalculateStats(pPlayer);
                        data.SaveToFile();
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "Set current class to maximum level.\n");
                    }
                    else if(choice == 2 && stats !is null)
                    {
                        stats.SetLevel(1);
                        data.CalculateStats(pPlayer);
                        data.SaveToFile();
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "Reset current class to level 1.\n");
                    }
                    else if(choice == 3)
                    {
                        switch(data.GetCurrentClass())
                        {
                            case PlayerClass::CLASS_MEDIC:
                            {
                                if(g_HealingAuras.exists(steamID))
                                {
                                    HealingAura@ a = cast<HealingAura@>(g_HealingAuras[steamID]);
                                    if(a !is null) a.FillAbilityCharge();
                                }
                                break;
                            }
                            case PlayerClass::CLASS_BERSERKER:
                            {
                                if(g_PlayerBloodlusts.exists(steamID))
                                {
                                    BloodlustData@ b = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                                    if(b !is null) b.FillAbilityCharge();
                                }
                                break;
                            }
                            case PlayerClass::CLASS_ROBOMANCER:
                            {
                                if(g_PlayerMinions.exists(steamID))
                                {
                                    MinionData@ m = cast<MinionData@>(g_PlayerMinions[steamID]);
                                    if(m !is null) m.FillAbilityCharge();
                                }
                                break;
                            }
                            case PlayerClass::CLASS_XENOMANCER:
                            {
                                if(g_XenologistMinions.exists(steamID))
                                {
                                    XenMinionData@ m = cast<XenMinionData@>(g_XenologistMinions[steamID]);
                                    if(m !is null) m.FillAbilityCharge();
                                }
                                break;
                            }
                            case PlayerClass::CLASS_NECROMANCER:
                            {
                                if(g_NecromancerMinions.exists(steamID))
                                {
                                    NecroMinionData@ m = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
                                    if(m !is null) m.FillAbilityCharge();
                                }
                                break;
                            }
                            case PlayerClass::CLASS_ENGINEER:
                            {
                                if(g_PlayerSentries.exists(steamID))
                                {
                                    SentryData@ s = cast<SentryData@>(g_PlayerSentries[steamID]);
                                    if(s !is null) s.FillAbilityCharge();
                                }
                                break;
                            }
                            case PlayerClass::CLASS_DEFENDER:
                            {
                                if(g_PlayerBarriers.exists(steamID))
                                {
                                    BarrierData@ b = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                                    if(b !is null) b.FillAbilityCharge();
                                }
                                break;
                            }
                            case PlayerClass::CLASS_SHOCKTROOPER:
                            {
                                if(g_ShockRifleData.exists(steamID))
                                {
                                    ShockRifleData@ s = cast<ShockRifleData@>(g_ShockRifleData[steamID]);
                                    if(s !is null) s.FillAbilityCharge();
                                }
                                break;
                            }
                            case PlayerClass::CLASS_CLOAKER:
                            {
                                if(g_PlayerCloaks.exists(steamID))
                                {
                                    CloakData@ c = cast<CloakData@>(g_PlayerCloaks[steamID]);
                                    if(c !is null) c.FillAbilityCharge();
                                }
                                break;
                            }
                            case PlayerClass::CLASS_VANQUISHER:
                            {
                                if(g_PlayerDragonsBreath.exists(steamID))
                                {
                                    DragonsBreathData@ d = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamID]);
                                    if(d !is null) d.FillAbilityCharge();
                                }
                                break;
                            }
                            case PlayerClass::CLASS_SWARMER:
                            {
                                if(g_PlayerSnarkNests.exists(steamID))
                                {
                                    SnarkNestData@ s = cast<SnarkNestData@>(g_PlayerSnarkNests[steamID]);
                                    if(s !is null) s.FillAbilityCharge();
                                }
                                break;
                            }
                        }
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "Class resource filled.\n");
                    }
                    else if(choice == 4)
                    {
                        pPlayer.pev.flags = pPlayer.pev.flags ^ FL_GODMODE;
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "Godmode " + ((pPlayer.pev.flags & FL_GODMODE) != 0 ? "enabled" : "disabled") + "\n");
                    }
                }
            }
        }
    }
}