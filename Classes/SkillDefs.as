/*
Skills definition file.

*/

// Standard skills, available to all classes.
const float SKILL_MAXHP = 0.10f;  // Max HP per level.
    const int SKILL_MAXHP_LVL = 10;

const float SKILL_MAXAP = 0.05f;  // Max AP per level.
    const int SKILL_MAXAP_LVL = 10;

const float SKILL_REGENHP = 0.002f;  // HP regen scale (% of max HP) per level.
    const int SKILL_REGENHP_LVL = 10;

const float SKILL_REGENAP = 0.0005f;  // AP regen scale (% of max AP) per level.
    const int SKILL_REGENAP_LVL = 10;

const float SKILL_ABILITYRECHARGE = 0.05f; // Percent increase to ability recharge speed per level.
    const int SKILL_ABILITYRECHARGE_LVL = 10;

const int SKILL_AMMOREGEN = 1; // +1 bullet per regen interval, per level.
    const int SKILL_AMMOREGEN_LVL = 5;

const float SKILL_LIFESTEAL = 0.01f; // Percent of damage dealt as lifesteal per level.
    const int SKILL_LIFESTEAL_LVL = 10;

const float SKILL_HPCONVERSION = 0.06f; // Percent of Max HP to convert to AP per level.
    const int SKILL_HPCONVERSION_LVL = 10;


// Class/Ability specific skills.
// Minion Class exclusive.
const int SKILL_MINIONPOINT = 1; // +1 minion point per level.
    const int SKILL_MINIONPOINT_LVL = 3; // More than 3 is excessive. Changing this is not recommended.

const float SKILL_MINIONHP = 0.50f; // HP percent increase for minions per level.
    const int SKILL_MINIONHP_LVL = 5;

const float SKILL_MINIONREGEN = 0.001f; // Max HP regen percent for minions per level.
    const int SKILL_MINIONREGEN_LVL = 5;

const float SKILL_MINIONDAMAGE = 0.20f; // Damage percent increase for minions per level.
    const int SKILL_MINIONDAMAGE_LVL = 5;


// Medic.
const float SKILL_MEDIC_HEALPERCENT = 1.00f;  // Increase max health percent healed per level (divided by 100).
    const int SKILL_MEDIC_HEALPERCENT_LVL = 5;

const float SKILL_MEDIC_POISON = 2.00f; // Flat poison damage per level.
    const int SKILL_MEDIC_POISON_LVL = 5;

const float SKILL_MEDIC_REVIVE = 6.00f;   // Reduce revive cooldown in seconds per level.
    const int SKILL_MEDIC_REVIVE_LVL = 5;

const float SKILL_MEDIC_HEALAP = 0.40f;  // Percent of max AP to heal per level (divided by 100).
    const int SKILL_MEDIC_HEALAP_LVL = 5;

const float SKILL_MEDIC_DURATION = 0.20f; // Percent increase to heal aura duration per level.
    const int SKILL_MEDIC_DURATION_LVL = 5;


// Berserker.
const float SKILL_BERSERKER_LIFESTEAL = 0.05f; // Flat increase to lifesteal per level.
    const int SKILL_BERSERKER_LIFESTEAL_LVL = 5;

const float SKILL_BERSERKER_DAMAGEABILITYCHARGE = 0.01f; // Percent of damage dealt converted to ability charge per level.
    const int SKILL_BERSERKER_DAMAGEABILITYCHARGE_LVL = 5;

const float SKILL_BERSERKER_DAMAGEREDUCTION = 0.08f; // Damage reduction per level.
    const int SKILL_BERSERKER_DAMAGEREDUCTION_LVL = 5;

const float SKILL_BERSERKER_OVERHEAL = 0.10f; // Percent of max HP to overheal from lifesteal per level.
    const int SKILL_BERSERKER_OVERHEAL_LVL = 5;

const float SKILL_BERSERKER_APCONVERSION = 0.20f; // Percent of Max AP converted into Max HP.
    const int SKILL_BERSERKER_APCONVERSION_LVL = 5;

const float SKILL_BERSERKER_DURATION = 0.20f; // Percent increase to Bloodlust duration per level.
    const int SKILL_BERSERKER_BLOODLUSTDURATION_LVL = 5;


