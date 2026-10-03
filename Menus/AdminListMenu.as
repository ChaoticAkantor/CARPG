/* Admin list manager for connected players. */
namespace Menu
{
    final class AdminListMenu
    {
        private CTextMenu@ m_pMenuA;
        private CTextMenu@ m_pMenuB;
        private bool m_bNextIsA = true;

        void Show(CBasePlayer@ pPlayer)
        {
            if(pPlayer is null)
                return;

            string actorSteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(!IsAdmin(actorSteamID))
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "CARPG: Only listed admins can manage the admin list.\n");
                return;
            }

            CTextMenu@ newMenu = CreateMenu();
            newMenu.SetTitle("=== CARPG Admin List ===\nSelect a connected player to add or remove.\n");
            for(int i = 1; i <= g_Engine.maxClients; ++i)
            {
                CBasePlayer@ candidate = g_PlayerFuncs.FindPlayerByIndex(i);
                if(candidate is null || !candidate.IsConnected())
                    continue;

                string steamID = g_EngineFuncs.GetPlayerAuthId(candidate.edict());
                if(steamID.IsEmpty())
                    continue;

                string action = IsAdmin(steamID) ? "Remove" : "Add";
                newMenu.AddItem(action + ": " + string(candidate.pev.netname) + " (" + steamID + ")", any(i));
            }

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

            string actorSteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(!IsAdmin(actorSteamID))
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "CARPG: Only listed admins can manage the admin list.\n");
                return;
            }

            int targetIndex;
            item.m_pUserData.retrieve(targetIndex);
            CBasePlayer@ target = g_PlayerFuncs.FindPlayerByIndex(targetIndex);
            if(target is null || !target.IsConnected())
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "CARPG: That player is no longer connected.\n");
                Show(pPlayer);
                return;
            }

            string targetSteamID = g_EngineFuncs.GetPlayerAuthId(target.edict());
            if(IsAdmin(targetSteamID))
            {
                if(g_AdminList.length() <= 1)
                {
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "CARPG: The last admin cannot be removed.\n");
                }
                else if(RemoveAdmin(targetSteamID))
                {
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "CARPG: Removed " + targetSteamID + " from the admin list.\n");
                }
            }
            else if(AddAdmin(targetSteamID))
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "CARPG: Added " + targetSteamID + " to the admin list.\n");
            }

            if(IsAdmin(actorSteamID))
                Show(pPlayer);
        }
    }

    dictionary g_AdminListMenuInstances;

    void ShowAdminListMenu(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!IsAdmin(steamID))
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "CARPG: Only listed admins can manage the admin list.\n");
            return;
        }

        AdminListMenu@ menu = AdminListMenu();
        @g_AdminListMenuInstances[steamID] = @menu;
        menu.Show(pPlayer);
    }
}