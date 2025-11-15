# CARPG
 Class-based RPG Mod for Sven Co-op by Chaotic Akantor. Many features are still a work in progress and may be subject to change, especially class balancing. Discord can be found here, if you have any feedback or suggestions.

 https://discord.gg/FbsxHMvPGN

# What is it?
 This plugin takes the basic principals of SCXPM but in an attempt to simplify features and turn it into a class-based mod similar to Killing Floor.

# Classes?!
Rather than having lots of skills, most of the old SCXPM skills were coalested into auto-increasing stats on level up and regen was merged into it's own recovery system.

All abilities gain increased duration or extra charges as they level.
All abilities require full charge to activate, but can be ended early to either refund cost or start recharging.
Most ability features or strength scale with level.

1 Frag/score = 1 XP, no nonsence calculations and bloated numbers.
All XP is shared between players! And minion classes share XP with their team. No more hogging. Even in whilst dead or in observer mode you continue to earn XP!

# How do I use Skills?
 Typing useability in chat, or binding a button to it and pressing it will activate your class ability.
 Type bind mouse3 say "useability" in console and replace mouse3 with the key you want to use. 
 
 Most if not all abilities are togglable, but can only be activated when full.

# Current Classes
# Medic - Healer
Whilst active creates a Healing aura with a large radius, can heal yourself as well as friendly players and friendly NPC's every second, this includes other player's minions. Can also revive players for an increased cost.

Deals equivalent poison damage as heal value to all enemies caught in the aura.

NPC healing is 50% stronger.

Has a moderate recharge rate.

# Berserker - HP/Lifesteal Tank
Toggles a Bloodlust rage state, giving % damage dealt as lifesteal. It relies on dealing damage to gain charge and maintain it whilst active as it recharges very slowly on it's own.

Also gain a damage bonus the lower your current HP, that scales with level.

Has a slow recharge rate.

# Engineer - Healer/Minion Hybrid
Can summon a single friendly Sentry that heals all allies every second, has an extremely large radius. Activating the ability again will recall the Sentry. Uses duration rather than minion points system. 

Health, damage and heal amount scales with level. Sentry turrets are very brittle, so it has very high base health to compensate.

Sentry heal affects itself at 20x strength. Can also hit it with the wrench to heal it by a large amount.

Triggers detonation sequence on death! Medium damage.

Any XP (frags/score) it gains is sent to you instead.

Has a moderate recharge rate.

# Robomancer - Robogrunt Minions
Can summon friendly robogrunts based on points remaining via a menu, robots with stronger weapons cost more points.

Points regenerate very slowly when not in use, number of points increase with level.

They can be be killed or teleported from the menu.

Can be controlled with Sven NPC keybinds.  

Their health and damage scales with level. Robogrunts have thick armor and are resistant to bullets.

Robogrunts regenerate 1% health per second. Can hit them with the wrench to heal them by a large amount.

Triggers detonation sequence on death! High damage.

Any XP (frags/score) they gain is sent to you instead.

Has a slow recharge rate.

# Xenomancer - Xen Minions
Can summon friendly creatures based on points remaining via a menu, larger creature types cost more points but have more health.

Points regenerate very slowly when not in use, number of points increase with level.

They can be be killed or teleported from the menu.

Can be controlled with Sven NPC keybinds.  

Their health and damage scales with level.

Creatures regenerate 1% health per second. Can heal them with the medkit, but it is not very effective.

Can be revived if they die, is only considered truly dead once their corpse has faded. Can be teleported to you in revivable state.

Any XP (frags/score) they gain is sent to you instead.

Has a slow recharge rate.

# Warden - Ice Shield Tank
Whilst active it absorbs all incoming damage until it shatters, there is no bleed-through, making you functionally immortal against all damage types, but does not stop recovery delay from triggering.

Whilst active it will still recover over time, but 50% slower.

Has a faster recharge rate.

# Shocktrooper - Power Weapon Damage Dealer
Can equip a Shockrifle, can re-stow it by pressing ability button whilst holding one. Even if you throw it away, you will always get another.

Picked up Shockroaches can also be stowed to restore a battery, stowing restores half of current ammo to battery.

Damage of Shockrifle increases with level, this damage bonus counts for any Shockroach you hold.

Battery Capacity increases with level, far beyond a normal Shockroach.

Has a slow recharge rate.

# Cloaker - Stealthy Damage Dealer 
Invisiblity cloak that gains a damage bonus, based on how full the battery is.

Becomes completely invisible to AI.

Battery drains by a large amount when dealing damage.

Has a faster recharge rate.

# Vanquisher - AoE Damage Dealer
Can consume Explosive Ammo Packs to grant Explosive Ammo to all bullet-type weapons, adding extra radius explosive damage.

One Explosive Ammo Pack fills 20% of your maximum capacity.

Slow-firing weapons get a radius damage multiplier with Explosive Ammo.

Maximum Explosive Ammo capacity, radius damage and Explosive Ammo Pack charges increase with level.

Has a slow recharge rate.

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
 Regeneration will halt for a 2s delay after taking damage, displaying an icon in the hud.
 HP restores 1% of Max HP every 1.0s.
 AP restores 1% of Max AP every 0.5s.

# Difficulty
 The mod also features it's own difficulty normalising system.
 Damage dealt by players is slightly increased, most weapons are rebalanced.
 Zombies and headcrabs specifically hit harder.

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
