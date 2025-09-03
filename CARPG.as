/*
My personal crack at writing an RPG mod for Sven Co-op from the ground up, to replace the SCXPM style mods.
This plugin uses a class based system with singular abilities and passives similar to killing floor.
Attempts to strike a better balance than other RPG mods. Whilst featuring tons of classes each with a unique ability.
In order to keep gameplay similar to vanilla Sven Co-op.

All aspects of classes abilities and passives scale directly with class level.
Classes XP/Level is saved independently, all classes must be leveled to the cap individually.

Player damage dealt is reworked, some enemies are now more deadly.
Players passively recover health and armor at a fixed rate after a delay, if damaged.
Armor recovers much faster than health.

Credit to Johnnboy his RPG mod as inspiration for learning and also some of his coding logic is used for PlayerData.

Credit to Namira, Zebigdt and Mister Copper for testing, as well as class and ability ideas.

Thanks for letting me annoy the shit out of you all by tweaking.

This is our core file. Hooks, timers, initialisations of functions.
*/


// Includes now all in one file.
#include "Includes"

// Add near the top with other globals.
array<string> g_DevList = 
{
    "STEAM_0:1:21530096" // Unlike file structure, must use actual STEAM ID format.
};

Menu::DebugMenu g_DebugMenu;

// Check Devs list.
bool IsDev(const string& in steamID)
{
    for(uint i = 0; i < g_DevList.length(); i++)
    {
        if(steamID == g_DevList[i])
            return true;
    }
    return false;
}

// Timers, precaches, and hook handling go here.
void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor("ChaoticAkantor");
    g_Module.ScriptInfo.SetContactInfo("None");

    PluginReset(); // Call a full reset whenever plugin is initialised or reloaded.
}

void MapInit() // When a new map is started, all scripts are initialized by calling their MapInit function.
{
    PrecacheAll(); // Precache our models, sounds and sprites.
    //PluginReset(); // Reset all plugin data when a new map is loaded.
}

void MapActivate() // Like MapInit, only called after all mapper placed entities have been activated and the sound list has been written.
{

}

void MapStart() // Called after 0.1 seconds of game activity, this is used to simplify the triggering on map start.
{
    // Startup console message so we know it is installed.
    g_Game.AlertMessage(at_console, "=== CARPG Enabled! ===\n");

    // Hints to play on map load.
    g_Scheduler.SetTimeout("ShowHints", 5.0f); // Show hints X seconds after map load.
}

void PluginReset() // Used to reset anything important to the plugin on reload.
{
    g_Scheduler.ClearTimerList(); // Clear all timers.
    //RemoveHooks(); // Remove Hooks.

    // Clear all dictionaries.
    g_PlayerRPGData.deleteAll();
    g_PlayerMinions.deleteAll();
    g_XenologistMinions.deleteAll();
    g_PlayerSentries.deleteAll();
    g_HealingAuras.deleteAll();
    g_PlayerBarriers.deleteAll();
    g_PlayerBloodlusts.deleteAll();
    g_PlayerCloaks.deleteAll();
    g_PlayerExplosiveRounds.deleteAll();
    g_ShockRifleData.deleteAll();
    g_PlayerClassResources.deleteAll();
    g_PlayerSnarkNests.deleteAll();
    
    RegisterHooks(); // Re-register Hooks.
    InitializeAmmoRegen(); // Re-apply ammo types for ammo recovery.
    SetupTimers(); // Re-setup timers.
    ApplyDifficultySettings(); // Re-apply difficulty settings.
}

void RegisterHooks()
{
    g_Hooks.RegisterHook(Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage);
    g_Hooks.RegisterHook(Hooks::Weapon::WeaponPrimaryAttack, @OnWeaponPrimaryAttack);
    g_Hooks.RegisterHook(Hooks::Weapon::WeaponSecondaryAttack, @OnWeaponSecondaryAttack);
    g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @OnClientPutInServer);
    g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @OnClientDisconnect);
    g_Hooks.RegisterHook(Hooks::Player::ClientSay, @ClientSay);
    g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @PlayerRespawn);
    g_Hooks.RegisterHook(Hooks::Monster::MonsterTakeDamage, @MonsterTakeDamage);
}

void RemoveHooks()
{
    g_Hooks.RemoveHook(Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage);
    g_Hooks.RemoveHook(Hooks::Weapon::WeaponPrimaryAttack, @OnWeaponPrimaryAttack);
    g_Hooks.RemoveHook(Hooks::Weapon::WeaponSecondaryAttack, @OnWeaponSecondaryAttack);
    g_Hooks.RemoveHook(Hooks::Player::ClientPutInServer, @OnClientPutInServer);
    g_Hooks.RemoveHook(Hooks::Player::ClientDisconnect, @OnClientDisconnect);
    g_Hooks.RemoveHook(Hooks::Player::ClientSay, @ClientSay);
    g_Hooks.RemoveHook(Hooks::Player::PlayerSpawn, @PlayerRespawn);
    g_Hooks.RemoveHook(Hooks::Monster::MonsterTakeDamage, @MonsterTakeDamage);
}

