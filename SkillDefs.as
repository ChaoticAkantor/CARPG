/*
Skills definition file.

*/

// Standard/Basic skills, available to all classes.
const float SKILL_BASIC_MAXHP = 0.10f;  // Max HP per level.
const float SKILL_BASIC_MAXAP = 0.05f;  // Max AP per level.
const float SKILL_BASIC_REGENHP = 0.002f;  // HP regen scale (% of max HP) per level.
const float SKILL_BASIC_REGENAP = 0.0005f;  // AP regen scale (% of max AP) per level.
const float SKILL_BASIC_ABILITYRECHARGE = 0.05f; // Percent increase to ability recharge speed per level.
const int SKILL_BASIC_AMMOREGEN = 1; // +1 bullet per regen interval, per level.
const float SKILL_BASIC_LIFESTEAL = 0.01f; // Percent of damage dealt as lifesteal per level.
const float SKILL_BASIC_ARMORSTEAL = 0.0030f; // Percent of damage dealt as armorsteal per level.
const float SKILL_BASIC_HPCONVERSION = 0.06f; // Percent of Max HP to convert to AP per level.

// Class/Ability specific skills.
// Minion Class ('mancers) exclusive.
const int SKILL_MINION_POINT = 1; // +1 minion point per level.
const float SKILL_MINION_HP = 0.80f; // HP percent increase for minions per level.
const float SKILL_MINION_REGEN = 0.001f; // Max HP regen percent for minions per level.
const float SKILL_MINION_DAMAGE = 0.20f; // Damage percent increase for minions per level.
const float SKILL_MINION_LIFESTEAL = 0.03f; // Minion lifesteal percent to players (team) per level.

// Medic.
const float SKILL_MEDIC_HEALPERCENT = 0.20f; // Percent increase to max health healed per level.
const float SKILL_MEDIC_HEALREGEN = 0.20f; // Max health percent healed per interval after initial heal, per level (divided by 100).
const float SKILL_MEDIC_POISON = 5.00f; // Flat poison damage per level.
const float SKILL_MEDIC_REVIVE = 3.00f; // Reduce revive cooldown in seconds per level.
const float SKILL_MEDIC_HEALAP = 1.50f; // Percent of max AP to heal per level (divided by 100).

// Vampire.
const float SKILL_VAMPIRE_LIFESTEAL = 0.06f; // Percent increase to ALL lifesteal per level.
const float SKILL_VAMPIRE_DAMAGEABILITYCHARGE = 0.005f; // Percent of damage dealt converted to ability charge per level.
const float SKILL_VAMPIRE_DAMAGEREDUCTION = 0.05f; // Damage reduction per level.
const float SKILL_VAMPIRE_OVERHEAL = 0.10f; // Percent of max HP to overheal from lifesteal per level.
const float SKILL_VAMPIRE_APCONVERSION = 0.15f; // Percent of Max AP converted into Max HP.
const float SKILL_VAMPIRE_DURATION = 0.20f; // Percent increase to Bloodlust duration per level.

// Engineer.
const float SKILL_ENGINEER_SENTRYDAMAGE = 0.10f; // Sentry damage per level.
const float SKILL_ENGINEER_SENTRYSPEED = 0.10f; // Sentry attack speed per level.
const float SKILL_ENGINEER_MINIHEALAURA = 0.80f; // Mini-heal Aura % max HP heal per level (divided by 100).
const float SKILL_ENGINEER_ROCKETS = 0.06f; // Rocket % cooldown reduction per level.
const float SKILL_ENGINEER_SENTRYDURATION = 0.50f; // Sentry duration increase per level.

// Xenomancer.

// Necromancer.
const float SKILL_NECROMANCER_RATS = 0.06f; // Rat % cooldown reduction per level.

// Frostguard.
const float SKILL_FROSTGUARD_SHIELDHP = 0.20f; // Ice shield HP percent increase per level.
const float SKILL_FROSTGUARD_DAMAGEREFLECT = 0.08f; // Damage reflect per level.
const float SKILL_FROSTGUARD_ACTIVERECHARGE = 0.04f; // Active shield recharge per level.
const float SKILL_FROSTGUARD_HPABSORB = 0.05f; // HP absorb from damage reflected per level.
const float SKILL_FROSTGUARD_TEAMLINK = 0.05f; // Shield charge damage reduction per linked player per level.

