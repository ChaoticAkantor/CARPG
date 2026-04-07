/*
Skills definition file.

Add new skills here:
  1. Add a new SkillID entry before SKILL_MAX_COUNT.
  2. Add its SkillDefinition in InitializeSkillDefinitions().
  3. Add the SkillID to GetAbilitySkillIDs() for the relevant class,
     or to GetStandardSkillIDs() if it applies to all classes.
  4. Apply the bonus inside CalculateStats() in PlayerData.as,
     or read it directly inside the ability script via:
         stats.GetSkillLevel(SkillID::YOUR_SKILL_ID)
*/

// Standard skills, available to all classes.
const float SKILL_MAXHP         = 0.10f;  // Max HP per level.
    const int SKILL_MAXHP_LVL       = 10;

const float SKILL_MAXAP         = 0.05f;  // Max AP per level.
    const int SKILL_MAXAP_LVL       = 10;

const float SKILL_REGENHP       = 0.002f;  // HP regen scale (% of max HP) per level.
    const int SKILL_REGENHP_LVL     = 10;

const float SKILL_REGENAP       = 0.0005f;  // AP regen scale (% of max AP) per level.
    const int SKILL_REGENAP_LVL     = 10;

const float SKILL_ABILITYRECHARGE = 0.05f; // Percent increase to ability recharge speed per level.
    const int SKILL_ABILITYRECHARGE_LVL = 10;

const int SKILL_AMMOREGEN = 1; // +1 bullet per regen interval, per level.
    const int SKILL_AMMOREGEN_LVL = 5; // More than 5 levels is excessive.


// Class/Ability specific skills.
// Minion Class exclusive.
const int SKILL_MINIONPOINT = 1; // +1 minion point per level.
    const int SKILL_MINIONPOINT_LVL = 3; // More than 3 is excessive.

const float SKILL_MINIONHP = 0.60f; // HP percent increase for minions per level.
    const int SKILL_MINIONHP_LVL = 5;

const float SKILL_MINIONREGEN = 0.001f; // Max HP regen percent for minions per level.
    const int SKILL_MINIONREGEN_LVL = 5;

const float SKILL_MINIONDAMAGE = 0.40f; // Damage percent increase for minions per level.
    const int SKILL_MINIONDAMAGE_LVL = 5;


// Medic.
const float SKILL_MEDIC_HEALPERCENT     = 2.0f;  // Increase max healing percent per level. (absolute)
    const int SKILL_MEDIC_HEALPERCENT_LVL = 5;

const float SKILL_MEDIC_POISON          = 2.0f; // Poison damage (% max health) per level.
    const int SKILL_MEDIC_POISON_LVL      = 5;

const float SKILL_MEDIC_REVIVE          = 2.5f;   // Reduce revive cooldown per level.
    const int SKILL_MEDIC_REVIVE_LVL      = 5;

const float SKILL_MEDIC_HEALAP          = 0.02f;  // Percent of heal applied as AP per level.
    const int SKILL_MEDIC_HEALAP_LVL      = 5;


// Berserker.
const float SKILL_BERSERKER_LIFESTEAL   = 0.04f; // Increase lifesteal per level.
    const int SKILL_BERSERKER_LIFESTEAL_LVL = 5;

const float SKILL_BERSERKER_DAMAGEABILITYCHARGE = 0.02f; // Percent of damage dealt converted to ability charge per level.
    const int SKILL_BERSERKER_DAMAGEABILITYCHARGE_LVL = 5;

const float SKILL_BERSERKER_DAMAGEREDUCTION = 0.06f; // Damage reduction per level.
    const int SKILL_BERSERKER_DAMAGEREDUCTION_LVL = 5;

const float SKILL_BERSERKER_OVERHEAL     = 0.12f; // Percent of max HP to overheal from lifesteal per level.
    const int SKILL_BERSERKER_OVERHEAL_LVL = 5;


// Engineer.
const float SKILL_ENGINEER_SENTRYDAMAGE   = 0.60f; // Sentry damage per level.
    const int SKILL_ENGINEER_SENTRYDAMAGE_LVL = 5;

const float SKILL_ENGINEER_MINIHEALAURA  = 1.0f; // Mini-heal Aura % max HP heal per level.
    const int SKILL_ENGINEER_MINIHEALAURA_LVL = 5;

const float SKILL_ENGINEER_EXPLOSIVEAMMO = 0.05f;  // % of damage as area explosive damage per level.
    const int SKILL_ENGINEER_EXPLOSIVEAMMO_LVL = 5;


