/*
This is our Difficulty Settings file.

It allows us to force all skill values on load. Ensuring consistent balance no matter the map. May cause some maps to be easier or harder.
Player and Monster damage is determined by sk_ convars. 
Difficulty settings in Sven Co-op do nothing and most maps have their own map cfg, which may have sk_ values and other such settings.
Forcing them here helps keep things consistent and makes it easier to balance plugins.
*/

ForceDifficulty g_ForceDifficulty;

void ApplyDifficultySettings()
{
    g_ForceDifficulty.ApplyDifficultySettings();
}

final class ForceDifficulty
{
	private array<float> weapon_damage_values = 
	{
		10.0, //Medkit - Default 10 - Amount of charge used and amount healed per use.
		15.0, //Crowbar - Default 15.
		22.0, //Wrench - Default 22.
		40.0, //Grapple (Barnacle) - Default 40.
		12.0, //Handgun (9mm Handgun) - Default 12.
		66.0, //357 (Deagle is 2/3 of this) - Default 66.
		10.0, //Uzi (Also Akimbo, Gold do +1 extra damage) - Default 10.
		8.0, //MP5 (9mm AR) - Default 8.
		10.0, //Buckshot (7 pellets primary, 6 pellets secondary) - Default 10.
		60.0, //Crossbow (Alt weapon mode is explosive on impact) - Default 60.
		12.0, //556 (M16/SAW/Minigun, also effects enemies damage!) - Default 12.
		100.0, //M203 (ARgrenades) - Default 100.
		150.0, //RPG - Default 150.
		19.0, //Gauss (No charge) - Default 19.
		190.0, //Guass (Secondary, Max Charge) - Default 190.
		12.0, //Gluon (Egon) Gun - Default 12.
		12.0, //Hornet Gun - Default 12.
		100.0, //Hand Grenade - Default 100.
		160.0, //Satchel - Default 160.
		150.0, //Tripmine - Default 150.
		110.0, //762 (Sniper Rifle) - Default 110.
		100.0, //Spore Launcher - Default 100.
		250.0, //Displacer (Primary) - Default 250.
		300.0, //Displacer Radius - Default 300.
		15.0, //Shockrifle (Primary) - Default 15.
		2.0, //Shockrifle (Beam) - Default 2.
		350.0, //Shockrifle Touch damage (on self on detonate?) - Default 350.
		150.0 //Shockroach Splash damage (on self when detonate?) - Default 150.
	};


	private array<string> weapon_damage_strings = 
	{
		"sk_plr_HpMedic",
		"sk_plr_crowbar",
		"sk_plr_wrench",
		"sk_plr_grapple",
		"sk_plr_9mm_bullet",
		"sk_plr_357_bullet",
		"sk_plr_uzi",
		"sk_plr_9mmAR_bullet",
		"sk_plr_buckshot",
		"sk_plr_xbow_bolt_monster",
		"sk_556_bullet",
		"sk_plr_9mmAR_grenade",
		"sk_plr_rpg",
		"sk_plr_gauss",
		"sk_plr_secondarygauss",
		"sk_plr_egon_wide",
		"sk_hornet_pdmg",
		"sk_plr_hand_grenade",
		"sk_plr_satchel",
		"sk_plr_tripmine",
		"sk_plr_762_bullet",
		"sk_plr_spore",
		"sk_plr_displacer_other",
		"sk_plr_displacer_radius",
		"sk_plr_shockrifle",
		"sk_plr_shockrifle_beam",
		"sk_shockroach_dmg_xpl_touch",
		"sk_shockroach_dmg_xpl_splash"
	};


    private array<float> player_location_values = 
	{
		1.0, //sk_player_head
		1.0, //sk_player_chest
		1.0, //sk_player_stomach
		0.5, //sk_player_arm
		0.5 //sk_player_leg
	};
	

	private array<string> player_location_strings = 
	{
		"sk_player_head",
		"sk_player_chest",
		"sk_player_stomach",
		"sk_player_arm",
		"sk_player_leg"
	};


    private array<float> monster_location_values = 
	{
		3.0, //sk_monster_head
		1.0, //sk_monster_chest
		1.0, //sk_monster_stomach
		1.0, //sk_monster_arm
		1.0  //sk_monster_leg
	};
	

	private array<string> monster_location_strings = 
	{
		"sk_monster_head",
		"sk_monster_chest",
		"sk_monster_stomach",
		"sk_monster_arm",
		"sk_monster_leg"
	};
	

	void ApplyDifficultySettings()
	{   
		int iCurrentPlayers = g_Engine.maxClients; // Current amount of connected players.
		int iMinPlayers = 1; // Player minimum for full damage increase.
		int iMaxPlayers = 4; // Player limit to return to normal values.
		float flDamageBonus = 1.50f; // Total damage bonus at minimum players.
		float flTotal = 0.0f; // Total damage bonus after scaling.

		int iClampedPlayers = Math.min(iCurrentPlayers, iMaxPlayers); // Clamp to maximum.
		float flBonusScale = Math.max(0.0f, 1.0f - float(iClampedPlayers - iMinPlayers) / float(iMaxPlayers - iMinPlayers)); // Scale bonus from full at minimum players to none at maximum players.

		// Player Damage (Bonus is scaled back with number of players).
		int iMax = weapon_damage_values.size();
		for( int i = 0; i < iMax; ++i )
		{
			float flValue = weapon_damage_values[i];
			flTotal = flValue * (1.0f + (flDamageBonus * flBonusScale));
			string strStrings = weapon_damage_strings[i] + " " + flTotal + "\n";
				g_EngineFuncs.ServerCommand( strStrings );
		}
		
		// Player location damage (Currently not scaled with number of players).
		iMax = player_location_values.size();
		for( int i = 0; i < iMax; ++i )
		{
			float flValue = player_location_values[i];
			string strStrings = player_location_strings[i] + " " + flValue + "\n";
				g_EngineFuncs.ServerCommand( strStrings );
		}
		
		// Monster location damage (Currently not scaled with number of players).
		iMax = monster_location_values.size( );
		for( int i = 0; i < iMax; ++i )
		{
			float flValue = monster_location_values[i];
			string strStrings = monster_location_strings[i] + " " + flValue + "\n";
				g_EngineFuncs.ServerCommand( strStrings );
		}

		g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[CARPG - Difficulty Scaling: " + formatFloat(flTotal, "", 0, 2) + "%% Damage Bonus]\n");
	}
}