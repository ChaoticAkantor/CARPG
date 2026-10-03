/*
This file handles all includes.
*/

// Shared map policy and data handling.
#include "MapSettings"
#include "AdminList"
#include "PlayerData"
#include "Includes"

// Classes.
#include "Classes/Engineer/AbilitySentry"
#include "Classes/Robomancer/AbilityRobotMinion"
#include "Classes/Xenomancer/AbilityXenMinion"
#include "Classes/Necromancer/AbilityNecroMinion"
#include "Classes/Swarmer/AbilitySnarkSwarm"
#include "Classes/Medic/AbilityHeal"
#include "Classes/Frostguard/AbilityBarrier"
#include "Classes/Shocktrooper/AbilitySuperShockRifle"
#include "Classes/Vampire/AbilityBloodlust"
#include "Classes/Cloaker/AbilityCloak"
#include "Classes/Firebug/AbilityDragonsBreath"

// Skill Definitions and balancing.
#include "SkillDefs"

// Menus.
#include "Menus/ClassMenu" // Class selection and handling.
#include "Menus/SkillsMenu" // Skill selection and handling.
#include "Menus/HUDSettingsMenu" // HUD settings menu.
#include "Menus/MapSettingsMenu" // Admin map policy menu.
#include "Menus/AdminListMenu" // Admin list manager.
#include "Menus/DebugMenu" // Debug menu for admins/testers.

// Gameplay modules/Skills.
#include "ClassHUD" // Class HUD display.
#include "InfoWindow" // Information menu.
#include "DamageScaling" // Automatic player damage scaling based on player count.
#include "AmmoRegen" // Ammo regen skill and difficulty adjuster.
#include "Recovery" // Recovery related skills and difficulty adjuster.