void SetupTimers()
{
    g_Scheduler.ClearTimerList(); // Always clear timers first before setting them up again.

    // Ammo Recovery System.
    g_Scheduler.SetInterval("AmmoTimerTick", flAmmoTick, g_Scheduler.REPEAT_INFINITE_TIMES); // Schedule timer for ammo recovery system.

    // HP/AP Recovery System.
    g_Scheduler.SetInterval("RegenTickHP", flRegenTickHP, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for HP regen.
    g_Scheduler.SetInterval("RegenTickAP", flRegenTickAP, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for AP regen.
    g_Scheduler.SetInterval("HurtDelayTick", flHurtDelayTick, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for hurt delay.
    g_Scheduler.SetInterval("UpdateHUDHurtDelay", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for HUD display.

    // Resource System.
    g_Scheduler.SetInterval("RegenClassResource", flClassResourceRegenDelay, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for class resource regen.
    g_Scheduler.SetInterval("UpdateClassResource", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for class resource display.

    // RPG/Class System.
    g_Scheduler.SetInterval("UpdatePlayerHUDs", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for updating RPG HUD.
    g_Scheduler.SetInterval("CheckAllPlayerScores", 0.5f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for XP system.

    // Medic.
    g_Scheduler.SetInterval("CheckHealAura", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for checking heal aura.

    // Engineer.
    g_Scheduler.SetInterval("CheckSentries", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for checking engineer sentries.

    g_Scheduler.SetInterval("CheckEngineerMinions", 1.0f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for checking engineer Robogrunts.

    // Xenologist.
    g_Scheduler.SetInterval("CheckXenologistMinions", 1.0f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for checking Xenologist minions.

    // Defender.
    g_Scheduler.SetInterval("CheckBarrier", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for checking Barrier.

    // Berserker.
    g_Scheduler.SetInterval("UpdateBloodlusts", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES);

    // Cloaker.
    g_Scheduler.SetInterval("UpdateCloaks", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES);
    
    // Swarmer.
    g_Scheduler.SetInterval("CheckSnarkNests", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES);
}

void PrecacheAll()
{
    // CARPG Systems Precache.
        // Sounds.
        g_SoundSystem.PrecacheSound(strLevelUpSound);
        g_SoundSystem.PrecacheSound(strClassChangeSound);

    // Medic Ability Precache.
        // Models/Sprites.
        g_Game.PrecacheModel(strHealAuraSprite);
        g_Game.PrecacheModel(strHealAuraEffectSprite);
        g_Game.PrecacheModel(strHealAuraPoisonEffectSprite);

        // Sounds.
        g_SoundSystem.PrecacheSound(strHealAuraToggleSound);
        g_SoundSystem.PrecacheSound(strHealAuraActiveSound);
        g_SoundSystem.PrecacheSound(strHealSound);


    // Xenomancer Ability Precache.
        // Sounds.
        g_SoundSystem.PrecacheSound(strXenMinionSoundCreate);

    // Shocktrooper Ability Precache.
        // Sounds.
        g_SoundSystem.PrecacheSound(strShockrifleEquipSound);

    // Berserker Ability Precache.
        // Models/Sprites.
        g_Game.PrecacheModel(strBloodlustSprite);

        // Sounds.
        g_SoundSystem.PrecacheSound(strBloodlustStartSound);
        g_SoundSystem.PrecacheSound(strBloodlustEndSound);
        g_SoundSystem.PrecacheSound(strBloodlustActiveSound);
        g_SoundSystem.PrecacheSound(strBloodlustHitSound);

    // Defender Ability Precache.
        // Models/Sprites.
        g_Game.PrecacheModel(strBarrierBeamSprite);
        
        // Sounds.
        g_SoundSystem.PrecacheSound(strBarrierToggleSound);
        g_SoundSystem.PrecacheSound(strBarrierHitSound);
        g_SoundSystem.PrecacheSound(strBarrierBreakSound);
        g_SoundSystem.PrecacheSound(strBarrierActiveSound);

    // Cloaker Ability Precache.
        // Sounds.
        g_SoundSystem.PrecacheSound(strCloakActivateSound);
        g_SoundSystem.PrecacheSound(strCloakActiveSound);

    // Vanquisher Class Precache.
        // Models/Sprites.
    g_Game.PrecacheModel(strExplosiveRoundsExplosionSprite);
    g_Game.PrecacheModel(strExplosiveRoundsExplosionCoreSprite);
    g_Game.PrecacheModel(strExplosiveRoundsSplatterSprite);

        // Sounds.
    g_SoundSystem.PrecacheSound(strExplosiveRoundsActivateSound);
    g_SoundSystem.PrecacheSound(strExplosiveRoundsImpactSound);

    // Precache for all spawnable NPC's.
    // Sentry.
        // Models/Sprites.
        g_Game.PrecacheModel(strSentryModel);
        g_Game.PrecacheModel(strSentryGibs);

        // Sounds.
        g_SoundSystem.PrecacheSound(strSentryCreate);
        g_SoundSystem.PrecacheSound(strSentryRecall);
        g_SoundSystem.PrecacheSound(strSentryFire);
        g_SoundSystem.PrecacheSound(strSentryPing);
        g_SoundSystem.PrecacheSound(strSentryActive);
        g_SoundSystem.PrecacheSound(strSentryDie);
        g_SoundSystem.PrecacheSound(strSentryDeploy);
        g_SoundSystem.PrecacheSound(strSentrySpinUp);
        g_SoundSystem.PrecacheSound(strSentrySpinDown);
        g_SoundSystem.PrecacheSound(strSentrySearch);
        g_SoundSystem.PrecacheSound(strSentryAlert);

    // Robogrunt.
        // Models/Sprites.
        g_Game.PrecacheModel(strRobogruntModel);
        g_Game.PrecacheModel(strRobogruntModelF);
        g_Game.PrecacheModel(strRobogruntRope);
        g_Game.PrecacheModel(strRobogruntModelChromegibs);
        g_Game.PrecacheModel(strRobogruntModelComputergibs);

        // Sounds.
        g_SoundSystem.PrecacheSound(strRobogruntSoundDeath);
        g_SoundSystem.PrecacheSound(strRobogruntSoundDeath2);
        g_SoundSystem.PrecacheSound(strRobogruntSoundButton2);
        g_SoundSystem.PrecacheSound(strRobogruntSoundButton3);
        g_SoundSystem.PrecacheSound(strRobogruntSoundBeam);
        g_SoundSystem.PrecacheSound(strRobogruntSoundCreate);
        g_SoundSystem.PrecacheSound(strRobogruntSoundRepair);
        g_SoundSystem.PrecacheSound(strRobogruntSoundKick);
        g_SoundSystem.PrecacheSound(strRobogruntSoundMP5);
        g_SoundSystem.PrecacheSound(strRobogruntSoundM16);
        g_SoundSystem.PrecacheSound(strRobogruntSoundReload);

    // Houndeye.
        // Models/Sprites.
        g_Game.PrecacheModel(strHoundeyeModel);
        g_Game.PrecacheModel(strHoundeyeSpriteShockwave);

        // Sounds.
        g_SoundSystem.PrecacheSound(strHoundeyeSoundAlert1);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundAlert2);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundAlert3);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundAttack1);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundAttack2);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundAttack3);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundBlast1);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundBlast2);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundBlast3);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundDie1);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundDie2);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundDie3);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundHunt1);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundHunt2);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundHunt3);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundHunt4);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundIdle1);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundIdle2);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundIdle3);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundIdle4);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundPain1);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundPain2);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundPain3);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundPain4);
        g_SoundSystem.PrecacheSound(strHoundeyeSoundPain5);

    // Pitdrone.
        // Models/Sprites.
        g_Game.PrecacheModel(strPitdroneModel);
        g_Game.PrecacheModel(strPitdroneModelGibs);
        g_Game.PrecacheModel(strPitdroneModelSpike);
        g_Game.PrecacheModel(strPitdroneSpikeTrail);

        // Sounds.
        g_SoundSystem.PrecacheSound(strPitdroneSoundAttackSpike1);
        g_SoundSystem.PrecacheSound(strPitdroneSoundAlert1);
        g_SoundSystem.PrecacheSound(strPitdroneSoundAlert2);
        g_SoundSystem.PrecacheSound(strPitdroneSoundAlert3);
        g_SoundSystem.PrecacheSound(strPitdroneSoundIdle1);
        g_SoundSystem.PrecacheSound(strPitdroneSoundIdle2);
        g_SoundSystem.PrecacheSound(strPitdroneSoundIdle3);
        g_SoundSystem.PrecacheSound(strPitdroneSoundDie1);
        g_SoundSystem.PrecacheSound(strPitdroneSoundDie2);
        g_SoundSystem.PrecacheSound(strPitdroneSoundDie3);
        g_SoundSystem.PrecacheSound(strPitdroneSoundBite2);
        g_SoundSystem.PrecacheSound(strPitdroneSoundPain1);
        g_SoundSystem.PrecacheSound(strPitdroneSoundPain2);
        g_SoundSystem.PrecacheSound(strPitdroneSoundPain3);
        g_SoundSystem.PrecacheSound(strPitdroneSoundPain4);
        g_SoundSystem.PrecacheSound(strPitdroneSoundMelee1);
        g_SoundSystem.PrecacheSound(strPitdroneSoundMelee2);
        g_SoundSystem.PrecacheSound(strPitdroneSoundEat);

    // Bullsquid
        // Models/Sprites.
        g_Game.PrecacheModel(strBullsquidModel);
        g_Game.PrecacheModel(strBullsquidSpriteTinyspit);
        g_Game.PrecacheModel(strBullsquidSpriteBigspit);

        // Sounds.
        g_SoundSystem.PrecacheSound(strBullsquidAcid1);
        g_SoundSystem.PrecacheSound(strBullsquidAcid2);
        g_SoundSystem.PrecacheSound(strBullsquidAttack1);
        g_SoundSystem.PrecacheSound(strBullsquidAttack2);
        g_SoundSystem.PrecacheSound(strBullsquidAttack3);
        g_SoundSystem.PrecacheSound(strBullsquidAttackGrowl);
        g_SoundSystem.PrecacheSound(strBullsquidAttackGrowl2);
        g_SoundSystem.PrecacheSound(strBullsquidAttackGrowl3);
        g_SoundSystem.PrecacheSound(strBullsquidBite1);
        g_SoundSystem.PrecacheSound(strBullsquidBite2);
        g_SoundSystem.PrecacheSound(strBullsquidBite3);
        g_SoundSystem.PrecacheSound(strBullsquidDie1);
        g_SoundSystem.PrecacheSound(strBullsquidDie2);
        g_SoundSystem.PrecacheSound(strBullsquidDie3);
        g_SoundSystem.PrecacheSound(strBullsquidIdle1);
        g_SoundSystem.PrecacheSound(strBullsquidIdle2);
        g_SoundSystem.PrecacheSound(strBullsquidIdle3);
        g_SoundSystem.PrecacheSound(strBullsquidIdle4);
        g_SoundSystem.PrecacheSound(strBullsquidIdle5);
        g_SoundSystem.PrecacheSound(strBullsquidSoundPain1);
        g_SoundSystem.PrecacheSound(strBullsquidSoundPain2);
        g_SoundSystem.PrecacheSound(strBullsquidSoundPain3);
        g_SoundSystem.PrecacheSound(strBullsquidSoundPain4);
        g_SoundSystem.PrecacheSound(strBullsquidSpithit1);
        g_SoundSystem.PrecacheSound(strBullsquidSpithit2);
        g_SoundSystem.PrecacheSound(strBullsquidSpithit3);

    // Shocktrooper.
        // Models/Sprites.
        g_Game.PrecacheModel(strShocktrooperModel);
        g_Game.PrecacheModel(strShocktrooperModelGibs);
        g_Game.PrecacheModel(strShocktrooperSpriteMuzzleshock);

        // Sounds.
        g_SoundSystem.PrecacheSound(strShocktrooperBlis);
        g_SoundSystem.PrecacheSound(strShocktrooperDit);
        g_SoundSystem.PrecacheSound(strShocktrooperDup);
        g_SoundSystem.PrecacheSound(strShocktrooperGa);
        g_SoundSystem.PrecacheSound(strShocktrooperHyu);
        g_SoundSystem.PrecacheSound(strShocktrooperKa);
        g_SoundSystem.PrecacheSound(strShocktrooperKiml);
        g_SoundSystem.PrecacheSound(strShocktrooperKss);
        g_SoundSystem.PrecacheSound(strShocktrooperKu);
        g_SoundSystem.PrecacheSound(strShocktrooperKur);
        g_SoundSystem.PrecacheSound(strShocktrooperKyur);
        g_SoundSystem.PrecacheSound(strShocktrooperMub);
        g_SoundSystem.PrecacheSound(strShocktrooperPuh);
        g_SoundSystem.PrecacheSound(strShocktrooperPur);
        g_SoundSystem.PrecacheSound(strShocktrooperRas);
        g_SoundSystem.PrecacheSound(strShocktrooperThirv);
        g_SoundSystem.PrecacheSound(strShocktrooperWirt);
        g_SoundSystem.PrecacheSound(strShocktrooperFire);
        g_SoundSystem.PrecacheSound(strShocktrooperAttack);
        g_SoundSystem.PrecacheSound(strShocktrooperDie1);
        g_SoundSystem.PrecacheSound(strShocktrooperDie2);
        g_SoundSystem.PrecacheSound(strShocktrooperDie3);
        g_SoundSystem.PrecacheSound(strShocktrooperDie4);
        g_SoundSystem.PrecacheSound(strShocktrooperPain1);
        g_SoundSystem.PrecacheSound(strShocktrooperPain2);
        g_SoundSystem.PrecacheSound(strShocktrooperPain3);
        g_SoundSystem.PrecacheSound(strShocktrooperPain4);
        g_SoundSystem.PrecacheSound(strShocktrooperPain5);

    // Baby Gargantua.
        //Models/Sprites.
        g_Game.PrecacheModel(strBabyGargModel);
        g_Game.PrecacheModel(strBabyGargSpriteEye);
        g_Game.PrecacheModel(strBabyGargSpriteBeam);

        // Sounds.