// Cloaker.
const float SKILL_CLOAKER_CLOAKDAMAGE = 0.20f; // Cloak damage multiplier increase per level.
const float SKILL_CLOAKER_CLOAKNOVADAMAGE = 0.20f; // Cloak nova damage increase per level.
const float SKILL_CLOAKER_CLOAKDURATION = 0.20f; // Cloak duration increase per level.
const float SKILL_CLOAKER_DRAINREDUCTION = 0.05f; // Percent drain reduction.
const float SKILL_CLOAKER_SPEED = 0.10f; // Percent speed increase while cloaked.

// Shocktrooper.
const float SKILL_SHOCK_CAPACITY = 0.20f; // Shockrifle capacity per level.
const float SKILL_SHOCK_DAMAGE = 0.10f; // Shockrifle damage per level.
const float SKILL_SHOCK_LIGHTNING = 0.03f; // Shockrifle damage % as area lightning damage per level.
const float SKILL_SHOCK_DISPLACER = 0.04f; // Displacer Orb cooldown reduction per level.

// Firebug.
const float SKILL_FIREBUG_AMMOPOOL = 0.40f; // Ammo pool increase per level.
const float SKILL_FIREBUG_EXPLOSIVEDAMAGE = 0.10f; // Increase % of weapon damage dealt as radius damage per level.
const float SKILL_FIREBUG_FIREDAMAGE = 0.20f; // Increase % of weapon damage dealt as fire per tick per level.
const float SKILL_FIREBUG_FIREDURATION = 0.20f; // Fire duration increase per level.

// Swarmer.
const float SKILL_SWARMER_SNARKDAMAGE = 1.00f; // Snark damage per level.
const float SKILL_SWARMER_SNARKCOUNT = 0.20f; // Percent of extra snarks per level.

// formatFloat is for display strings only, strength (4th ctor arg) must stay a raw float for math.
string FormatSkillPerLevelText(float perLevelValue)
{
    return formatFloat(perLevelValue, "f", 0, 2);
}

string FormatSkillPerLevelPercentText(float perLevelFraction)
{
    return formatFloat(perLevelFraction * 100.0f, "f", 0, 2);
}

// --- Skill IDs ---
// Standard skills are available to all classes; Ability skills are class-specific.
enum SkillID
{
    // Standard (all classes).
    SKILL_BASIC_MAXHP = 0,
    SKILL_BASIC_MAXAP,
    SKILL_BASIC_REGENHP,
    SKILL_BASIC_REGENAP,
    SKILL_BASIC_ABILITYRECHARGE,
    SKILL_BASIC_AMMOREGEN,
    SKILL_BASIC_LIFESTEAL,
    SKILL_BASIC_ARMORSTEAL,
    SKILL_BASIC_HPCONVERSION,

    //Minion Classes.
    SKILL_MINION_POINT,
    SKILL_MINION_HP,
    SKILL_MINION_REGEN,
    SKILL_MINION_DAMAGE,
    SKILL_MINION_LIFESTEAL,

    // Medic.
    SKILL_MEDIC_HEALPERCENT,
    SKILL_MEDIC_HEALREGEN,
    SKILL_MEDIC_POISON,          
    SKILL_MEDIC_REVIVE,
    SKILL_MEDIC_HEALAP,

    // Vampire.
    SKILL_VAMPIRE_LIFESTEAL,
    SKILL_VAMPIRE_DAMAGEABILITYCHARGE,
    SKILL_VAMPIRE_DAMAGEREDUCTION,
    SKILL_VAMPIRE_OVERHEAL,
    SKILL_VAMPIRE_APCONVERSION,
    SKILL_VAMPIRE_DURATION,