// Engineer.
const float SKILL_ENGINEER_SENTRYDAMAGE = 0.30f; // Sentry damage per level.
    const int SKILL_ENGINEER_SENTRYDAMAGE_LVL = 5;

const float SKILL_ENGINEER_MINIHEALAURA = 1.0f; // Mini-heal Aura % max HP heal per level.
    const int SKILL_ENGINEER_MINIHEALAURA_LVL = 5;

const float SKILL_ENGINEER_EXPLOSIVEAMMO = 0.20f;  // % of damage as area explosive damage per level.
    const int SKILL_ENGINEER_EXPLOSIVEAMMO_LVL = 5;

const float SKILL_ENGINEER_SENTRYDURATION = 0.20f; // Sentry duration increase per level.
    const int SKILL_ENGINEER_SENTRYDURATION_LVL = 5;


// Xenomancer.
const float SKILL_XENOMANCER_LIFESTEAL = 0.01f; // Minion lifesteal percent to players per level.
    const int SKILL_XENOMANCER_LIFESTEAL_LVL = 3;


// Necromancer.
const float SKILL_NECROMANCER_RATS = 3.0f; // Cooldown reduction in seconds per level.
    const int SKILL_NECROMANCER_RATS_LVL = 5;


// Warden.
const float SKILL_WARDEN_SHIELDHP = 0.20f; // Ice shield HP percent increase per level.
    const int SKILL_WARDEN_SHIELDHP_LVL = 5;

const float SKILL_WARDEN_DAMAGEREFLECT = 0.08f; // Damage reflect per level.
    const int SKILL_WARDEN_DAMAGEREFLECT_LVL = 5;

const float SKILL_WARDEN_ACTIVERECHARGE = 0.05f; // Active shield recharge per level.
    const int SKILL_WARDEN_ACTIVERECHARGE_LVL = 5;

const float SKILL_WARDEN_HPABSORB = 0.06f; // HP absorb from damage reflected per level.
    const int SKILL_WARDEN_HPABSORB_LVL = 5;


// Cloaker.
const float SKILL_CLOAKER_CLOAKDAMAGE = 0.10f; // Cloak damage bonus increase per level.
    const int SKILL_CLOAKER_CLOAKDAMAGE_LVL = 5;

const float SKILL_CLOAKER_CLOAKNOVADAMAGE = 0.20f; // Cloak nova damage increase per level.
    const int SKILL_CLOAKER_CLOAKNOVADAMAGE_LVL = 5;

const float SKILL_CLOAKER_CLOAKDURATION = 0.20f; // Cloak duration increase per level.
    const int SKILL_CLOAKER_CLOAKDURATION_LVL = 5;

const float SKILL_CLOAKER_STANDINGDRAIN = 0.20f; // Percent drain reduction while standing still.
    const int SKILL_CLOAKER_STANDINGDRAIN_LVL = 5;

const float SKILL_CLOAKER_SPEED = 0.20f; // Percent speed increase while cloaked.
    const int SKILL_CLOAKER_SPEED_LVL = 5;


// Shocktrooper.
const float SKILL_SHOCK_CAPACITY = 0.20f; // Shockrifle capacity per level.
    const int SKILL_SHOCK_CAPACITY_LVL = 5;

const float SKILL_SHOCK_DAMAGE = 0.20f; // Shockrifle damage per level.
    const int SKILL_SHOCK_DAMAGE_LVL = 5;

const float SKILL_SHOCK_LIGHTNING = 0.04f; // Shockrifle damage % as area lightning damage per level.
    const int SKILL_SHOCK_LIGHTNING_LVL = 5;


// Vanquisher.
const float SKILL_VANQUISHER_AMMOPOOL = 0.60f; // Ammo pool increase per level.
    const int SKILL_VANQUISHER_AMMOPOOL_LVL = 5;

const float SKILL_VANQUISHER_EXPLOSIVEDAMAGE = 1.0f; // Flat increase of added explosive damage per level.
    const int SKILL_VANQUISHER_EXPLOSIVEDAMAGE_LVL = 5;

const float SKILL_VANQUISHER_FIREDAMAGE = 0.06f; // Percentage of explosion converted to extra fire damage per level.
    const int SKILL_VANQUISHER_FIREDAMAGE_LVL = 5;

