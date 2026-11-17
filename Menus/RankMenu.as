namespace Menu
{
    const int RANK_MENU_RESET = -1;

    final class RankMenu
    {
        private CTextMenu@ m_pMenuA;
        private CTextMenu@ m_pMenuB;
        private bool m_bNextIsA = true;
        private PlayerData@ m_pOwner;

        RankMenu(PlayerData@ owner)
        {
            @m_pOwner = owner;
        }

        void ShowMain(CBasePlayer@ pPlayer)
        {
            if(pPlayer is null) return;
            CTextMenu@ newMenu = CTextMenu(TextMenuPlayerSlotCallback(this.MenuCallback));
            newMenu.SetTitle("=== Rank Skills ===\nRank: " + m_pOwner.GetRebirthRank()
                + " | Rank Points (RP): " + m_pOwner.GetRankPoints() + "/" + m_pOwner.GetTotalRankPoints() + "\n\n");
            for(int i = int(RankSkillID::RANK_SKILL_BASIC_CAP); i < int(RankSkillID::RANK_SKILL_COUNT); i++)
            {
                RankSkillDefinition@ def = g_RankSkillDefs[i];
                RankSkillID id = RankSkillID(i);
                string increase = formatFloat(def.increase, "f", 0, 2);
                string total = formatFloat(m_pOwner.GetRankSkillBonus(id), "f", 0, 2);
                newMenu.AddItem(def.name + " (Lv " + m_pOwner.GetRankSkillLevel(id) + ") [+" + total
                    + "] +" + increase + " " + def.description, any(i));
            }
            newMenu.AddItem("Refund RP.", any(RANK_MENU_RESET));
            newMenu.Register();
            if(m_bNextIsA) @m_pMenuA = newMenu;
            else @m_pMenuB = newMenu;
            m_bNextIsA = !m_bNextIsA;
            newMenu.Open(0, 0, pPlayer);
        }

        private void MenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item)
        {
            if(item is null || pPlayer is null) return;
            int choice;
            item.m_pUserData.retrieve(choice);
            if(choice == RANK_MENU_RESET)
            {
                m_pOwner.ResetRankSkills(pPlayer);
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[CARPG] Rank Points refunded; class and skill caps updated.\n");
            }
            else if(m_pOwner.TrySpendRankPoint(RankSkillID(choice), pPlayer))
                g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_ITEM, strSkillSpendSound, VOL_NORM, ATTN_NORM);
            else
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[CARPG] No Rank Points available.\n");
            ShowMain(pPlayer);
        }
    }
}