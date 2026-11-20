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
const float SKILL_VAMPIRE_DAMAGEABILITYCHARGE = 0.30f; // Percent increase to base damage-to-charge conversion per level.
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
bool g_bSkillDiminishingReturns = true; // Skill levels above a skill's base level give diminishing returns. If false, they scale linearly.
float g_flSkillDiminishingReturnsFactor = 0.9f; // Default diminishing returns factor, unless overridden with a manual value.
float g_flSkillDiminishingReturnsFactorMinion = 0.5f; // Diminishing returns factor specifically for minion skills.
float g_flSkillDiminishingReturnsFactorHPAP = 0.9f; // Diminishing returns factor specifically for HP/AP skills.
float g_flSkillDiminishingReturnsFactorConversion = 0.6f; // Diminishing returns factor specifically for conmversion skills.
float g_flSkillDiminishingReturnsFactorCooldown = 0.6f; // Diminishing returns factor specifically for cooldown skills.
float g_flSkillDiminishingReturnsMinimum = 0.20f; // Minimum percent return for diminishing returns to cap at, will not go lower than this.

bool g_bLimitMaxRank = false; // If true, rank is capped at g_iHardLimitMaxRank. Normally rank is effectively unlimited.
int g_iHardLimitMaxRank = 10; // Max rank when g_bLimitMaxRank is enabled.

