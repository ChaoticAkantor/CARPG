/*
Skills definition file.

*/

// Standard/Basic skills, available to all classes.
const float SKILL_BASIC_MAXHP = 0.10f;  // Max HP per level.
const float SKILL_BASIC_MAXAP = 0.05f;  // Max AP per level.
const float SKILL_BASIC_REGENHP = 0.002f;  // HP regen scale (% of max HP) per level.
const float SKILL_BASIC_REGENAP = 0.0005f;  // AP regen scale (% of max AP) per level.
const float SKILL_BASIC_ABILITYRECHARGE = 0.05f; // Percent increase to ability recharge speed per level.
const float SKILL_BASIC_AMMOREGEN = 0.03f; // Fraction of base max ammo capacity regenerated per level.
const float SKILL_BASIC_LIFESTEAL = 0.01f; // Percent of damage dealt as lifesteal per level.
const float SKILL_BASIC_ARMORSTEAL = 0.0030f; // Percent of damage dealt as armorsteal per level.
const float SKILL_BASIC_HPCONVERSION = 0.06f; // Percent of Max HP to convert to AP per level.
const float SKILL_BASIC_MEDKITCAPACITY = 0.10f; // Medkit capacity increase per level.

// Class-specific skills.
// Minion Class ('mancers) exclusive.
const float SKILL_MINION_POINT = 0.10f; // Percent increase to max reserve per level.
const float SKILL_MINION_HP = 0.80f; // HP percent increase for minions per level.
const float SKILL_MINION_REGEN = 0.001f; // Max HP regen percent for minions per level.
const float SKILL_MINION_DAMAGE = 0.10f; // Damage percent increase for minions per level.
const float SKILL_MINION_LIFESTEAL = 0.03f; // Minion lifesteal percent to players (team) per level.

// Medic.
const float SKILL_MEDIC_HEALPERCENT = 0.20f; // Percent increase to max health healed per level.
const float SKILL_MEDIC_HEALREGEN = 0.20f; // Max health percent healed per interval after initial heal, per level (divided by 100).
const float SKILL_MEDIC_POISON = 0.20f; // Percent increase to acid damage per level to enemies in heal radius.
const float SKILL_MEDIC_REVIVE = 3.00f; // Reduce revive cooldown in seconds per level.
const float SKILL_MEDIC_HEALAP = 1.50f; // Percent of max AP to heal per level (divided by 100).

// Vampire.
const float SKILL_VAMPIRE_LIFESTEAL = 0.06f; // Percent increase to ALL lifesteal per level.
const float SKILL_VAMPIRE_DAMAGEABILITYCHARGE = 0.40f; // Percent increase to base damage-to-charge conversion per level.
const float SKILL_VAMPIRE_DAMAGEREDUCTION = 0.005f; // Damage reduction per level for each 10% missing HP.
const float SKILL_VAMPIRE_OVERHEAL = 0.10f; // Percent of max HP to overheal from lifesteal per level.
const float SKILL_VAMPIRE_APCONVERSION = 0.15f; // Percent of Max AP converted into Max HP.
const float SKILL_VAMPIRE_DURATION = 0.20f; // Percent increase to Bloodlust duration per level.

// Engineer.
const float SKILL_ENGINEER_SENTRYDAMAGE = 0.10f; // Sentry damage per level.
const float SKILL_ENGINEER_SENTRYSPEED = 0.08f; // Sentry attack speed per level.
const float SKILL_ENGINEER_MINIHEALAURA = 0.80f; // Mini-heal Aura % max HP heal per level (divided by 100).
const float SKILL_ENGINEER_ROCKETS = 0.05f; // Rocket % cooldown reduction per level.
const float SKILL_ENGINEER_SENTRYDURATION = 0.20f; // Sentry duration increase per level.

// Robomancer.
const float SKILL_ROBOMANCER_DAMAGEREDUCTION = 0.03f; // Damage reduction per active robot, per level for robots and self.
const float SKILL_ROBOMANCER_FABRICATIONSTRENGTH = 0.15f; // Strength of Fabrication items per level.