    // Engineer.
    SKILL_ENGINEER_SENTRYDAMAGE,
    SKILL_ENGINEER_MINIHEALAURA,
    SKILL_ENGINEER_ROCKETS,
    SKILL_ENGINEER_SENTRYDURATION,
    SKILL_ENGINEER_SENTRYSPEED,

    // Robomancer.

    // Xenomancer.
    SKILL_XENOMANCER_LIFESTEAL,

    // Necromancer.
    SKILL_NECROMANCER_RATS,

    // Frostguard.
    SKILL_FROSTGUARD_SHIELDHP,
    SKILL_FROSTGUARD_DAMAGEREFLECT,
    SKILL_FROSTGUARD_ACTIVERECHARGE,
    SKILL_FROSTGUARD_HPABSORB,
    SKILL_FROSTGUARD_TEAMLINK,

    // Shocktrooper.
    SKILL_SHOCK_CAPACITY,
    SKILL_SHOCK_DAMAGE,
    SKILL_SHOCK_LIGHTNING,
    SKILL_SHOCK_DISPLACER,

    // Cloaker.
    SKILL_CLOAKER_CLOAKDAMAGE,
    SKILL_CLOAKER_CLOAKNOVADAMAGE,
    SKILL_CLOAKER_CLOAKDURATION,
    SKILL_CLOAKER_DRAINREDUCTION,
    SKILL_CLOAKER_SPEED,

    // Firebug.
    SKILL_FIREBUG_AMMOPOOL,
    SKILL_FIREBUG_EXPLOSIVEDAMAGE,
    SKILL_FIREBUG_FIREDAMAGE,
    SKILL_FIREBUG_FIREDURATION,

    // Swarmer.
    SKILL_SWARMER_SNARKDAMAGE,
    SKILL_SWARMER_SNARKCOUNT,


    // Total.
    SKILL_MAX_COUNT
}

class SkillDefinition
{
    string name; // Name.
    string description; // Description.
    int baseMaxLevel; // Base max level (without rank bonus).
    float strength; // Per-level bonus.
    string unit;    // Suffix appended to the computed bonus (e.g. "%" or "s").
    float rankBonusMultiplier;  // Multiplier for max levels to be added from rank.

    SkillDefinition(const string& in _name, const string& in _desc, int _baseMaxLevel,
                    float _strength = 0.0f, const string& in _unit = "%", float _rankBonusMultiplier = 0.0f)
    {
        name        = _name;
        description = _desc;
        baseMaxLevel = _baseMaxLevel;
        strength    = _strength;
        unit        = _unit;
        rankBonusMultiplier = _rankBonusMultiplier;
    }

    int GetEffectiveMaxLevel(int rebirthRank) const
    {
        return baseMaxLevel + int(rebirthRank * rankBonusMultiplier);
    }
}

array<SkillDefinition@> g_SkillDefs;

