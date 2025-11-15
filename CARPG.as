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
}

void MapActivate() // Like MapInit, only called after all mapper placed entities have been activated and the sound list has been written.
{

}

void MapStart() // Called after 0.1 seconds of game activity, this is used to simplify the triggering on map start.
{
    // Startup console message so we know it is installed.
    g_Game.AlertMessage(at_console, "=== CARPG Enabled! ===\n");

    g_EngineFuncs.ServerCommand("mp_friendlyfire 0\n"); // Disable friendly fire to ensure certain abilities don't hurt ally monsters.

    // Hints to play on map load.
    g_Scheduler.SetTimeout("ShowHints", 5.0f); // Show hints X seconds after map load.
}

void PluginReset() // Used to reset anything important to the plugin on reload.
{
    g_Game.AlertMessage(at_console, "=== CARPG Reset! ===\n");

    g_Scheduler.ClearTimerList(); // Clear all timers here also, this will ensure proper reset if plugin is reloaded with as_reloadplugins.
    //RemoveHooks(); // Remove Hooks.

    ResetData(); // Clear all dictionaries.
    ClearMinions(); // Clear all minion data.
    RegisterHooks(); // Re-register Hooks.
    InitializeAmmoRegen(); // Re-apply ammo types for ammo recovery.
    SetupTimers(); // Re-setup timers.
    ApplyDifficultySettings(); // Re-apply difficulty settings.
}

void ResetData()
{
    // Clear all dictionaries.
    g_PlayerRPGData.deleteAll();
    g_PlayerMinions.deleteAll();
    g_XenologistMinions.deleteAll();
    g_NecromancerMinions.deleteAll();
    g_PlayerSentries.deleteAll();
    g_HealingAuras.deleteAll();
    g_PlayerBarriers.deleteAll();
    g_PlayerBloodlusts.deleteAll();
    g_PlayerCloaks.deleteAll();
    g_PlayerDragonsBreath.deleteAll();
    g_ShockRifleData.deleteAll();
    g_PlayerSnarkNests.deleteAll();
    g_PlayerClassResources.deleteAll();
}

void RegisterHooks()
{
    g_Hooks.RegisterHook(Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage);
    g_Hooks.RegisterHook(Hooks::Weapon::WeaponPrimaryAttack, @WeaponPrimaryAttack);
    g_Hooks.RegisterHook(Hooks::Weapon::WeaponSecondaryAttack, @WeaponSecondaryAttack);
    g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @ClientPutInServer);
    g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @ClientDisconnect);
    g_Hooks.RegisterHook(Hooks::Player::ClientSay, @ClientSay);
    g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @PlayerRespawn);
    g_Hooks.RegisterHook(Hooks::Monster::MonsterTakeDamage, @MonsterTakeDamage);
    g_Hooks.RegisterHook(Hooks::Game::MapChange, @MapChange);
}