// Xenomancer.


// Necromancer.
const float SKILL_NECROMANCER_RATS = 0.05f; // Rat % cooldown reduction per level.
const float SKILL_NECROMANCER_MIASMA = 0.20f; // Percent increase to base miasma damage per level, on each active minion.

// Frostguard.
const float SKILL_FROSTGUARD_SHIELDHP = 0.20f; // Ice shield HP percent increase per level.
const float SKILL_FROSTGUARD_DAMAGEREFLECT = 0.08f; // Damage reflect per level.
const float SKILL_FROSTGUARD_ACTIVERECHARGE = 0.04f; // Active shield recharge per level.
const float SKILL_FROSTGUARD_HPABSORB = 0.05f; // HP absorb from damage reflected per level.
const float SKILL_FROSTGUARD_TEAMLINK = 0.05f; // Shield charge damage reduction per linked player per level.

// Cloaker.
const float SKILL_CLOAKER_CLOAKDAMAGE = 0.10f; // Cloak damage multiplier increase per level.
const float SKILL_CLOAKER_CLOAKNOVADAMAGE = 0.10f; // Cloak nova damage increase per level.
const float SKILL_CLOAKER_CLOAKDURATION = 0.20f; // Cloak duration increase per level.
const float SKILL_CLOAKER_DRAINREDUCTION = 0.05f; // Percent drain reduction.
const float SKILL_CLOAKER_SPEED = 0.10f; // Percent speed increase while cloaked.

// Shocktrooper.
const float SKILL_SHOCK_CAPACITY = 0.20f; // Shockrifle capacity per level.
const float SKILL_SHOCK_DAMAGE = 0.10f; // Shockrifle damage per level.
const float SKILL_SHOCK_LIGHTNING = 0.02f; // Shockrifle damage % as area lightning damage per level.
const float SKILL_SHOCK_DISPLACER = 0.06f; // Displacer Orb cooldown reduction per level.

// Firebug.
const float SKILL_FIREBUG_AMMOPOOL = 0.40f; // Ammo pool increase per level.
const float SKILL_FIREBUG_EXPLOSIVEDAMAGE = 0.05f; // Increase % of weapon damage dealt as radius damage per level.
const float SKILL_FIREBUG_FIREDAMAGE = 0.10f; // Increase % of weapon damage dealt as fire per tick per level.
const float SKILL_FIREBUG_FIREDURATION = 0.20f; // Fire duration increase per level.

// Swarmer.
const float SKILL_SWARMER_SNARKDAMAGE = 0.10f; // Snark damage per level.
const float SKILL_SWARMER_SNARKCOUNT = 0.20f; // Percent of extra snarks per level.
const float SKILL_SWARMER_SNARKCHARGES = 1.00f; // Snark charges per level (internally just an ability max increase).
const float SKILL_SWARMER_SNARKGROWTH = 0.20f; // Increases snark damage & health per level but reduces swarm count by HALF the modifier value.

// Rank system settings.
bool g_bSkillDiminishingReturns = true; // Disables diminishing returns for skill's over default max level, but locks rank to maximum defined below.
int g_iHardLimitMaxRank = 10; // Determines the max rank if above is enabled.


// formatFloat is for display strings only, strength (4th ctor arg) must stay a raw float for math.
enum RankSkillID
{
    RANK_SKILL_LEGACY_LEVEL_CAP = 0, // Retained for v8 save compatibility.
    RANK_SKILL_BASIC_CAP,
    RANK_SKILL_CLASS_CAP,
    RANK_SKILL_COUNT
}

class RankSkillDefinition
{
    string name;
    string description;
    float increase;

    RankSkillDefinition(const string& in _name, const string& in _description, float _increase)
    {
        name = _name;
        description = _description;
        increase = _increase;
    }
}

array<RankSkillDefinition@> g_RankSkillDefs;