/*  Had to disable Alien Grunt for now as the hornets it fires aren't owned by it, 
    so you gain no XP from score transfer as it doesn't gain any score.
    Known bug, hopefully fixed in the next Sven update.

    // Alien Grunt.
        // Models/Sprites.
        g_Game.PrecacheModel(strAlienGruntModel);
        g_Game.PrecacheModel(strAlienGruntModelGibs);
        g_Game.PrecacheModel(strAlienGruntMuzzleFlash);

        // Sounds.
        g_SoundSystem.PrecacheSound(strAlienGruntSoundIdle1);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundIdle2);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundIdle3);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundIdle4);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundDie1);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundDie4);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundDie5);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundPain1);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundPain2);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundPain3);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundPain4);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundPain5);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundAttack1);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundAttack2);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundAttack3);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundAlert1);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundAlert3);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundAlert4);
        g_SoundSystem.PrecacheSound(strAlienGruntSoundAlert5);
*/

/* -- Will be used on a seperate class for zombie family.
    // Gonome.
        // Models/Sprites.
        g_Game.PrecacheModel(strGonomeModel);
        g_Game.PrecacheModel(strGonomeSpriteSpit);

        // Sounds.
        g_SoundSystem.PrecacheSound(strGonomeSoundSpit1);
        g_SoundSystem.PrecacheSound(strGonomeSoundDeath2);
        g_SoundSystem.PrecacheSound(strGonomeSoundDeath3);
        g_SoundSystem.PrecacheSound(strGonomeSoundDeath4);
        g_SoundSystem.PrecacheSound(strGonomeSoundIdle1);
        g_SoundSystem.PrecacheSound(strGonomeSoundIdle2);
        g_SoundSystem.PrecacheSound(strGonomeSoundIdle3);
        g_SoundSystem.PrecacheSound(strGonomeSoundPain1);
        g_SoundSystem.PrecacheSound(strGonomeSoundPain3);
        g_SoundSystem.PrecacheSound(strGonomeSoundPain4);
        g_SoundSystem.PrecacheSound(strGonomeSoundMelee1);
        g_SoundSystem.PrecacheSound(strGonomeSoundMelee2);
        g_SoundSystem.PrecacheSound(strGonomeSoundRun);
        g_SoundSystem.PrecacheSound(strGonomeSoundEat);
    */

    /* -- Unused Mortar Strike Ability.
        // Sounds.
    //g_SoundSystem.PrecacheSound(strMortarStrikeLaunchSound);
    //g_SoundSystem.PrecacheSound(strMortarStrikeAirSound);
    //g_SoundSystem.PrecacheSound(strMortarStrikeSetSound);
    //g_SoundSystem.PrecacheSound(strMortarStrikeChargeSound);
    //g_SoundSystem.PrecacheSound(strMortarStrikeImpactSound);

        // Models/Sprites.
    //g_Game.PrecacheModel(strMortarStrikeTargetSprite);
    //g_Game.PrecacheModel(strMortarStrikeImpactSprite);
    //g_Game.PrecacheModel(strMortarStrikeSmokeSprite);
    //g_Game.PrecacheModel(strMortarStrikeGlowSprite);
    */
}