// Xenomancer.
const float SKILL_XENOMANCER_LIFESTEAL = 0.10f; // Minion lifesteal percent per level.
    const int SKILL_XENOMANCER_LIFESTEAL_LVL = 3;


// Warden.
const float SKILL_WARDEN_SHIELDHP        = 0.20f; // Ice shield HP percent increase per level.
    const int SKILL_WARDEN_SHIELDHP_LVL     = 5;

const float SKILL_WARDEN_DAMAGEREFLECT   = 0.20f; // Damage reflect per level.
    const int SKILL_WARDEN_DAMAGEREFLECT_LVL = 5;

const float SKILL_WARDEN_ACTIVERECHARGE  = 0.06f; // Active shield recharge per level.
    const int SKILL_WARDEN_ACTIVERECHARGE_LVL = 5;

const float SKILL_WARDEN_HPABSORB        = 0.12f; // HP absorb from damage reflected per level.
    const int SKILL_WARDEN_HPABSORB_LVL     = 5;


// Cloaker.
const float SKILL_CLOAKER_CLOAKDAMAGE    = 0.30f; // Cloak damage bonus increase per level.
    const int SKILL_CLOAKER_CLOAKDAMAGE_LVL = 5;

const float SKILL_CLOAKER_CLOAKNOVADAMAGE = 0.60f; // Cloak nova damage increase per level.
    const int SKILL_CLOAKER_CLOAKNOVADAMAGE_LVL = 5;


// Shocktrooper.
const float SKILL_SHOCK_CAPACITY         = 0.20f; // Shockrifle capacity per level.
    const int SKILL_SHOCK_CAPACITY_LVL      = 5;

const float SKILL_SHOCK_DAMAGE           = 0.20f; // Shockrifle damage per level.
    const int SKILL_SHOCK_DAMAGE_LVL        = 5;

const float SKILL_SHOCK_LIGHTNING        = 0.20f; // Shockrifle area lightning damage per level.
    const int SKILL_SHOCK_LIGHTNING_LVL     = 5;


// Vanquisher.
const float SKILL_VANQUISHER_AMMOPOOL    = 0.60f; // Ammo pool increase per level.
    const int SKILL_VANQUISHER_AMMOPOOL_LVL = 5;

const float SKILL_VANQUISHER_EXPLOSIVEDAMAGE = 1.0f; // Base damage increase of explosive damage per level.
    const int SKILL_VANQUISHER_EXPLOSIVEDAMAGE_LVL = 5;

const float SKILL_VANQUISHER_FIREDAMAGE = 0.04f; // Percentage of explosion as fire damage increase per level.
    const int SKILL_VANQUISHER_FIREDAMAGE_LVL = 5;

const float SKILL_VANQUISHER_FIREDURATION = 1.0f; // Fire damage duration increase per level.
    const int SKILL_VANQUISHER_FIREDURATION_LVL = 5;


// Swarmer.
const float SKILL_SWARMER_SNARKDAMAGE   = 0.40f; // Snark damage per level.
    const int SKILL_SWARMER_SNARKDAMAGE_LVL = 5;