string FormatSkillPerLevelText(float perLevelValue)
{
    return formatFloat(perLevelValue, "f", 0, 2);
}

string FormatSkillPerLevelPercentText(float perLevelFraction)
{
    return formatFloat(perLevelFraction * 100.0f, "f", 0, 2);
}

// --- Skill IDs ---
// Standard skills are available to all classes; class skills are class-specific.
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
    SKILL_BASIC_MEDKITCAPACITY,

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
    SKILL_ROBOMANCER_DAMAGEREDUCTION,
    SKILL_ROBOMANCER_FABRICATIONSTRENGTH,

    // Xenomancer.
    SKILL_XENOMANCER_LIFESTEAL,

    // Necromancer.
    SKILL_NECROMANCER_RATS,
    SKILL_NECROMANCER_MIASMA,

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
    SKILL_SWARMER_SNARKCHARGES,
    SKILL_SWARMER_SNARKGROWTH,

    // Total.
    SKILL_MAX_COUNT
}

class SkillDefinition
{
    string name; // Name.
    string description; // Description template; {amount} and {half} are per-level bonuses.
    int baseMaxLevel; // Base max level (without rank bonus).
    float strength; // Per-level bonus.
    string unit;    // Suffix appended to the computed bonus (e.g. "%" or "s").
    float diminishRate; // Each level above baseMaxLevel contributes this fraction of the previous level.

    SkillDefinition(const string& in _name, const string& in _desc, int _baseMaxLevel,
                    float _strength = 0.0f, const string& in _unit = "%", float _diminishRate = 0.9f)
    {
        name        = _name;
        description = _desc;
        baseMaxLevel = _baseMaxLevel;
        strength    = _strength;
        unit        = _unit;
        diminishRate = _diminishRate;
    }

    int GetEffectiveMaxLevel(int purchasedBonus) const
    {
        return baseMaxLevel + purchasedBonus;
    }

    float GetEffectiveLevel(int level) const
    {
        if(!g_bSkillDiminishingReturns || level <= baseMaxLevel)
            return float(level);

        float result = float(baseMaxLevel);
        float contribution = 1.0f;
        float rate = Math.max(0.0f, Math.min(1.0f, diminishRate));
        for(int i = baseMaxLevel; i < level; i++)
        {
            contribution *= rate;
            result += contribution;
        }
        return result;
    }

    string GetDescription(int level) const
    {
        float amount = (GetEffectiveLevel(level) - GetEffectiveLevel(level - 1)) * strength;
        string result = description;
        result = result.Replace("{amount}", formatFloat(amount, "f", 0, 3));
        return result.Replace("{half}", formatFloat(amount * 0.5f, "f", 0, 3));
    }
}

array<SkillDefinition@> g_SkillDefs;

