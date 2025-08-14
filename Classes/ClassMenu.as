/*
This file handles class selection.
*/
const string strClassChangeSound = "tfc/misc/r_tele1.wav";

namespace Menu
{
    final class ClassMenu
    {
        private CTextMenu@ m_pMenu;
        private PlayerData@ m_pOwner;
        
        ClassMenu(PlayerData@ owner)
        {
            @m_pOwner = owner;
        }
        
        void Show(CBasePlayer@ pPlayer)
        {
            if(pPlayer is null) return;
            
            @m_pMenu = CTextMenu(TextMenuPlayerSlotCallback(this.MenuCallback));
            m_pMenu.SetTitle("Select a Class\nCurrent Class: " + m_pOwner.GetClassName(m_pOwner.GetCurrentClass()) + "\n\n");
            
            // Add all classes from list.
            for(uint i = 0; i < g_ClassList.length(); i++)
            {
                AddClassOption(g_ClassList[i]);
            }
            
            m_pMenu.Register();
            m_pMenu.Open(0, 0, pPlayer);
        }
        
        private void AddClassOption(PlayerClass pClass)
        {
            ClassStats@ stats = m_pOwner.GetClassStats(pClass);
            if(stats !is null)
            {
                m_pMenu.AddItem(m_pOwner.GetClassName(pClass) + " - Level " + stats.GetLevel(), 
                    any(int(pClass)));
            }
        }
        
        private void MenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item)
        {
            if(item !is null && pPlayer !is null)
            {
                int classId;
                item.m_pUserData.retrieve(classId);
                PlayerClass newClass = PlayerClass(classId);
                
                m_pOwner.SetClass(newClass); // Set class.
                m_pOwner.CalculateStats(pPlayer); // Recalculate stats.
                ResetPlayer(pPlayer); // Reset player.
                
                // Reset resources when changing class, so it can't be exploited.
                string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
                if(g_PlayerClassResources.exists(steamID))
                {
                    dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                    if(resources !is null)
                    {
                        resources['current'] = 0; // Reset current energy to 0.
                    }
                }
                
                // Cancel any barrier refunds in progress.
                if(g_PlayerBarriers.exists(steamID))
                {
                    BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                    if(barrier !is null)
                    {
                        barrier.CancelRefunds(steamID);
                    }
                }

                PlayClassChangeEffects(pPlayer);
                
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, 
                    "Class changed to: " + m_pOwner.GetClassName(newClass) + "!\n");
            }
        }

        private void PlayClassChangeEffects(CBasePlayer@ pPlayer)
        {
            if(pPlayer is null) return;

            
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_ITEM, strClassChangeSound, VOL_NORM, ATTN_NORM); // Play class change sound.

            Vector pos = pPlayer.pev.origin; // Create effects at player position.

            // Primary effect - Teleport Splash (Quake-style).
            NetworkMessage teleport(MSG_ALL, NetworkMessages::SVC_TEMPENTITY);
            teleport.WriteByte(TE_TELEPORT);
            teleport.WriteCoord(pos.x);
            teleport.WriteCoord(pos.y);
            teleport.WriteCoord(pos.z);
            teleport.End();
        }
    }
}