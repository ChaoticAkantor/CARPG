# CARPG
 Class-based RPG Mod for Sven Co-op by Chaotic Akantor. Many features are still a work in progress and may be subject to change, especially class balancing. Discord can be found here, if you have any feedback or suggestions.

 https://discord.gg/JN6umuAt7H

# What is it?
 This plugin takes the basic principals of SCXPM but in an attempt to simplify features and ensure balance and has many more ingrained features and alterations.

# Classes?!
Rather than having lots of skills, most of the old SCXPM skills were coalested into auto-increasing stats on level up and regen was merged into it's own recovery system, so technically you start stronger but progress more steadily with a lower-ceiling for power instead of everyone ending up immortal.

1 Frag/score = 1 XP, no nonsence calculations and bloated numbers.
All XP is shared between players! And minion classes share XP with their master. No more hogging.

# How do I use Skills?
 Pressing Tertiary Fire (M3 by default) will activate your class ability. 
 
 Most if not all abilities are togglable and will drain class resource (default is called Energy) in some way. But some can only be activated whilst energy is full.

# Current Classes
# Medic - Healer
Toggles a healing aura with a very large radius, can heal yourself as well as friendly players and friendly NPC's. The minion class' best friend!
Can also revive players and NPC's at double the normal drain rate when triggered.
NPC healing is 50% stronger.

# Berserker - HP/Lifesteal Tank
Gain lifesteal.
Toggles a bloodlust rage state, giving % bonus HP, allowing you to overheal. Whilst bloodlust is active you gain double lifesteal, doubled again if holding a melee weapon.
Any overhealed health will slowly drain back to your default whilst inactive.
Has to fully recover between uses, but can be deactivated early to start recovering.

# Engineer - Robot Minions
Can summon friendly robots based on maximum reserve power via a menu.
Can be controlled with Sven NPC keybinds and teleported to you or destroyed on command. 
They can be also be killed or teleported from the menu. 
Teleporting pulls them around you in a circle and updates their HP from any gained levels. 
Manually killing them does not refund any cost, only reserve. 
Their health and damage scales with level. Robots have thick armor and are resistant to bullets.
Any XP (frags/score) they gain is sent to you instead.
Always gets a pipewrench, can hit them with the wrench to heal them. Can potentially be revived, but triggers detonation sequence on death!

# Xenologist - Xen Minions
Can summon friendly Xen Creatures based on maximum bio reserve via a menu. 
Can be controlled with Sven NPC keybinds and teleported to you or destroyed on command. 
They can be also be killed or teleported from the menu. 
Teleporting pulls them around you in a circle and updates their HP from any gained levels. 
Manually killing them does not refund any cost, only reserve.
All three minion types should attempt to eat other dead creatures to regain their lost health.
Their health and damage scales with level.
Any XP (frags/score) they gain is sent to you instead.
Can be healed with medkit. Can be revived.

# Warden - Ice Tank
Has a toggleable Ice Shield that layers over health and armor that has it's own health pool. 
Whilst active it absorbs all incoming damage until it shatters. 
Has to fully recover between uses, but can be shattered early to start recovering.

# Shocktrooper - Power Weapon Damage Dealer
Always has a Shockrifle available, can stow it to recharge Shock Charges (shockrifle ammo) using it's shockroach battery at an increased rate and max capacity. Can also stow picked up shock roaches in order to restore a large chunk of battery.

# Cloaker - Stealthy Damage Dealer 
Invisiblity cloak that gains a damage bonus based on the amount of energy you have, but drains a signifiant amount of energy per shot. 
Becomes completely invisible to AI for the duration. 
Cloak drains twice as fast whilst moving at max speed, crouching significantly reduces drain.
Has to fully recover between uses, but can be deactivated early to start recharging.

# Stat Scaling/Leveling
 Max HP/AP/Energy and certain ability features will scale with your level. Max level is 50.

 Each class has it's own max level and stats saved individually.

 Type "class" without quotes in chat to bring up the class menu in order to switch classes, can be done on the fly!

 Type "stats" without quotes in chat to bring up the stats menu to see your current stat and ability bonuses and see any other modifiers like ammo regen (WIP).

# Ammo Regeneration
 The mod also features an ammo regeneration system similar to Borderlands 1's ammo regen modifier, every bullet type is on it's own timer. Some classes get bonus reduction to these depending on levels gained.

 Explosives regeneration is extremely limited to most classes. Usually a threshold that stops you from regenerating it fully.

 The ammo system also multiplies ammo timers for horror map series for They Hunger and Afraid of Monsters Classic/DC.

# Recovery
 The mod also features it's own recovery system, regeneration will halt for a delay after taking damage.
 HP restores 1% per 1.0s. Meaning recovery will scale with max HP.
 AP restores 1% per 2.0s. Meaning recovery will scale with max AP.

# Difficulty
 The mod also features it's own difficulty system. 
 Damage dealt is slightly increased.
 Damage taken is also increasesd depending on enemy, mostly melee attacks. 
 Zombies and headcrabs specifically are more dangerous.

# Installation instructions:

1. Extract/drop CARPG into either Sven Co-op/Svencoop_addon/scripts/plugins/ or perferably Svencoop/scripts/plugins/.

2. Add the following to your default_plugins.txt located inside Sven Co-op/svencoop/;

		"plugin"
 	{
        "name" "CARPG"
		"script" "CARPG/CARPG"
	}

3. Go into Sven Co-op/svencoop/scripts/plugins and ensure you have a folder called "store" without the quotes, if you do not, you will need to create a blank folder and name it "store". If not, the plugin will not have the required access to store player data, as I don't think Angelscript has permission or functions to create folders, only text files.
