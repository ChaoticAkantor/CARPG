final class PerkMenu 
{
    // Constants for level requirements
    private int SLOT_1_LEVEL = 10;  // Level to unlock perk slot 1.
    private int SLOT_2_LEVEL = 20; // Level to unlock perk slot 2.
    private int SLOT_3_LEVEL = 30; // Level to unlock perk slot 3.
    
    array<int> m_PerkSlots = {0, 0, 0}; // Store selected perk IDs for each slot
    
    void ShowPerkSlotsMenu(CBasePlayer@ pPlayer) 
    {
        if(pPlayer is null) return;
        
        // Get player's class level
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerRPGData.exists(steamID)) return;
        
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data is null) return;
        
        int playerLevel = data.GetCurrentClassStats().GetLevel();
        
        CTextMenu@ menu = CTextMenu(@PerkSlotsMenuCallback);
        menu.SetTitle("Class Perk Slots\n");
        
        // Add perk slot options based on level
        for(uint i = 0; i < m_PerkSlots.length(); i++)
        {
            string slotStatus;
            bool unlocked = false;
            
            switch(i)
            {
                case 0:
                    unlocked = (playerLevel >= SLOT_1_LEVEL);
                    slotStatus = unlocked ? GetPerkName(m_PerkSlots[i]) : "< LOCKED - Lv. " + SLOT_1_LEVEL + " >";
                    break;
                case 1:
                    unlocked = (playerLevel >= SLOT_2_LEVEL);
                    slotStatus = unlocked ? GetPerkName(m_PerkSlots[i]) : "< LOCKED - Lv. " + SLOT_2_LEVEL + " >";
                    break;
                case 2:
                    unlocked = (playerLevel >= SLOT_3_LEVEL);
                    slotStatus = unlocked ? GetPerkName(m_PerkSlots[i]) : "< LOCKED - Lv. " + SLOT_3_LEVEL + " >";
                    break;
            }
            
            if(unlocked)
            {
                string perkName = m_PerkSlots[i] == 0 ? "Empty" : GetPerkName(m_PerkSlots[i]);
                menu.AddItem(perkName + "\n", any(i));
            }
            else
            {
                menu.AddItem(slotStatus + "\n", any(-1));
            }
        }
        
        menu.Register();
        menu.Open(0, 0, pPlayer);
    }
}

void PerkSlotsMenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item) 
{
    if(item !is null && pPlayer !is null) 
    {
        int slotIndex;
        item.m_pUserData.retrieve(slotIndex);
        
        // Don't show perk list for locked slots
        if(slotIndex == -1)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "This perk slot is not yet unlocked.\n");
            return;
        }
        
        ShowPerkList(pPlayer, slotIndex);
    }
}

void ShowPerkList(CBasePlayer@ pPlayer, int slotIndex)
{
    CTextMenu@ menu = CTextMenu(@PerkListMenuCallback);
    menu.SetTitle("Select Perk for Slot " + (slotIndex + 1) + "\n");
    
    // Add slot index to each item's data instead of storing as separate item
    menu.AddItem("Back\n", any(array<int> = {slotIndex, -1}));
    menu.AddItem("Health Boost\n", any(array<int> = {slotIndex, 1}));
    menu.AddItem("Quick Reload\n", any(array<int> = {slotIndex, 2}));
    
    menu.Register();
    menu.Open(0, 0, pPlayer);
}

void PerkListMenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item)
{
    if(item !is null && pPlayer !is null)
    {
        array<int> data;
        item.m_pUserData.retrieve(data);
        
        int slotIndex = data[0];
        int perkId = data[1];
        
        if(perkId == -1)
        {
            g_PerkMenu.ShowPerkSlotsMenu(pPlayer); // Update reference here
            return;
        }
        
        ShowPerkConfirm(pPlayer, slotIndex, perkId);
    }
}

void ShowPerkConfirm(CBasePlayer@ pPlayer, int slotIndex, int perkId)
{
    CTextMenu@ menu = CTextMenu(@PerkConfirmMenuCallback);
    menu.SetTitle("Perk Details\nSlot: " + (slotIndex + 1) + "\nPerk: " + GetPerkName(perkId) + "\n");
    
    // Store both indices in each option
    menu.AddItem("Equip\n", any(array<int> = {slotIndex, perkId, 1}));
    menu.AddItem("Back\n", any(array<int> = {slotIndex, perkId, 0}));
    
    menu.Register();
    menu.Open(0, 0, pPlayer);
}

void PerkConfirmMenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item)
{
    if(item !is null && pPlayer !is null)
    {
        array<int> data;
        item.m_pUserData.retrieve(data);
        
        int slotIndex = data[0];
        int perkId = data[1];
        int choice = data[2];
        
        if(choice == 1)
        {
            g_PerkMenu.m_PerkSlots[slotIndex] = perkId;
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, 
                "Equipped " + GetPerkName(perkId) + " to slot " + (slotIndex + 1) + "\n");
        }
        
        ShowPerkList(pPlayer, slotIndex);
    }
}

string GetPerkName(int perkId)
{
    switch(perkId)
    {
        case 1: return "Health Boost";
        case 2: return "Quick Reload";
        default: return "Unknown Perk";
    }
}

PerkMenu g_PerkMenu;