// Hook handler for Primary Attack.
HookReturnCode OnWeaponPrimaryAttack(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon) 
{
    if(pWeapon is null || pPlayer is null || pWeapon.m_iClip <= 0) // Make sure clip is not empty.
        return HOOK_CONTINUE;
    
    string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(g_PlayerExplosiveRounds.exists(steamId))
    {
        ExplosiveRoundsData@ explosiveRounds = cast<ExplosiveRoundsData@>(g_PlayerExplosiveRounds[steamId]);
        if(explosiveRounds !is null && explosiveRounds.HasRounds())
        {
            explosiveRounds.FireExplosiveRounds(pPlayer, pWeapon); // Consume rounds and fire explosive shots if active.
        }
    }
    
    return HOOK_CONTINUE;
}

// Hook handler for Secondary Attack.
HookReturnCode OnWeaponSecondaryAttack(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon) 
{
    if(pWeapon is null || pPlayer is null || pWeapon.m_iClip <= 0 && pWeapon.m_iClip2 != -1 ) // Check if clip is not empty and clip2 isn't infinite.
        return HOOK_CONTINUE;

    string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    string SecondaryWeaponName = pWeapon.pev.classname;
    if(SecondaryWeaponName == "weapon_shotgun" || SecondaryWeaponName == "weapon_9mmhandgun" || SecondaryWeaponName == "weapon_sawedoff")
    {
        if(g_PlayerExplosiveRounds.exists(steamId))
        {
            ExplosiveRoundsData@ explosiveRounds = cast<ExplosiveRoundsData@>(g_PlayerExplosiveRounds[steamId]);
            if(explosiveRounds !is null && explosiveRounds.HasRounds())
            {
                explosiveRounds.FireExplosiveRounds(pPlayer, pWeapon); // Consume rounds and fire explosive shots if active.
            }
        }
    }
    
    return HOOK_CONTINUE;
}

