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
Toggles a Bloodlust rage state, giving % damage dealt as lifesteal. Bloodlust recharges very slowly and drains very quickly. It relies on dealing damage to gain charge and maintain it when active.
20% of damage dealt as energy steal, does not scale with level.
Gain a damage bonus the lower your current HP, that scales with level.
Can be activated regardless of charge level.

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
Teleporting pulls them around you in a circle. 
Manually killing them does not refund any cost, only restores reserve.
All three minion types should attempt to eat dead enemies to regain their lost health when not in combat.
Their health and damage scales with level.
Any XP (frags/score) they gain is sent to you instead.
Can be healed with medkit. Can be revived.

# Warden - Ice Shield Tank
Can form an Ice Shield that layers over health and armor that has it's own health pool, making you functionally immortal against all damage types. Works best when used strategically to negate extreme burst damage such as fall damage and explosions.
Whilst active it absorbs all incoming damage until it shatters, there is no bleed-through.
Whilst active it will still recover over time, but 50% slower.
Has to fully recover between uses, but can be ended early to start recovering at 100%.
If ended early, any remaining health will be refunded over 5s.

# Shocktrooper - Power Weapon Damage Dealer
Always has a Shockrifle available, can stow it to regain Battery charge, meaning picked up shock roaches can be consumed to restore a large chunk of battery, stowing restores half of current ammo to battery.
Damage of Shockrifle scales with level.
Battery Capacity increases with level, allowing you to use it for longer.
Has to fully recharge between uses.

# Cloaker - Stealthy Damage Dealer 
Invisiblity cloak that gains a damage bonus, that drops as your battery loses charge.
Becomes completely invisible to AI.
Battery drains very quickly.
Battery is drained a signifiant amount per shot.
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
 The mod also features it's own recovery system. 
 Regeneration will halt for a delay after taking damage, displaying an icon in the hud.
 HP restores 1% of Max HP every 1.0s.
 AP restores 1% of Max AP every 0.5s.

# Difficulty
 The mod also features it's own difficulty setting system.
 Damage dealt by players is slightly increased, most weapons are rebalanced.
 Zombies and headcrabs specifically are more dangerous.

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
