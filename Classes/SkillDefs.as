/*
Skills definition file.

*/

// Standard/Basic skills, available to all classes.
const float SKILL_MAXHP = 0.10f;  // Max HP per level.
const float SKILL_MAXAP = 0.05f;  // Max AP per level.
const float SKILL_REGENHP = 0.002f;  // HP regen scale (% of max HP) per level.
const float SKILL_REGENAP = 0.0005f;  // AP regen scale (% of max AP) per level.
const float SKILL_ABILITYRECHARGE = 0.05f; // Percent increase to ability recharge speed per level.
const int SKILL_AMMOREGEN = 1; // +1 bullet per regen interval, per level.
const float SKILL_LIFESTEAL = 0.01f; // Percent of damage dealt as lifesteal per level.
const float SKILL_HPCONVERSION = 0.06f; // Percent of Max HP to convert to AP per level.

// Class/Ability specific skills.
// Minion Class exclusive.
const int SKILL_MINIONPOINT = 1; // +1 minion point per level.
const float SKILL_MINIONHP = 0.50f; // HP percent increase for minions per level.
const float SKILL_MINIONREGEN = 0.001f; // Max HP regen percent for minions per level.
const float SKILL_MINIONDAMAGE = 0.20f; // Damage percent increase for minions per level.

// Medic.
const float SKILL_MEDIC_HEALPERCENT = 1.00f;  // Increase max health percent healed per level (divided by 100).
const float SKILL_MEDIC_POISON = 2.00f; // Flat poison damage per level.
const float SKILL_MEDIC_REVIVE = 6.00f;   // Reduce revive cooldown in seconds per level.
const float SKILL_MEDIC_HEALAP = 0.40f;  // Percent of max AP to heal per level (divided by 100).
const float SKILL_MEDIC_DURATION = 0.20f; // Percent increase to heal aura duration per level.

// Berserker.
const float SKILL_BERSERKER_LIFESTEAL = 0.05f; // Flat increase to lifesteal per level.
const float SKILL_BERSERKER_DAMAGEABILITYCHARGE = 0.01f; // Percent of damage dealt converted to ability charge per level.
const float SKILL_BERSERKER_DAMAGEREDUCTION = 0.08f; // Damage reduction per level.
const float SKILL_BERSERKER_OVERHEAL = 0.10f; // Percent of max HP to overheal from lifesteal per level.
const float SKILL_BERSERKER_APCONVERSION = 0.20f; // Percent of Max AP converted into Max HP.
const float SKILL_BERSERKER_DURATION = 0.20f; // Percent increase to Bloodlust duration per level.

// Engineer.
const float SKILL_ENGINEER_SENTRYDAMAGE = 0.30f; // Sentry damage per level.
const float SKILL_ENGINEER_MINIHEALAURA = 1.0f; // Mini-heal Aura % max HP heal per level.
const float SKILL_ENGINEER_EXPLOSIVEAMMO = 0.20f;  // % of damage as area explosive damage per level.
const float SKILL_ENGINEER_SENTRYDURATION = 0.20f; // Sentry duration increase per level.

// Xenomancer.
const float SKILL_XENOMANCER_LIFESTEAL = 0.01f; // Minion lifesteal percent to players per level.

// Necromancer.
const float SKILL_NECROMANCER_RATS = 3.0f; // Cooldown reduction in seconds per level.

// Warden.
const float SKILL_WARDEN_SHIELDHP = 0.20f; // Ice shield HP percent increase per level.
const float SKILL_WARDEN_DAMAGEREFLECT = 0.08f; // Damage reflect per level.
const float SKILL_WARDEN_ACTIVERECHARGE = 0.05f; // Active shield recharge per level.
const float SKILL_WARDEN_HPABSORB = 0.06f; // HP absorb from damage reflected per level.

// Cloaker.
const float SKILL_CLOAKER_CLOAKDAMAGE = 0.10f; // Cloak damage bonus increase per level.
const float SKILL_CLOAKER_CLOAKNOVADAMAGE = 0.20f; // Cloak nova damage increase per level.
const float SKILL_CLOAKER_CLOAKDURATION = 0.20f; // Cloak duration increase per level.
const float SKILL_CLOAKER_STANDINGDRAIN = 0.20f; // Percent drain reduction while standing still.
const float SKILL_CLOAKER_SPEED = 0.20f; // Percent speed increase while cloaked.