void InitializeSkillDefinitions()
{
    g_SkillDefs.resize(int(SkillID::SKILL_MAX_COUNT));

    // Standard/Basic skills (last value is for rank bonus multiplier).
    @g_SkillDefs[int(SkillID::SKILL_BASIC_MAXHP)] = SkillDefinition("Max Health", "+" + int(SKILL_BASIC_MAXHP * 100) + "% Max HP.", 10, int(SKILL_BASIC_MAXHP * 100.0f), "%", 1.0f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_MAXAP)] = SkillDefinition("Max Armor", "+" + int(SKILL_BASIC_MAXAP * 100) + "% Max AP.", 10, int(SKILL_BASIC_MAXAP * 100.0f), "%", 1.0f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_REGENHP)] = SkillDefinition("Health Regen", "+" + formatFloat(SKILL_BASIC_REGENHP * 100.0f, "f", 0, 2) + "% HP/s.", 10, SKILL_BASIC_REGENHP * 100.0f, "% HP/s", 1.0f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_REGENAP)] = SkillDefinition("Armor Regen", "+" + formatFloat(SKILL_BASIC_REGENAP * 100.0f, "f", 0, 2) + "% AP/s.", 10, SKILL_BASIC_REGENAP * 100.0f, "% AP/s", 1.0f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_ABILITYRECHARGE)] = SkillDefinition("Ability Recharge", "+" + formatFloat(SKILL_BASIC_ABILITYRECHARGE * 100, "f", 0, 2) + "% ability recharge speed.", 10, SKILL_BASIC_ABILITYRECHARGE * 100.0f, "%", 1.0f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_AMMOREGEN)] = SkillDefinition("Ammo Regen", "+" + int(SKILL_BASIC_AMMOREGEN) + " ammo gain per interval.", 5, int(SKILL_BASIC_AMMOREGEN), " Ammo", 0.0f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_LIFESTEAL)] = SkillDefinition("Lifesteal", "+" + formatFloat(SKILL_BASIC_LIFESTEAL * 100.0f, "f", 0, 2) + "% lifesteal.", 10, SKILL_BASIC_LIFESTEAL * 100.0f, "%", 1.0f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_ARMORSTEAL)] = SkillDefinition("Armorsteal", "+" + formatFloat(SKILL_BASIC_ARMORSTEAL * 100.0f, "f", 0, 2) + "% armorsteal.", 10, SKILL_BASIC_ARMORSTEAL * 100.0f, "%", 1.0f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_HPCONVERSION)] = SkillDefinition("Convert HP -> AP", "+" + formatFloat(SKILL_BASIC_HPCONVERSION * 100.0f, "f", 0, 2) + "% of Max HP converted to AP.", 10, SKILL_BASIC_HPCONVERSION * 100.0f, "%", 1.0f);

    // Minion Class exclusive.
    @g_SkillDefs[int(SkillID::SKILL_MINION_POINT)] = SkillDefinition("Minion: Minion Point", "+" + SKILL_MINION_POINT + " minion point.", 3, SKILL_MINION_POINT, " Point", 0.0f);
    @g_SkillDefs[int(SkillID::SKILL_MINION_HP)] = SkillDefinition("Minion: Max HP", "+" + int(SKILL_MINION_HP * 100) + "% minion HP.", 5, int(SKILL_MINION_HP * 100.0f), "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_MINION_REGEN)] = SkillDefinition("Minion: HP Regen", "+" + formatFloat(SKILL_MINION_REGEN * 100.0f, "f", 0, 2) + "% minion HP/s.", 5, SKILL_MINION_REGEN * 100.0f, "% HP/s", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_MINION_DAMAGE)] = SkillDefinition("Minion: Damage", "+" + formatFloat(SKILL_MINION_DAMAGE * 100.0f, "f", 0, 2) + "% minion damage.", 5, SKILL_MINION_DAMAGE * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_MINION_LIFESTEAL)] = SkillDefinition("Minion: Lifesteal", "+" + formatFloat(SKILL_MINION_LIFESTEAL * 100.0f, "f", 0, 2) + "% minion lifesteal to team.", 5, SKILL_MINION_LIFESTEAL * 100.0f, "%", 0.5f);

    // Medic.
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALPERCENT)] = SkillDefinition("Heal: Healing", "+" + formatFloat(SKILL_MEDIC_HEALPERCENT * 100.0f, "f", 0, 2) + "% Healed.", 5, SKILL_MEDIC_HEALPERCENT * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALREGEN)] = SkillDefinition("Heal: Regeneration", "+" + formatFloat(SKILL_MEDIC_HEALREGEN, "f", 0, 2) + "% HP/s for 10s.", 5, SKILL_MEDIC_HEALREGEN, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_POISON)] = SkillDefinition("Heal: Acid", "+" + formatFloat(SKILL_MEDIC_POISON, "f", 0, 2) + " acid damage.", 5, SKILL_MEDIC_POISON, "", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_REVIVE)] = SkillDefinition("Heal: Revive", "-" + formatFloat(SKILL_MEDIC_REVIVE, "f", 0, 2) + "s revive cooldown.", 5, SKILL_MEDIC_REVIVE, "s", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALAP)] = SkillDefinition("Heal: AP Restore", "+" + formatFloat(SKILL_MEDIC_HEALAP, "f", 0, 2) + "% of heals to AP.", 5, SKILL_MEDIC_HEALAP, "%", 0.5f);

    // Vampire.
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_LIFESTEAL)] = SkillDefinition("Bloodlust: Lifesteal", "+" + formatFloat(SKILL_VAMPIRE_LIFESTEAL * 100.0f, "f", 0, 2) + "% all lifesteal.", 5, SKILL_VAMPIRE_LIFESTEAL * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_DAMAGEABILITYCHARGE)] = SkillDefinition("Bloodlust: Damage Charge", "+" + formatFloat(SKILL_VAMPIRE_DAMAGEABILITYCHARGE * 100.0f, "f", 0, 2) + "% of damage charge.", 5, SKILL_VAMPIRE_DAMAGEABILITYCHARGE * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_DAMAGEREDUCTION)] = SkillDefinition("Bloodlust: Damage Reduction", "+" + formatFloat(SKILL_VAMPIRE_DAMAGEREDUCTION * 100.0f, "f", 0, 2) + "% damage reduction.", 5, SKILL_VAMPIRE_DAMAGEREDUCTION * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_OVERHEAL)] = SkillDefinition("Bloodlust: Overheal", "+" + formatFloat(SKILL_VAMPIRE_OVERHEAL * 100.0f, "f", 0, 2) + "% Overheal per level.", 5, SKILL_VAMPIRE_OVERHEAL * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_APCONVERSION)] = SkillDefinition("Bloodlust: Convert AP -> HP", "+" + formatFloat(SKILL_VAMPIRE_APCONVERSION * 100.0f, "f", 0, 2) + "% of Max AP -> HP.", 5, SKILL_VAMPIRE_APCONVERSION * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_DURATION)] = SkillDefinition("Bloodlust: Duration", "+" + formatFloat(SKILL_VAMPIRE_DURATION * 100.0f, "f", 0, 2) + "% Bloodlust duration.", 5, SKILL_VAMPIRE_DURATION * 100.0f, "%", 0.5f);

    // Engineer.
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYDAMAGE)] = SkillDefinition("Sentry: Damage", "+" + formatFloat(SKILL_ENGINEER_SENTRYDAMAGE * 100.0f, "f", 0, 2) + "% damage.", 5, SKILL_ENGINEER_SENTRYDAMAGE * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYSPEED)] = SkillDefinition("Sentry: Speed", "+" + formatFloat(SKILL_ENGINEER_SENTRYSPEED * 100.0f, "f", 0, 2) + "% attack speed.", 5, SKILL_ENGINEER_SENTRYSPEED * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_MINIHEALAURA)] = SkillDefinition("Sentry: Heal Aura", "+" + formatFloat(SKILL_ENGINEER_MINIHEALAURA * 100.0f, "f", 0, 2) + "% HP/s.", 5, SKILL_ENGINEER_MINIHEALAURA, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_ROCKETS)] = SkillDefinition("Sentry: Rockets", "-" + formatFloat(SKILL_ENGINEER_ROCKETS * 100.0f, "f", 0, 2) + "% rocket cooldown.", 5, SKILL_ENGINEER_ROCKETS * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYDURATION)] = SkillDefinition("Sentry: Duration", "+" + formatFloat(SKILL_ENGINEER_SENTRYDURATION * 100.0f, "f", 0, 2) + "% sentry duration.", 5, SKILL_ENGINEER_SENTRYDURATION * 100.0f, "%", 0.5f);

    // Robomancer.

    // Xenomancer.

    // Necromancer.
    @g_SkillDefs[int(SkillID::SKILL_NECROMANCER_RATS)] = SkillDefinition("Necro: Zombie Rats", "-" + formatFloat(SKILL_NECROMANCER_RATS * 100.0f, "f", 0, 2) + "% Zombie Rat cooldown.", 5, SKILL_NECROMANCER_RATS * 100.0f, "%", 0.5f);

    // Frostguard.
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_SHIELDHP)] = SkillDefinition("Iceshield: Shield HP", "+" + formatFloat(SKILL_FROSTGUARD_SHIELDHP * 100.0f, "f", 0, 2) + "% shield HP.", 5, SKILL_FROSTGUARD_SHIELDHP * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_DAMAGEREFLECT)] = SkillDefinition("Iceshield: Damage Reflect", "+" + formatFloat(SKILL_FROSTGUARD_DAMAGEREFLECT * 100.0f, "f", 0, 2) + "% shield damage reflect.", 5, SKILL_FROSTGUARD_DAMAGEREFLECT * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_ACTIVERECHARGE)] = SkillDefinition("Iceshield: Active Recharge", "+" + formatFloat(SKILL_FROSTGUARD_ACTIVERECHARGE * 100.0f, "f", 0, 2) + "% shield recharge.", 5, SKILL_FROSTGUARD_ACTIVERECHARGE * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_HPABSORB)] = SkillDefinition("Iceshield: HP Absorb", "+" + formatFloat(SKILL_FROSTGUARD_HPABSORB * 100.0f, "f", 0, 2) + "% shield HP absorb.", 5, SKILL_FROSTGUARD_HPABSORB * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_TEAMLINK)] = SkillDefinition("Iceshield: Share Shield", "+" + formatFloat(SKILL_FROSTGUARD_TEAMLINK * 100.0f, "f", 0, 2) + "% DR per protected player.", 5, SKILL_FROSTGUARD_TEAMLINK * 100.0f, "%", 0.5f);

    // Shocktrooper.
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_CAPACITY)] = SkillDefinition("Shockroach: Capacity", "+" + formatFloat(SKILL_SHOCK_CAPACITY * 100.0f, "f", 0, 2) + "% shockrifle capacity.", 5, SKILL_SHOCK_CAPACITY * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_DAMAGE)] = SkillDefinition("Shockroach: Damage", "+" + formatFloat(SKILL_SHOCK_DAMAGE * 100.0f, "f", 0, 2) + "% shockrifle damage.", 5, SKILL_SHOCK_DAMAGE * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_LIGHTNING)] = SkillDefinition("Shockroach: Lightning Strike", "+" + formatFloat(SKILL_SHOCK_LIGHTNING * 100.0f, "f", 0, 2) + "% lightning strike damage.", 5, SKILL_SHOCK_LIGHTNING * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_DISPLACER)] = SkillDefinition("Shockroach: Displacer Orb", "-" + formatFloat(SKILL_SHOCK_DISPLACER * 100.0f, "f", 0, 2) + "% orb cooldown.", 5, SKILL_SHOCK_DISPLACER * 100.0f, "%", 0.5f);

    // Cloaker.
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKDAMAGE)] = SkillDefinition("Cloak: Damage Multiplier", "+" + formatFloat(SKILL_CLOAKER_CLOAKDAMAGE * 100.0f, "f", 0, 2) + "% damage multiplier.", 5, SKILL_CLOAKER_CLOAKDAMAGE * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKNOVADAMAGE)] = SkillDefinition("Cloak: Nova Damage", "+" + formatFloat(SKILL_CLOAKER_CLOAKNOVADAMAGE * 100.0f, "f", 0, 2) + "% nova damage.", 5, SKILL_CLOAKER_CLOAKNOVADAMAGE * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKDURATION)] = SkillDefinition("Cloak: Duration", "+" + formatFloat(SKILL_CLOAKER_CLOAKDURATION * 100.0f, "f", 0, 2) + "% cloak duration.", 5, SKILL_CLOAKER_CLOAKDURATION * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_DRAINREDUCTION)] = SkillDefinition("Cloak: Drain Reduction", "-" + formatFloat(SKILL_CLOAKER_DRAINREDUCTION * 100.0f, "f", 0, 2) + "% reduced drain.", 5, SKILL_CLOAKER_DRAINREDUCTION * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_SPEED)] = SkillDefinition("Cloak: Speed Boost", "+" + formatFloat(SKILL_CLOAKER_SPEED * 100.0f, "f", 0, 2) + "% speed whilst cloaked.", 5, SKILL_CLOAKER_SPEED * 100.0f, "%", 0.5f);

    // Firebug.
    @g_SkillDefs[int(SkillID::SKILL_FIREBUG_AMMOPOOL)] = SkillDefinition("Dragons Breath: Ammo", "+" + formatFloat(SKILL_FIREBUG_AMMOPOOL * 100.0f, "f", 0, 2) + "% ammo pool.", 5, SKILL_FIREBUG_AMMOPOOL * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_FIREBUG_EXPLOSIVEDAMAGE)] = SkillDefinition("Dragons Breath: Area Damage", "+" + formatFloat(SKILL_FIREBUG_EXPLOSIVEDAMAGE * 100.0f, "f", 0, 2) + "% weapon damage in a radius.", 5, SKILL_FIREBUG_EXPLOSIVEDAMAGE * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_FIREBUG_FIREDAMAGE)] = SkillDefinition("Dragons Breath: Fire Damage", "+" + formatFloat(SKILL_FIREBUG_FIREDAMAGE * 100.0f, "f", 0, 2) + "% weapon damage as fire per tick.", 5, SKILL_FIREBUG_FIREDAMAGE * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_FIREBUG_FIREDURATION)] = SkillDefinition("Dragons Breath: Fire Duration", "+" + formatFloat(SKILL_FIREBUG_FIREDURATION * 100.0f, "f", 0, 2) + "% fire duration.", 5, SKILL_FIREBUG_FIREDURATION * 100.0f, "%", 0.5f);

    // Swarmer.
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKDAMAGE)] = SkillDefinition("Snarks: Snark Damage", "+" + formatFloat(SKILL_SWARMER_SNARKDAMAGE * 100.0f, "f", 0, 2) + "% snark damage.", 5, SKILL_SWARMER_SNARKDAMAGE * 100.0f, "%", 0.5f);
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKCOUNT)] = SkillDefinition("Snarks: Snark Count", "+" + int(SKILL_SWARMER_SNARKCOUNT * 100.0f) + "% swarm size.", 5, int(SKILL_SWARMER_SNARKCOUNT * 100.0f), "%", 0.5f);
}

