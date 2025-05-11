# CARPG
 Class-based RPG Mod for Sven Co-op by Chaotic Akantor. Many features are still a work in progress and may be subject to change, especially class balancing.

# What is it?
 This mod takes the basic principals of SCXPM but in an attempt to simplify features and ensure balance and has many more ingrained features and alterations.

# Classes?!
Rather than having lots of skills, most of the old SCXPM skills were coalested into auto-increasing stats on level up and regen was merged into it's own recovery system, so technically you start stronger but progress more steadily with a lower-ceiling for power through being unkillable.

1 Frag/score = 1 XP, no nonsence calculations and bloated numbers.
All XP is shared between players! And minion classes share XP with their master. No more hogging.

# Current Classes
# Medic - Healer
Toggles a healing aura with a very large radius, can heal yourself as well as friendly players and friendly NPC's.
NPC healing is 3x stronger.

# Berserker - HP/Lifesteal Tank
Toggles a bloodlust rage state, a scaling % of your AP is converted into bonus temporary HP and will allow you to overheal, you also gain lifesteal for a % of damage dealt, doubled if holding a melee weapon.
Any overhealed health will slowly drain back to your default whilst inactive.

# Engineer - Minions
can summon friendly robots based on maximum energy pool. Can be controlled with Sven NPC keybinds and teleported to you or destroyed on command. Always gets a pipewrench, can hit them with the wrench to heal them. Teleporting them also heals them but does not give you XP.
Any XP they gain is sent to you instead.

# Defender - DR Tank
Has a toggleable barrier that layers over health and armor that has it's own health pool. Whilst active, further reduces damage you take. Starts at 75% damage reduction and scales up to 100% as you level.

# Shocktrooper - Power Weapon Damage Dealer
Always has a Shockrifle available, can stow it to recharge Shock Charges (shockrifle ammo) using it's shockroach battery at an increased rate and max capacity. Can also stow picked up shock roaches in order to restore a large chunk of battery.

# Cloaker - Stealthy Damage Dealer 
Invisiblity cloak that gains a damage bonus based on the amount of energy you have, but drains a signifiant amount of energy per shot. Becomes completely invisible to AI for the duration. Cloak drains faster whilst moving at max speed, crouching significantly reduces drain.

# No Skills?
 Rather than skill points and a skill menu, the mod has classes. Each class has a single unique ability.

 Pressing Tertiary Fire (M3 by default) will activate your class ability. 
 
 Most if not all abilities are togglable and will drain class resource (default is called Energy) in some way.

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
 HP restores 1% /1s.
 AP restores 1% /0.1s.

# Difficulty
 The mod also features it's own difficulty system. 
 Damage dealt is significantly increased, making combat much faster and feel more visceral.
 Damage taken is also reworked depending on enemy types. 
 Hostile Xen wildlife and Zombies are now a threat. Weaker guns hit harder, melee attacks from lower-tier and human enemies now pack a punch.
 
 Players generally have full armor between encounters, which tends to make them much tougher.

# Installation instructions:

1. Extract/drop CARPG into either Sven Co-op/Svencoop_addon/scripts/plugins/ or perferably Svencoop/scripts/plugins/.

2. Add the following to your default_plugins.txt located inside Sven Co-op/svencoop/;

		"plugin"
 	{
        "name" "CARPG"
		"script" "CARPG/CARPG"
	}

3. Go into Sven Co-op/svencoop/scripts/plugins and ensure you have a folder called "store" without the quotes, if you do not, you will need to create a blank folder and name it "store". If not, the plugin will not have the required access to store player data, as I don't think Angelscript has permission or functions to create folders, only text files.