const float SKILL_VANQUISHER_FIREDURATION = 1.0f; // Flat added fire damage ticks per level.
    const int SKILL_VANQUISHER_FIREDURATION_LVL = 5;


// Swarmer.
const float SKILL_SWARMER_SNARKDAMAGE = 1.50f; // Snark damage per level.
    const int SKILL_SWARMER_SNARKDAMAGE_LVL = 5;

const float SKILL_SWARMER_SNARKCOUNT = 0.20f; // Percent of extra snarks per level.
    const int SKILL_SWARMER_SNARKCOUNT_LVL = 5;


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
    SKILL_MAXHP = 0,
    SKILL_MAXAP,
    SKILL_REGENHP,
    SKILL_REGENAP,
    SKILL_ABILITYRECHARGE,
    SKILL_AMMOREGEN,
    SKILL_LIFESTEAL,
    SKILL_HPCONVERSION,

    //Minion Classes.
    SKILL_MINIONPOINT,
    SKILL_MINIONHP,
    SKILL_MINIONREGEN,
    SKILL_MINIONDAMAGE,

    // Medic.
    SKILL_MEDIC_HEALPERCENT,
    SKILL_MEDIC_POISON,          
    SKILL_MEDIC_REVIVE,
    SKILL_MEDIC_HEALAP,
    SKILL_MEDIC_DURATION,

    // Berserker.
    SKILL_BERSERKER_LIFESTEAL,
    SKILL_BERSERKER_DAMAGEABILITYCHARGE,
    SKILL_BERSERKER_DAMAGEREDUCTION,
    SKILL_BERSERKER_OVERHEAL,
    SKILL_BERSERKER_APCONVERSION,
    SKILL_BERSERKER_DURATION,

    // Engineer.
    SKILL_ENGINEER_SENTRYDAMAGE,
    SKILL_ENGINEER_MINIHEALAURA,
    SKILL_ENGINEER_EXPLOSIVEAMMO,
    SKILL_ENGINEER_SENTRYDURATION,

    // Robomancer.


    // Xenomancer.
    SKILL_XENOMANCER_LIFESTEAL,

    // Necromancer.
    SKILL_NECROMANCER_RATS,

    // Warden.
    SKILL_WARDEN_SHIELDHP,
    SKILL_WARDEN_DAMAGEREFLECT,
    SKILL_WARDEN_ACTIVERECHARGE,
    SKILL_WARDEN_HPABSORB,

    // Shocktrooper.
    SKILL_SHOCK_CAPACITY,
    SKILL_SHOCK_DAMAGE,
    SKILL_SHOCK_LIGHTNING,

    // Cloaker.
    SKILL_CLOAKER_CLOAKDAMAGE,
    SKILL_CLOAKER_CLOAKNOVADAMAGE,
    SKILL_CLOAKER_CLOAKDURATION,
    SKILL_CLOAKER_STANDINGDRAIN,
    SKILL_CLOAKER_SPEED,

    // Vanquisher.
    SKILL_VANQUISHER_AMMOPOOL,
    SKILL_VANQUISHER_EXPLOSIVEDAMAGE,
    SKILL_VANQUISHER_FIREDAMAGE,
    SKILL_VANQUISHER_FIREDURATION,

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
    int maxLevel; // Max skill level.
    float strength; // Per-level bonus.
    string unit;    // Suffix appended to the computed bonus (e.g. "%" or "s").

    SkillDefinition(const string& in _name, const string& in _desc, int _maxLevel, float _strength = 0.0f, const string& in _unit = "%")
    {
        name        = _name;
        description = _desc;
        maxLevel    = _maxLevel;
        strength    = _strength;
        unit        = _unit;
    }
}

array<SkillDefinition@> g_SkillDefs;

