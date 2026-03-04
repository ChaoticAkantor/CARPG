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
# Medic - Healer/AoE Damage Dealer
Healing Aura that restores a percentage of HP for allies (including NPC's).
Also deals a percentage of HP as poison damage to enemies.

Can revive, but drains more charge.

# Berserker - Lifesteal Tank
Passively gains Life Steal and damage reduction the lower their health. Activating ability toggles a Bloodlust rage state, which doubles all bonuses whilst active.

Life steal will return HP as AP at a severely reduced value if HP is full.

# Engineer - Healer/Minion Hybrid
Can summon a single friendly Sentry for a duration that regenerates HP for all players and itself. Activating the ability again will recall the Sentry. The sentry turret uses Cryo rounds that can slow targets.

Health, damage and healing and cryo slow strength scales with level.

Any XP (frags/score) it gains is sent to you instead.

# Robomancer - Robogrunt Minions
Can summon friendly robogrunts that will follow you, can be teleported or killed via the minion menu.

Their health and damage scales with level. Robogrunts have thick armor and are resistant to bullets.

Regenerates HP.

Any XP (frags/score) they gain is sent to you instead.

# Xenomancer - Xen Minions
Can summon friendly Xen creatures that will follow you, can be teleported or killed via the minion menu. 

Their health and damage scales with level.

Regenerates HP.

Can be revived if they are dying, is only considered truly dead once their corpse has faded. Can be teleported to you in revivable state.

Any XP (frags/score) they gain is sent to you instead.

# Warden - Ice Shield Tank
Forms a shield of ice around the user that absorbs all damage. The shield has it's own HP. Recharges slower whilst it is active.

All damage taken is reflected back at the attacker, dealing damage as Radius Damage.

# Shocktrooper - Power Weapon Damage Dealer
Can equip a Shockrifle at will, can re-stow it by pressing ability button whilst holding one.

Stowing restores half of remaining ammo to battery. Picked up Shockroaches can also be stowed to restore battery this way.

Damage and Capacity of Shockrifles scale with level.

# Cloaker - Stealthy Damage Dealer 
Invisiblity cloak that gains a damage bonus, based on how full the battery is. Ending the cloak will activate a damaging nova, dealing damage based on remaining energy. Also become completely invisible to AI.

A percent of damage dealt by the nova will restore AP.

# Vanquisher - AoE Damage Dealer
Can consume Explosive Ammo Packs to grant a portion of Explosive Ammo to the ammo pool. All hitscan weapons will deal extra radius explosive damage, as well as creating a fire DoT at the impact location for a duration, DoT's stack infinitely.

Fire damage will scale with level.

Fire duration and AoE is fixed.

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