const int SKILL_UNLIMITED_MAX_LEVEL = 9999; // Skills have no practical level cap; base max level only decides where diminishing returns start.


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
    int baseMaxLevel; // Level at which diminishing returns begin (not a cap).
    float strength; // Per-level bonus.
    string unit;    // Suffix appended to the computed bonus (e.g. "%" or "s").
    float diminishRate; // Each level above baseMaxLevel contributes this fraction of the previous level.

    SkillDefinition(const string& in _name, const string& in _desc, int _baseMaxLevel,
                    float _strength, const string& in _unit, float _diminishRate)
    {
        name        = _name;
        description = _desc;
        baseMaxLevel = _baseMaxLevel;
        strength    = _strength;
        unit        = _unit;
        diminishRate = _diminishRate;
    }

    float GetEffectiveLevel(int level) const
    {
        if(!g_bSkillDiminishingReturns || level <= baseMaxLevel)
            return float(level);

        float result = float(baseMaxLevel);
        float contribution = 1.0f;
        float rate = Math.max(0.0f, Math.min(1.0f, diminishRate));
        float minimum = Math.max(0.0f, Math.min(1.0f, g_flSkillDiminishingReturnsMinimum));
        for(int i = baseMaxLevel; i < level; i++)
        {
            contribution = Math.max(minimum, contribution * rate);
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
    g_SkillDefs.resize(int(SkillID::SKILL_MAX_COUNT));

    // Basic skills. Def, name, description, max level (before diminishing returns), strength (for display), unit of measurement (for display) diminishing return rate.
    @g_SkillDefs[int(SkillID::SKILL_BASIC_MAXHP)] = SkillDefinition("Max Health", "Increases Max Health.", 10, int(SKILL_BASIC_MAXHP * 100.0f), "%", g_flSkillDiminishingReturnsFactorHPAP);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_MAXAP)] = SkillDefinition("Max Armor", "Increases Max Armor.", 10, int(SKILL_BASIC_MAXAP * 100.0f), "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_REGENHP)] = SkillDefinition("Health Regen", "Increases % HP/s regeneration.", 10, SKILL_BASIC_REGENHP * 100.0f, "% HP/s", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_REGENAP)] = SkillDefinition("Armor Regen", "Increases % AP/s regeneration.", 10, SKILL_BASIC_REGENAP * 100.0f, "% AP/s", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_ABILITYRECHARGE)] = SkillDefinition("Ability Recharge", "Increases ability recharge rate.", 10, SKILL_BASIC_ABILITYRECHARGE * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_AMMOREGEN)] = SkillDefinition("Ammo Resupply", "Increases max ammo resupplied. Resupplies a percentage of all max ammo every 30s. Explosives recovered at 50% of total amount.", 10, SKILL_BASIC_AMMOREGEN * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_LIFESTEAL)] = SkillDefinition("Lifesteal", "Increases lifesteal. Adds lifesteal effect to attacks.", 10, SKILL_BASIC_LIFESTEAL * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_ARMORSTEAL)] = SkillDefinition("Armorsteal", "Increases armorsteal. Adds armor steal effect to attacks.", 10, SKILL_BASIC_ARMORSTEAL * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_HPCONVERSION)] = SkillDefinition("Convert HP -> AP", "Converts Max HP to Max AP.", 10, SKILL_BASIC_HPCONVERSION * 100.0f, "%", g_flSkillDiminishingReturnsFactorConversion);
    @g_SkillDefs[int(SkillID::SKILL_BASIC_MEDKITCAPACITY)] = SkillDefinition("Medkit Capacity", "Increases medkit capacity.", 10, SKILL_BASIC_MEDKITCAPACITY * 100.0f, "%", g_flSkillDiminishingReturnsFactor);

    // Minion Class exclusive.
    @g_SkillDefs[int(SkillID::SKILL_MINION_POINT)] = SkillDefinition("Minion: Max Reserve", "Increases max reserve.", 5, SKILL_MINION_POINT * 100.0f, "%", g_flSkillDiminishingReturnsFactorMinion);
    @g_SkillDefs[int(SkillID::SKILL_MINION_HP)] = SkillDefinition("Minion: Max HP", "Increases minion HP.", 5, int(SKILL_MINION_HP * 100.0f), "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_MINION_REGEN)] = SkillDefinition("Minion: HP Regen", "Increases % HP/s regeneration for minions.", 5, SKILL_MINION_REGEN * 100.0f, "% HP/s", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_MINION_DAMAGE)] = SkillDefinition("Minion: Damage", "Increases minion damage.", 5, SKILL_MINION_DAMAGE * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_MINION_LIFESTEAL)] = SkillDefinition("Minion: Lifesteal", "Increases minion lifesteal to team. Adds lifesteal effect to minions, heals minions and players.", 5, SKILL_MINION_LIFESTEAL * 100.0f, "%", g_flSkillDiminishingReturnsFactor);

    // Medic.
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALPERCENT)] = SkillDefinition("Heal: Healing", "Increases healing from ability.", 5, SKILL_MEDIC_HEALPERCENT * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALREGEN)] = SkillDefinition("Heal: Regeneration", "Increases % HP/s regeneration for 10s. Adds regenerative effect to heal ability. Can heal NPC's.", 5, SKILL_MEDIC_HEALREGEN, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_POISON)] = SkillDefinition("Heal: Acid", "Increases acid damage. Adds acid effect to heal ability for enemies in radius.", 5, SKILL_MEDIC_POISON * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_REVIVE)] = SkillDefinition("Heal: Revive", "Reduces revive cooldown. Adds revive effect to heal ability. Can also be used whilst dead.", 5, SKILL_MEDIC_REVIVE, "s", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALAP)] = SkillDefinition("Heal: AP Restore", "Increases AP restored from ability heal.", 5, SKILL_MEDIC_HEALAP, "%", g_flSkillDiminishingReturnsFactor);

    // Vampire.
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_LIFESTEAL)] = SkillDefinition("Bloodlust: Lifesteal", "Increases lifesteal from all sources.", 5, SKILL_VAMPIRE_LIFESTEAL * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_DAMAGEABILITYCHARGE)] = SkillDefinition("Bloodlust: Damage Charge", "Increases damage to ability charge.", 5, SKILL_VAMPIRE_DAMAGEABILITYCHARGE * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_DAMAGEREDUCTION)] = SkillDefinition("Vampire: Damage Reduction", "Increases damage reduction per 10% missing HP. Adds stacking damage reduction based on missing HP (max of 80%). Does not require bloodlust to be active.", 5, SKILL_VAMPIRE_DAMAGEREDUCTION * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_OVERHEAL)] = SkillDefinition("Bloodlust: Overheal", "Increases overheal per level. Adds overhealing up to a percentage of Max HP.", 5, SKILL_VAMPIRE_OVERHEAL * 100.0f, "%", g_flSkillDiminishingReturnsFactorConversion);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_APCONVERSION)] = SkillDefinition("Bloodlust: Convert AP -> HP", "Converts Max AP to Max HP.", 5, SKILL_VAMPIRE_APCONVERSION * 100.0f, "%", g_flSkillDiminishingReturnsFactorConversion);
    @g_SkillDefs[int(SkillID::SKILL_VAMPIRE_DURATION)] = SkillDefinition("Bloodlust: Duration", "Increases bloodlust duration.", 5, SKILL_VAMPIRE_DURATION * 100.0f, "%", g_flSkillDiminishingReturnsFactor);

    // Engineer.
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYDAMAGE)] = SkillDefinition("Sentry: Damage", "Increases sentry damage.", 5, SKILL_ENGINEER_SENTRYDAMAGE * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYSPEED)] = SkillDefinition("Sentry: Speed", "Increases sentry fire rate and turn speed.", 5, SKILL_ENGINEER_SENTRYSPEED * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_MINIHEALAURA)] = SkillDefinition("Sentry: Heal Aura", "Increases HP/s. Adds a healing aura to the sentry that restores a percentage of HP each pulse.", 5, SKILL_ENGINEER_MINIHEALAURA * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_ROCKETS)] = SkillDefinition("Sentry: Rockets", "Reduces rocket cooldown. Adds rockets that the sentry can fire at targets to deal significant damage.", 5, SKILL_ENGINEER_ROCKETS * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYDURATION)] = SkillDefinition("Sentry: Duration", "Increases sentry duration.", 5, SKILL_ENGINEER_SENTRYDURATION * 100.0f, "%", g_flSkillDiminishingReturnsFactor);

    // Robomancer.
    @g_SkillDefs[int(SkillID::SKILL_ROBOMANCER_DAMAGEREDUCTION)] = SkillDefinition("Robo: Damage Reduction", "Increases damage reduction per active robot for self and minion. Adds stacking damage reduction for you and your minions, per minion you have active.", 5, SKILL_ROBOMANCER_DAMAGEREDUCTION * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_ROBOMANCER_FABRICATIONSTRENGTH)] = SkillDefinition("Robo: Fabrication Strength", "Increases restore power for Fabricated items.", 5, SKILL_ROBOMANCER_FABRICATIONSTRENGTH * 100.0f, "%", g_flSkillDiminishingReturnsFactor);

    // Xenomancer.

    // Necromancer.
    @g_SkillDefs[int(SkillID::SKILL_NECROMANCER_RATS)] = SkillDefinition("Necro: Zombie Rats Cooldown", "Decreases Zombie Rat cooldown. Adds Zombie Rats that burst from active minions.", 5, SKILL_NECROMANCER_RATS * 100.0f, "%", g_flSkillDiminishingReturnsFactorCooldown);
    @g_SkillDefs[int(SkillID::SKILL_NECROMANCER_MIASMA)] = SkillDefinition("Necro: Miasma", "Increases miasma damage. Adds a damaging Miasma Aura to active minions.", 5, SKILL_NECROMANCER_MIASMA * 100.0f, "%", g_flSkillDiminishingReturnsFactor);

    // Frostguard.
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_SHIELDHP)] = SkillDefinition("Iceshield: Shield HP", "Increases shield HP.", 5, SKILL_FROSTGUARD_SHIELDHP * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_DAMAGEREFLECT)] = SkillDefinition("Iceshield: Damage Reflect", "Increases shield damage reflect. Adds damage reflection to enemies that damage the shield.", 5, SKILL_FROSTGUARD_DAMAGEREFLECT * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_ACTIVERECHARGE)] = SkillDefinition("Iceshield: Active Recharge", "Increases shield recharge. Adds shield recharge whilst shield is active.", 5, SKILL_FROSTGUARD_ACTIVERECHARGE * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_HPABSORB)] = SkillDefinition("Iceshield: HP Absorb", "Increases shield HP absorb. Adds damage dealt to shield transferred to your HP.", 5, SKILL_FROSTGUARD_HPABSORB * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_FROSTGUARD_TEAMLINK)] = SkillDefinition("Iceshield: Share Shield", "Increases shield absorption per protected player (maximum 90%). Adds sharing your shield with nearby players, absorbing damage dealt to them.", 5, SKILL_FROSTGUARD_TEAMLINK * 100.0f, "%", g_flSkillDiminishingReturnsFactor);

    // Shocktrooper.
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_CAPACITY)] = SkillDefinition("Shockroach: Capacity", "Increases shockrifle capacity.", 5, SKILL_SHOCK_CAPACITY * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_DAMAGE)] = SkillDefinition("Shockroach: Damage", "Increases shockrifle damage.", 5, SKILL_SHOCK_DAMAGE * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_LIGHTNING)] = SkillDefinition("Shockroach: Lightning Strike", "Increases lightning strike damage. Adds lightning strikes to Shockroach attack hits.", 5, SKILL_SHOCK_LIGHTNING * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_DISPLACER)] = SkillDefinition("Shockroach: Displacer Orb Cooldown", "Increases orb cooldown. Use the skill again whilst active to fire a devastating portal orb.", 5, SKILL_SHOCK_DISPLACER * 100.0f, "%", g_flSkillDiminishingReturnsFactorCooldown);

    // Cloaker.
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKDAMAGE)] = SkillDefinition("Cloak: Damage Multiplier", "Increases cloak damage multiplier. Adds extra damage while cloaked. Dealing damage drains charge based on dealt damage.", 5, SKILL_CLOAKER_CLOAKDAMAGE * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKNOVADAMAGE)] = SkillDefinition("Cloak: Nova Damage", "Increases nova damage. Adds a damaging Nova to the cloak when deactivating it.", 5, SKILL_CLOAKER_CLOAKNOVADAMAGE * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKDURATION)] = SkillDefinition("Cloak: Duration", "Increases cloak duration.", 5, SKILL_CLOAKER_CLOAKDURATION * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_DRAINREDUCTION)] = SkillDefinition("Cloak: Drain Reduction", "Reduces cloak drain over time.", 5, SKILL_CLOAKER_DRAINREDUCTION * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_SPEED)] = SkillDefinition("Cloak: Speed Boost", "Increases speed whilst cloaked. Adds speed boost whilst cloaked.", 5, SKILL_CLOAKER_SPEED * 100.0f, "%", g_flSkillDiminishingReturnsFactor);

    // Firebug.
    @g_SkillDefs[int(SkillID::SKILL_FIREBUG_AMMOPOOL)] = SkillDefinition("Dragons Breath: Ammo", "Increases Dragon's Breath ammo pool maximum.", 5, SKILL_FIREBUG_AMMOPOOL * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_FIREBUG_EXPLOSIVEDAMAGE)] = SkillDefinition("Dragons Breath: Area Damage", "Increases area damage of Dragon's Breath.", 5, SKILL_FIREBUG_EXPLOSIVEDAMAGE * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_FIREBUG_FIREDAMAGE)] = SkillDefinition("Dragons Breath: Fire Damage", "Increases weapon damage as fire, per tick. Adds fire damage over time to Dragon's Breath.", 5, SKILL_FIREBUG_FIREDAMAGE * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_FIREBUG_FIREDURATION)] = SkillDefinition("Dragons Breath: Fire Duration", "Increases Dragon's Breath fire duration.", 5, SKILL_FIREBUG_FIREDURATION * 100.0f, "%", g_flSkillDiminishingReturnsFactor);

    // Swarmer.
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKDAMAGE)] = SkillDefinition("Snarks: Damage", "Increases snark damage.", 5, SKILL_SWARMER_SNARKDAMAGE * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKCOUNT)] = SkillDefinition("Snarks: Swarm Size", "Increases swarm size.", 5, SKILL_SWARMER_SNARKCOUNT * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKCHARGES)] = SkillDefinition("Snarks: Ability Uses", "Increases the number of swarms that can be held at once.", 3, SKILL_SWARMER_SNARKCHARGES * 100.0f, "%", g_flSkillDiminishingReturnsFactor);
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKGROWTH)] = SkillDefinition("Snarks: Snark Growth", "Increases snark Damage & Health, but reduces swarm size.", 5, int(SKILL_SWARMER_SNARKGROWTH * 100.0f), "%", g_flSkillDiminishingReturnsFactor);
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