// Shocktrooper.
const float SKILL_SHOCK_CAPACITY = 0.20f; // Shockrifle capacity per level.
const float SKILL_SHOCK_DAMAGE = 0.20f; // Shockrifle damage per level.
const float SKILL_SHOCK_LIGHTNING = 0.04f; // Shockrifle damage % as area lightning damage per level.

// Vanquisher.
const float SKILL_VANQUISHER_AMMOPOOL = 0.60f; // Ammo pool increase per level.
const float SKILL_VANQUISHER_EXPLOSIVEDAMAGE = 1.0f; // Flat increase of added explosive damage per level.
const float SKILL_VANQUISHER_FIREDAMAGE = 0.06f; // Percentage of explosion converted to extra fire damage per level.
const float SKILL_VANQUISHER_FIREDURATION = 1.0f; // Flat added fire damage ticks per level.

// Swarmer.
const float SKILL_SWARMER_SNARKDAMAGE = 1.50f; // Snark damage per level.
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
    int baseMaxLevel; // Base max level (without rank bonus).
    float strength; // Per-level bonus.
    string unit;    // Suffix appended to the computed bonus (e.g. "%" or "s").
    bool bIsBasic;  // True for standard skills (get +1 max per rank).

    SkillDefinition(const string& in _name, const string& in _desc, int _baseMaxLevel,
                    float _strength = 0.0f, const string& in _unit = "%", bool _bIsBasic = false)
    {
        name        = _name;
        description = _desc;
        baseMaxLevel = _baseMaxLevel;
        strength    = _strength;
        unit        = _unit;
        bIsBasic    = _bIsBasic;
    }

    int GetEffectiveMaxLevel(int rebirthRank) const
    {
        return bIsBasic ? baseMaxLevel + rebirthRank : baseMaxLevel;
    }
}

array<SkillDefinition@> g_SkillDefs;

