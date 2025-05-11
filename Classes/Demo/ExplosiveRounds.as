// Base stats and scaling
float flExplosiveRoundsDamage = 10.0f;
float flExplosiveRoundsDamageScaling = 0.1f; // % Damage increase per level.
float flExplosiveRoundsPoolScaling = 0.1f; // % Pool size increase per level.
float flExplosiveRoundsRadius = 64.0f; // Radius of explosion.
int iBaseExplosiveRounds = 15; // Base max rounds in pool.

// Stats menu values.
float flExplosiveRoundsDamageBase = flExplosiveRoundsDamage; // used for stats menu.
float flExplosiveRoundsDamageBonus = 0.0f; // used for stats menu.
float flExplosiveRoundsPoolBase = iBaseExplosiveRounds; // used for stats menu.
float flExplosiveRoundsPoolBonus = 0.0f; // used for stats menu.


// Energy and rounds settings
const float flEnergyCostPerActivation = 10.0f; // Fixed energy cost.
const float flRoundsGivenPerActivation = 1.0f; // Fixed rounds given per activation.

// Sounds and models
const string strExplosiveRoundsActivateSound = "weapons/reload3.wav";
const string strExplosiveRoundsExplosionSprite = "sprites/eexplo.spr";

// Replace the fixed index dictionary with string-based one
dictionary g_AmmoTypeDamageMultipliers = 
{
    {"9mm", 1.0f},
    {"357", 1.0f},
    {"buckshot", 0.5f},
    {"bolts", 1.5f},
    {"556", 1.0f},
    {"762", 1.5f},
    {"uranium", 1.5f},
    {"m40a1", 1.5f}
};

dictionary g_PlayerExplosiveRounds;

class ExplosiveRoundsData
{
    private float m_flRoundsInPool = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flToggleCooldown = 0.10f;
    private ClassStats@ m_pStats = null;

    bool HasStats() { return m_pStats !is null; }
    bool HasRounds() { return m_flRoundsInPool > 0; }
    float GetRounds() { return m_flRoundsInPool; }
    void ResetRounds() { m_flRoundsInPool = 0; }
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetScaledDamage()
    {
        if(m_pStats is null)
            return flExplosiveRoundsDamage;
            flExplosiveRoundsDamageBonus = flExplosiveRoundsDamage * (1.0f + (m_pStats.GetLevel() * flExplosiveRoundsDamageScaling)) - flExplosiveRoundsDamageBase; // For stats menu.
        return flExplosiveRoundsDamage * (1.0f + (m_pStats.GetLevel() * flExplosiveRoundsDamageScaling));

    }

    float GetRadius() { return flExplosiveRoundsRadius; }

    void ConsumeRound() 
    { 
        m_flRoundsInPool = Math.max(0.0f, m_flRoundsInPool - 1.0f);
    }

    int GetMaxRounds()
    {
        if(m_pStats is null)
            return iBaseExplosiveRounds;
            flExplosiveRoundsPoolBonus = int(iBaseExplosiveRounds * (1.0f + (m_pStats.GetLevel() * flExplosiveRoundsPoolScaling))) - flExplosiveRoundsPoolBase; // For stats menu.
        return int(iBaseExplosiveRounds * (1.0f + (m_pStats.GetLevel() * flExplosiveRoundsPoolScaling)));
    }

    void ActivateExplosiveRounds(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
            return;

        if(m_flRoundsInPool >= GetMaxRounds())
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Explosive Rounds full!\n");
            return;
        }