void RemoveHooks()
{
    g_Hooks.RemoveHook(Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage);
    g_Hooks.RemoveHook(Hooks::Weapon::WeaponPrimaryAttack, @WeaponPrimaryAttack);
    g_Hooks.RemoveHook(Hooks::Weapon::WeaponSecondaryAttack, @WeaponSecondaryAttack);
    g_Hooks.RemoveHook(Hooks::Player::ClientPutInServer, @ClientPutInServer);
    g_Hooks.RemoveHook(Hooks::Player::ClientDisconnect, @ClientDisconnect);
    g_Hooks.RemoveHook(Hooks::Player::ClientSay, @ClientSay);
    g_Hooks.RemoveHook(Hooks::Player::PlayerSpawn, @PlayerRespawn);
    g_Hooks.RemoveHook(Hooks::Monster::MonsterTakeDamage, @MonsterTakeDamage);
    g_Hooks.RemoveHook(Hooks::Game::MapChange, @MapChange);
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
    g_Scheduler.SetInterval("CheckAllPlayerScores", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for XP system.

    // Medic.
    g_Scheduler.SetInterval("CheckHealAura", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for checking heal aura.

    // Engineer.
    g_Scheduler.SetInterval("CheckSentries", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for checking engineer sentries.

    g_Scheduler.SetInterval("CheckEngineerMinions", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for checking engineer Robogrunts.

    // Xenologist.
    g_Scheduler.SetInterval("CheckXenologistMinions", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for checking Xenologist minions.

    // Necromancer.
    g_Scheduler.SetInterval("CheckNecromancerMinions", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES); // Timer for checking Necromancer minions.

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

    // Necromancer Ability Precache.
        // Sounds.
        g_SoundSystem.PrecacheSound(strNecroMinionSoundCreate);

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
        g_Game.PrecacheModel(strBarrierReflectDamageSprite);
        
        // Sounds.
        g_SoundSystem.PrecacheSound(strBarrierToggleSound);
        g_SoundSystem.PrecacheSound(strBarrierHitSound);
        g_SoundSystem.PrecacheSound(strBarrierBreakSound);
        g_SoundSystem.PrecacheSound(strBarrierActiveSound);

    // Cloaker Ability Precache.
        // Models/Sprites.
        g_Game.PrecacheModel(strCloakNovaSprite);

        // Sounds.
        g_SoundSystem.PrecacheSound(strCloakActivateSound);
        g_SoundSystem.PrecacheSound(strCloakActiveSound);
        g_SoundSystem.PrecacheSound(strCloakNovaSound);

    // Vanquisher Class Precache.
        // Models/Sprites.
    g_Game.PrecacheModel(strDragonsBreathExplosionSprite);
    g_Game.PrecacheModel(strDragonsBreathExplosionCoreSprite);
    g_Game.PrecacheModel(strDragonsBreathFireSprite);

        // Sounds.
    g_SoundSystem.PrecacheSound(strDragonsBreathActivateSound);
    g_SoundSystem.PrecacheSound(strDragonsBreathImpactSound);

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

    // Zombie.
        // Models/Sprites.
        g_Game.PrecacheModel(strZombieModel);
        g_Game.PrecacheModel(strZombieModelGibs);

        // Sounds.
        g_SoundSystem.PrecacheSound(strZombieSoundClawMiss1);
        g_SoundSystem.PrecacheSound(strZombieSoundClawMiss2);
        g_SoundSystem.PrecacheSound(strZombieSoundClawStrike1);
        g_SoundSystem.PrecacheSound(strZombieSoundClawStrike2);
        g_SoundSystem.PrecacheSound(strZombieSoundClawStrike3);
        g_SoundSystem.PrecacheSound(strZombieSoundAlert10);
        g_SoundSystem.PrecacheSound(strZombieSoundAlert20);
        g_SoundSystem.PrecacheSound(strZombieSoundAlert30);
        g_SoundSystem.PrecacheSound(strZombieSoundAttack1);
        g_SoundSystem.PrecacheSound(strZombieSoundAttack2);
        g_SoundSystem.PrecacheSound(strZombieSoundIdle1);
        g_SoundSystem.PrecacheSound(strZombieSoundIdle2);
        g_SoundSystem.PrecacheSound(strZombieSoundIdle3);
        g_SoundSystem.PrecacheSound(strZombieSoundIdle4);
        g_SoundSystem.PrecacheSound(strZombieSoundPain1);
        g_SoundSystem.PrecacheSound(strZombieSoundPain2);

    // Skeleton (Vortigaunt).
        // Models/Sprites.
        g_Game.PrecacheModel(strSkeletonModel);

        // Sounds.
        g_SoundSystem.PrecacheSound(strSkeletonSoundShoot1);
        g_SoundSystem.PrecacheSound(strSkeletonSoundBite);
        g_SoundSystem.PrecacheSound(strSkeletonSoundWord3);
        g_SoundSystem.PrecacheSound(strSkeletonSoundWord4);
        g_SoundSystem.PrecacheSound(strSkeletonSoundWord5);
        g_SoundSystem.PrecacheSound(strSkeletonSoundWord7);
        g_SoundSystem.PrecacheSound(strSkeletonSoundPain1);
        g_SoundSystem.PrecacheSound(strSkeletonSoundPain2);
        g_SoundSystem.PrecacheSound(strSkeletonSoundDie1);
        g_SoundSystem.PrecacheSound(strSkeletonSoundDie2);
        g_SoundSystem.PrecacheSound(strSkeletonSoundZap1);
        g_SoundSystem.PrecacheSound(strSkeletonSoundZap4);


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
        g_SoundSystem.PrecacheSound(strGonomeSoundPain2);
        g_SoundSystem.PrecacheSound(strGonomeSoundPain3);
        g_SoundSystem.PrecacheSound(strGonomeSoundPain4);
        g_SoundSystem.PrecacheSound(strGonomeSoundMelee1);
        g_SoundSystem.PrecacheSound(strGonomeSoundMelee2);
        g_SoundSystem.PrecacheSound(strGonomeSoundRun);
        g_SoundSystem.PrecacheSound(strGonomeSoundEat);

/* -- Removed as they flinch, retreat and hesitate too much due to pack tactics.
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
*/

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

    // Bullsquid.
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
        g_SoundSystem.PrecacheSound(strBabyGargSoundAlert1);
        g_SoundSystem.PrecacheSound(strBabyGargSoundAlert2);
        g_SoundSystem.PrecacheSound(strBabyGargSoundAlert3);
        g_SoundSystem.PrecacheSound(strBabyGargSoundAttack1);
        g_SoundSystem.PrecacheSound(strBabyGargSoundAttack2);
        g_SoundSystem.PrecacheSound(strBabyGargSoundAttack3);
        g_SoundSystem.PrecacheSound(strBabyGargSoundBreathe1);
        g_SoundSystem.PrecacheSound(strBabyGargSoundBreathe2);
        g_SoundSystem.PrecacheSound(strBabyGargSoundBreathe3);
        g_SoundSystem.PrecacheSound(strBabyGargSoundDie1);
        g_SoundSystem.PrecacheSound(strBabyGargSoundDie2);
        g_SoundSystem.PrecacheSound(strBabyGargSoundFlameoff1);
        g_SoundSystem.PrecacheSound(strBabyGargSoundFlameon1);
        g_SoundSystem.PrecacheSound(strBabyGargSoundFlamerun1);
        g_SoundSystem.PrecacheSound(strBabyGargSoundIdle1);
        g_SoundSystem.PrecacheSound(strBabyGargSoundIdle2);
        g_SoundSystem.PrecacheSound(strBabyGargSoundIdle3);
        g_SoundSystem.PrecacheSound(strBabyGargSoundIdle4);
        g_SoundSystem.PrecacheSound(strBabyGargSoundIdle5);
        g_SoundSystem.PrecacheSound(strBabyGargSoundPain1);
        g_SoundSystem.PrecacheSound(strBabyGargSoundPain2);
        g_SoundSystem.PrecacheSound(strBabyGargSoundPain3);
        g_SoundSystem.PrecacheSound(strBabyGargSoundStep1);
        g_SoundSystem.PrecacheSound(strBabyGargSoundStep2);
        g_SoundSystem.PrecacheSound(strBabyGargSoundStomp1);

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

HookReturnCode MapChange(const string& in nextMap) // Called on map change.
{
    PluginReset(); // Reset all plugin elements on map change.
    return HOOK_CONTINUE;
}

// Hook handler for Primary Attack. This is used for Dragons Breath on each shot.
HookReturnCode WeaponPrimaryAttack(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon) 
{
    if(pWeapon is null || pPlayer is null || pWeapon.m_iClip <= 0) // Make sure clip is not empty.
        return HOOK_CONTINUE;
    
    string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(g_PlayerDragonsBreath.exists(steamId))
    {
        DragonsBreathData@ DragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamId]);
        if(DragonsBreath !is null && DragonsBreath.HasRounds())
        {
            DragonsBreath.FireDragonsBreathRound(pPlayer, pWeapon); // Consume rounds and fire Dragons Breath shots if active.
        }
    }
    
    return HOOK_CONTINUE;
}

// Hook handler for Secondary Attack.
HookReturnCode WeaponSecondaryAttack(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon) 
{
    if(pWeapon is null || pPlayer is null || pWeapon.m_iClip <= 0 && pWeapon.m_iClip2 != -1 ) // Check if clip is not empty and clip2 isn't infinite.
        return HOOK_CONTINUE;

    string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    string SecondaryWeaponName = pWeapon.pev.classname;
    if(SecondaryWeaponName == "weapon_shotgun" || SecondaryWeaponName == "weapon_9mmhandgun" || SecondaryWeaponName == "weapon_sawedoff")
    {
        if(g_PlayerDragonsBreath.exists(steamId))
        {
            DragonsBreathData@ DragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamId]);
            if(DragonsBreath !is null && DragonsBreath.HasRounds())
            {
                DragonsBreath.FireDragonsBreathRound(pPlayer, pWeapon); // Consume rounds and fire Dragons Breath shots if active.
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
    CBaseEntity@ victim = info.pVictim;

    string targetname = string(attacker.pev.targetname);
    Vector targetPos = info.pVictim.pev.origin;

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

        //Sentry perk, explosive shots.
        if(sentry.HasStats() && sentry.GetStats().HasUnlockedPerk1())
        {
            sentry.ApplyElementalShots(targetPos, attacker, victim, info.flDamage);
        }
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
        // Find owner's XenMinionData by the index in targetname.
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

        // Process life steal - when xenminion deals damage, give health to owner.
        xenMinion.ProcessMinionDamage(pOwner, info.flDamage);
    }
    else if(targetname.StartsWith("_necrominion_"))
    {
        // Find owner's NecroMinionData by the index in targetname.
        string ownerIndex = targetname.SubString(12); // Look specifically for only targetnames with indexes added.
        if(ownerIndex.IsEmpty())
            return HOOK_CONTINUE;
            
        CBasePlayer@ pOwner = g_PlayerFuncs.FindPlayerByIndex(atoi(ownerIndex));
        if(pOwner is null || !pOwner.IsConnected())
            return HOOK_CONTINUE;
            
        string steamID = g_EngineFuncs.GetPlayerAuthId(pOwner.edict());
        if(steamID.IsEmpty() || !g_NecromancerMinions.exists(steamID))
            return HOOK_CONTINUE;
            
        NecroMinionData@ necroMinion = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
        if(necroMinion is null)
            return HOOK_CONTINUE;
            
        // Apply the damage multiplier.
        float damageNecroMultiplier = 1.0f + necroMinion.GetScaledDamage();
        info.flDamage *= damageNecroMultiplier;

        // Process lifesteal - when necrominion deals damage, give health to owner.
        necroMinion.ProcessMinionDamage(pOwner, info.flDamage);
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
            
        // Apply the damage multiplier.
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
                            
                            bloodlust.ProcessLifesteal(pAttacker, info.flDamage); // Process lifesteal on damage dealt.
                            bloodlust.ProcessEnergySteal(pAttacker, info.flDamage); // Process energy steal on damage dealt.
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
            float damageMultiplier = cloak.GetDamageMultiplier(pAttacker); // Get multiplier.
            float originalDamage = info.flDamage; // Store original damage so we can use to to scale drain.
            info.flDamage *= damageMultiplier; // Calculate damage with the multiplier.
            info.bitsDamageType |= DMG_ALWAYSGIB; // Add damage bit type always gib for the feels.
            cloak.DrainEnergyFromShot(pAttacker, originalDamage); // Drain energy on dealing damage.
        }
    }

    // Perk 1 - AP Steal Nova.
    if(g_PlayerCloaks.exists(steamID))
    {
        CloakData@ cloak = cast<CloakData@>(g_PlayerCloaks[steamID]);
        if(cloak !is null && cloak.IsNovaActive() && cloak.GetStats().HasUnlockedPerk1())
        {
            float healAmount = info.flDamage * cloak.GetAPStealPercent(); // Get damage dealt to repair.

            // Apply to AP, don't repair over maximum.
            pAttacker.pev.armorvalue = Math.min(pAttacker.pev.armorvalue + healAmount, pAttacker.pev.armortype);
            
            // After healing, check if AP actually changed, if it didn't, AP must be disabled by map, apply to HP instead.
            if (pAttacker.pev.armorvalue > 0)
            {
                //Apply to HP, don't repair over maximum.
                pAttacker.pev.health = Math.min(pAttacker.pev.health + healAmount, pAttacker.pev.max_health);

                // Health Bubbles Effect.
                Vector pos = pAttacker.pev.origin;
                Vector mins = pos - Vector(16, 16, 0);
                Vector maxs = pos + Vector(16, 16, 64);

                NetworkMessage healbubblesmsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
                    healbubblesmsg.WriteByte(TE_BUBBLES);
                    healbubblesmsg.WriteCoord(mins.x);
                    healbubblesmsg.WriteCoord(mins.y);
                    healbubblesmsg.WriteCoord(mins.z);
                    healbubblesmsg.WriteCoord(maxs.x);
                    healbubblesmsg.WriteCoord(maxs.y);
                    healbubblesmsg.WriteCoord(maxs.z);
                    healbubblesmsg.WriteCoord(80.0f); // Height of the bubble effect.
                    healbubblesmsg.WriteShort(g_EngineFuncs.ModelIndex(strHealAuraEffectSprite));
                    healbubblesmsg.WriteByte(18); // Count.
                    healbubblesmsg.WriteCoord(6.0f); // Speed.
                    healbubblesmsg.End();

                // Play HP healing sound.
                //g_SoundSystem.EmitSoundDyn(pAttacker.edict(), CHAN_ITEM, "items/smallmedkit1.wav", 0.5f, ATTN_NORM, 0, PITCH_NORM);
            }
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

    // Check if barrier is active - only process damage from actual enemies.
    if(g_PlayerRPGData.exists(steamID))
    {
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_DEFENDER && g_PlayerBarriers.exists(steamID))
        {
            BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
            if(barrier !is null && barrier.IsActive())
            {
                // Only process barrier damage if attacker is NOT a player, otherwise friendly fire can strip shield. We don't care about PvP.
                if(!attacker.IsPlayer())
                {
                    CBaseMonster@ pMonster = cast<CBaseMonster@>(attacker);
                    if(pMonster !is null)
                    {
                        int relationship = pMonster.IRelationship(pPlayer);
                        if(relationship != R_AL) // Only process if NOT an ally of the player.
                        {
                            barrier.HandleBarrier(pPlayer, attacker, pDamageInfo.flDamage, pDamageInfo.flDamage);
                            barrier.EffectReflectDamage(attacker.pev.origin, attacker);
                        }
                    }
                }
                return HOOK_CONTINUE;
            }
        }
    }

    return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer(CBasePlayer@ pPlayer)
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
        data.CalculateStats(pPlayer); // Calculate stats on join.
        ResetPlayer(pPlayer); // Initialize player defaults if they rejoined.
        RefillHealthArmor(pPlayer); // Refill health and armor to full.
        
        // Reset any active Engineer sentries for the player when they join/changelevel.
        if(g_PlayerSentries.exists(steamID))
        {
            SentryData@ sentry = cast<SentryData@>(g_PlayerSentries[steamID]);
            if(sentry !is null)
            {
                sentry.Reset();
            }
        }
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

HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer)
{
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(g_PlayerRPGData.exists(steamID))
    {
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data !is null)
        {
            data.CalculateStats(pPlayer); // Re-Calculate stats on disconnect incase we rejoin.
            ResetPlayer(pPlayer); // We disconnected, so re-initialize defaults incase we rejoin.
        }
    }
    
    // First ensure all minions are destroyed.
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
    
    if(g_NecromancerMinions.exists(steamID))
    {
        NecroMinionData@ necroMinion = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
        if(necroMinion !is null)
        {
            necroMinion.DestroyAllMinions(pPlayer);
        }
    }
    
    // Then save player data.
    if(g_PlayerRPGData.exists(steamID))
    {
        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data !is null)
        {
            data.SaveToFile(); // Save player data when they disconnect.
        }
    }
    
    //ClearMinions();
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
                        else
                        {
                            // Re-initialize if switching from another class
                            BarrierData@ existingBarrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                            if(existingBarrier !is null)
                            {
                                existingBarrier.Initialize(data.GetCurrentClassStats());
                            }
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
                        if(!g_PlayerDragonsBreath.exists(steamID))
                        {
                            DragonsBreathData DragonsBreath;
                            @g_PlayerDragonsBreath[steamID] = DragonsBreath;
                            DragonsBreath.Initialize(data.GetCurrentClassStats());
                        }
                        DragonsBreathData@ DragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamID]);
                        if(DragonsBreath !is null)
                            DragonsBreath.ActivateDragonsBreath(pPlayer);
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
                    // Necromancer ability handling.
                    else if(data.GetCurrentClass() == PlayerClass::CLASS_NECROMANCER)
                    {
                        if(!g_NecromancerMinions.exists(steamID))
                        {
                            NecroMinionData necroData;
                            @g_NecromancerMinions[steamID] = necroData;
                        }
                        NecroMinionData@ necroMinion = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
                        if(necroMinion !is null)
                            necroMinion.SpawnNecroMinion(pPlayer);
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

    // Reset Dragon's Breath Rounds.
    if(g_PlayerDragonsBreath.exists(steamID))
    {
        DragonsBreathData@ DragonsBreath = cast<DragonsBreathData@>(g_PlayerDragonsBreath[steamID]);
        if(DragonsBreath !is null)
        {
            DragonsBreath.ResetRounds();
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
    
    // Reset Necromancer Minions and pools.
    if(g_NecromancerMinions.exists(steamID))
    {
        NecroMinionData@ necroMinion = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
        if(necroMinion !is null)
        {
            // Log that we're destroying minions from ResetPlayer
            //g_Game.AlertMessage(at_console, "CARPG: ResetPlayer - Destroying Necromancer minions for " + steamID + "\n");
            necroMinion.DestroyAllMinions(pPlayer);
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
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerBarriers.exists(steamID))
            {
                BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
                if(barrier !is null)
                {
                    barrier.Update(pPlayer);
                }
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
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            
            // Clear Robomancer minions.
            if(g_PlayerMinions.exists(steamID))
            {
                MinionData@ minion = cast<MinionData@>(g_PlayerMinions[steamID]);
                if(minion !is null)
                {
                    minion.DestroyAllMinions(pPlayer);
                }
            }
            
            // Clear Xenomancer minions.
            if(g_XenologistMinions.exists(steamID))
            {
                XenMinionData@ xenMinion = cast<XenMinionData@>(g_XenologistMinions[steamID]);
                if(xenMinion !is null)
                {
                    xenMinion.DestroyAllMinions(pPlayer);
                }
            }
            
            // Clear Necromancer minions.
            if(g_NecromancerMinions.exists(steamID))
            {
                NecroMinionData@ necroMinion = cast<NecroMinionData@>(g_NecromancerMinions[steamID]);
                if(necroMinion !is null)
                {
                    necroMinion.DestroyAllMinions(pPlayer);
                }
            }
        }
    }
    
    // Fallback for any minions not cleared by player iteration (in case dictionary entries exist without connected players).
    CBasePlayer@ fallbackPlayer = null;
    
    // Find any valid player to use as the killer for orphaned minions.
    for(int i = 1; i <= g_Engine.maxClients; i++)
    {
        @fallbackPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(fallbackPlayer !is null)
            break;
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
    g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "This server uses CARPG! Type 'class' to select your class. Bind say UseAbility to a button to use your Class Ability.\n");
    g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "Type 'Stats' to see your class and ability info. Or 'Help' to display this message again.\n");
}

void RefillHealthArmor(CBasePlayer@ pPlayer)
{
    {
        // Refill HP/AP.
        pPlayer.pev.health = pPlayer.pev.max_health;
        pPlayer.pev.armorvalue = pPlayer.pev.armortype;
    }
}