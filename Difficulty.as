/*
This is our Difficulty Settings file.

It allows us to force all skill values on load. Ensuring consistent balance no matter the map. May cause some maps to be easier or harder.
Player and Monster damage is determined by sk_ convars. 
Difficulty settings in Sven Co-op do nothing and most maps have their own map cfg, which may have sk_ values and other such settings.
Forcing them here helps keep things consistent and makes it easier to balance plugins.
*/

bool bDisableAmmoRespawns = false; // Set to true to flag all ammo entities to not respawn on a map start. WARNING: Potential to make some maps unplayable if you respawn!

ForceDifficulty g_ForceDifficulty;

void ApplyDifficultySettings()
{
    g_ForceDifficulty.ApplyDifficultySettings();
}

final class ForceDifficulty
{
	private array<float> weapon_damage_values = 
	{
		10.0, //Medkit - Default 10.
		18.0, //Crowbar - Default 15.
		25.0, //Wrench - Default 22.
		45.0, //Grapple (Barnacle) - Default 40.
		14.0, //Handgun (9mm Handgun) - Default 12.
		70.0, //357 (Deagle is 2/3 of this) - Default 66.
		13.0, //Uzi (Also Akimbo, Gold do +1 extra damage) - Default 10.
		13.0, //MP5 (9mm AR) - Default 8.
		12.0, //Buckshot (7 pellets primary, 6 pellets secondary) - Default 10.
		70.0, //Crossbow (Alt weapon mode is explosive on impact) - Default 60.
		20.0, //556 (M16/SAW/Minigun, also effects enemies damage!) - Default 12.
		150.0, //M203 (ARgrenades) - Default 100.
		200.0, //RPG - Default 150.
		22.0, //Gauss (No charge) - Default 19.
		220.0, //Secondary Guass (Max Charge) - Default 190.
		14.0, //Gluon (Egon) Gun - Default 12.
		16.0, //Hornet Gun - Default 12.
		150.0, //Hand Grenade - Default 100.
		180.0, //Satchel - Default 160.
		200.0, //Tripmine - Default 150.
		120.0, //762 (Sniper Rifle) - Default 110.
		100.0, //Spore Launcher - Default 100.
		300.0, //Displacer (Primary) - Default 250.
		300.0, //Displacer Radius - Default 300.
		26.0, //Shockrifle (Primary) - Default 15.
		8.0, //Shockrifle (Beam) - Default 2 (x3? I think it does this damage per beam that connects).
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


	private array<float> monster_damage_values = 
	{
		150.0, // sk_agrunt_health
		20.0, // sk_agrunt_dmg_punch - Default 15
		256.0, // sk_agrunt_melee_engage_distance
		25.0, // sk_agrunt_berserker_dmg_punch - Default 20
		500.0, // sk_apache_health
		50.0, // sk_barnacle_health
		15.0, // sk_barnacle_bite - Default 15
		65.0, // sk_barney_health
		150.0, // sk_bullsquid_health - Default 110
		20.0, // sk_bullsquid_dmg_bite - Default 10
		45.0, // sk_bullsquid_dmg_whip - Default 25
		20.0, // sk_bullsquid_dmg_spit - Default 10
		1.0, // sk_bigmomma_health_factor
		50.0, // sk_bigmomma_dmg_slash - Default 50
		100.0, // sk_bigmomma_dmg_blast - Default 100
		260.0, // sk_bigmomma_radius_blast
		1000.0, // sk_gargantua_health
		30.0, // sk_gargantua_dmg_slash - Default 30
		8.0, // sk_gargantua_dmg_fire - Default 4
		100.0, // sk_gargantua_dmg_stomp - Default 100
		50.0, // sk_hassassin_health
		50.0, // sk_headcrab_health - Default 20
		30.0, // sk_headcrab_dmg_bite - Default 10
		100.0, // sk_hgrunt_health
		40.0, // sk_hgrunt_kick - Default 15?
		500.0, // sk_hgrunt_gspeed
		100.0, // sk_houndeye_health - Default 50
		15.0, // sk_houndeye_dmg_blast - Default 10
		80.0, // sk_islave_health
		20.0, // sk_islave_dmg_claw - Default 10
		20.0, // sk_islave_dmg_clawrake - Default 10
		18.0, // sk_islave_dmg_zap - Default 10
		350.0, // sk_ichthyosaur_health
		30.0, // sk_ichthyosaur_shake
		3.0, // sk_leech_health
		5.0, // sk_leech_dmg_bite
		100.0, // sk_controller_health
		10.0, // sk_controller_dmgzap - Default 5
		900.0, // sk_controller_speedball
		8.0, // sk_controller_dmgball - Default 5
		900.0, // sk_nihilanth_health
		30.0, // sk_nihilanth_zap
		50.0, // sk_scientist_health
		2.0, // sk_snark_health
		10.0, // sk_snark_dmg_bite - Default 5 or 10?
		5.0, // sk_snark_dmg_pop - Default 5?
		150.0, // sk_zombie_health
		20.0, // sk_zombie_dmg_one_slash - Default 10
		30.0, // sk_zombie_dmg_both_slash - Default 20
		200.0, // sk_turret_health
		80.0, // sk_miniturret_health
		80.0, // sk_sentry_health
		600.0, // sk_babygargantua_health
		30.0, // sk_babygargantua_dmg_slash
		4.0, // sk_babygargantua_dmg_fire
		50.0, // sk_babygargantua_dmg_stomp
		200.0, // sk_hwgrunt_health
		100.0, // sk_rgrunt_explode
		50.0, // sk_massassin_sniper
		65.0, // sk_otis_health
		150.0, // sk_zombie_barney_health
		20.0, // sk_zombie_barney_dmg_one_slash - Default 10
		30.0, // sk_zombie_barney_dmg_both_slash - Default 20
		180.0, // sk_zombie_soldier_health
		25.0, // sk_zombie_soldier_dmg_one_slash - Default 10
		35.0, // sk_zombie_soldier_dmg_both_slash - Default 20
		250.0, // sk_gonome_health - Default 200.0
		15.0, // sk_gonome_dmg_one_slash - Default 5
		20.0, // sk_gonome_dmg_guts - Default 5
		15.0, // sk_gonome_dmg_one_bite - Default 5
		100.0, // sk_pitdrone_health - Default 50
		20.0, // sk_pitdrone_dmg_bite - Default 10
		20.0, // sk_pitdrone_dmg_whip - Default 10
		20.0, // sk_pitdrone_dmg_spit - Default 10
		200.0, // sk_shocktrooper_health
		40.0, // sk_shocktrooper_kick - Default 12
		12.0, // sk_shocktrooper_maxcharge
		800.0, // sk_tor_health
		30.0, // sk_tor_punch
		3.0, // sk_tor_energybeam
		15.0, // sk_tor_sonicblast
		500.0, // sk_voltigore_health
		30.0, // sk_voltigore_dmg_punch - Default 30.
		50.0, // sk_voltigore_dmg_beam
		750.0, // sk_tentacle
		600.0, // sk_blkopsosprey
		600.0, // sk_osprey
		125.0, // sk_stukabat
		20.0, // sk_stukabat_dmg_bite
		50.0, // sk_sqknest_health
		500.0, // sk_kingpin_health - Default 450.0
		20.0, // sk_kingpin_lightning
		15.0, // sk_kingpin_tele_blast
		50.0, // sk_kingpin_plasma_blast
		30.0, // sk_kingpin_melee
		500.0 // sk_kingpin_telefrag
	};


    private array<string> monster_damage_strings = 
	{
		"sk_agrunt_health",
		"sk_agrunt_dmg_punch",
		"sk_agrunt_melee_engage_distance",
		"sk_agrunt_berserker_dmg_punch",
		"sk_apache_health",
		"sk_barnacle_health",
		"sk_barnacle_bite",
		"sk_barney_health",
		"sk_bullsquid_health",
		"sk_bullsquid_dmg_bite",
		"sk_bullsquid_dmg_whip",
		"sk_bullsquid_dmg_spit",
		"sk_bigmomma_health_factor",
		"sk_bigmomma_dmg_slash",
		"sk_bigmomma_dmg_blast",
		"sk_bigmomma_radius_blast",
		"sk_gargantua_health",
		"sk_gargantua_dmg_slash",
		"sk_gargantua_dmg_fire",
		"sk_gargantua_dmg_stomp",
		"sk_hassassin_health",
		"sk_headcrab_health",
		"sk_headcrab_dmg_bite",
		"sk_hgrunt_health",
		"sk_hgrunt_kick",
		"sk_hgrunt_gspeed",
		"sk_houndeye_health",
		"sk_houndeye_dmg_blast",
		"sk_islave_health",
		"sk_islave_dmg_claw",
		"sk_islave_dmg_clawrake",
		"sk_islave_dmg_zap",
		"sk_ichthyosaur_health",
		"sk_ichthyosaur_shake",
		"sk_leech_health",
		"sk_leech_dmg_bite",
		"sk_controller_health",
		"sk_controller_dmgzap",
		"sk_controller_speedball",
		"sk_controller_dmgball",
		"sk_nihilanth_health",
		"sk_nihilanth_zap",
		"sk_scientist_health",
		"sk_snark_health",
		"sk_snark_dmg_bite",
		"sk_snark_dmg_pop",
		"sk_zombie_health",
		"sk_zombie_dmg_one_slash",
		"sk_zombie_dmg_both_slash",
		"sk_turret_health",
		"sk_miniturret_health",
		"sk_sentry_health",
		"sk_babygargantua_health",
		"sk_babygargantua_dmg_slash",
		"sk_babygargantua_dmg_fire",
		"sk_babygargantua_dmg_stomp",
		"sk_hwgrunt_health",
		"sk_rgrunt_explode",
		"sk_massassin_sniper",
		"sk_otis_health",
		"sk_zombie_barney_health",
		"sk_zombie_barney_dmg_one_slash",
		"sk_zombie_barney_dmg_both_slash",
		"sk_zombie_soldier_health",
		"sk_zombie_soldier_dmg_one_slash",
		"sk_zombie_soldier_dmg_both_slash",
		"sk_gonome_health",
		"sk_gonome_dmg_one_slash",
		"sk_gonome_dmg_guts",
		"sk_gonome_dmg_one_bite",
		"sk_pitdrone_health",
		"sk_pitdrone_dmg_bite",
		"sk_pitdrone_dmg_whip",
		"sk_pitdrone_dmg_spit",
		"sk_shocktrooper_health",
		"sk_shocktrooper_kick",
		"sk_shocktrooper_maxcharge",
		"sk_tor_health",
		"sk_tor_punch",
		"sk_tor_energybeam",
		"sk_tor_sonicblast",
		"sk_voltigore_health",
		"sk_voltigore_dmg_punch",
		"sk_voltigore_dmg_beam",
		"sk_tentacle",
		"sk_blkopsosprey",
		"sk_osprey",
		"sk_stukabat",
		"sk_stukabat_dmg_bite",
		"sk_sqknest_health",
		"sk_kingpin_health",
		"sk_kingpin_lightning",
		"sk_kingpin_tele_blast",
		"sk_kingpin_plasma_blast",
		"sk_kingpin_melee",
		"sk_kingpin_telefrag"
	};


	private array<float> monster_damage_values_bullet = {
		8, // sk_12mm_bullet - Default 8
		4, // sk_9mmAR_bullet - Default 3
		4, // sk_9mm_bullet - Default 3
		8, // sk_hornet_dmg - Default 8
		34, // sk_otis_bullet - Default 34
		4, // sk_grunt_buckshot - Default 3
		20 // sk_556_bullet - Default 12
	};


	private array<string> monster_damage_strings_bullet = {
		"sk_12mm_bullet",
		"sk_9mmAR_bullet",
		"sk_9mm_bullet",
		"sk_hornet_dmg",
		"sk_otis_bullet",
		"sk_grunt_buckshot",
		"sk_556_bullet"
	};


    private array<float> player_location_values = {
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

		//Player Damage
		int iMax = weapon_damage_values.size();
		for( int i = 0; i < iMax; ++i )
		{
			float flValue = weapon_damage_values[i];
			string strStrings = weapon_damage_strings[i] + " " + flValue + "\n";
			g_EngineFuncs.ServerCommand( strStrings );
		}
        //Monster Damage
		iMax = monster_damage_values.size();
		for( int i = 0; i < iMax; ++i )
		{
			float flValue = monster_damage_values[i];
			string strStrings = monster_damage_strings[i] + " " + flValue + "\n";
			g_EngineFuncs.ServerCommand( strStrings );
		}

		//Monster Damage Bullet
		iMax = monster_damage_values_bullet.size();
		for( int i = 0; i < iMax; ++i )
		{
			float flValue = monster_damage_values_bullet[i];
			string strStrings = monster_damage_strings_bullet[i] + " " + flValue + "\n";
			g_EngineFuncs.ServerCommand( strStrings );
		}
		
		//Player location damage
		iMax = player_location_values.size();
		for( int i = 0; i < iMax; ++i )
		{
			float flValue = player_location_values[i];
			string strStrings = player_location_strings[i] + " " + flValue + "\n";
			g_EngineFuncs.ServerCommand( strStrings );
		}
		
		//Monster location damage
		iMax = monster_location_values.size( );
		for( int i = 0; i < iMax; ++i )
		{
			float flValue = monster_location_values[i];
			string strStrings = monster_location_strings[i] + " " + flValue + "\n";
			g_EngineFuncs.ServerCommand( strStrings );
		}
	}
}