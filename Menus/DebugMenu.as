/* Admin debug menu with explicit player targeting. */
namespace Menu
{
    dictionary g_DebugMenuInstances;

    final class DebugMenu
    {
        private CTextMenu@ m_pMenuA;
        private CTextMenu@ m_pMenuB;
        private bool m_bNextIsA = true;
        private int m_iTargetPlayerIndex = 0;
        private string m_szTargetSteamID;

        void ShowPlayerPicker(CBasePlayer@ pAdmin)
        {
            if(!IsAuthorizedAdmin(pAdmin))
                return;

            CTextMenu@ newMenu = CreatePlayerMenu();
            newMenu.SetTitle("=== Debug: Select Player ===\n");
            for(int i = 1; i <= g_Engine.maxClients; ++i)
            {
                CBasePlayer@ candidate = g_PlayerFuncs.FindPlayerByIndex(i);
                if(candidate is null || !candidate.IsConnected())
                    continue;

                string steamID = g_EngineFuncs.GetPlayerAuthId(candidate.edict());
                if(steamID.IsEmpty())
                    continue;

                newMenu.AddItem(string(candidate.pev.netname) + " (" + steamID + ")", any(i));
            }

            newMenu.Register();
            newMenu.Open(0, 0, pAdmin);
        }

        private CTextMenu@ CreatePlayerMenu()
        {
            CTextMenu@ newMenu = CTextMenu(TextMenuPlayerSlotCallback(this.PlayerPickerCallback));
            RetainMenu(newMenu);
            return newMenu;
        }

        private CTextMenu@ CreateActionMenu()
        {
            CTextMenu@ newMenu = CTextMenu(TextMenuPlayerSlotCallback(this.ActionMenuCallback));
            RetainMenu(newMenu);
            return newMenu;
        }

        private void RetainMenu(CTextMenu@ menu)
        {
            if(m_bNextIsA)
                @m_pMenuA = menu;
            else
                @m_pMenuB = menu;
            m_bNextIsA = !m_bNextIsA;
        }

        private bool IsAuthorizedAdmin(CBasePlayer@ pAdmin)
        {
            return pAdmin !is null && pAdmin.IsConnected()
                && IsAdmin(g_EngineFuncs.GetPlayerAuthId(pAdmin.edict()));
        }

        private void PlayerPickerCallback(CTextMenu@ menu, CBasePlayer@ pAdmin, int page, const CTextMenuItem@ item)
        {
            if(item is null || !IsAuthorizedAdmin(pAdmin))
                return;

            int targetIndex;
            item.m_pUserData.retrieve(targetIndex);
            CBasePlayer@ target = g_PlayerFuncs.FindPlayerByIndex(targetIndex);
            if(target is null || !target.IsConnected())
            {
                g_PlayerFuncs.ClientPrint(pAdmin, HUD_PRINTTALK, "Debug: That player is no longer connected.\n");
                ShowPlayerPicker(pAdmin);
                return;
            }

            m_iTargetPlayerIndex = targetIndex;
            m_szTargetSteamID = g_EngineFuncs.GetPlayerAuthId(target.edict());
            ShowActions(pAdmin, target);
        }

        private void ShowActions(CBasePlayer@ pAdmin, CBasePlayer@ target)
        {
            if(!IsAuthorizedAdmin(pAdmin) || target is null || !target.IsConnected())
                return;

            CTextMenu@ newMenu = CreateActionMenu();
            newMenu.SetTitle("=== Debug: " + string(target.pev.netname) + " ===\n");
            newMenu.AddItem("Add 1000 XP", any(0));
            newMenu.AddItem("Set Max Level", any(1));
            newMenu.AddItem("Set Max Rank", any(2));
            newMenu.AddItem("Reset Level", any(3));
            newMenu.AddItem("Reset Rank", any(4));
            newMenu.AddItem("Fill Class Resource", any(5));
            newMenu.AddItem("Toggle God Mode", any(6));
            newMenu.AddItem("Choose Another Player", any(7));
            newMenu.Register();
            newMenu.Open(0, 0, pAdmin);
        }

        private CBasePlayer@ ResolveTarget()
        {
            CBasePlayer@ target = g_PlayerFuncs.FindPlayerByIndex(m_iTargetPlayerIndex);
            if(target is null || !target.IsConnected())
                return null;
            if(g_EngineFuncs.GetPlayerAuthId(target.edict()) != m_szTargetSteamID)
                return null;
            return target;
        }

        private void ActionMenuCallback(CTextMenu@ menu, CBasePlayer@ pAdmin, int page, const CTextMenuItem@ item)
        {
            if(item is null || !IsAuthorizedAdmin(pAdmin))
                return;

            int choice;
            item.m_pUserData.retrieve(choice);
            if(choice == 7)
            {
                ShowPlayerPicker(pAdmin);
                return;
            }

            CBasePlayer@ target = ResolveTarget();
            if(target is null)
            {
                g_PlayerFuncs.ClientPrint(pAdmin, HUD_PRINTTALK, "Debug: Target disconnected or slot was reused. Choose a player again.\n");
                ShowPlayerPicker(pAdmin);
                return;
            }

            ApplyAction(pAdmin, target, choice);
            ShowPlayerPicker(pAdmin);
        }