void InitializeSkillDefinitions()
{
    g_RankSkillDefs.resize(int(RankSkillID::RANK_SKILL_COUNT));
    @g_RankSkillDefs[int(RankSkillID::RANK_SKILL_BASIC_CAP)] = RankSkillDefinition("Basic Skill Cap", "Max", 1.0f);
    @g_RankSkillDefs[int(RankSkillID::RANK_SKILL_CLASS_CAP)] = RankSkillDefinition("Class Skill Cap", "Max", 1.0f);
    g_SkillDefs.resize(int(SkillID::SKILL_MAX_COUNT));

    // The final value on each skill is its diminishing-return rate.
    @g_SkillDefs[int(SkillID::SKILL_BASIC_MAXHP)] = SkillDefinition("Max Health", "+{amount}% Max HP.", 10, int(SKILL_BASIC_MAXHP * 100.0f), "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_MAXAP)] = SkillDefinition("Max Armor", "+{amount}% Max AP.", 10, int(SKILL_BASIC_MAXAP * 100.0f), "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_REGENHP)] = SkillDefinition("Health Regen", "+{amount}% HP/s.", 10, SKILL_BASIC_REGENHP * 100.0f, "% HP/s", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_REGENAP)] = SkillDefinition("Armor Regen", "+{amount}% AP/s.", 10, SKILL_BASIC_REGENAP * 100.0f, "% AP/s", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_ABILITYRECHARGE)] = SkillDefinition("Ability Recharge", "+{amount}% ability recharge.", 10, SKILL_BASIC_ABILITYRECHARGE * 100.0f, "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_AMMOREGEN)] = SkillDefinition("Ammo Resupply", "+{amount}% max ammo resupplied.", 10, SKILL_BASIC_AMMOREGEN * 100.0f, "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_LIFESTEAL)] = SkillDefinition("Lifesteal", "+{amount}% lifesteal.", 10, SKILL_BASIC_LIFESTEAL * 100.0f, "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_ARMORSTEAL)] = SkillDefinition("Armorsteal", "+{amount}% armorsteal.", 10, SKILL_BASIC_ARMORSTEAL * 100.0f, "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_HPCONVERSION)] = SkillDefinition("Convert HP -> AP", "+{amount}% Max HP converted to AP.", 10, SKILL_BASIC_HPCONVERSION * 100.0f, "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_MEDKITCAPACITY)] = SkillDefinition("Medkit Capacity", "+{amount}% medkit capacity.", 10, SKILL_BASIC_MEDKITCAPACITY * 100.0f, "%", 0.9f);

    // Minion Class exclusive.
    @g_SkillDefs[int(SkillID::SKILL_MINION_POINT)] = SkillDefinition("Minion: Max Reserve", "+{amount}% max reserve.", 5, SKILL_MINION_POINT * 100.0f, "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_MINION_HP)] = SkillDefinition("Minion: Max HP", "+{amount}% minion HP.", 5, int(SKILL_MINION_HP * 100.0f), "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_MINION_REGEN)] = SkillDefinition("Minion: HP Regen", "+{amount}% minion HP/s.", 5, SKILL_MINION_REGEN * 100.0f, "% HP/s", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_MINION_DAMAGE)] = SkillDefinition("Minion: Damage", "+{amount}% minion damage.", 5, SKILL_MINION_DAMAGE * 100.0f, "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_MINION_LIFESTEAL)] = SkillDefinition("Minion: Lifesteal", "+{amount}% minion lifesteal to team.", 5, SKILL_MINION_LIFESTEAL * 100.0f, "%", 0.9f);

    // Medic.
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALPERCENT)] = SkillDefinition("Heal: Healing", "+{amount}% Healed.", 5, SKILL_MEDIC_HEALPERCENT * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALREGEN)] = SkillDefinition("Heal: Regeneration", "+{amount}% HP/s for 10s.", 5, SKILL_MEDIC_HEALREGEN, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_POISON)] = SkillDefinition("Heal: Acid", "+{amount}% acid damage.", 5, SKILL_MEDIC_POISON * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_REVIVE)] = SkillDefinition("Heal: Revive", "-{amount}s revive cooldown.", 5, SKILL_MEDIC_REVIVE, "s", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALAP)] = SkillDefinition("Heal: AP Restore", "+{amount}% of heals to AP.", 5, SKILL_MEDIC_HEALAP, "%", 0.95f);

    // Vampire.
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_LIFESTEAL)] = SkillDefinition("Bloodlust: Lifesteal", "+{amount}% all lifesteal.", 5, SKILL_VAMPIRE_LIFESTEAL * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_DAMAGEABILITYCHARGE)] = SkillDefinition("Bloodlust: Damage Charge", "+{amount}% damage charge.", 5, SKILL_VAMPIRE_DAMAGEABILITYCHARGE * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_DAMAGEREDUCTION)] = SkillDefinition("Vampire: Damage Reduction", "+{amount}% (max 80%) per 10% missing HP.", 5, SKILL_VAMPIRE_DAMAGEREDUCTION * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_OVERHEAL)] = SkillDefinition("Bloodlust: Overheal", "+{amount}% Overheal per level.", 5, SKILL_VAMPIRE_OVERHEAL * 100.0f, "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_APCONVERSION)] = SkillDefinition("Bloodlust: Convert AP -> HP", "+{amount}% of Max AP -> HP.", 5, SKILL_VAMPIRE_APCONVERSION * 100.0f, "%", 0.85f);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_DURATION)] = SkillDefinition("Bloodlust: Duration", "+{amount}% duration.", 5, SKILL_VAMPIRE_DURATION * 100.0f, "%", 0.95f);

    // Engineer.
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYDAMAGE)] = SkillDefinition("Sentry: Damage", "+{amount}% damage.", 5, SKILL_ENGINEER_SENTRYDAMAGE * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYSPEED)] = SkillDefinition("Sentry: Speed", "+{amount}% attack speed.", 5, SKILL_ENGINEER_SENTRYSPEED * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_MINIHEALAURA)] = SkillDefinition("Sentry: Heal Aura", "+{amount}% HP/s.", 5, SKILL_ENGINEER_MINIHEALAURA, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_ROCKETS)] = SkillDefinition("Sentry: Rockets", "-{amount}% rocket cooldown.", 5, SKILL_ENGINEER_ROCKETS * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYDURATION)] = SkillDefinition("Sentry: Duration", "+{amount}% sentry duration.", 5, SKILL_ENGINEER_SENTRYDURATION * 100.0f, "%", 0.95f);

    // Robomancer.
    @g_SkillDefs[int(SkillID::SKILL_ROBOMANCER_DAMAGEREDUCTION)] = SkillDefinition("Robo: Damage Reduction", "+{amount}% damage reduction per robot for self and minion.", 5, SKILL_ROBOMANCER_DAMAGEREDUCTION * 100.0f, "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_ROBOMANCER_FABRICATIONSTRENGTH)] = SkillDefinition("Robo: Fabrication Strength", "+{amount}% strength for Fabricated items.", 5, SKILL_ROBOMANCER_FABRICATIONSTRENGTH * 100.0f, "%", 0.95f);

    // Xenomancer.

    // Necromancer.
    @g_SkillDefs[int(SkillID::SKILL_NECROMANCER_RATS)] = SkillDefinition("Necro: Zombie Rats", "-{amount}% Zombie Rat cooldown.", 5, SKILL_NECROMANCER_RATS * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_NECROMANCER_MIASMA)] = SkillDefinition("Necro: Miasma", "+{amount}% minion miasma damage.", 5, SKILL_NECROMANCER_MIASMA * 100.0f, "%", 0.95f);

    // Frostguard.
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_SHIELDHP)] = SkillDefinition("Iceshield: Shield HP", "+{amount}% shield HP.", 5, SKILL_FROSTGUARD_SHIELDHP * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_DAMAGEREFLECT)] = SkillDefinition("Iceshield: Damage Reflect", "+{amount}% shield damage reflect.", 5, SKILL_FROSTGUARD_DAMAGEREFLECT * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_ACTIVERECHARGE)] = SkillDefinition("Iceshield: Active Recharge", "+{amount}% shield recharge.", 5, SKILL_FROSTGUARD_ACTIVERECHARGE * 100.0f, "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_HPABSORB)] = SkillDefinition("Iceshield: HP Absorb", "+{amount}% shield HP absorb.", 5, SKILL_FROSTGUARD_HPABSORB * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_TEAMLINK)] = SkillDefinition("Iceshield: Share Shield", "+{amount}% DR per protected player.", 5, SKILL_FROSTGUARD_TEAMLINK * 100.0f, "%", 0.95f);

    // Shocktrooper.
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_CAPACITY)] = SkillDefinition("Shockroach: Capacity", "+{amount}% shockrifle capacity.", 5, SKILL_SHOCK_CAPACITY * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_DAMAGE)] = SkillDefinition("Shockroach: Damage", "+{amount}% shockrifle damage.", 5, SKILL_SHOCK_DAMAGE * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_LIGHTNING)] = SkillDefinition("Shockroach: Lightning Strike", "+{amount}% lightning strike damage.", 5, SKILL_SHOCK_LIGHTNING * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_DISPLACER)] = SkillDefinition("Shockroach: Displacer Orb", "-{amount}% orb cooldown.", 5, SKILL_SHOCK_DISPLACER * 100.0f, "%", 0.95f);

    // Cloaker.
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKDAMAGE)] = SkillDefinition("Cloak: Damage Multiplier", "+{amount}% damage multiplier.", 5, SKILL_CLOAKER_CLOAKDAMAGE * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKNOVADAMAGE)] = SkillDefinition("Cloak: Nova Damage", "+{amount}% nova damage.", 5, SKILL_CLOAKER_CLOAKNOVADAMAGE * 100.0f, "%", 0.9f);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKDURATION)] = SkillDefinition("Cloak: Duration", "+{amount}% cloak duration.", 5, SKILL_CLOAKER_CLOAKDURATION * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_DRAINREDUCTION)] = SkillDefinition("Cloak: Drain Reduction", "-{amount}% reduced drain.", 5, SKILL_CLOAKER_DRAINREDUCTION * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_SPEED)] = SkillDefinition("Cloak: Speed Boost", "+{amount}% speed whilst cloaked.", 5, SKILL_CLOAKER_SPEED * 100.0f, "%", 0.95f);

    // Firebug.
    @g_SkillDefs[int(SkillID::SKILL_FIREBUG_AMMOPOOL)] = SkillDefinition("Dragons Breath: Ammo", "+{amount}% ammo pool.", 5, SKILL_FIREBUG_AMMOPOOL * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_FIREBUG_EXPLOSIVEDAMAGE)] = SkillDefinition("Dragons Breath: Area Damage", "+{amount}% weapon damage in a radius.", 5, SKILL_FIREBUG_EXPLOSIVEDAMAGE * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_FIREBUG_FIREDAMAGE)] = SkillDefinition("Dragons Breath: Fire Damage", "+{amount}% weapon damage as fire per tick.", 5, SKILL_FIREBUG_FIREDAMAGE * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_FIREBUG_FIREDURATION)] = SkillDefinition("Dragons Breath: Fire Duration", "+{amount}% fire duration.", 5, SKILL_FIREBUG_FIREDURATION * 100.0f, "%", 0.95f);

    // Swarmer.
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKDAMAGE)] = SkillDefinition("Snarks: Damage", "+{amount}% snark damage.", 5, SKILL_SWARMER_SNARKDAMAGE * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKCOUNT)] = SkillDefinition("Snarks: Swarm Size", "+{amount}% swarm size.", 5, SKILL_SWARMER_SNARKCOUNT * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKCHARGES)] = SkillDefinition("Snarks: Ability Uses", "+{amount}% max uses.", 3, SKILL_SWARMER_SNARKCHARGES * 100.0f, "%", 0.95f);
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKGROWTH)] = SkillDefinition("Snarks: Snark Growth", "+{amount}% DMG & HP -{half}% swarm size.", 5, int(SKILL_SWARMER_SNARKGROWTH * 100.0f), "%", 0.95f);
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
    result.insertLast(SkillID::SKILL_BASIC_MEDKITCAPACITY);
    return result;
}

// Returns the class skill IDs for a given class.
array<SkillID> GetClassSkillIDs(PlayerClass pClass)
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
            result.insertLast(SkillID::SKILL_ROBOMANCER_DAMAGEREDUCTION);
            result.insertLast(SkillID::SKILL_ROBOMANCER_FABRICATIONSTRENGTH);
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
            result.insertLast(SkillID::SKILL_NECROMANCER_MIASMA);
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
            result.insertLast(SkillID::SKILL_SWARMER_SNARKCHARGES);
            result.insertLast(SkillID::SKILL_SWARMER_SNARKGROWTH);
            break;
    }
    return result;
}