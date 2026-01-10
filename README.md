# CARPG
 Class-based RPG Mod for Sven Co-op by Chaotic Akantor. Many features are still a work in progress and may be subject to change, especially class balancing. Discord can be found here, if you have any feedback or suggestions.

 https://discord.gg/FbsxHMvPGN

# What is it?
 This plugin takes the basic principals of SCXPM but in an attempt to simplify features and turn it into a class-based mod similar to Killing Floor.

# Classes?!
Rather than having lots of skills, most of the old SCXPM skills were coalested into auto-increasing stats on level up and regen was merged into it's own recovery system.

All abilities scale in various ways as they level.

1 Frag/score = 1 XP, no bloated numbers.
All XP is shared between players! And minion classes share XP with their team. No more hogging. Even whilst dead or in observer mode you will continue to earn XP!

# How do I use Skills?
 Typing useability in chat, or binding a button to it and pressing it will activate your class ability.
 Type bind mouse3 say "useability" in console and replace mouse3 with the key you want to use. 

# Current Classes
# Medic - Healer/AoE Damage Dealer
Whilst active creates a Healing aura with a large radius, can heal yourself as well as friendly players and friendly NPC's every second, this includes other player's minions. Can also revive players for an increased cost.

Deals equivalent poison damage as heal value to all enemies caught in the aura.

NPC healing is stronger.

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

# Leveling
 Default Max Level is 100.

 Max HP and AP will scale with your level, based on your class.

 Each class has it's own max level and stats saved individually.

 Type "class" without quotes in chat to bring up the class menu in order to switch classes, can be done on the fly!

 Type "stats" without quotes in chat to bring up the stats menu to see your current stat and ability bonuses and see any other modifiers like ammo regen (WIP).

# Ammo Regeneration
 The mod also features an ammo regeneration system similar to Borderlands 1's ammo regen modifier, every bullet type is on it's own timer. Some classes get bonus reduction to these timers depending on levels gained.

 Explosives regeneration is extremely limited to most classes. Usually a threshold that stops you from regenerating it fully.

 The ammo system also multiplies ammo timers for different map series such as They Hunger and Afraid of Monsters Classic/DC.

# Recovery
 The mod also features it's own recovery system. 
 Regeneration will halt a small delay after taking damage, displaying an icon in the hud.
 HP restores 1% of Max HP every 1.0s.
 AP restores 1% of Max AP every 2.0s.

# Difficulty
 The mod also features it's own difficulty normalising system.
 Damage dealt by players is slightly increased, most weapons are rebalanced.
 Zombies and headcrabs specifically hit harder. Certain bullet types from enemies do more damage due to the player changes.

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