        private void ApplyAction(CBasePlayer@ pAdmin, CBasePlayer@ target, int choice)
        {
            string targetSteamID = g_EngineFuncs.GetPlayerAuthId(target.edict());
            PlayerData@ data = g_PlayerRPGData.exists(targetSteamID)
                ? cast<PlayerData@>(g_PlayerRPGData[targetSteamID]) : null;
            ClassStats@ stats = data is null ? null : data.GetClassStats(data.GetCurrentClass());
            string result = "";

            if(choice == 6)
            {
                target.pev.flags = target.pev.flags ^ FL_GODMODE;
                result = "Godmode " + ((target.pev.flags & FL_GODMODE) != 0 ? "enabled" : "disabled");
            }
            else if(data is null)
            {
                result = "No RPG data is loaded for that player.";
            }
            else if(choice == 0 && stats !is null)
            {
                stats.AddXP(1000, target, data);
                result = "Added 1000 XP.";
            }
            else if(choice == 1 && stats !is null)
            {
                stats.SetLevel(g_iMaxLevel);
                data.CalculateStats(target);
                data.SaveToFile();
                result = "Set current class to maximum level.";
            }
            else if(choice == 2)
            {
                data.SetRebirthRank(g_iMaxRebirthRank);
                data.CalculateStats(target);
                data.SaveToFile();
                result = "Set rank to maximum.";
            }
            else if(choice == 3 && stats !is null)
            {
                stats.SetLevel(1);
                data.CalculateStats(target);
                data.SaveToFile();
                result = "Reset current class to level 1.";
            }
            else if(choice == 4)
            {
                data.SetRebirthRank(0);
                data.CalculateStats(target);
                data.SaveToFile();
                result = "Reset rank to 0.";
            }
            else if(choice == 5)
            {
                FillClassResource(targetSteamID, data.GetCurrentClass());
                result = "Filled class resource.";
            }
            else
            {
                result = "The selected action is unavailable for that player's class.";
            }

            g_PlayerFuncs.ClientPrint(pAdmin, HUD_PRINTTALK,
                "Debug: " + result + " for " + string(target.pev.netname) + " (" + targetSteamID + ").\n");
        }

        private void FillClassResource(const string& in steamID, PlayerClass playerClass)
        {
            switch(playerClass)
            {
                case PlayerClass::CLASS_MEDIC:
                    if(g_HealingAuras.exists(steamID))
                    {
                        HealingAura@ aura = cast<HealingAura@>(g_HealingAuras[steamID]);
                        if(aura !is null) aura.FillAbilityCharge();
                    }
                    break;
                case PlayerClass::CLASS_VAMPIRE:
                    if(g_PlayerBloodlusts.exists(steamID))
                    {
                        BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                        if(bloodlust !is null) bloodlust.FillAbilityCharge();
                    }
                    break;
                case PlayerClass::CLASS_ROBOMANCER:
                    if(g_PlayerMinions.exists(steamID))
                    {
                        MinionData@ minion = cast<MinionData@>(g_PlayerMinions[steamID]);
                        if(minion !is null) minion.FillAbilityCharge();
                    }
                    break;
                case PlayerClass::CLASS_XENOMANCER:
                    if(g_XenologistMinions.exists(steamID))
                    {
                        XenMinionData@ minion = cast<XenMinionData@>(g_XenologistMinions[steamID]);
                        if(minion !is null) minion.FillAbilityCharge();
                    }
                    break;
                case PlayerClass::CLASS_NECROMANCER:
                    if(g_NecromancerMinions.exists(steamID))
                    {
                        NecroMinionData@ minion = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
                        if(minion !is null) minion.FillAbilityCharge();
                    }
                    break;
                case PlayerClass::CLASS_ENGINEER:
                    if(g_PlayerSentries.exists(steamID))
                    {
                        SentryData@ sentry = cast<SentryData@>(g_PlayerSentries[steamID]);
                        if(sentry !is null) sentry.FillAbilityCharge();
                    }
                    break;
                case PlayerClass::CLASS_FROSTGUARD:
                    if(g_PlayerBarriers.exists(steamID))
                    {
                        BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                        if(barrier !is null) barrier.FillAbilityCharge();
                    }
                    break;
                case PlayerClass::CLASS_SHOCKTROOPER:
                    if(g_ShockRifleData.exists(steamID))
                    {
                        ShockRifleData@ shockRifle = cast<ShockRifleData@>(g_ShockRifleData[steamID]);
                        if(shockRifle !is null) shockRifle.FillAbilityCharge();
                    }
                    break;
                case PlayerClass::CLASS_CLOAKER:
                    if(g_PlayerCloaks.exists(steamID))
                    {
                        CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
                        if(cloak !is null) cloak.FillAbilityCharge();
                    }
                    break;
                case PlayerClass::CLASS_FIREBUG:
                    if(g_PlayerDragonsBreath.exists(steamID))
                    {
                        DragonsBreathData@ dragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamID]);
                        if(dragonsBreath !is null) dragonsBreath.FillAbilityCharge();
                    }
                    break;
                case PlayerClass::CLASS_SWARMER:
                    if(g_PlayerSnarkNests.exists(steamID))
                    {
                        SnarkNestData@ snarkNest = cast<SnarkNestData@>(g_PlayerSnarkNests[steamID]);
                        if(snarkNest !is null) snarkNest.FillAbilityCharge();
                    }
                    break;
            }
        }
    }

    void ShowDebugMenu(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!IsAdmin(steamID))
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "Only admins can access the debug menu.\n");
            return;
        }

        DebugMenu@ menu = cast<DebugMenu@>(g_DebugMenuInstances[steamID]);
        if(menu is null)
        {
            @menu = DebugMenu();
            @g_DebugMenuInstances[steamID] = @menu;
        }
        menu.ShowPlayerPicker(pPlayer);
    }
}