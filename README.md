# CARPG
 Class-based RPG Mod for Sven Co-op by Chaotic Akantor. Many features are still a work in progress and may be subject to change, especially class balancing. Discord can be found here, if you have any feedback or suggestions.

 https://discord.gg/FbsxHMvPGN

# What is it?
 This plugin takes the basic principals of SCXPM but in an attempt to simplify features and do something completely different. The goal is always balance, no more immortal tanks bunny hopping through maps without a care.

 Most classes bring something to the fight and push them into a specific role based on the holy trinity. Tank, DPS, Support.

# Leveling
 Default Max Level is 60.

 Default 1 skillpoint per level.

 Each class has it's own max level and skills saved individually.

 Type "class" without quotes in chat to bring up the class menu in order to switch classes, can be done on the fly!

 Type "stats" without quotes in chat to bring up the stats menu to see your current stat and ability bonuses.

# Skills
  Type "skills" to see skills menu and spend skillpoints.

  Basic skills are available to all classes. These are displayed first in the list.

  Ability skills are available only to that class and vary based on ability. These are usually in the second or third skill page, these add extra varying effects or increase aspects of a skill to make it stronger.

# Difficulty
 Player weapon damage is slightly increased, and will be forced, regardless of map.

 Certain things do increased damage to the player:
 Zombies
 Headcrabs
 Grunts with 556 (as it's also tied to player damage grrr).

# How do I use Abilities?
 Typing useability in chat, or binding a button to it and pressing it will activate your class ability.
 Type bind mouse3 say "useability" in console and replace mouse3 with the key you want to use.

# XP Gain
 XP gain is naturally quite fast.

 All XP is shared between players.
 
 Minion classes share all of their accumulated XP with their team. 
 
 Continue to earn XP even if dead or spectating.

 By default 1 Score/Frag = 1 XP. A customisable multiplier does exist in PlayerData, but no console commands yet.

# Classes?!
 Classes have a single abilitiy that automatically scales in various ways as you level up.

# Current Classes
# Medic
 Healing Aura that restores a percentage of HP for allies (including NPC's).


# Berserker
  Bloodlust is a passive ability, that can be activated to double all healing bonuses, draining charge.

  Can steal health by dealing damage inside and outside of bloodlust.


# Engineer
 Summons a single friendly Sentry.

 Activating whilst active will recall the turret for a cost.


# Robomancer
 Can summon friendly robogrunts, amount depends on points used.

 Uses a summon menu to choose weapon type, teleport or kill them.

 Robogrunts are naturally armored and take significantly reduced damage from most damage types.

 They move and attack faster than normal.


# Xenomancer
 Can summon friendly robogrunts, amount depends on points used.

 Uses a summon menu to choose monster type, teleport or kill them.

 They move and attack faster than normal.


# Necromancer
 Can summon friendly Undead, amount depends on points used.

 Has higher HP than other minion types.

 Can summon more of the weaker variant than other minion types.

 Uses a summon menu to choose monster type, teleport or kill them.

 They move and attack faster than normal.


# Warden
 Ice Shield that absorbs all damage and has it's own HP.

 Restores Shield HP when not active.
 
 Activating whilst active will break the shield for a cost.


# Shocktrooper
 Equips an improved Shockrifle.

 Can activate whilst holding a Shockrifle to stow it and restore a portion of ammo to battery.


# Cloaker
 Cloaking device that will render you completely undetectable to NPC's.

 Has to fully recharge between uses.


# Vanquisher
 Can load Dragon's Breath rounds into a seperate ammo pool.

 If you have Dragon's Breath ammo, all shots will cause an explosion of fire damage where you shoot.

 Fire damage is low but will stack for each area of effect.

 Area of effects have no limit.

# Swarmer
 Summons a swarm of improved snarks.

 Snarks have considerably increased HP and damage.

 Snarks are thrown out at random infront of you, at signifcant velocity. Allowing you to throw them over or bounce them around obsticles.


# Installation instructions:

1. 

Extract/drop CARPG into perferably Svencoop/scripts/plugins/
or 
Sven Co-op/Svencoop_addon/scripts/plugins/

Svencoop/scripts/plugins/CARPG should be what the structure looks like.


2. 

Add the following to your default_plugins.txt located inside Sven Co-op/svencoop/

		"plugin"
 	{
        "name" "CARPG"
		"script" "CARPG/CARPG"
	}

Name is the name of the plugin.

Script is the file path of the script being loaded (which also loads the rest of the files in the folder.)


3. 

Go into Sven Co-op/svencoop/scripts/plugins and ensure you have a folder called "store" without the quotes, if you do not, you will need to create a blank folder and name it "store". If not, the plugin will not have the required access to store player data, as I don't think Angelscript has permission or functions to create folders, only text files.

ENSURE THE FOLDER NAMES MATCH THE FILE PATH, OR IT WON'T LOAD!
