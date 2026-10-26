/*
This file handles all includes.
*/

// Shared map policy and data handling.
#include "MapSettings" // Map-specific settings for balancing.
#include "AdminList" // Admin list handling.
#include "PlayerData" // Player data handling.
#include "Includes" // Core includes for the plugin.

// Classes.
#include "Classes/Medic" // Ability and skill code for the Medic class.
#include "Classes/Vampire" // Ability and skill code for the Vampire class.
#include "Classes/Frostguard" // Ability and skill code for the Frostguard class.
#include "Classes/Engineer" // Ability and skill code for the Engineer class.
#include "Classes/Robomancer" // Ability and skill code for the Robomancer class.
#include "Classes/Xenomancer" // Ability and skill code for the Xenomancer class.
#include "Classes/Necromancer" // Ability and skill code for the Necromancer class.
#include "Classes/Cloaker" // Ability and skill code for the Cloaker class.
#include "Classes/Shocktrooper" // Ability and skill code for the Shocktrooper class.
#include "Classes/Firebug" // Ability and skill code for the Firebug class.
#include "Classes/Swarmer" // Ability and skill code for the Swarmer class.

// Skills and balancing.
#include "SkillDefs" // Skill definitions, scaling values and descriptions.
#include "BasicSkills" // Basic skills code.

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