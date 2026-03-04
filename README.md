# CARPG
 Class-based RPG Mod for Sven Co-op by Chaotic Akantor. Many features are still a work in progress and may be subject to change, especially class balancing. Discord can be found here, if you have any feedback or suggestions.

 https://discord.gg/FbsxHMvPGN

# What is it?
 This plugin takes the basic principals of SCXPM but in an attempt to simplify features and do something completely different. The goal is always balance, no more immortal tanks bunny hopping through maps without a care.

 Most classes bring something to the fight and push them into a specific role based on the holy trinity. Tank, DPS, Support.

# Leveling
 Default Max Level is 100, this can be changed, but the abilities will always scale UP to the max level.

 Max HP scales with your class level.

 Max AP DOES NOT increase in any way, but you can always regenerate up to the default maximum slowly, the reasoning for this is that armor in Sven is VERY strong compared to Half-Life.

 Each class has it's own max level and stats saved individually.

 Type "class" without quotes in chat to bring up the class menu in order to switch classes, can be done on the fly!

 Type "stats" without quotes in chat to bring up the stats menu to see your current stat and ability bonuses.

# Ammo Resupply (and Explosives)
 The mod also features an ammo resupply system.

 Explosives resupply is extremely limited, using a threshold system that only allows you a maximum usually of 1 at a time, unless you find more in a level.

 It also does not give you the weapons pertaining to any of the ammo types to retain map balance.

 Please see "Difficulty" for notes on further map balancing for horror map series.

# Recovery
 Regeneration will halt a small delay after taking damage, displaying an icon in the hud.
 By default, HP and AP restore 1% per tic.

 HP restores every 1s.
 AP restores every 4s.

 Recovery DOES NOT scale with level in any way.

 Please see "Difficulty" for notes on further map balancing for horror map series.

# Difficulty
 Player weapon damage is slightly increased, and will be forced, regardless of map.

 Sven's Auto-player balancing for the moment is forcibly disabled (for now).

 Certain things do increased damage to the player:
 Zombies
 Headcrabs
 Grunts with 556 (as it's also tied to player damage grrr).

# How do I use Skills?
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
 Also deals a percentage of HP as poison damage to enemies.

 Can revive both players and NPC's, but drains more charge.


# Berserker
Bloodlust is a passive ability, that can be activated to double all bonuses, draining charge.

 # Passives:
  Can leech health by dealing damage.

  Can overheal a percentage of Max HP as extra temporary HP.

  Gains damage reduction as health decreases.

  Gain ability recharge by dealing damage (even whilst ability is active!)


# Engineer
 Summons a single friendly Sentry.

 Sentry can slow down enemies.
 
 Has a weaker version of Heal Aura without poison damage.

 Activating whilst active will recall the turret for a cost.


# Robomancer
 Can summon friendly robogrunts, amount depends on points used.

 Uses a summon menu to choose weapon type, teleport or kill them.

 Robogrunts are naturally armored and take significantly reduced damage from most damage types.

 They move faster than normal.

 Will repair over time.


# Xenomancer
 Can summon friendly robogrunts, amount depends on points used.

 Uses a summon menu to choose monster type, teleport or kill them.

 They move faster than normal.

 Will heal over time.


# Necromancer
 Can summon friendly Undead, amount depends on points used.

 Has higher HP than other minion types.

 Can summon more of the weaker variant than other minion types.

 Uses a summon menu to choose monster type, teleport or kill them.

 They move faster than normal.

 Will heal over time.

 Damage leeches life to themself and owner.


# Warden
 Ice Shield that absorbs all damage and has it's own HP.

 Restores Shield HP when not active.

 Reflects a percentage of damage at attacking enemies (including grenades and projectiles).
 
 Absorbs a percentage of absorbed damage and restores HP.

 Can restore Shield HP whilst active, but at a severely reduced rate.
 
 Activating whilst active will break the shield for a cost.


# Shocktrooper
 Equips an improved Shockrifle.

 Has significantly increased capacity and increased damage.

 Can activate whilst holding a Shockrifle to stow it and restore a portion of ammo to battery.

 More features will come for this class later.


# Cloaker
 Cloaking device that will render you completely undetectable to NPC's.

 Gains a massive damage bonus to shots whilst active. Shooting drains battery, damage bonus depends on remaining battery.

 Activating while active will create a damaging Nova. Also happens if Cloak runs out.

 Nova Damage depends on remaining battery.

 Nova damage leeches HP.


# Vanquisher
 Can load Dragon's Breath rounds into a seperate ammo pool.

 If you have Dragon's Breath ammo, all shots will cause a fire damage area of effect where you shoot.

 Fire damage is low but will stack for each area of effect.

 Area of effects have no limit.

# Swarmer
 Summons a swarm of improved snarks.

 Snarks have considerably increased HP and damage.

 Snarks are thrown out at random infront of you, at signifcant velocity. Allowing you to throw them over or bounce them around obsticles.

 Damage leeches HP to self and owner.


# Installation instructions:

1. Extract/drop CARPG into perferably Svencoop/scripts/plugins/
or 
Sven Co-op/Svencoop_addon/scripts/plugins/

Svencoop/scripts/plugins/CARPG should be what the structure looks like.

2. Add the following to your default_plugins.txt located inside Sven Co-op/svencoop/;

		"plugin"
 	{
        "name" "CARPG"
		"script" "CARPG/CARPG"
	}

3. Go into Sven Co-op/svencoop/scripts/plugins and ensure you have a folder called "store" without the quotes, if you do not, you will need to create a blank folder and name it "store". If not, the plugin will not have the required access to store player data, as I don't think Angelscript has permission or functions to create folders, only text files.

ENSURE THE PLUGIN FOLDER IS NAMED AS ABOVE, OR IT WON'T LOAD!