HookReturnCode MonsterTakeDamage(DamageInfo@ info) // Class weapon and minion damage scaling is done here.
{
    if(info is null || info.pVictim is null || info.pAttacker is null)
        return HOOK_CONTINUE;

    // Check if attacker is a minion.
    CBaseEntity@ attacker = info.pAttacker;
    string targetname = string(attacker.pev.targetname);

    if(targetname.StartsWith("_sentry_"))
    {
        string ownerIndex = targetname.SubString(8);
        if(ownerIndex.IsEmpty())
            return HOOK_CONTINUE;

        CBasePlayer@ pOwner = g_PlayerFuncs.FindPlayerByIndex(atoi(ownerIndex));
        if(pOwner is null || !pOwner.IsConnected())
            return HOOK_CONTINUE;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pOwner.edict());
        if(steamID.IsEmpty() || !g_PlayerSentries.exists(steamID))
            return HOOK_CONTINUE;

        SentryData@ sentry = cast<SentryData@>(g_PlayerSentries[steamID]);
        if(sentry is null)
            return HOOK_CONTINUE;

        // Apply damage multiplier.
        float damageSentryMultiplier = 1.0f + sentry.GetScaledDamage();
        info.flDamage *= damageSentryMultiplier;

        // Sentry enhancement, change damage type. Doesn't seem to make armor damagable.
        //if(sentry.HasStats() && sentry.GetStats().HasUnlockedEnhancement3())
        //{
        //    info.bitsDamageType |= DMG_RADIATION; // Add AP damage type.
        //}
    }
    else if(targetname.StartsWith("_minion_"))
    {
        // Find owner's MinionData by the index in targetname.
        string ownerIndex = targetname.SubString(8); // Look specifically for only targetnames with indexes added.
        if(ownerIndex.IsEmpty())
            return HOOK_CONTINUE;
            
        CBasePlayer@ pOwner = g_PlayerFuncs.FindPlayerByIndex(atoi(ownerIndex));
        if(pOwner is null || !pOwner.IsConnected())
            return HOOK_CONTINUE;
            
        string steamID = g_EngineFuncs.GetPlayerAuthId(pOwner.edict());
        if(steamID.IsEmpty() || !g_PlayerMinions.exists(steamID))
            return HOOK_CONTINUE;
            
        MinionData@ minion = cast<MinionData@>(g_PlayerMinions[steamID]);
        if(minion is null)
            return HOOK_CONTINUE;
            
        // Apply the damage multiplier.
        float damageRoboMultiplier = 1.0f + minion.GetScaledDamage();
        info.flDamage *= damageRoboMultiplier;
    }
    else if(targetname.StartsWith("_xenminion_"))
    {
        // Find owner's XenMinionData by the index in targetname
        string ownerIndex = targetname.SubString(11); // Look specifically for only targetnames with indexes added.
        if(ownerIndex.IsEmpty())
            return HOOK_CONTINUE;
            
        CBasePlayer@ pOwner = g_PlayerFuncs.FindPlayerByIndex(atoi(ownerIndex));
        if(pOwner is null || !pOwner.IsConnected())
            return HOOK_CONTINUE;
            
        string steamID = g_EngineFuncs.GetPlayerAuthId(pOwner.edict());
        if(steamID.IsEmpty() || !g_XenologistMinions.exists(steamID))
            return HOOK_CONTINUE;
            
        XenMinionData@ xenMinion = cast<XenMinionData@>(g_XenologistMinions[steamID]);
        if(xenMinion is null)
            return HOOK_CONTINUE;
            
        // Apply the damage multiplier.
        float damageXenMultiplier = 1.0f + xenMinion.GetScaledDamage();
        info.flDamage *= damageXenMultiplier;

        // Process lifesteal - when xenminion deals damage, give health to owner
        xenMinion.ProcessMinionDamage(pOwner, info.flDamage);
    }
    else if(targetname.StartsWith("_snark_"))
    {
        // Find owner's player index from targetname.
        string targetStr = targetname.SubString(7); // Skip "_snark_".
        int delimPos = targetStr.Find("_");
        if(delimPos == -1)
            return HOOK_CONTINUE;
            
        string ownerIndex = targetStr.SubString(0, delimPos);
        if(ownerIndex.IsEmpty())
            return HOOK_CONTINUE;
            
        CBasePlayer@ pOwner = g_PlayerFuncs.FindPlayerByIndex(atoi(ownerIndex));
        if(pOwner is null || !pOwner.IsConnected())
            return HOOK_CONTINUE;
        
        string steamID = g_EngineFuncs.GetPlayerAuthId(pOwner.edict());
        if(steamID.IsEmpty() || !g_PlayerSnarkNests.exists(steamID))
            return HOOK_CONTINUE;
            
        SnarkNestData@ snarkNest = cast<SnarkNestData@>(g_PlayerSnarkNests[steamID]);
        if(snarkNest is null)
            return HOOK_CONTINUE;
            
        // Apply the damage multiplier
        float damageSnarkMultiplier = 1.0f + snarkNest.GetScaledDamage();
        info.flDamage *= damageSnarkMultiplier;
    }

    if(info.pAttacker is null || !info.pAttacker.IsPlayer())
        return HOOK_CONTINUE;
        
    CBasePlayer@ pAttacker = cast<CBasePlayer@>(info.pAttacker);
    string steamID = g_EngineFuncs.GetPlayerAuthId(pAttacker.edict());
    
    // Handle all class-specific damage scaling.
    if(g_PlayerRPGData.exists(steamID))
    {
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data !is null)
        {
            switch(data.GetCurrentClass())
            {
                case PlayerClass::CLASS_SHOCKTROOPER:
                {
                    // Check if player has shock rifle equipped.
                    CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pAttacker.m_hActiveItem.GetEntity());
                    if(pWeapon !is null && pWeapon.GetClassname() == "weapon_shockrifle")
                    {
                        if(g_ShockRifleData.exists(steamID))
                        {
                            ShockRifleData@ shockRifle = cast<ShockRifleData@>(g_ShockRifleData[steamID]);
                            if(shockRifle !is null)
                            {
                                float damageMultiplier = shockRifle.GetScaledDamage();
                                info.flDamage *= damageMultiplier; // Scaling damage multiplier for shocktroopers.

                                info.bitsDamageType |= DMG_ALWAYSGIB; // Add always gib for feelgood effect.
                            }
                        }
                    }
                    break;
                }
                case PlayerClass::CLASS_BERSERKER:
                {
                    // Get bloodlust data for damage bonus.
                    if(g_PlayerBloodlusts.exists(steamID))
                    {
                        BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                        if(bloodlust !is null)
                        {
                            // Apply damage bonus based on missing health.
                            float damageBonus = bloodlust.GetDamageBonus(pAttacker);
                            info.flDamage *= (1.0f + damageBonus);

                            bloodlust.ProcessEnergySteal(pAttacker, info.flDamage); // Energy steal inside and outside of bloodlust.
                            
                            // Only process lifesteal if bloodlust is active.
                            if(bloodlust.IsActive())
                            {
                                bloodlust.ProcessLifesteal(pAttacker, info.flDamage); // Bloodlust active lifesteal.
                                
                                // Add rising blood particles.
                                Vector pos = pAttacker.pev.origin;
                                Vector mins = pos - Vector(16, 16, 0);
                                Vector maxs = pos + Vector(16, 16, 64);

                                NetworkMessage bubbleMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY);
                                    bubbleMsg.WriteByte(TE_BUBBLES);
                                    bubbleMsg.WriteCoord(mins.x);
                                    bubbleMsg.WriteCoord(mins.y);
                                    bubbleMsg.WriteCoord(mins.z);
                                    bubbleMsg.WriteCoord(maxs.x);
                                    bubbleMsg.WriteCoord(maxs.y);
                                    bubbleMsg.WriteCoord(maxs.z);
                                    bubbleMsg.WriteCoord(112.0f);
                                    bubbleMsg.WriteShort(g_EngineFuncs.ModelIndex(strBloodlustSprite));
                                    bubbleMsg.WriteByte(10);
                                    bubbleMsg.WriteCoord(2.0f);
                                bubbleMsg.End();

                                // Add dynamic light
                                NetworkMessage msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                                    msg.WriteByte(TE_DLIGHT);
                                    msg.WriteCoord(pAttacker.pev.origin.x);
                                    msg.WriteCoord(pAttacker.pev.origin.y);
                                    msg.WriteCoord(pAttacker.pev.origin.z);
                                    msg.WriteByte(5); // Radius.
                                    msg.WriteByte(int(BLOODLUST_COLOR.x));
                                    msg.WriteByte(int(BLOODLUST_COLOR.y));
                                    msg.WriteByte(int(BLOODLUST_COLOR.z));
                                    msg.WriteByte(2); // Life in 0.1s.
                                    msg.WriteByte(1); // Decay rate.
                                msg.End();
                            }
                        }
                    }
                    break;
                }
                case PlayerClass::CLASS_VANQUISHER:
                {

                    break;
                }
                case PlayerClass::CLASS_XENOMANCER:
                {

                    break;
                }
                case PlayerClass::CLASS_DEFENDER:
                {

                    break;
                }
            }
        }
    }

    // Handle Cloak damage multiplier.
    if(g_PlayerCloaks.exists(steamID))
    {
        CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
        if(cloak !is null && cloak.IsActive())
        {
            float damageCloakMultiplier = cloak.GetDamageMultiplier(pAttacker);
            info.flDamage *= damageCloakMultiplier;
            info.bitsDamageType |= DMG_ALWAYSGIB;
            cloak.DrainEnergyFromShot(pAttacker);
        }
    }
    
    return HOOK_CONTINUE;
}

