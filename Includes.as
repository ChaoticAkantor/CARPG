//All includes go here.

// Data Handling.
#include "PlayerData"

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

// Skill Definitions and balancing.
#include "Classes/SkillDefs"

// Menus.
#include "Classes/ClassMenu" // Class selection and handling.
#include "Classes/ClassHUD" // Class hud display.
#include "Classes/SkillsMenu" // Skill selection and handling.

// Gameplay modules/Skills.
#include "InfoWindow" // Information menu.
#include "DamageScaling" // Automatic player damage scaling based on player count.
#include "AmmoRegen" // Ammo regen skill and difficulty adjuster.
#include "Recovery" // Recovery related skills and difficulty adjuster.
#include "DebugMenu" // Debug menu for admins/testers.