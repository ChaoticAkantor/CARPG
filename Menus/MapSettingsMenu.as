/* Admin menu for current-map CARPG policy. */
namespace Menu
{
    final class MapSettingsMenu
    {
        private CTextMenu@ m_pMenuA;
        private CTextMenu@ m_pMenuB;
        private bool m_bNextIsA = true;

        void Show(CBasePlayer@ pPlayer)
        {
            if(pPlayer is null)
                return;

            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(!IsAdmin(steamID))
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "CARPG: Only configured admins can change map settings.\n");
                return;
            }

            CTextMenu@ newMenu = CreateMenu();
            newMenu.SetTitle("=== CARPG Map Settings ===\nMap: " + g_szCARPGMapName
                + "\nCurrent mode: " + GetCARPGMapModeName(g_iCARPGCurrentMapMode)
                + "\nChanges save to the shared map settings file.\n");
            newMenu.AddItem("0 - No change", any(CARPG_MAP_NO_CHANGE));
            newMenu.AddItem("1 - Apply balancing", any(CARPG_MAP_BALANCED));
            newMenu.AddItem("2 - Disable CARPG", any(CARPG_MAP_DISABLED));
            newMenu.Register();
            newMenu.Open(0, 0, pPlayer);
        }

        private CTextMenu@ CreateMenu()
        {
            CTextMenu@ newMenu = CTextMenu(TextMenuPlayerSlotCallback(this.MenuCallback));
            if(m_bNextIsA)
                @m_pMenuA = newMenu;
            else
                @m_pMenuB = newMenu;
            m_bNextIsA = !m_bNextIsA;
            return newMenu;
        }

        private void MenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item)
        {
            if(item is null || pPlayer is null)
                return;

            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(!IsAdmin(steamID))
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "CARPG: Only configured admins can change map settings.\n");
                return;
            }

            int mode;
            item.m_pUserData.retrieve(mode);
            int previousMode = g_iCARPGCurrentMapMode;
            SetCurrentCARPGMapMode(mode);
            ApplyCARPGMapModeRuntime(previousMode, mode);

            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK,
                "CARPG: " + g_szCARPGMapName + " mode set to " + GetCARPGMapModeName(mode) + ".\n");
            Show(pPlayer);
        }
    }

    dictionary g_MapSettingsMenuInstances;

    void ShowMapSettingsMenu(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!IsAdmin(steamID))
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "CARPG: Only configured admins can change map settings.\n");
            return;
        }

        MapSettingsMenu@ menu = MapSettingsMenu();
        @g_MapSettingsMenuInstances[steamID] = @menu;
        menu.Show(pPlayer);
    }
}