HookReturnCode PlayerTakeDamage(DamageInfo@ pDamageInfo)
{
    if(pDamageInfo is null || pDamageInfo.pVictim is null) 
        return HOOK_CONTINUE;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>(pDamageInfo.pVictim);
    if(pPlayer is null || pDamageInfo.flDamage <= 0) 
        return HOOK_CONTINUE;

    // Get attacker before any damage calculations.
    CBaseEntity@ attacker = pDamageInfo.pAttacker;
    if(attacker is null)
        return HOOK_CONTINUE;

    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    
    // Add hurt delay when player takes damage.
    if(g_PlayerRecoveryData.exists(steamID))
    {
        RecoveryData@ data = cast<RecoveryData@>(g_PlayerRecoveryData[steamID]);
        if(data !is null)
        {
            data.isRegenerating = false;
            data.hurtDelayCounter = flHurtDelay;
            data.lastHurtTime = g_Engine.time;
        }
    }

    // Check for personal barrier protection first.
    if(g_PlayerRPGData.exists(steamID))
    {
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_DEFENDER && g_PlayerBarriers.exists(steamID))
        {
            BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
            if(barrier !is null && barrier.IsActive())
            {
                // Let the barrier handle all damage reflection logic.
                barrier.HandleBarrier(pPlayer, attacker, pDamageInfo.flDamage, pDamageInfo.flDamage);
                return HOOK_CONTINUE;
            }
        }
    }
    
    // If player doesn't have their own barrier, check if they're being protected by someone else's.
    if(IsPlayerProtectedByBarrier(pPlayer, attacker))
    {
        // Let the protection system handle the damage.
        HandleProtectedPlayerDamage(pPlayer, attacker, pDamageInfo);
        return HOOK_CONTINUE;
    }

    return HOOK_CONTINUE;
}

HookReturnCode OnClientPutInServer(CBasePlayer@ pPlayer)
{
    if(pPlayer is null) return HOOK_CONTINUE;
    
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(steamID.IsEmpty()) return HOOK_CONTINUE;
    
    PlayerData@ data;    
    if(!g_PlayerRPGData.exists(steamID)) // Create or load data for the player when they join.
    {
        @data = PlayerData(steamID);
        @g_PlayerRPGData[steamID] = @data;
        g_Game.AlertMessage(at_console, "RPG: Created new data for " + steamID + "\n");
    }
    else
    {
        @data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
    }
    
    if(data !is null)
    {
        data.CalculateStats(pPlayer);
        
        // After a map change, previous minion entities won't exist.
        // Let's ensure no stale minion data persists.
        if(g_PlayerMinions.exists(steamID))
        {
            MinionData@ minion = cast<MinionData@>(g_PlayerMinions[steamID]);
            if(minion !is null)
            {
                //g_Game.AlertMessage(at_console, "CARPG: OnClientPutInServer - Clearing Robomancer minion data for " + steamID + "\n");
                minion.RecalculateReservePool(); // Reset the reserve pool.
            }
        }
        
        if(g_XenologistMinions.exists(steamID))
        {
            XenMinionData@ xenMinion = cast<XenMinionData@>(g_XenologistMinions[steamID]);
            if(xenMinion !is null)
            {
                //g_Game.AlertMessage(at_console, "CARPG: OnClientPutInServer - Clearing Xenomancer minion data for " + steamID + "\n");
                xenMinion.RecalculateReservePool(); // Reset the reserve pool.
            }
        }
        
        ResetPlayer(pPlayer);
        RefillHealthArmor(pPlayer);
    }
    
    // Show class menu if no class selected.
    if(data.GetCurrentClass() == PlayerClass::CLASS_NONE)
    {
        g_Scheduler.SetTimeout("ShowClassMenuDelayed", 0.1f, @pPlayer);
    }

    return HOOK_CONTINUE;
}

HookReturnCode PlayerRespawn(CBasePlayer@ pPlayer)
{
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(g_PlayerRPGData.exists(steamID))
    {
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data !is null)
        {
            data.CalculateStats(pPlayer); // Re-calculate stats if we respawn.
            ResetPlayer(pPlayer); // We respawned, so re-initialize defaults.
            RefillHealthArmor(pPlayer); // Refill health and armor to full.

            // Show class menu if no class selected.
            if(data.GetCurrentClass() == PlayerClass::CLASS_NONE)
            {
                g_Scheduler.SetTimeout("ShowClassMenuDelayed", 0.1f, @pPlayer);
            }
        }
    }

    AdjustAmmoForClass(pPlayer);
    return HOOK_CONTINUE;
}

HookReturnCode OnClientDisconnect(CBasePlayer@ pPlayer)
{
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    
    // First ensure all minions are destroyed
    if(g_PlayerMinions.exists(steamID))
    {
        MinionData@ minion = cast<MinionData@>(g_PlayerMinions[steamID]);
        if(minion !is null)
        {
            minion.DestroyAllMinions(pPlayer);
        }
    }
    
    if(g_XenologistMinions.exists(steamID))
    {
        XenMinionData@ xenMinion = cast<XenMinionData@>(g_XenologistMinions[steamID]);
        if(xenMinion !is null)
        {
            xenMinion.DestroyAllMinions(pPlayer);
        }
    }
    
    // Then save player data
    if(g_PlayerRPGData.exists(steamID))
    {
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data !is null)
        {
            data.SaveToFile(); // Save player data when they disconnect.
        }
    }
    
    // Cancel any barrier refunds
    if(g_PlayerBarriers.exists(steamID))
    {
        BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
        if(barrier !is null)
        {
            barrier.CancelRefunds(steamID);
        }
    }
    
    // Clean up any barrier protection relationships.
    CleanupPlayerBarrierProtection(steamID);
    
    ClearMinions();
    return HOOK_CONTINUE;
}

