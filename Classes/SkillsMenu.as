/*
This file handles the Skills menu.

All standard and class ability skills are shown in one flat list.
Selecting a skill spends one point and reopens the menu.
The last item resets (refunds) all skills for the current class.

Ability scripts read invested levels via:
    stats.GetSkillLevel(SkillID::SKILL_SKILL_ID_HERE);
*/

namespace Menu
{
    const int SKILL_MENU_RESET = -1;

    final class SkillsMenu
    {
        // Two menu slots are used so that ShowMain can be safely called from within
        // a MenuCallback. The callback fires on whichever slot is "active"; ShowMain
        // always writes to the OTHER slot, so the active menu is never destroyed
        // while its callback is still executing.
        private CTextMenu@ m_pMenuA;
        private CTextMenu@ m_pMenuB;
        private bool m_bNextIsA;  // Which slot ShowMain should write to next.
        private PlayerData@ m_pOwner;

        SkillsMenu(PlayerData@ owner)
        {
            @m_pOwner = owner;
            m_bNextIsA = true;
        }

        void ShowMain(CBasePlayer@ pPlayer)
        {
            if(pPlayer is null) return;

            CTextMenu@ newMenu = CTextMenu(TextMenuPlayerSlotCallback(this.MenuCallback));

            PlayerClass curClass = m_pOwner.GetCurrentClass();
            ClassStats@ stats = m_pOwner.GetCurrentClassStats();
            int remaining = (stats !is null) ? stats.GetSkillPoints() : 0;

            newMenu.SetTitle("=== Skills: " + m_pOwner.GetClassName(curClass) + " ===\n" + "Skillpoints Remaining: " + remaining + "\n\n");

            // Standard skills.
            array<SkillID> stdSkills = GetStandardSkillIDs();
            for(uint i = 0; i < stdSkills.length(); i++)
                AddSkillItem(newMenu, stdSkills[i], stats);

            // Ability skills for the current class.
            array<SkillID> abilitySkills = GetAbilitySkillIDs(curClass);
            for(uint i = 0; i < abilitySkills.length(); i++)
                AddSkillItem(newMenu, abilitySkills[i], stats);

            newMenu.AddItem("Refund Skillpoints", any(int(SKILL_MENU_RESET)));
            newMenu.Register();

            // Store in the slot that is NOT currently dispatching a callback.
            if(m_bNextIsA)
                @m_pMenuA = newMenu;
            else
                @m_pMenuB = newMenu;
            m_bNextIsA = !m_bNextIsA;

            newMenu.Open(0, 0, pPlayer);
        }

        private void MenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item)
        {
            if(item is null || pPlayer is null) return;

            int choice;
            item.m_pUserData.retrieve(choice);

            if(choice == SKILL_MENU_RESET)
            {
                m_pOwner.ResetCurrentSkills(pPlayer);
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK,
                    "[CARPG] " + m_pOwner.GetClassName(m_pOwner.GetCurrentClass()) + " - All skillpoints refunded.\n");
            }
            else
            {
                SkillID id = SkillID(choice);
                if(m_pOwner.TrySpendSkillPoint(id, pPlayer))
                {
                    SkillDefinition@ def = g_SkillDefs[choice];
                    //g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK,
                        //"[CARPG] Invested in " + ((def !is null) ? def.name : "Unknown") + " (Lv " + m_pOwner.GetSkillLevel(id) + ").\n");
                }
                else
                {
                    ClassStats@ stats = m_pOwner.GetCurrentClassStats();
                    if(stats !is null && stats.GetSkillPoints() < 1)
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[CARPG] No skill points!\n");
                    else
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[CARPG] Skill is max level!\n");
                }
            }

            // Reopen only if the player still has points to spend.
            ClassStats@ stats = m_pOwner.GetCurrentClassStats();
            if(stats !is null && stats.GetSkillPoints() > 0)
                ShowMain(pPlayer);
        }

        private void AddSkillItem(CTextMenu@ menu, SkillID id, ClassStats@ stats)
        {
            int idx = int(id);
            SkillDefinition@ def = (int(g_SkillDefs.length()) > idx) ? g_SkillDefs[idx] : null;
            if(def is null) return;

            int curLevel = (stats !is null) ? stats.GetSkillLevel(id) : 0;

            string levelTag = (curLevel >= def.maxLevel) ? "(MAX)" : ("(" + curLevel + "/" + def.maxLevel + ")");

            string bonusStr = "";
            if(def.strength > 0.0f && curLevel > 0)
            {
                float total = curLevel * def.strength;
                int totalInt = int(total);
                string totalStr = (total == float(totalInt)) ? ("" + totalInt) : ("" + total);
                bonusStr = " [" + totalStr + def.unit + "]";
            }

            menu.AddItem(def.name + " " + levelTag + bonusStr + " " + def.description + "\n", any(int(id)));
        }
    }
}
