//All includes go here.

// Data Handling.
#include "PlayerData"

// Skill Definitions and balancing.
#include "Classes/SkillDefs"

// Menus.
#include "Classes/ClassMenu" // Class selection and handling.
#include "Classes/ClassHUD" // Class hud display.
//#include "classes/ClassStatsMenu" // Class stats info - Depriciated.
#include "Classes/ClassInfo" // Class information menu.
#include "Classes/SkillsMenu" // Skill selection and handling.

// Classes.
#include "Classes/Engineer/SentryMinion"
#include "Classes/Robomancer/RobotMinion"
#include "Classes/Xenomancer/XenMinion"
#include "Classes/Necromancer/NecroMinion"
#include "Classes/Swarmer/SnarkSwarm"
#include "Classes/Medic/HealAura"
#include "Classes/Warden/Barrier"
#include "Classes/Shocktrooper/ShockRifle"
#include "Classes/Berserker/Bloodlust"
#include "Classes/Cloaker/Cloak"
#include "Classes/Vanquisher/DragonsBreath"

// Gameplay modules/Skills.
#include "DamageScaling"
#include "AmmoRegen"
#include "Recovery"
#include "DebugMenu"