void InitializeSkillDefinitions()
{
    g_SkillDefs.resize(int(SkillID::SKILL_MAX_COUNT));

    // Standard.
    @g_SkillDefs[int(SkillID::SKILL_MAXHP)] = SkillDefinition("Max Health", "+" + int(SKILL_MAXHP * 100) + "% Max HP.", SKILL_MAXHP_LVL, int(SKILL_MAXHP * 100.0f), "%");
    @g_SkillDefs[int(SkillID::SKILL_MAXAP)] = SkillDefinition("Max Armor", "+" + int(SKILL_MAXAP * 100) + "% Max AP.", SKILL_MAXAP_LVL, int(SKILL_MAXAP * 100.0f), "%");
    @g_SkillDefs[int(SkillID::SKILL_REGENHP)] = SkillDefinition("Health Regen", "+" + formatFloat(SKILL_REGENHP * 100.0f, "f", 0, 2) + "% HP/s.", SKILL_REGENHP_LVL, SKILL_REGENHP * 100.0f, "% HP/s");
    @g_SkillDefs[int(SkillID::SKILL_REGENAP)] = SkillDefinition("Armor Regen", "+" + formatFloat(SKILL_REGENAP * 100.0f, "f", 0, 2) + "% AP/s.", SKILL_REGENAP_LVL, SKILL_REGENAP * 100.0f, "% AP/s");
    @g_SkillDefs[int(SkillID::SKILL_ABILITYRECHARGE)] = SkillDefinition("Ability Recharge", "+" + formatFloat(SKILL_ABILITYRECHARGE * 100, "f", 0, 2) + "% ability recharge speed.", SKILL_ABILITYRECHARGE_LVL, SKILL_ABILITYRECHARGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_AMMOREGEN)] = SkillDefinition("Ammo Regen", "+" + int(SKILL_AMMOREGEN) + " ammo gain per interval.", SKILL_AMMOREGEN_LVL, int(SKILL_AMMOREGEN), " Ammo");
    @g_SkillDefs[int(SkillID::SKILL_LIFESTEAL)] = SkillDefinition("Lifesteal", "+" + formatFloat(SKILL_LIFESTEAL * 100.0f, "f", 0, 2) + "% lifesteal.", SKILL_LIFESTEAL_LVL, SKILL_LIFESTEAL * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_HPCONVERSION)] = SkillDefinition("Convert HP -> AP", "+" + formatFloat(SKILL_HPCONVERSION * 100.0f, "f", 0, 2) + "% of Max HP converted to AP.", SKILL_HPCONVERSION_LVL, SKILL_HPCONVERSION * 100.0f, "%");

    // Minion Class exclusive.
    @g_SkillDefs[int(SkillID::SKILL_MINIONPOINT)] = SkillDefinition("Minions: Minion Point", "+" + SKILL_MINIONPOINT + " minion point.", SKILL_MINIONPOINT_LVL, SKILL_MINIONPOINT, " Point");
    @g_SkillDefs[int(SkillID::SKILL_MINIONHP)] = SkillDefinition("Minions: Max HP", "+" + int(SKILL_MINIONHP * 100) + "% minion HP.", SKILL_MINIONHP_LVL, int(SKILL_MINIONHP * 100.0f), "%");
    @g_SkillDefs[int(SkillID::SKILL_MINIONREGEN)] = SkillDefinition("Minions: HP Regen", "+" + formatFloat(SKILL_MINIONREGEN * 100.0f, "f", 0, 2) + "% minion HP/s.", SKILL_MINIONREGEN_LVL, SKILL_MINIONREGEN * 100.0f, "% HP/s");
    @g_SkillDefs[int(SkillID::SKILL_MINIONDAMAGE)] = SkillDefinition("Minions: Damage", "+" + formatFloat(SKILL_MINIONDAMAGE * 100.0f, "f", 0, 2) + "% minion damage.", SKILL_MINIONDAMAGE_LVL, SKILL_MINIONDAMAGE * 100.0f, "%");

    // Medic.
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALPERCENT)] = SkillDefinition("Heal Aura: Healing", "+" + formatFloat(SKILL_MEDIC_HEALPERCENT * 100.0f, "f", 0, 2) + "% max heal.", SKILL_MEDIC_HEALPERCENT_LVL, SKILL_MEDIC_HEALPERCENT * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_POISON)] = SkillDefinition("Heal Aura: Poison", "+" + formatFloat(SKILL_MEDIC_POISON, "f", 0, 2) + " poison damage.", SKILL_MEDIC_POISON_LVL, SKILL_MEDIC_POISON, "");
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_REVIVE)] = SkillDefinition("Heal Aura: Revive", "-" + formatFloat(SKILL_MEDIC_REVIVE, "f", 0, 2) + "s revive cooldown.", SKILL_MEDIC_REVIVE_LVL, SKILL_MEDIC_REVIVE, "s");
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALAP)] = SkillDefinition("Heal Aura: Restore AP", "+" + formatFloat(SKILL_MEDIC_HEALAP, "f", 0, 2) + "% of heal to AP.", SKILL_MEDIC_HEALAP_LVL, SKILL_MEDIC_HEALAP, "%");
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_DURATION)] = SkillDefinition("Heal Aura: Duration", "+" + formatFloat(SKILL_MEDIC_DURATION * 100.0f, "f", 0, 2) + "% heal aura duration.", SKILL_MEDIC_DURATION_LVL, SKILL_MEDIC_DURATION * 100.0f, "%");

    // Berserker.
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_LIFESTEAL)] = SkillDefinition("Bloodlust: Lifesteal", "+" + formatFloat(SKILL_BERSERKER_LIFESTEAL * 100.0f, "f", 0, 2) + "% lifesteal.", SKILL_BERSERKER_LIFESTEAL_LVL, SKILL_BERSERKER_LIFESTEAL * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_DAMAGEABILITYCHARGE)] = SkillDefinition("Bloodlust: Damage Charge", "+" + formatFloat(SKILL_BERSERKER_DAMAGEABILITYCHARGE * 100.0f, "f", 0, 2) + "% of damage charge.", SKILL_BERSERKER_DAMAGEABILITYCHARGE_LVL, SKILL_BERSERKER_DAMAGEABILITYCHARGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_DAMAGEREDUCTION)] = SkillDefinition("Bloodlust: Damage Reduction", "+" + formatFloat(SKILL_BERSERKER_DAMAGEREDUCTION * 100.0f, "f", 0, 2) + "% damage reduction.", SKILL_BERSERKER_DAMAGEREDUCTION_LVL, SKILL_BERSERKER_DAMAGEREDUCTION * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_OVERHEAL)] = SkillDefinition("Bloodlust: Overheal", "+" + formatFloat(SKILL_BERSERKER_OVERHEAL * 100.0f, "f", 0, 2) + "% Overheal per level.", SKILL_BERSERKER_OVERHEAL_LVL, SKILL_BERSERKER_OVERHEAL * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_APCONVERSION)] = SkillDefinition("Bloodlust: Convert AP -> HP", "+" + formatFloat(SKILL_BERSERKER_APCONVERSION * 100.0f, "f", 0, 2) + "% of Max AP -> HP.", SKILL_BERSERKER_APCONVERSION_LVL, SKILL_BERSERKER_APCONVERSION * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_DURATION)] = SkillDefinition("Bloodlust: Duration", "+" + formatFloat(SKILL_BERSERKER_DURATION * 100.0f, "f", 0, 2) + "% Bloodlust duration.", SKILL_BERSERKER_BLOODLUSTDURATION_LVL, SKILL_BERSERKER_DURATION * 100.0f, "%");

    // Engineer.
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYDAMAGE)] = SkillDefinition("Sentry: Damage", "+" + formatFloat(SKILL_ENGINEER_SENTRYDAMAGE * 100.0f, "f", 0, 2) + "% damage.", SKILL_ENGINEER_SENTRYDAMAGE_LVL, SKILL_ENGINEER_SENTRYDAMAGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_MINIHEALAURA)] = SkillDefinition("Sentry: Mini-Heal Aura", "+" + formatFloat(SKILL_ENGINEER_MINIHEALAURA * 100.0f, "f", 0, 2) + "% max HP heal/s.", SKILL_ENGINEER_MINIHEALAURA_LVL, SKILL_ENGINEER_MINIHEALAURA * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_EXPLOSIVEAMMO)] = SkillDefinition("Sentry: Explosive Ammo", "+" + formatFloat(SKILL_ENGINEER_EXPLOSIVEAMMO * 100.0f, "f", 0, 2) + "% explosive damage.", SKILL_ENGINEER_EXPLOSIVEAMMO_LVL, SKILL_ENGINEER_EXPLOSIVEAMMO * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYDURATION)] = SkillDefinition("Sentry: Duration", "+" + formatFloat(SKILL_ENGINEER_SENTRYDURATION * 100.0f, "f", 0, 2) + "% sentry duration.", SKILL_ENGINEER_SENTRYDURATION_LVL, SKILL_ENGINEER_SENTRYDURATION * 100.0f, "%");

    // Robomancer.

    // Xenomancer.
    @g_SkillDefs[int(SkillID::SKILL_XENOMANCER_LIFESTEAL)] = SkillDefinition("Xenomancer: Lifesteal", "+" + formatFloat(SKILL_XENOMANCER_LIFESTEAL * 100.0f, "f", 0, 2) + "% minion lifesteal to players.", SKILL_XENOMANCER_LIFESTEAL_LVL, SKILL_XENOMANCER_LIFESTEAL * 100.0f, "%");

    // Necromancer.
    @g_SkillDefs[int(SkillID::SKILL_NECROMANCER_RATS)] = SkillDefinition("Necromancer: Zombie Rats", "-" + formatFloat(SKILL_NECROMANCER_RATS, "f", 0, 2) + "s Zombie Rat cooldown.", SKILL_NECROMANCER_RATS_LVL, SKILL_NECROMANCER_RATS, "s");

    // Warden.
    @g_SkillDefs[int(SkillID::SKILL_WARDEN_SHIELDHP)] = SkillDefinition("Ice Shield: Shield HP", "+" + formatFloat(SKILL_WARDEN_SHIELDHP * 100.0f, "f", 0, 2) + "% shield HP.", SKILL_WARDEN_SHIELDHP_LVL, SKILL_WARDEN_SHIELDHP * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_WARDEN_DAMAGEREFLECT)] = SkillDefinition("Ice Shield: Damage Reflect", "+" + formatFloat(SKILL_WARDEN_DAMAGEREFLECT * 100.0f, "f", 0, 2) + "% shield damage reflect.", SKILL_WARDEN_DAMAGEREFLECT_LVL, SKILL_WARDEN_DAMAGEREFLECT * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_WARDEN_ACTIVERECHARGE)] = SkillDefinition("Ice Shield: Active Recharge", "+" + formatFloat(SKILL_WARDEN_ACTIVERECHARGE * 100.0f, "f", 0, 2) + "% shield recharge.", SKILL_WARDEN_ACTIVERECHARGE_LVL, SKILL_WARDEN_ACTIVERECHARGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_WARDEN_HPABSORB)] = SkillDefinition("Ice Shield: HP Absorb", "+" + formatFloat(SKILL_WARDEN_HPABSORB * 100.0f, "f", 0, 2) + "% shield HP absorb.", SKILL_WARDEN_HPABSORB_LVL, SKILL_WARDEN_HPABSORB * 100.0f, "%");

    // Shocktrooper.
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_CAPACITY)] = SkillDefinition("Shockrifle: Shock Capacity", "+" + formatFloat(SKILL_SHOCK_CAPACITY * 100.0f, "f", 0, 2) + "% shockrifle capacity.", SKILL_SHOCK_CAPACITY_LVL, SKILL_SHOCK_CAPACITY * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_DAMAGE)] = SkillDefinition("Shockrifle: Shock Damage", "+" + formatFloat(SKILL_SHOCK_DAMAGE * 100.0f, "f", 0, 2) + "% shockrifle damage.", SKILL_SHOCK_DAMAGE_LVL, SKILL_SHOCK_DAMAGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_LIGHTNING)] = SkillDefinition("Shockrifle: Lightning Damage", "+" + formatFloat(SKILL_SHOCK_LIGHTNING * 100.0f, "f", 0, 2) + "% shockrifle damage as lightning damage.", SKILL_SHOCK_LIGHTNING_LVL, SKILL_SHOCK_LIGHTNING * 100.0f, "%");

    // Cloaker.
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKDAMAGE)] = SkillDefinition("Cloak: Damage Bonus", "+" + formatFloat(SKILL_CLOAKER_CLOAKDAMAGE * 100.0f, "f", 0, 2) + "% damage bonus.", SKILL_CLOAKER_CLOAKDAMAGE_LVL, SKILL_CLOAKER_CLOAKDAMAGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKNOVADAMAGE)] = SkillDefinition("Cloak: Nova Damage", "+" + formatFloat(SKILL_CLOAKER_CLOAKNOVADAMAGE * 100.0f, "f", 0, 2) + "% nova damage.", SKILL_CLOAKER_CLOAKNOVADAMAGE_LVL, SKILL_CLOAKER_CLOAKNOVADAMAGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKDURATION)] = SkillDefinition("Cloak: Duration", "+" + formatFloat(SKILL_CLOAKER_CLOAKDURATION * 100.0f, "f", 0, 2) + "% cloak duration.", SKILL_CLOAKER_CLOAKDURATION_LVL, SKILL_CLOAKER_CLOAKDURATION * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_STANDINGDRAIN)] = SkillDefinition("Cloak: Standing Drain", "-" + formatFloat(SKILL_CLOAKER_STANDINGDRAIN * 100.0f, "f", 0, 2) + "% reduced drain whilst motionless.", SKILL_CLOAKER_STANDINGDRAIN_LVL, SKILL_CLOAKER_STANDINGDRAIN * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_SPEED)] = SkillDefinition("Cloak: Speed Boost", "+" + formatFloat(SKILL_CLOAKER_SPEED * 100.0f, "f", 0, 2) + "% speed whilst cloaked.", SKILL_CLOAKER_SPEED_LVL, SKILL_CLOAKER_SPEED * 100.0f, "%");

    // Vanquisher.
    @g_SkillDefs[int(SkillID::SKILL_VANQUISHER_AMMOPOOL)] = SkillDefinition("Dragon's Breath: Ammo Pool", "+" + formatFloat(SKILL_VANQUISHER_AMMOPOOL * 100.0f, "f", 0, 2) + "% ammo pool.", SKILL_VANQUISHER_AMMOPOOL_LVL, SKILL_VANQUISHER_AMMOPOOL * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_VANQUISHER_EXPLOSIVEDAMAGE)] = SkillDefinition("Dragon's Breath: Explosive Damage", "+" + formatFloat(SKILL_VANQUISHER_EXPLOSIVEDAMAGE, "f", 0, 2) + " explosive damage.", SKILL_VANQUISHER_EXPLOSIVEDAMAGE_LVL, SKILL_VANQUISHER_EXPLOSIVEDAMAGE, "");
    @g_SkillDefs[int(SkillID::SKILL_VANQUISHER_FIREDAMAGE)] = SkillDefinition("Dragon's Breath: Fire Damage", "+" + formatFloat(SKILL_VANQUISHER_FIREDAMAGE * 100.0f, "f", 0, 2) + "% of explosion as fire damage.", SKILL_VANQUISHER_FIREDAMAGE_LVL, SKILL_VANQUISHER_FIREDAMAGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_VANQUISHER_FIREDURATION)] = SkillDefinition("Dragon's Breath: Fire Duration", "+" + formatFloat(SKILL_VANQUISHER_FIREDURATION, "f", 0, 2) + "s fire duration.", SKILL_VANQUISHER_FIREDURATION_LVL, SKILL_VANQUISHER_FIREDURATION, "s");

    // Swarmer.
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKDAMAGE)] = SkillDefinition("Snarks: Snark Damage", "+" + formatFloat(SKILL_SWARMER_SNARKDAMAGE * 100.0f, "f", 0, 2) + "% snark damage.", SKILL_SWARMER_SNARKDAMAGE_LVL, SKILL_SWARMER_SNARKDAMAGE, "");
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKCOUNT)] = SkillDefinition("Snarks: Snark Count", "+" + int(SKILL_SWARMER_SNARKCOUNT * 100.0f) + "% swarm size.", SKILL_SWARMER_SNARKCOUNT_LVL, int(SKILL_SWARMER_SNARKCOUNT * 100.0f), "%");
}