HookReturnCode ClientSay(SayParameters@ pParams)
{
    CBasePlayer@ pPlayer = pParams.GetPlayer();
    const CCommand@ args = pParams.GetArguments();
    
    if(args.ArgC() > 0)
    {
        string command = args.Arg(0).ToLowercase();
        if(command == "class")
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null)
                {
                    data.ShowClassMenu(pPlayer);
                    pParams.ShouldHide = true;
                    return HOOK_HANDLED;
                }
            }
        }
        else if(command == "stats")
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() != PlayerClass::CLASS_NONE)
                {
                    ShowClassStats(pPlayer); // Show class stats menu.
                    pParams.ShouldHide = true;
                    return HOOK_HANDLED;
                }
            }
        }
        else if(command == "useability")
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null)
                {
                    // Engineer ability handling (new)
                    if(data.GetCurrentClass() == PlayerClass::CLASS_ENGINEER)
                    {
                        if(!g_PlayerSentries.exists(steamID))
                        {
                            SentryData sentry;
                            @g_PlayerSentries[steamID] = sentry;
                            sentry.Initialize(data.GetCurrentClassStats());
                        }
                        SentryData@ sentry = cast<SentryData@>(g_PlayerSentries[steamID]);
                        if(sentry !is null)
                            sentry.ToggleSentry(pPlayer);
                    }
                    // Robomancer ability handling (keep existing)
                    else if(data.GetCurrentClass() == PlayerClass::CLASS_ROBOMANCER)
                    {
                        if(!g_PlayerMinions.exists(steamID))
                        {
                            MinionData MinionData;
                            @g_PlayerMinions[steamID] = MinionData;
                        }
                        MinionData@ Minion = cast<MinionData@>(g_PlayerMinions[steamID]);
                        if(Minion !is null)
                            Minion.SpawnMinion(pPlayer);
                    }
                    // Medic ability handling.
                    else if(data.GetCurrentClass() == PlayerClass::CLASS_MEDIC)
                    {
                        if(!g_HealingAuras.exists(steamID))
                        {
                            HealingAura aura;
                            @g_HealingAuras[steamID] = aura;
                        }
                        HealingAura@ aura = cast<HealingAura@>(g_HealingAuras[steamID]);
                        if(aura !is null)
                            aura.ToggleAura(pPlayer);
                    }
                    // Shocktrooper ability handling.
                    else if(data.GetCurrentClass() == PlayerClass::CLASS_SHOCKTROOPER)
                    {
                        if(!g_ShockRifleData.exists(steamID))
                        {
                            ShockRifleData shockRifle;
                            @g_ShockRifleData[steamID] = shockRifle;
                            shockRifle.Initialize(data.GetCurrentClassStats());
                        }
                        ShockRifleData@ shockRifle = cast<ShockRifleData@>(g_ShockRifleData[steamID]);
                        if(shockRifle !is null)
                            shockRifle.EquipShockRifle(pPlayer);
                    }
                    // Defender ability handling.
                    else if(data.GetCurrentClass() == PlayerClass::CLASS_DEFENDER)
                    {
                        if(!g_PlayerBarriers.exists(steamID))
                        {
                            BarrierData barrier;
                            barrier.Initialize(data.GetCurrentClassStats());
                            @g_PlayerBarriers[steamID] = barrier;
                        }
                        
                        BarrierData@ barrierRef = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                        if(barrierRef !is null)
                        {
                            barrierRef.ToggleBarrier(pPlayer);
                        }
                    }
                    // Berserker ability handling.
                    else if(data.GetCurrentClass() == PlayerClass::CLASS_BERSERKER)
                    {
                        if(!g_PlayerBloodlusts.exists(steamID))
                        {
                            BloodlustData bloodlust;
                            @g_PlayerBloodlusts[steamID] = bloodlust;
                            bloodlust.Initialize(data.GetCurrentClassStats());
                        }
                        BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                        if(bloodlust !is null)
                            bloodlust.ToggleBloodlust(pPlayer);
                    }
                    // Cloaker ability handling.
                    else if(data.GetCurrentClass() == PlayerClass::CLASS_CLOAKER)
                    {
                        if(!g_PlayerCloaks.exists(steamID))
                        {
                            CloakData cloak;
                            @g_PlayerCloaks[steamID] = cloak;
                            cloak.Initialize(data.GetCurrentClassStats());
                        }
                        CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
                        if(cloak !is null)
                            cloak.ToggleCloak(pPlayer);
                    }
                    // Vanquisher ability handling.
                    else if(data.GetCurrentClass() == PlayerClass::CLASS_VANQUISHER)
                    {
                        if(!g_PlayerExplosiveRounds.exists(steamID))
                        {
                            ExplosiveRoundsData explosiveRounds;
                            @g_PlayerExplosiveRounds[steamID] = explosiveRounds;
                            explosiveRounds.Initialize(data.GetCurrentClassStats());
                        }
                        ExplosiveRoundsData@ explosiveRounds = cast<ExplosiveRoundsData@>(g_PlayerExplosiveRounds[steamID]);
                        if(explosiveRounds !is null)
                            explosiveRounds.ActivateExplosiveRounds(pPlayer);
                    }
                    // Xenologist ability handling.
                    else if(data.GetCurrentClass() == PlayerClass::CLASS_XENOMANCER)
                    {
                        if(!g_XenologistMinions.exists(steamID))
                        {
                            XenMinionData xenData;
                            @g_XenologistMinions[steamID] = xenData;
                        }
                        XenMinionData@ xenMinion = cast<XenMinionData@>(g_XenologistMinions[steamID]);
                        if(xenMinion !is null)
                            xenMinion.SpawnXenMinion(pPlayer);
                    }
                    // Swarmer ability handling.
                    else if(data.GetCurrentClass() == PlayerClass::CLASS_SWARMER)
                    {
                        if(!g_PlayerSnarkNests.exists(steamID))
                        {
                            SnarkNestData snarkNestData;
                            @g_PlayerSnarkNests[steamID] = snarkNestData;
                            snarkNestData.Initialize(data.GetCurrentClassStats());
                        }
                        SnarkNestData@ snarkNest = cast<SnarkNestData@>(g_PlayerSnarkNests[steamID]);
                        if(snarkNest !is null)
                            snarkNest.SummonSnarks(pPlayer);
                    }
                    
                    pParams.ShouldHide = true;
                    return HOOK_HANDLED;
                }
            }
        }
        else if(command == "debug")
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(IsDev(steamID))
            {
                g_DebugMenu.ShowDebugMenu(pPlayer);
                pParams.ShouldHide = true;
                return HOOK_HANDLED;
            }
            else
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "Only developers can access the debug menu.\n");
                pParams.ShouldHide = true;
                return HOOK_HANDLED;
            }
        }
        else if(command == "help")
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(IsDev(steamID))
            {
                ShowHints();
                pParams.ShouldHide = true;
                return HOOK_HANDLED;
            }
        }
    }
    
    return HOOK_CONTINUE;
}

// Check and update all player scores for XP system.
void CheckAllPlayerScores() 
{
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i) 
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer is null || !pPlayer.IsConnected()) 
            continue;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(steamID.IsEmpty())
            continue;

        if(!g_PlayerRPGData.exists(steamID))
        {
            // Create new player data and store it by reference.
            PlayerData@ data = PlayerData(steamID);
            @g_PlayerRPGData[steamID] = @data;
        }

        // Get existing data by reference.
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data !is null)
        {
            data.CheckScoreChange(pPlayer);
        }
    }
}

void UpdateAllPlayerStats()
{
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null)
                {
                    data.CalculateStats(pPlayer);
                }
            }
        }
    }
}

void UpdatePlayerHUDs()
{
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(!steamID.IsEmpty() && g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null)
                {
                    data.UpdateRPGHUD(pPlayer);
                }
            }
        }
    }
}

