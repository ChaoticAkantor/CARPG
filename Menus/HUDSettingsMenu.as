/*
This file handles the HUD settings menu.
*/

namespace Menu
{
	const int HUD_SETTINGS_MAIN_RPG = 1000;
	const int HUD_SETTINGS_MAIN_RESOURCE = 1001;
	const int HUD_SETTINGS_MAIN_AMMO = 1002;
	const int HUD_SETTINGS_EDIT_COLOR = 2000;
	const int HUD_SETTINGS_EDIT_POSITION = 3000;
	const int HUD_SETTINGS_COLOR = 4000;
	const int HUD_SETTINGS_POSITION = 5000;

	dictionary g_HUDSettingsMenuInstances;

	final class HUDSettingsMenu
	{
		private CTextMenu@ m_pMenuA;
		private CTextMenu@ m_pMenuB;
		private bool m_bNextIsA = true;
		private PlayerData@ m_pOwner;
		private int m_iCurrentHUD = CARPG_HUD_RPG;

		HUDSettingsMenu(PlayerData@ owner)
		{
			@m_pOwner = owner;
		}

		void ShowMain(CBasePlayer@ pPlayer)
		{
			if(pPlayer is null || m_pOwner is null)
				return;

			CTextMenu@ newMenu = CreateMenu();
			newMenu.SetTitle("=== HUD Settings ===\nChoose a display to customise.\nChanges save automatically.\n");
			newMenu.AddItem("Class/XP", any(HUD_SETTINGS_MAIN_RPG));
			newMenu.AddItem("Class Resource", any(HUD_SETTINGS_MAIN_RESOURCE));
			newMenu.AddItem("Ammo Regen Counter", any(HUD_SETTINGS_MAIN_AMMO));
			newMenu.Register();
			newMenu.Open(0, 0, pPlayer);
		}

		private void ShowHUD(CBasePlayer@ pPlayer, int hudType)
		{
			m_iCurrentHUD = hudType;
			CTextMenu@ newMenu = CreateMenu();
			newMenu.SetTitle("=== " + GetHUDName(hudType) + " ===\nColor: "
				+ GetCARPGHUDColorName(m_pOwner.GetHUDColorIndex(hudType))
				+ " | Position: "
				+ GetCARPGHUDPositionName(hudType, m_pOwner.GetHUDPositionIndex(hudType)) + "\n");
			newMenu.AddItem("Change Color", any(HUD_SETTINGS_EDIT_COLOR + hudType));
			newMenu.AddItem("Change Position", any(HUD_SETTINGS_EDIT_POSITION + hudType));
			newMenu.AddItem("Back", any(-1));
			newMenu.Register();
			newMenu.Open(0, 0, pPlayer);
		}

		private void ShowColors(CBasePlayer@ pPlayer, int hudType)
		{
			m_iCurrentHUD = hudType;
			CTextMenu@ newMenu = CreateMenu();
			newMenu.SetTitle("=== " + GetHUDName(hudType) + " Color ===\nSelect a color.\n");
			for(uint i = 0; i < g_CARPGHUDColorNames.length(); ++i)
				newMenu.AddItem(g_CARPGHUDColorNames[i], any(HUD_SETTINGS_COLOR + int(i)));
			newMenu.AddItem("Back", any(-2));
			newMenu.Register();
			newMenu.Open(0, 0, pPlayer);
		}

		private void ShowPositions(CBasePlayer@ pPlayer, int hudType)
		{
			m_iCurrentHUD = hudType;
			CTextMenu@ newMenu = CreateMenu();
			newMenu.SetTitle("=== " + GetHUDName(hudType) + " Position ===\n");
			int positionCount = hudType == CARPG_HUD_RESOURCE ? 5 : 4;
			for(int i = 0; i < positionCount; ++i)
				newMenu.AddItem(GetCARPGHUDPositionName(hudType, i), any(HUD_SETTINGS_POSITION + i));
			newMenu.AddItem("Back", any(-3));
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

		private string GetHUDName(int hudType)
		{
			if(hudType == CARPG_HUD_RESOURCE) return "Resource Display";
			if(hudType == CARPG_HUD_AMMO) return "Ammo Regen Counter";
			return "RPG HUD";
		}

		private void MenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item)
		{
			if(item is null || pPlayer is null || m_pOwner is null)
				return;

			int choice;
			item.m_pUserData.retrieve(choice);
			if(choice >= HUD_SETTINGS_MAIN_RPG && choice <= HUD_SETTINGS_MAIN_AMMO)
			{
				ShowHUD(pPlayer, choice - HUD_SETTINGS_MAIN_RPG);
			}
			else if(choice >= HUD_SETTINGS_EDIT_COLOR && choice < HUD_SETTINGS_EDIT_COLOR + 3)
			{
				ShowColors(pPlayer, choice - HUD_SETTINGS_EDIT_COLOR);
			}
			else if(choice >= HUD_SETTINGS_EDIT_POSITION && choice < HUD_SETTINGS_EDIT_POSITION + 3)
			{
				ShowPositions(pPlayer, choice - HUD_SETTINGS_EDIT_POSITION);
			}
			else if(choice >= HUD_SETTINGS_COLOR && choice < HUD_SETTINGS_COLOR + int(g_CARPGHUDColorNames.length()))
			{
				m_pOwner.SetHUDColorIndex(m_iCurrentHUD, choice - HUD_SETTINGS_COLOR);
				ShowHUD(pPlayer, m_iCurrentHUD);
			}
			else if(choice >= HUD_SETTINGS_POSITION && choice < HUD_SETTINGS_POSITION + 5)
			{
				m_pOwner.SetHUDPositionIndex(m_iCurrentHUD, choice - HUD_SETTINGS_POSITION);
				ShowHUD(pPlayer, m_iCurrentHUD);
			}
			else if(choice == -1)
			{
				ShowMain(pPlayer);
			}
			else if(choice == -2 || choice == -3)
			{
				ShowHUD(pPlayer, m_iCurrentHUD);
			}
		}
	}

	void ShowHUDSettingsMenu(PlayerData@ owner, CBasePlayer@ pPlayer)
	{
		if(owner is null || pPlayer is null)
			return;

		string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		HUDSettingsMenu@ settingsMenu = HUDSettingsMenu(owner);
		@g_HUDSettingsMenuInstances[steamID] = @settingsMenu;
		settingsMenu.ShowMain(pPlayer);
	}
}