const float SKILL_SWARMER_SNARKCOUNT    = 0.80f; // Percent of extra snarks per level.
    const int SKILL_SWARMER_SNARKCOUNT_LVL = 5;


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

    // Berserker.
    SKILL_BERSERKER_LIFESTEAL,
    SKILL_BERSERKER_DAMAGEABILITYCHARGE,
    SKILL_BERSERKER_DAMAGEREDUCTION,
    SKILL_BERSERKER_OVERHEAL,

    // Engineer.
    SKILL_ENGINEER_SENTRYDAMAGE,
    SKILL_ENGINEER_MINIHEALAURA,
    SKILL_ENGINEER_EXPLOSIVEAMMO,

    // Robomancer.


    // Xenomancer.
    SKILL_XENOMANCER_LIFESTEAL,

    // Necromancer.

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

    // Vanquisher.
    SKILL_VANQUISHER_AMMOPOOL,
    SKILL_VANQUISHER_EXPLOSIVEDAMAGE,
    SKILL_VANQUISHER_FIREDAMAGE,
    SKILL_VANQUISHER_FIREDURATION,

    // Swarmer.
    SKILL_SWARMER_SNARKDAMAGE,
    SKILL_SWARMER_SNARKCOUNT,

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
    @g_SkillDefs[int(SkillID::SKILL_MAXHP)] = SkillDefinition("Max Health", "+" + int(SKILL_MAXHP * 100) + "% Max HP per level.", SKILL_MAXHP_LVL, int(SKILL_MAXHP * 100.0f), "%");
    @g_SkillDefs[int(SkillID::SKILL_MAXAP)] = SkillDefinition("Max Armor", "+" + int(SKILL_MAXAP * 100) + "% Max AP per level.", SKILL_MAXAP_LVL, int(SKILL_MAXAP * 100.0f), "%");
    @g_SkillDefs[int(SkillID::SKILL_REGENHP)] = SkillDefinition("Health Regen", "+" + SKILL_REGENHP * 100.0f + "% HP/s per level.", SKILL_REGENHP_LVL, SKILL_REGENHP * 100.0f, "% HP/s");
    @g_SkillDefs[int(SkillID::SKILL_REGENAP)] = SkillDefinition("Armor Regen", "+" + SKILL_REGENAP * 100.0f + "% AP/s per level.", SKILL_REGENAP_LVL, SKILL_REGENAP * 100.0f, "% AP/s");
    @g_SkillDefs[int(SkillID::SKILL_ABILITYRECHARGE)] = SkillDefinition("Ability Recharge", "+" + SKILL_ABILITYRECHARGE * 100 + "% ability recharge speed per level.", SKILL_ABILITYRECHARGE_LVL, SKILL_ABILITYRECHARGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_AMMOREGEN)] = SkillDefinition("Ammo Regen", "+" + SKILL_AMMOREGEN + " ammo per interval, per level.", SKILL_AMMOREGEN_LVL, SKILL_AMMOREGEN, " Ammo");

    // Minion Class exclusive.
    @g_SkillDefs[int(SkillID::SKILL_MINIONPOINT)] = SkillDefinition("Minions: Minion Point", "+" + SKILL_MINIONPOINT + " minion point per level.", SKILL_MINIONPOINT_LVL, SKILL_MINIONPOINT, " Point");
    @g_SkillDefs[int(SkillID::SKILL_MINIONHP)] = SkillDefinition("Minions: Max HP", "+" + int(SKILL_MINIONHP * 100) + "% minion HP per level.", SKILL_MINIONHP_LVL, int(SKILL_MINIONHP * 100.0f), "%");
    @g_SkillDefs[int(SkillID::SKILL_MINIONREGEN)] = SkillDefinition("Minions: HP Regen", "+" + SKILL_MINIONREGEN * 100.0f + "% minion HP/s per level.", SKILL_MINIONREGEN_LVL, SKILL_MINIONREGEN * 100.0f, "% HP/s");
    @g_SkillDefs[int(SkillID::SKILL_MINIONDAMAGE)] = SkillDefinition("Minions: Damage", "+" + int(SKILL_MINIONDAMAGE * 100) + "% minion damage per level.", SKILL_MINIONDAMAGE_LVL, int(SKILL_MINIONDAMAGE * 100.0f), "%");

    // Medic.
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALPERCENT)] = SkillDefinition("Heal Aura: Healing", "+" + SKILL_MEDIC_HEALPERCENT + "% max heal per level.", SKILL_MEDIC_HEALPERCENT_LVL, SKILL_MEDIC_HEALPERCENT, "%");
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_POISON)] = SkillDefinition("Heal Aura: Poison", "+" + SKILL_MEDIC_POISON + "% poison damage per level.", SKILL_MEDIC_POISON_LVL, SKILL_MEDIC_POISON, "%");
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_REVIVE)] = SkillDefinition("Heal Aura: Revive", "-" + SKILL_MEDIC_REVIVE + "s revive cooldown per level.", SKILL_MEDIC_REVIVE_LVL, SKILL_MEDIC_REVIVE, "s");
    @g_SkillDefs[int(SkillID::SKILL_MEDIC_HEALAP)] = SkillDefinition("Heal Aura: AP Heal", "+" + (SKILL_MEDIC_HEALAP * 100.0f) + "% of heal to AP per level.", SKILL_MEDIC_HEALAP_LVL, SKILL_MEDIC_HEALAP * 100.0f, "%");

    // Berserker.
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_LIFESTEAL)] = SkillDefinition("Bloodlust: Lifesteal", "+" + (SKILL_BERSERKER_LIFESTEAL * 100.0f) + "% lifesteal per level.", SKILL_BERSERKER_LIFESTEAL_LVL, SKILL_BERSERKER_LIFESTEAL * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_DAMAGEABILITYCHARGE)] = SkillDefinition("Bloodlust: Damage to Ability Charge", "+" + (SKILL_BERSERKER_DAMAGEABILITYCHARGE * 100.0f) + "% of damage dealt converted to ability charge per level.", SKILL_BERSERKER_DAMAGEABILITYCHARGE_LVL, SKILL_BERSERKER_DAMAGEABILITYCHARGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_DAMAGEREDUCTION)] = SkillDefinition("Bloodlust: Damage Reduction", "+" + (SKILL_BERSERKER_DAMAGEREDUCTION * 100.0f) + "% damage reduction per level.", SKILL_BERSERKER_DAMAGEREDUCTION_LVL, SKILL_BERSERKER_DAMAGEREDUCTION * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_BERSERKER_OVERHEAL)]        = SkillDefinition("Bloodlust: Overheal",  "+" + (SKILL_BERSERKER_OVERHEAL * 100.0f) + "% Overheal per level.",            SKILL_BERSERKER_OVERHEAL_LVL,        SKILL_BERSERKER_OVERHEAL * 100.0f, "%");

    // Engineer.
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_SENTRYDAMAGE)] = SkillDefinition("Sentry: Damage", "+" + int(SKILL_ENGINEER_SENTRYDAMAGE * 100.0f) + "% damage per level.", SKILL_ENGINEER_SENTRYDAMAGE_LVL, int(SKILL_ENGINEER_SENTRYDAMAGE * 100.0f), "%");
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_MINIHEALAURA)]  = SkillDefinition("Sentry: Mini-Heal Aura",  "+" + int(SKILL_ENGINEER_MINIHEALAURA * 100.0f) + "% max HP heal/s per level.", SKILL_ENGINEER_MINIHEALAURA_LVL, int(SKILL_ENGINEER_MINIHEALAURA * 100.0f),  "%");
    @g_SkillDefs[int(SkillID::SKILL_ENGINEER_EXPLOSIVEAMMO)] = SkillDefinition("Sentry: Explosive Ammo",  "+" + int(SKILL_ENGINEER_EXPLOSIVEAMMO * 100.0f) + "% explosive damage per level.", SKILL_ENGINEER_EXPLOSIVEAMMO_LVL, int(SKILL_ENGINEER_EXPLOSIVEAMMO * 100.0f), "%");

    // Robomancer.

    // Xenomancer.
    @g_SkillDefs[int(SkillID::SKILL_XENOMANCER_LIFESTEAL)] = SkillDefinition("Xenomancer: Lifesteal", "+" + (SKILL_XENOMANCER_LIFESTEAL * 100.0f) + "% minion lifesteal per level.", SKILL_XENOMANCER_LIFESTEAL_LVL, SKILL_XENOMANCER_LIFESTEAL * 100.0f, "%");

    // Necromancer.

    // Warden.
    @g_SkillDefs[int(SkillID::SKILL_WARDEN_SHIELDHP)]       = SkillDefinition("Ice Shield: Shield HP", "+" + (SKILL_WARDEN_SHIELDHP * 100.0f) + "% shield HP per level.", SKILL_WARDEN_SHIELDHP_LVL, SKILL_WARDEN_SHIELDHP * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_WARDEN_DAMAGEREFLECT)]   = SkillDefinition("Ice Shield: Damage Reflect", "+" + (SKILL_WARDEN_DAMAGEREFLECT * 100.0f) + "% damage reflect per level.", SKILL_WARDEN_DAMAGEREFLECT_LVL, SKILL_WARDEN_DAMAGEREFLECT * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_WARDEN_ACTIVERECHARGE)] = SkillDefinition("Ice Shield: Active Recharge", "+" + (SKILL_WARDEN_ACTIVERECHARGE * 100.0f) + "% shield recharge per level.", SKILL_WARDEN_ACTIVERECHARGE_LVL, SKILL_WARDEN_ACTIVERECHARGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_WARDEN_HPABSORB)]       = SkillDefinition("Ice Shield: HP Absorb", "+" + (SKILL_WARDEN_HPABSORB * 100.0f) + "% HP absorb per level.", SKILL_WARDEN_HPABSORB_LVL, SKILL_WARDEN_HPABSORB * 100.0f, "%");

    // Shocktrooper.
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_CAPACITY)]  = SkillDefinition("Shockrifle: Shock Capacity",  "+" + (SKILL_SHOCK_CAPACITY * 100.0f) + "% shockrifle capacity per level.",  SKILL_SHOCK_CAPACITY_LVL,  SKILL_SHOCK_CAPACITY * 100.0f,  "%");
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_DAMAGE)]    = SkillDefinition("Shockrifle: Shock Damage",    "+" + (SKILL_SHOCK_DAMAGE * 100.0f) + "% shockrifle damage per level.",    SKILL_SHOCK_DAMAGE_LVL,    SKILL_SHOCK_DAMAGE * 100.0f,    "%");
    @g_SkillDefs[int(SkillID::SKILL_SHOCK_LIGHTNING)] = SkillDefinition("Shockrifle: Shock Lightning", "+" + (SKILL_SHOCK_LIGHTNING * 100.0f) + "% shockrifle lightning per level.", SKILL_SHOCK_LIGHTNING_LVL, SKILL_SHOCK_LIGHTNING * 100.0f, "%");

    // Cloaker.
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKDAMAGE)] = SkillDefinition("Cloak: Damage Bonus", "+" + (SKILL_CLOAKER_CLOAKDAMAGE * 100.0f) + "% damage bonus per level.", SKILL_CLOAKER_CLOAKDAMAGE_LVL, SKILL_CLOAKER_CLOAKDAMAGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_CLOAKER_CLOAKNOVADAMAGE)] = SkillDefinition("Cloak: Nova Damage", "+" + (SKILL_CLOAKER_CLOAKNOVADAMAGE * 100.0f) + "% nova damage per level.", SKILL_CLOAKER_CLOAKNOVADAMAGE_LVL, SKILL_CLOAKER_CLOAKNOVADAMAGE * 100.0f, "%");

    // Vanquisher.
    @g_SkillDefs[int(SkillID::SKILL_VANQUISHER_AMMOPOOL)] = SkillDefinition("Dragon's Breath: Ammo Pool", "+" + int(SKILL_VANQUISHER_AMMOPOOL * 100.0f) + "% ammo pool per level.", SKILL_VANQUISHER_AMMOPOOL_LVL, int(SKILL_VANQUISHER_AMMOPOOL * 100.0f), "%");
    @g_SkillDefs[int(SkillID::SKILL_VANQUISHER_EXPLOSIVEDAMAGE)] = SkillDefinition("Dragon's Breath: Explosive Damage", "+" + int(SKILL_VANQUISHER_EXPLOSIVEDAMAGE * 100.0f) + " explosive damage per level.", SKILL_VANQUISHER_EXPLOSIVEDAMAGE_LVL, SKILL_VANQUISHER_EXPLOSIVEDAMAGE, "");
    @g_SkillDefs[int(SkillID::SKILL_VANQUISHER_FIREDAMAGE)] = SkillDefinition("Dragon's Breath: Fire Damage", "+" + int(SKILL_VANQUISHER_FIREDAMAGE * 100.0f) + "% of explosion as fire damage per level.", SKILL_VANQUISHER_FIREDAMAGE_LVL, int(SKILL_VANQUISHER_FIREDAMAGE * 100.0f), "%");
    @g_SkillDefs[int(SkillID::SKILL_VANQUISHER_FIREDURATION)] = SkillDefinition("Dragon's Breath: Fire Duration", "+" + int(SKILL_VANQUISHER_FIREDURATION) + "s fire duration per level.", SKILL_VANQUISHER_FIREDURATION_LVL, int(SKILL_VANQUISHER_FIREDURATION), "s");

    // Swarmer.
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKDAMAGE)] = SkillDefinition("Snarks: Snark Damage", "+" + (SKILL_SWARMER_SNARKDAMAGE * 100.0f) + "% snark damage per level.", SKILL_SWARMER_SNARKDAMAGE_LVL, SKILL_SWARMER_SNARKDAMAGE * 100.0f, "%");
    @g_SkillDefs[int(SkillID::SKILL_SWARMER_SNARKCOUNT)]  = SkillDefinition("Snarks: Snark Count", "+" + (SKILL_SWARMER_SNARKCOUNT * 100.0f) + "% extra snarks per level.", SKILL_SWARMER_SNARKCOUNT_LVL, SKILL_SWARMER_SNARKCOUNT * 100.0f, "%");
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
            break;
        case PlayerClass::CLASS_BERSERKER:
            result.insertLast(SkillID::SKILL_BERSERKER_LIFESTEAL);
            result.insertLast(SkillID::SKILL_BERSERKER_DAMAGEABILITYCHARGE);
            result.insertLast(SkillID::SKILL_BERSERKER_DAMAGEREDUCTION);
            result.insertLast(SkillID::SKILL_BERSERKER_OVERHEAL);
            break;
        case PlayerClass::CLASS_ENGINEER:
            result.insertLast(SkillID::SKILL_ENGINEER_SENTRYDAMAGE);
            result.insertLast(SkillID::SKILL_ENGINEER_MINIHEALAURA);
            result.insertLast(SkillID::SKILL_ENGINEER_EXPLOSIVEAMMO);
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
