# CARPG
 Class-based RPG Mod for Sven Co-op.
 
 Discord can be found here, if you have any feedback or suggestions.

 https://discord.gg/FbsxHMvPGN

# What is it?
 This plugin offers RPG style leveling with multiple classes and a skill system, as well as file based player saves and seperate level/skillpoints per class.
 
 Also attempts to be more balanced and grounded, whilst using ZERO custom content, all assets are recycled from vanilla Sven install.

 Most classes play a role based on the holy trinity. Tank, DPS, Support.


# Chat commands
 - All commands should be typed without quotes!

   - Type "Class" without quotes in chat to bring up the class menu in order to switch classes, can be done on the fly!

   - Type "Skills" to display the skills menu, to view and purchase skills with skillpoints from leveling.

   - Type "useability" to use your class ability. It's advised to bind this to a button. Help command will explain how.

   - Type "Info" to display a window with brief information on current selected class.

   - Type "Hints" or "/help" to display all commands and explain how to activate abilities.

   - Type "scaling" or "difficulty" to show current player damage bonus based on number of players.


# Leveling
 - Gaining score will award you with XP, by default you will gain 1XP per score point. 

   - Earning enough XP will increase your Class level and also contribute towards your Rank.

   - Each class has it's own max level and skills saved individually.

   - Gain +1 Skillpoint per level by default. Can be spent on Basic or Ability skills (dependent on Class).

   - Default Max Level is 60.
   
   - XP is shared and all players will recieve the XP that another player earns (even from minions!).

   - Still earn XP even whilst dead or spectating.

 - Ranks - After earning enough XP, your rank will increase by +1.

   - Rank increases the maximum skill level cap of Basic Skills by +1 (except for ammo regen), allowing you to spend more skillpoints in those skills.

   - Rank also increases XP per score by +1 per Rank.

   - Default Max Rank is 10.


# Skills
 - Skills can be purchased and increased with Skillpoints via a menu.

   - There are two types of skills, Basic Skills and Ability Skills. 

   - Basic Skills are available to every class, are passive and always enabled.

   - Ability Skills only affect your Class Ability and are only available to the chosen class.

   - Type "skills" to see skills menu and spend skillpoints.


# Difficulty
 - Player Weapon damage is automatically adjusted for low-player count to make solo play more viable.

   - By default +50% damage at 1 player and will reduce per player that joins, giving 0 at 4 players by default.

   - Does not alter mp_pcbalancefactor server setting.


# How do I use Abilities?
  - Typing useability in chat, or binding a button to it and pressing it will activate your class ability.

  - Use [bind mouse3 say "useability"] in console and replace mouse3 with the key you want to use (without the brackets).


# Classes
  - Classes have a unique ability that can be modified with Ability Skills, duration, charge time and activation/deactivation costs vary.

# Medic
  - Healing Aura that restores a percentage of Max HP for allies (Players & NPC's).


# Berserker
  - Bloodlust doubles all lifesteal and Ability related HP bonuses whilst active.

  - Can restore health by dealing damage.


# Engineer
  - Summon a friendly Sentry Turret for a duration.

  - Has a lot of HP.

  - Can be recalled for a cost.


# Robomancer
  - Can permanently summon different types of friendly robogrunts.

  - Has access to minion only skills.

  - Amount that can be summoned and Max HP depends on their weapon type.

  - Uses a summon menu to choose type, teleport or kill them.

  - Robogrunts are naturally armored and take significantly reduced damage from most damage types, as a result they have lower HP scaling.

  - Animation speeds increased.

  - They have 360 degrees FoV and react faster as a result.


# Xenomancer
  - Can permanently summon friendly Xen creatures.

  - Has access to minion only skills.

  - Amount that can be summoned and Max HP depends on creature type.

  - Uses a summon menu to choose type, teleport or kill them.

  - Animation speeds are increased based on type.

  - 360 degrees FoV and react faster as a result.


# Necromancer
  - Can permanently summon friendly Undead.

  - Has access to minion only skills.

  - Amount that can be summoned and Max HP depends on undead type.

  - Uses a summon menu to choose monster type, teleport or kill them.

  - Animation speeds are increased based on type. 
  
  - Zombies have much higher animation speeds than any other minion type.

  - 360 degrees FoV and react faster as a result.


# Warden
  - Ice Shield that absorbs all damage and has it's own HP.

  - Any damage taken will be completely negated whilst the shield has at least 1HP.

  - Will not recharge when active, unless affected by skills.
 
  - Can be deactivated for a cost.


# Shocktrooper
  - Equips an improved Shockrifle.

  - Will not recharge whilst holding any Shockrifle.

  - Can activate whilst holding any Shockrifle to convert a portion of remaining ammo to Ability Charge.


# Cloaker
  - Cloaking device that will render you completely undetectable to NPC's.

  - Has faster Ability Charge than most skills.

  - Requires 100% Ability Charge to activate.


# Vanquisher
  - Loads Dragon's Breath rounds into a seperate ammo pool.

  - If you have rounds in the ammo pool, all shots will cause an explosion of fire damage where you shoot.

  - Explosive damage and ammo pool cost varies by ammo type.

  - Area of effects from skills can stack indefinetely.


# Swarmer
  - Summons a small swarm of large super Snarks.

  - Snarks have considerably increased HP, damage and size.

  - Snarks are thrown out at random infront of you, at signifcant velocity. Allowing you to throw them behind cover and over walls.


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