        string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamId))
            return;

        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamId]);
        float current = float(resources['current']);

        if(current < flEnergyCostPerActivation)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Need " + int(flEnergyCostPerActivation) + " energy!\n");
            return;
        }

        // Add fixed number of rounds
        m_flRoundsInPool = Math.min(m_flRoundsInPool + flRoundsGivenPerActivation, float(GetMaxRounds()));

        // Deduct fixed energy cost
        resources['current'] = Math.max(0, current - flEnergyCostPerActivation);

        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strExplosiveRoundsActivateSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "+" + int(flRoundsGivenPerActivation) + " Explosive Rounds\n");

        m_flLastToggleTime = currentTime;
    }

    // Then modify FireExplosiveRounds to use ammo names
    void FireExplosiveRounds(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon)
    {
        if(pPlayer is null || pWeapon is null || !HasRounds())
            return;
            
        int ammoType = -1; // Initialize with invalid index
        if(pWeapon !is null)
        {
            ammoType = pWeapon.PrimaryAmmoIndex();
        }

        if(ammoType == -1)
            return;

        string ammoName = GetAmmoName(ammoType);
        string weaponName = pWeapon.GetClassname();
        float damageMultiplier = 1.0f; // Default multiplier
        
        if(g_AmmoTypeDamageMultipliers.exists(ammoName))
        {
            damageMultiplier = float(g_AmmoTypeDamageMultipliers[ammoName]);
        }

        // Special handling for specific ammo types
        if(ammoName == "buckshot")
        {
            const int SHOTGUN_PELLETS = 6;
            
            for(int i = 0; i < SHOTGUN_PELLETS; i++)
            {
                Vector angles = pPlayer.pev.v_angle;
                Math.MakeVectors(angles);
                Vector vecAiming = g_Engine.v_forward;
                Vector spread = Vector(
                    Math.RandomFloat(-0.1, 0.1),
                    Math.RandomFloat(-0.1, 0.1),
                    Math.RandomFloat(-0.1, 0.1)
                );
                vecAiming = vecAiming + spread;

                Vector vecSrc = pPlayer.GetGunPosition();
                Vector vecEnd = vecSrc + vecAiming * 4096;

                TraceResult tr;
                g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr);

                // Create visual explosion
                NetworkMessage msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos);
                msg.WriteByte(TE_EXPLOSION);
                msg.WriteCoord(tr.vecEndPos.x);
                msg.WriteCoord(tr.vecEndPos.y);
                msg.WriteCoord(tr.vecEndPos.z);
                msg.WriteShort(g_EngineFuncs.ModelIndex(strExplosiveRoundsExplosionSprite));
                msg.WriteByte(10); // Scale
                msg.WriteByte(15); // Framerate
                msg.WriteByte(0); // Flags
                msg.End();

                // Apply damage at same position
                g_WeaponFuncs.RadiusDamage(
                    tr.vecEndPos,
                    pPlayer.pev,
                    pPlayer.pev,
                    GetScaledDamage() * damageMultiplier,
                    GetRadius(),
                    CLASS_PLAYER_ALLY,
                    DMG_BLAST | DMG_ALWAYSGIB
                );
            }

            ConsumeRound();
        }
        else if(weaponName == "weapon_m16" && ammoName == "556")
        {
            const int BURST_SHOTS = 3;
            const float BURST_DELAY = 0.085f;
            const float currentTime = g_Engine.time;
            
            for(int i = 0; i < BURST_SHOTS; i++)
            {
                Vector vecSrc = pPlayer.GetGunPosition();
                Vector angles = pPlayer.pev.v_angle;
                Math.MakeVectors(angles);
                Vector vecAiming = g_Engine.v_forward;
                Vector vecEnd = vecSrc + (vecAiming * 4096);

                TraceResult tr;
                g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr);

                // Create visual explosion
                NetworkMessage msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos);
                msg.WriteByte(TE_EXPLOSION);
                msg.WriteCoord(tr.vecEndPos.x);
                msg.WriteCoord(tr.vecEndPos.y);
                msg.WriteCoord(tr.vecEndPos.z);
                msg.WriteShort(g_EngineFuncs.ModelIndex(strExplosiveRoundsExplosionSprite));
                msg.WriteByte(8); // Slightly smaller scale for burst
                msg.WriteByte(15); // Framerate
                msg.WriteByte(0); // Flags
                msg.End();

                g_WeaponFuncs.RadiusDamage(
                    tr.vecEndPos,
                    pPlayer.pev,
                    pPlayer.pev,
                    GetScaledDamage() * damageMultiplier,
                    GetRadius(),
                    CLASS_PLAYER_ALLY,
                    DMG_BLAST | DMG_ALWAYSGIB
                );

                ConsumeRound();
            }
        }
        else
        {
            // Normal weapon handling
            Vector vecSrc = pPlayer.GetGunPosition();

            // Get player's view angles and convert to aim vector
            Vector angles = pPlayer.pev.v_angle;
            Math.MakeVectors(angles);
            Vector vecAiming = g_Engine.v_forward;

            Vector vecEnd = vecSrc + (vecAiming * 4096);

            TraceResult tr;
            g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr);

            // Create explosion at exact impact point
            NetworkMessage msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos);
            msg.WriteByte(TE_EXPLOSION);
            msg.WriteCoord(tr.vecEndPos.x);
            msg.WriteCoord(tr.vecEndPos.y);
            msg.WriteCoord(tr.vecEndPos.z);
            msg.WriteShort(g_EngineFuncs.ModelIndex(strExplosiveRoundsExplosionSprite));
            msg.WriteByte(15); // Scale
            msg.WriteByte(15); // Framerate
            msg.WriteByte(0); // Flags
            msg.End();

            g_WeaponFuncs.RadiusDamage(
                tr.vecEndPos,
                pPlayer.pev,
                pPlayer.pev,
                GetScaledDamage() * damageMultiplier,
                GetRadius(),
                CLASS_PLAYER_ALLY,
                DMG_BLAST | DMG_ALWAYSGIB
            );
            
            ConsumeRound();
        }
    }
}

// Helper function to get ammo name from index
string GetAmmoName(int ammoType)
{
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("9mm")) return "9mm";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("357")) return "357";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("buckshot")) return "buckshot";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("bolts")) return "bolts";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("556")) return "556";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("762")) return "762";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("uranium")) return "uranium";
    if(ammoType == g_PlayerFuncs.GetAmmoIndex("m40a1")) return "m40a1";
    return "";
}