// Returns the standard skill IDs (shared across all classes).
array<SkillID> GetStandardSkillIDs()
{
    array<SkillID> result;
    result.insertLast(SkillID::SKILL_BASIC_MAXHP);
    result.insertLast(SkillID::SKILL_BASIC_MAXAP);
    result.insertLast(SkillID::SKILL_BASIC_REGENHP);
    result.insertLast(SkillID::SKILL_BASIC_REGENAP);
    result.insertLast(SkillID::SKILL_BASIC_ABILITYRECHARGE);
    result.insertLast(SkillID::SKILL_BASIC_AMMOREGEN);
    result.insertLast(SkillID::SKILL_BASIC_LIFESTEAL);
    result.insertLast(SkillID::SKILL_BASIC_ARMORSTEAL);
    result.insertLast(SkillID::SKILL_BASIC_HPCONVERSION);
    return result;
}

// Returns the ability skill IDs for a given class.
array<SkillID> GetAbilitySkillIDs(PlayerClass pClass)
{
    array<SkillID> result;
    switch(pClass)
    {
        case PlayerClass::CLASS_MEDIC:
            result.insertLast(SkillID::SKILL_MEDIC_HEALPERCENT);
            result.insertLast(SkillID::SKILL_MEDIC_HEALREGEN);

            result.insertLast(SkillID::SKILL_MEDIC_POISON);
            result.insertLast(SkillID::SKILL_MEDIC_REVIVE);
            result.insertLast(SkillID::SKILL_MEDIC_HEALAP);
            break;

        case PlayerClass::CLASS_VAMPIRE:
            result.insertLast(SkillID::SKILL_VAMPIRE_LIFESTEAL);
            result.insertLast(SkillID::SKILL_VAMPIRE_DAMAGEABILITYCHARGE);
            result.insertLast(SkillID::SKILL_VAMPIRE_DAMAGEREDUCTION);
            result.insertLast(SkillID::SKILL_VAMPIRE_OVERHEAL);
            result.insertLast(SkillID::SKILL_VAMPIRE_APCONVERSION);
            result.insertLast(SkillID::SKILL_VAMPIRE_DURATION);
            break;

        case PlayerClass::CLASS_ENGINEER:
            result.insertLast(SkillID::SKILL_ENGINEER_SENTRYDAMAGE);
            result.insertLast(SkillID::SKILL_ENGINEER_SENTRYSPEED);
            result.insertLast(SkillID::SKILL_ENGINEER_MINIHEALAURA);
            result.insertLast(SkillID::SKILL_ENGINEER_ROCKETS);
            result.insertLast(SkillID::SKILL_ENGINEER_SENTRYDURATION);
            break;

        case PlayerClass::CLASS_ROBOMANCER:
            result.insertLast(SkillID::SKILL_MINION_POINT);
            result.insertLast(SkillID::SKILL_MINION_HP);
            result.insertLast(SkillID::SKILL_MINION_REGEN);
            result.insertLast(SkillID::SKILL_MINION_DAMAGE);
            result.insertLast(SkillID::SKILL_MINION_LIFESTEAL);
            break;

        case PlayerClass::CLASS_XENOMANCER:
            result.insertLast(SkillID::SKILL_MINION_POINT);
            result.insertLast(SkillID::SKILL_MINION_HP);
            result.insertLast(SkillID::SKILL_MINION_REGEN);
            result.insertLast(SkillID::SKILL_MINION_DAMAGE);
            result.insertLast(SkillID::SKILL_MINION_LIFESTEAL);
            break;

        case PlayerClass::CLASS_NECROMANCER:
            result.insertLast(SkillID::SKILL_MINION_POINT);
            result.insertLast(SkillID::SKILL_MINION_HP);
            result.insertLast(SkillID::SKILL_MINION_REGEN);
            result.insertLast(SkillID::SKILL_MINION_DAMAGE);
            result.insertLast(SkillID::SKILL_MINION_LIFESTEAL);
            result.insertLast(SkillID::SKILL_NECROMANCER_RATS);
            break;

        case PlayerClass::CLASS_FROSTGUARD:
            result.insertLast(SkillID::SKILL_FROSTGUARD_SHIELDHP);
            result.insertLast(SkillID::SKILL_FROSTGUARD_DAMAGEREFLECT);
            result.insertLast(SkillID::SKILL_FROSTGUARD_ACTIVERECHARGE);
            result.insertLast(SkillID::SKILL_FROSTGUARD_HPABSORB);
            result.insertLast(SkillID::SKILL_FROSTGUARD_TEAMLINK);
            break;

        case PlayerClass::CLASS_SHOCKTROOPER:
            result.insertLast(SkillID::SKILL_SHOCK_CAPACITY);
            result.insertLast(SkillID::SKILL_SHOCK_DAMAGE);
            result.insertLast(SkillID::SKILL_SHOCK_LIGHTNING);
            result.insertLast(SkillID::SKILL_SHOCK_DISPLACER);
            break;

        case PlayerClass::CLASS_CLOAKER:
            result.insertLast(SkillID::SKILL_CLOAKER_CLOAKDAMAGE);
            result.insertLast(SkillID::SKILL_CLOAKER_CLOAKNOVADAMAGE);
            result.insertLast(SkillID::SKILL_CLOAKER_CLOAKDURATION);
            result.insertLast(SkillID::SKILL_CLOAKER_DRAINREDUCTION);
            result.insertLast(SkillID::SKILL_CLOAKER_SPEED);
            break;

        case PlayerClass::CLASS_FIREBUG:
            result.insertLast(SkillID::SKILL_FIREBUG_AMMOPOOL);
            result.insertLast(SkillID::SKILL_FIREBUG_EXPLOSIVEDAMAGE);
            result.insertLast(SkillID::SKILL_FIREBUG_FIREDAMAGE);
            result.insertLast(SkillID::SKILL_FIREBUG_FIREDURATION);
            break;
            
        case PlayerClass::CLASS_SWARMER:
            result.insertLast(SkillID::SKILL_SWARMER_SNARKDAMAGE);
            result.insertLast(SkillID::SKILL_SWARMER_SNARKCOUNT);
            break;
    }
    return result;
}