void InitializeSkillDefinitions()
{
    g_SkillDefs.resize(int(SkillID::SKILL_MAX_COUNT));

    // Standard/Basic skills (bIsBasic = true for any skill that we don't want to gain rank bonuses).
    @g_SkillDefs[int(SkillID::SKILL_MAXHP)] = SkillDefinition("Max Health", "+" + int(SKILL_MAXHP * 100) + "% Max HP.", 10, int(SKILL_MAXHP * 100.0f), "%", true);
    @g_SkillDefs[int(SkillID::SKILL_MAXAP)] = SkillDefinition("Max Armor", "+" + int(SKILL_MAXAP * 100) + "% Max AP.", 10, int(SKILL_MAXAP * 100.0f), "%", true);
    @g_SkillDefs[int(SkillID::SKILL_REGENHP)] = SkillDefinition("Health Regen", "+" + formatFloat(SKILL_REGENHP * 100.0f, "f", 0, 2) + "% HP/s.", 10, SKILL_REGENHP * 100.0f, "% HP/s", true);
    @g_SkillDefs[int(SkillID::SKILL_REGENAP)] = SkillDefinition("Armor Regen", "+" + formatFloat(SKILL_REGENAP * 100.0f, "f", 0, 2) + "% AP/s.", 10, SKILL_REGENAP * 100.0f, "% AP/s", true);
    @g_SkillDefs[int(SkillID::SKILL_ABILITYRECHARGE)] = SkillDefinition("Ability Recharge", "+" + formatFloat(SKILL_ABILITYRECHARGE * 100, "f", 0, 2) + "% ability recharge speed.", 10, SKILL_ABILITYRECHARGE * 100.0f, "%", true);
    @g_SkillDefs[int(SkillID::SKILL_AMMOREGEN)] = SkillDefinition("Ammo Regen", "+" + int(SKILL_AMMOREGEN) + " ammo gain per interval.", 5, int(SKILL_AMMOREGEN), " Ammo", false);
    @g_SkillDefs[int(SkillID::SKILL_LIFESTEAL)] = SkillDefinition("Lifesteal", "+" + formatFloat(SKILL_LIFESTEAL * 100.0f, "f", 0, 2) + "% lifesteal.", 10, SKILL_LIFESTEAL * 100.0f, "%", true);
    @g_SkillDefs[int(SkillID::SKILL_HPCONVERSION)] = SkillDefinition("Convert HP -> AP", "+" + formatFloat(SKILL_HPCONVERSION * 100.0f, "f", 0, 2) + "% of Max HP converted to AP.", 10, SKILL_HPCONVERSION * 100.0f, "%", true);

    // Minion Class exclusive.
    @g_SkillDefs[int(SkillID::SKILL_MINIONPOINT)] = SkillDefinition("Minions: Minion Point", "+" + SKILL_MINIONPOINT + " minion point.", 3, SKILL_MINIONPOINT, " Point", false);
    @g_SkillDefs[int(SkillID::SKILL_MINIONHP)] = SkillDefinition("Minions: Max HP", "+" + int(SKILL_MINIONHP * 100) + "% minion HP.", 5, int(SKILL_MINIONHP * 100.0f), "%", false);
    @g_SkillDefs[int(SkillID::SKILL_MINIONREGEN)] = SkillDefinition("Minions: HP Regen", "+" + formatFloat(SKILL_MINIONREGEN * 100.0f, "f", 0, 2) + "% minion HP/s.", 5, SKILL_MINIONREGEN * 100.0f, "% HP/s", false);
    @g_SkillDefs[int(SkillID::SKILL_MINIONDAMAGE)] = SkillDefinition("Minions: Damage", "+" + formatFloat(SKILL_MINIONDAMAGE * 100.0f, "f", 0, 2) + "% minion damage.", 5, SKILL_MINIONDAMAGE * 100.0f, "%", false);

    // Medic.
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALPERCENT)] = SkillDefinition("Heal Aura: Healing", "+" + formatFloat(SKILL_MEDIC_HEALPERCENT, "f", 0, 2) + "% max heal.", 5, SKILL_MEDIC_HEALPERCENT, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_POISON)] = SkillDefinition("Heal Aura: Acid", "+" + formatFloat(SKILL_MEDIC_POISON, "f", 0, 2) + " acid damage.", 5, SKILL_MEDIC_POISON, "", false);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_REVIVE)] = SkillDefinition("Heal Aura: Revive", "-" + formatFloat(SKILL_MEDIC_REVIVE, "f", 0, 2) + "s revive cooldown.", 5, SKILL_MEDIC_REVIVE, "s", false);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALAP)] = SkillDefinition("Heal Aura: Restore AP", "+" + formatFloat(SKILL_MEDIC_HEALAP, "f", 0, 2) + "% of heal to AP.", 5, SKILL_MEDIC_HEALAP, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_DURATION)] = SkillDefinition("Heal Aura: Duration", "+" + formatFloat(SKILL_MEDIC_DURATION * 100.0f, "f", 0, 2) + "% heal aura duration.", 5, SKILL_MEDIC_DURATION * 100.0f, "%", false);

    // Berserker.
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_LIFESTEAL)] = SkillDefinition("Bloodlust: Lifesteal", "+" + formatFloat(SKILL_BERSERKER_LIFESTEAL * 100.0f, "f", 0, 2) + "% lifesteal.", 5, SKILL_BERSERKER_LIFESTEAL * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_DAMAGEABILITYCHARGE)] = SkillDefinition("Bloodlust: Damage Charge", "+" + formatFloat(SKILL_BERSERKER_DAMAGEABILITYCHARGE * 100.0f, "f", 0, 2) + "% of damage charge.", 5, SKILL_BERSERKER_DAMAGEABILITYCHARGE * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_DAMAGEREDUCTION)] = SkillDefinition("Bloodlust: Damage Reduction", "+" + formatFloat(SKILL_BERSERKER_DAMAGEREDUCTION * 100.0f, "f", 0, 2) + "% damage reduction.", 5, SKILL_BERSERKER_DAMAGEREDUCTION * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_OVERHEAL)] = SkillDefinition("Bloodlust: Overheal", "+" + formatFloat(SKILL_BERSERKER_OVERHEAL * 100.0f, "f", 0, 2) + "% Overheal per level.", 5, SKILL_BERSERKER_OVERHEAL * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_APCONVERSION)] = SkillDefinition("Bloodlust: Convert AP -> HP", "+" + formatFloat(SKILL_BERSERKER_APCONVERSION * 100.0f, "f", 0, 2) + "% of Max AP -> HP.", 5, SKILL_BERSERKER_APCONVERSION * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_DURATION)] = SkillDefinition("Bloodlust: Duration", "+" + formatFloat(SKILL_BERSERKER_DURATION * 100.0f, "f", 0, 2) + "% Bloodlust duration.", 5, SKILL_BERSERKER_DURATION * 100.0f, "%", false);

    // Engineer.
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYDAMAGE)] = SkillDefinition("Sentry: Damage", "+" + formatFloat(SKILL_ENGINEER_SENTRYDAMAGE * 100.0f, "f", 0, 2) + "% damage.", 5, SKILL_ENGINEER_SENTRYDAMAGE * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_MINIHEALAURA)] = SkillDefinition("Sentry: Mini-Heal Aura", "+" + formatFloat(SKILL_ENGINEER_MINIHEALAURA * 100.0f, "f", 0, 2) + "% max HP heal/s.", 5, SKILL_ENGINEER_MINIHEALAURA * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_EXPLOSIVEAMMO)] = SkillDefinition("Sentry: Explosive Ammo", "+" + formatFloat(SKILL_ENGINEER_EXPLOSIVEAMMO * 100.0f, "f", 0, 2) + "% explosive damage.", 5, SKILL_ENGINEER_EXPLOSIVEAMMO * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYDURATION)] = SkillDefinition("Sentry: Duration", "+" + formatFloat(SKILL_ENGINEER_SENTRYDURATION * 100.0f, "f", 0, 2) + "% sentry duration.", 5, SKILL_ENGINEER_SENTRYDURATION * 100.0f, "%", false);

    // Robomancer – none defined yet.

    // Xenomancer.
    @g_SkillDefs[int(SkillID::SKILL_XENOMANCER_LIFESTEAL)] = SkillDefinition("Xenomancer: Lifesteal", "+" + formatFloat(SKILL_XENOMANCER_LIFESTEAL * 100.0f, "f", 0, 2) + "% minion lifesteal to players.", 3, SKILL_XENOMANCER_LIFESTEAL * 100.0f, "%", false);

    // Necromancer.
    @g_SkillDefs[int(SkillID::SKILL_NECROMANCER_RATS)] = SkillDefinition("Necromancer: Zombie Rats", "-" + formatFloat(SKILL_NECROMANCER_RATS, "f", 0, 2) + "s Zombie Rat cooldown.", 5, SKILL_NECROMANCER_RATS, "s", false);

    // Warden.
    @g_SkillDefs[int(SkillID::SKILL_WARDEN_SHIELDHP)] = SkillDefinition("Ice Shield: Shield HP", "+" + formatFloat(SKILL_WARDEN_SHIELDHP * 100.0f, "f", 0, 2) + "% shield HP.", 5, SKILL_WARDEN_SHIELDHP * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_WARDEN_DAMAGEREFLECT)] = SkillDefinition("Ice Shield: Damage Reflect", "+" + formatFloat(SKILL_WARDEN_DAMAGEREFLECT * 100.0f, "f", 0, 2) + "% shield damage reflect.", 5, SKILL_WARDEN_DAMAGEREFLECT * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_WARDEN_ACTIVERECHARGE)] = SkillDefinition("Ice Shield: Active Recharge", "+" + formatFloat(SKILL_WARDEN_ACTIVERECHARGE * 100.0f, "f", 0, 2) + "% shield recharge.", 5, SKILL_WARDEN_ACTIVERECHARGE * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_WARDEN_HPABSORB)] = SkillDefinition("Ice Shield: HP Absorb", "+" + formatFloat(SKILL_WARDEN_HPABSORB * 100.0f, "f", 0, 2) + "% shield HP absorb.", 5, SKILL_WARDEN_HPABSORB * 100.0f, "%", false);

    // Shocktrooper.
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_CAPACITY)] = SkillDefinition("Shockrifle: Shock Capacity", "+" + formatFloat(SKILL_SHOCK_CAPACITY * 100.0f, "f", 0, 2) + "% shockrifle capacity.", 5, SKILL_SHOCK_CAPACITY * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_DAMAGE)] = SkillDefinition("Shockrifle: Shock Damage", "+" + formatFloat(SKILL_SHOCK_DAMAGE * 100.0f, "f", 0, 2) + "% shockrifle damage.", 5, SKILL_SHOCK_DAMAGE * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_LIGHTNING)] = SkillDefinition("Shockrifle: Lightning Damage", "+" + formatFloat(SKILL_SHOCK_LIGHTNING * 100.0f, "f", 0, 2) + "% shockrifle damage as lightning damage.", 5, SKILL_SHOCK_LIGHTNING * 100.0f, "%", false);

    // Cloaker.
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKDAMAGE)] = SkillDefinition("Cloak: Damage Bonus", "+" + formatFloat(SKILL_CLOAKER_CLOAKDAMAGE * 100.0f, "f", 0, 2) + "% damage bonus.", 5, SKILL_CLOAKER_CLOAKDAMAGE * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKNOVADAMAGE)] = SkillDefinition("Cloak: Nova Damage", "+" + formatFloat(SKILL_CLOAKER_CLOAKNOVADAMAGE * 100.0f, "f", 0, 2) + "% nova damage.", 5, SKILL_CLOAKER_CLOAKNOVADAMAGE * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKDURATION)] = SkillDefinition("Cloak: Duration", "+" + formatFloat(SKILL_CLOAKER_CLOAKDURATION * 100.0f, "f", 0, 2) + "% cloak duration.", 5, SKILL_CLOAKER_CLOAKDURATION * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_STANDINGDRAIN)] = SkillDefinition("Cloak: Standing Drain", "-" + formatFloat(SKILL_CLOAKER_STANDINGDRAIN * 100.0f, "f", 0, 2) + "% reduced drain whilst motionless.", 5, SKILL_CLOAKER_STANDINGDRAIN * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_SPEED)] = SkillDefinition("Cloak: Speed Boost", "+" + formatFloat(SKILL_CLOAKER_SPEED * 100.0f, "f", 0, 2) + "% speed whilst cloaked.", 5, SKILL_CLOAKER_SPEED * 100.0f, "%", false);

    // Vanquisher.
    @g_SkillDefs[int(SkillID::SKILL_VANQUISHER_AMMOPOOL)] = SkillDefinition("Dragon's Breath: Ammo Pool", "+" + formatFloat(SKILL_VANQUISHER_AMMOPOOL * 100.0f, "f", 0, 2) + "% ammo pool.", 5, SKILL_VANQUISHER_AMMOPOOL * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_VANQUISHER_EXPLOSIVEDAMAGE)] = SkillDefinition("Dragon's Breath: Explosive Damage", "+" + formatFloat(SKILL_VANQUISHER_EXPLOSIVEDAMAGE, "f", 0, 2) + " explosive damage.", 5, SKILL_VANQUISHER_EXPLOSIVEDAMAGE, "", false);
    @g_SkillDefs[int(SkillID::SKILL_VANQUISHER_FIREDAMAGE)] = SkillDefinition("Dragon's Breath: Fire Damage", "+" + formatFloat(SKILL_VANQUISHER_FIREDAMAGE * 100.0f, "f", 0, 2) + "% of explosion as fire damage.", 5, SKILL_VANQUISHER_FIREDAMAGE * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_VANQUISHER_FIREDURATION)] = SkillDefinition("Dragon's Breath: Fire Duration", "+" + formatFloat(SKILL_VANQUISHER_FIREDURATION, "f", 0, 2) + "s fire duration.", 5, SKILL_VANQUISHER_FIREDURATION, "s", false);

    // Swarmer.
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKDAMAGE)] = SkillDefinition("Snarks: Snark Damage", "+" + formatFloat(SKILL_SWARMER_SNARKDAMAGE * 100.0f, "f", 0, 2) + "% snark damage.", 5, SKILL_SWARMER_SNARKDAMAGE * 100.0f, "%", false);
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKCOUNT)] = SkillDefinition("Snarks: Snark Count", "+" + int(SKILL_SWARMER_SNARKCOUNT * 100.0f) + "% swarm size.", 5, int(SKILL_SWARMER_SNARKCOUNT * 100.0f), "%", false);
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