void ResetPlayer(CBasePlayer@ pPlayer) // Reset Abilities, HP/AP and Energy.
{
    if (pPlayer is null)
        return;
        
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    
    // Clean up any barrier protection relationships
    CleanupPlayerBarrierProtection(steamID);
    
    // Reset Heal Aura.
    if (g_HealingAuras.exists(steamID))
    {
        HealingAura@ aura = cast<HealingAura@>(g_HealingAuras[steamID]);
        if (aura !is null)
        {
            aura.ResetAura(pPlayer);
        }
    }

    // Reset Barrier.
    if (g_PlayerBarriers.exists(steamID))
    {
        BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
        if (barrier !is null)
        {
            barrier.DeactivateBarrier(pPlayer);
        }
    }

    // Reset Shock Rifle.
    if (g_ShockRifleData.exists(steamID))
    {
        ShockRifleData@ shockRifle = cast<ShockRifleData@>(g_ShockRifleData[steamID]);
        if (shockRifle !is null)
        {
            shockRifle.RemoveShockRifle(pPlayer);
        }
    }

   
    // Reset Bloodlust.
    if (g_PlayerBloodlusts.exists(steamID))
    {
        BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
        if (bloodlust !is null)
        {
            bloodlust.DeactivateBloodlust(pPlayer);
        }
    }

    // Reset Cloak.
    if (g_PlayerCloaks.exists(steamID))
    {
        CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
        if (cloak !is null)
        {
            cloak.DeactivateCloak(pPlayer);
        }
    }

    // Reset Explosive Rounds.
    if(g_PlayerExplosiveRounds.exists(steamID))
    {
        ExplosiveRoundsData@ explosiveRounds = cast<ExplosiveRoundsData@>(g_PlayerExplosiveRounds[steamID]);
        if(explosiveRounds !is null)
        {
            explosiveRounds.ResetRounds();
        }
    }

    // Reset Engineer Sentry.
    if(g_PlayerSentries.exists(steamID))
    {
        SentryData@ sentry = cast<SentryData@>(g_PlayerSentries[steamID]);
        if(sentry !is null)
        {
            sentry.DestroySentry(pPlayer);
        }
    }

    // Reset Robomancer Minions.
    if(g_PlayerMinions.exists(steamID))
    {
        MinionData@ minion = cast<MinionData@>(g_PlayerMinions[steamID]);
        if(minion !is null)
        {
            // Log that we're destroying minions from ResetPlayer
            //g_Game.AlertMessage(at_console, "CARPG: ResetPlayer - Destroying Robomancer minions for " + steamID + "\n");
            minion.DestroyAllMinions(pPlayer);
        }
    }

    // Reset Xenologist Minions and pools.
    if(g_XenologistMinions.exists(steamID))
    {
        XenMinionData@ xenMinion = cast<XenMinionData@>(g_XenologistMinions[steamID]);
        if(xenMinion !is null)
        {
            // Log that we're destroying minions from ResetPlayer
            //g_Game.AlertMessage(at_console, "CARPG: ResetPlayer - Destroying Xenomancer minions for " + steamID + "\n");
            xenMinion.DestroyAllMinions(pPlayer);
        }
    }
    
    // Reset Swarmer's Snark Nests
    if(g_PlayerSnarkNests.exists(steamID))
    {
        SnarkNestData@ snarkNestData = cast<SnarkNestData@>(g_PlayerSnarkNests[steamID]);
        if(snarkNestData !is null)
        {
            snarkNestData.Reset();
        }
    }

    // Set max health/armor based on class stats
    if (g_PlayerRPGData.exists(steamID))
    {
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if (data !is null)
        {
            data.CalculateStats(pPlayer);
        }
    }
}

void ShowClassMenuDelayed(CBasePlayer@ pPlayer)
{
    if(pPlayer is null || !pPlayer.IsConnected())
        return;

    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(g_PlayerRPGData.exists(steamID))
    {
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data !is null)
        {
            data.ShowClassMenu(pPlayer);
        }
    }
}

void CheckBarrier()
{
    array<string>@ barrierKeys = g_PlayerBarriers.getKeys();
    for(uint i = 0; i < barrierKeys.length(); i++)
    {
        string steamID = barrierKeys[i];
        BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
        if(barrier !is null)
        {
            // Find player by steamID instead of index
            CBasePlayer@ pPlayer = null;
            const int iMaxPlayers = g_Engine.maxClients;
            
            for(int j = 1; j <= iMaxPlayers; j++)
            {
                CBasePlayer@ tempPlayer = g_PlayerFuncs.FindPlayerByIndex(j);
                if(tempPlayer !is null && g_EngineFuncs.GetPlayerAuthId(tempPlayer.edict()) == steamID)
                {
                    @pPlayer = tempPlayer;
                    break;
                }
            }
            
            if(pPlayer !is null)
            {
                barrier.Update(pPlayer);
            }
        }
    }
}

void UpdateBloodlusts()
{
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerBloodlusts.exists(steamID))
            {
                BloodlustData@ bloodlust = cast<BloodlustData@>(g_PlayerBloodlusts[steamID]);
                if(bloodlust !is null)
                {
                    bloodlust.Update(pPlayer);
                }
            }
        }
    }
}

void UpdateCloaks()
{
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerCloaks.exists(steamID))
            {
                CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
                if(cloak !is null)
                {
                    cloak.Update(pPlayer);
                }
            }
        }
    }
}

void ClearMinions()
{
    array<string>@ minionKeys = g_PlayerMinions.getKeys();
    for(uint i = 0; i < minionKeys.length(); i++)
    {
        MinionData@ minion = cast<MinionData@>(g_PlayerMinions[minionKeys[i]]);
        if(minion !is null)
        {
            // Find the owning player if possible.
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i + 1);
            if(pPlayer is null)
            {
                // If owner not found, use first valid player as killer.
                for(int j = 1; j <= g_Engine.maxClients; j++)
                {
                    @pPlayer = g_PlayerFuncs.FindPlayerByIndex(j);
                    if(pPlayer !is null)
                        break;
                }
            }
            minion.DestroyAllMinions(pPlayer);
        }
    }

    // Clear Xenologist minions too.
    array<string>@ xenKeys = g_XenologistMinions.getKeys();
    for(uint i = 0; i < xenKeys.length(); i++)
    {
        XenMinionData@ xenMinion = cast<XenMinionData@>(g_XenologistMinions[xenKeys[i]]);
        if(xenMinion !is null)
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i + 1);
            if(pPlayer is null)
            {
                for(int j = 1; j <= g_Engine.maxClients; j++)
                {
                    @pPlayer = g_PlayerFuncs.FindPlayerByIndex(j);
                    if(pPlayer !is null)
                        break;
                }
            }
            xenMinion.DestroyAllMinions(pPlayer);
        }
    }
}

void AdjustAmmoForClass(CBasePlayer@ pPlayer)
{
    // Create temporary copies of ammo types for this player.
    array<AmmoType@> playerAmmoTypes;
    for (uint i = 0; i < g_AmmoTypes.length(); i++) 
    {
        AmmoType@ original = g_AmmoTypes[i];
        AmmoType@ copy = AmmoType(original.name, original.delay, original.amount, original.maxAmount, 
                                 original.hasThreshold, original.threshold);
        playerAmmoTypes.insertLast(copy);
    }
    
    // Call the existing function with the player's ammo types.
    AdjustAmmoForPlayerClass(pPlayer, playerAmmoTypes);
}

void ShowHints()
{
    g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "Welcome to CARPG! Type 'class' to select your class. Bind say UseAbility to a button to use your Class Ability.\n");
}

void RefillHealthArmor(CBasePlayer@ pPlayer)
{
    {
        // Refill HP/AP.
        pPlayer.pev.health = pPlayer.pev.max_health;
        pPlayer.pev.armorvalue = pPlayer.pev.armortype;
    }
}