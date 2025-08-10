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
            m_pMenu.SetTitle("Dev Debug Menu\n");
            
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

                if(!IsDev(steamID))
                    return;

                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null)
                {
                    ClassStats@ stats = data.GetClassStats(data.GetCurrentClass());
                    
                    if(choice == 0 && stats !is null)
                    {
                        stats.AddXP(1000, pPlayer, data);
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "Added 100 XP to current class.\n");
                    }
                    else if(choice == 1 && stats !is null)
                    {
                        stats.SetXP(99999999, pPlayer, data); // Add enough XP to reach max level.
                        stats.SetLevel(g_iMaxLevel); // Set level to max.
                        stats.UpdateCurrentLevelXP(); // Recalculate Needed XP.
                        data.CalculateStats(pPlayer); // Recalculate stats.
                        data.SaveToFile(); // Save the changes.
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "Set current class to maximum level.\n");
                    }
                    else if(choice == 2 && stats !is null)
                    {
                        stats.SetLevel(1); // Set level to 1.
                        stats.SetXP(0, pPlayer, data); // Set XP to 0.
                        stats.UpdateCurrentLevelXP(); // Recalculate Needed XP.
                        data.CalculateStats(pPlayer); // Recalculate stats.
                        data.SaveToFile(); // Save the changes.
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "Reset current class to level 1.\n");
                    }
                    else if(choice == 3)
                    {
                        if(g_PlayerClassResources.exists(steamID))
                        {
                            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                            if(resources !is null)
                            {
                                resources['current'] = int(resources['max']);
                                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "Resources set to max.\n");
                            }
                        }
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