// Returns the standard skill IDs (shared across all classes).
array<SkillID> GetStandardSkillIDs()
{
    array<SkillID> result;
    result.insertLast(SkillID::SKILL_MAXHP);
    result.insertLast(SkillID::SKILL_MAXAP);
    result.insertLast(SkillID::SKILL_REGENHP);
    result.insertLast(SkillID::SKILL_REGENAP);
    result.insertLast(SkillID::SKILL_ABILITYRECHARGE);
    result.insertLast(SkillID::SKILL_AMMOREGEN);
    result.insertLast(SkillID::SKILL_LIFESTEAL);
    result.insertLast(SkillID::SKILL_HPCONVERSION);
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
            result.insertLast(SkillID::SKILL_MEDIC_POISON);
            result.insertLast(SkillID::SKILL_MEDIC_REVIVE);
            result.insertLast(SkillID::SKILL_MEDIC_HEALAP);
            result.insertLast(SkillID::SKILL_MEDIC_DURATION);
            break;

        case PlayerClass::CLASS_BERSERKER:
            result.insertLast(SkillID::SKILL_BERSERKER_LIFESTEAL);
            result.insertLast(SkillID::SKILL_BERSERKER_DAMAGEABILITYCHARGE);
            result.insertLast(SkillID::SKILL_BERSERKER_DAMAGEREDUCTION);
            result.insertLast(SkillID::SKILL_BERSERKER_OVERHEAL);
            result.insertLast(SkillID::SKILL_BERSERKER_APCONVERSION);
            result.insertLast(SkillID::SKILL_BERSERKER_DURATION);
            break;

        case PlayerClass::CLASS_ENGINEER:
            result.insertLast(SkillID::SKILL_ENGINEER_SENTRYDAMAGE);
            result.insertLast(SkillID::SKILL_ENGINEER_MINIHEALAURA);
            result.insertLast(SkillID::SKILL_ENGINEER_EXPLOSIVEAMMO);
            result.insertLast(SkillID::SKILL_ENGINEER_SENTRYDURATION);
            break;

        case PlayerClass::CLASS_ROBOMANCER:
            result.insertLast(SkillID::SKILL_MINIONPOINT);
            result.insertLast(SkillID::SKILL_MINIONHP);
            result.insertLast(SkillID::SKILL_MINIONREGEN);
            result.insertLast(SkillID::SKILL_MINIONDAMAGE);
            break;

        case PlayerClass::CLASS_XENOMANCER:
            result.insertLast(SkillID::SKILL_MINIONPOINT);
            result.insertLast(SkillID::SKILL_MINIONHP);
            result.insertLast(SkillID::SKILL_MINIONREGEN);
            result.insertLast(SkillID::SKILL_MINIONDAMAGE);
            result.insertLast(SkillID::SKILL_XENOMANCER_LIFESTEAL);
            break;

        case PlayerClass::CLASS_NECROMANCER:
            result.insertLast(SkillID::SKILL_MINIONPOINT);
            result.insertLast(SkillID::SKILL_MINIONHP);
            result.insertLast(SkillID::SKILL_MINIONREGEN);
            result.insertLast(SkillID::SKILL_MINIONDAMAGE);
            result.insertLast(SkillID::SKILL_NECROMANCER_RATS);
            break;

        case PlayerClass::CLASS_DEFENDER:
            result.insertLast(SkillID::SKILL_WARDEN_SHIELDHP);
            result.insertLast(SkillID::SKILL_WARDEN_DAMAGEREFLECT);
            result.insertLast(SkillID::SKILL_WARDEN_ACTIVERECHARGE);
            result.insertLast(SkillID::SKILL_WARDEN_HPABSORB);
            break;

        case PlayerClass::CLASS_SHOCKTROOPER:
            result.insertLast(SkillID::SKILL_SHOCK_CAPACITY);
            result.insertLast(SkillID::SKILL_SHOCK_DAMAGE);
            result.insertLast(SkillID::SKILL_SHOCK_LIGHTNING);
            break;

        case PlayerClass::CLASS_CLOAKER:
            result.insertLast(SkillID::SKILL_CLOAKER_CLOAKDAMAGE);
            result.insertLast(SkillID::SKILL_CLOAKER_CLOAKNOVADAMAGE);
            result.insertLast(SkillID::SKILL_CLOAKER_CLOAKDURATION);
            result.insertLast(SkillID::SKILL_CLOAKER_STANDINGDRAIN);
            result.insertLast(SkillID::SKILL_CLOAKER_SPEED);
            break;

        case PlayerClass::CLASS_VANQUISHER:
            result.insertLast(SkillID::SKILL_VANQUISHER_AMMOPOOL);
            result.insertLast(SkillID::SKILL_VANQUISHER_EXPLOSIVEDAMAGE);
            result.insertLast(SkillID::SKILL_VANQUISHER_FIREDAMAGE);
            result.insertLast(SkillID::SKILL_VANQUISHER_FIREDURATION);
            break;
            
        case PlayerClass::CLASS_SWARMER:
            result.insertLast(SkillID::SKILL_SWARMER_SNARKDAMAGE);
            result.insertLast(SkillID::SKILL_SWARMER_SNARKCOUNT);
            break;
    }
    return result;
}
