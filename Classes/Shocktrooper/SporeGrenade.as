/*
Created as an example using Claude AI.

SporeGrenade.as
A custom bouncing scripted projectile that replicates the spore/acid grenade
attack used by Shock Troopers in Half-Life: Opposing Force.

Behaviour:
  - Launched from the player in an upward arc.
  - Bounces off world geometry using MOVETYPE_BOUNCE physics.
  - Detonates on direct contact with a player or monster.
  - Detonates on fuse expiry after SPORE_FUSE_TIME seconds.
  - Explosion: burst of acid-green particles, radius DMG_ACID blast, then a
    lingering toxic cloud that ticks repeated DMG_ACID for SPORE_DOT_TICKS
    intervals.

HOW TO INTEGRATE:
  1. In PrecacheAll()     ->  RegisterSporeGrenade();
                              PrecacheSporeGrenade();
  2. In ClientSay / ability code  ->  LaunchSporeGrenade(pPlayer, damage, radius);

NOTE: "sprites/tinyspit.spr" must be precached before use. It is precached
by XenMinion on most maps, but registering it inside PrecacheSporeGrenade()
below makes this standalone.
*/

// ============================================================
//  Assets  (swap to better spore assets if available)
// ============================================================
const string SPORE_GRN_MODEL         = "models/grenade.mdl";     // Replace with a spore/organic model if available.
const string SPORE_GRN_SPRITE_CLOUD  = "sprites/tinyspit.spr";   // Spore-spit particle - same as used by the bullsquid acid trail.
const string SPORE_GRN_SPRITE_GLOW   = "sprites/glow01.spr";     // Central burst glow on detonation.
const string SPORE_GRN_SPRITE_SMOKE  = "sprites/steam1.spr";     // Lingering cloud visual.
const string SPORE_GRN_SND_BOUNCE    = "debris/metal1.wav";      // Impact sound on world bounce. Swap for an organic thud if preferred.
const string SPORE_GRN_SND_EXPLODE   = "weapons/explode3.wav";   // Detonation sound.

// ============================================================
//  Tuning constants
// ============================================================
const float SPORE_FUSE_TIME     = 3.5f;   // Seconds until it detonates without hitting anything.
const float SPORE_LAUNCH_SPEED  = 700.0f; // Forward velocity on throw.
const float SPORE_UPWARD_ARC    = 200.0f; // Extra upward velocity for a grenade arc.
const int   SPORE_MAX_BOUNCES   = 4;      // After this many world bounces the fuse is shortened to SPORE_ARMED_FUSE.
const float SPORE_ARMED_FUSE    = 0.35f;  // Short fuse (seconds) once max bounces is reached.
const int   SPORE_DOT_TICKS     = 5;      // Number of damage-over-time ticks after the explosion.
const float SPORE_DOT_INTERVAL  = 0.8f;   // Seconds between each tick.

// ============================================================
//  Registration & Precache
//  Call RegisterSporeGrenade() and PrecacheSporeGrenade()
//  from PrecacheAll() (which is invoked in MapInit).
// ============================================================
void RegisterSporeGrenade()
{
    g_CustomEntityFuncs.RegisterCustomEntity("CSporeGrenade", "carpg_spore_grenade");
}

void PrecacheSporeGrenade()
{
    g_Game.PrecacheModel(SPORE_GRN_MODEL);
    g_Game.PrecacheModel(SPORE_GRN_SPRITE_CLOUD);
    g_Game.PrecacheModel(SPORE_GRN_SPRITE_GLOW);
    g_Game.PrecacheModel(SPORE_GRN_SPRITE_SMOKE);
    g_SoundSystem.PrecacheSound(SPORE_GRN_SND_BOUNCE);
    g_SoundSystem.PrecacheSound(SPORE_GRN_SND_EXPLODE);
}

// ============================================================
//  Launch helper
//  Throws a spore grenade from the player's gun position.
//  flDamage  - instant blast damage at detonation.
//  flRadius  - blast/DoT radius in units.
// ============================================================
void LaunchSporeGrenade(CBasePlayer@ pPlayer, float flDamage, float flRadius)
{
    if(pPlayer is null) return;

    Math.MakeVectors(pPlayer.pev.v_angle);

    Vector vecSrc      = pPlayer.GetGunPosition() + g_Engine.v_forward * 16;
    Vector vecVelocity = g_Engine.v_forward * SPORE_LAUNCH_SPEED;
    vecVelocity.z     += SPORE_UPWARD_ARC;

    dictionary keys;
    keys["origin"]      = vecSrc.ToString();
    keys["angles"]      = pPlayer.pev.v_angle.ToString();
    keys["owner_index"] = string(pPlayer.entindex());
    keys["damage"]      = string(flDamage);
    keys["dot_damage"]  = string(flDamage * 0.4f); // DoT tick damage is 40% of the initial blast.
    keys["radius"]      = string(flRadius);

    CBaseEntity@ pGrenade = g_EntityFuncs.CreateEntity("carpg_spore_grenade", keys, true);
    if(pGrenade !is null)
        pGrenade.pev.velocity = vecVelocity;
}

// ============================================================
//  Spore Grenade - Scripted Entity
// ============================================================
class CSporeGrenade : ScriptBaseEntity
{
    // --- Config fields set via KeyValue ---
    private int   m_iOwnerIndex  = -1;
    private float m_flDamage     = 20.0f;
    private float m_flDotDamage  = 8.0f;
    private float m_flRadius     = 200.0f;

    // --- Internal state ---
    private bool  m_bExploded        = false;
    private int   m_iBounces         = 0;
    private float m_flLastBounceTime = 0.0f; // Guards against rapid-fire bounce sound spam.

    // --- KeyValue: receives values set by LaunchSporeGrenade() ---
    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if(szKey == "owner_index") { m_iOwnerIndex = atoi(szValue); return true; }
        if(szKey == "damage")      { m_flDamage    = atof(szValue); return true; }
        if(szKey == "dot_damage")  { m_flDotDamage = atof(szValue); return true; }
        if(szKey == "radius")      { m_flRadius    = atof(szValue); return true; }
        return BaseClass.KeyValue(szKey, szValue);
    }

    // --- Spawn: set up physics and appearance ---
    void Spawn()
    {
        // Physics: bouncing projectile.
        self.pev.movetype = MOVETYPE_BOUNCE;
        self.pev.solid    = SOLID_BBOX;
        self.pev.gravity  = 1.1f;  // Slightly heavier than a normal object.
        self.pev.friction = 0.7f;  // Retain ~70% velocity per bounce — a realistic grenade roll-off.

        g_EntityFuncs.SetModel(self, SPORE_GRN_MODEL);
        g_EntityFuncs.SetSize(self.pev, Vector(-4, -4, -4), Vector(4, 4, 4));
        g_EntityFuncs.SetOrigin(self, self.pev.origin);

        // Tumble spin for visual authenticity.
        self.pev.avelocity = Vector(
            Math.RandomFloat(-250.0f, 250.0f),
            Math.RandomFloat(-250.0f, 250.0f),
            Math.RandomFloat(-250.0f, 250.0f)
        );

        // Subtle green glow shell on the projectile.
        self.pev.renderfx    = kRenderFxGlowShell;
        self.pev.rendermode  = kRenderNormal;
        self.pev.renderamt   = 20;
        self.pev.rendercolor = Vector(30, 200, 30);

        SetTouch(TouchFunction(this.BounceTouch));
        SetThink(ThinkFunction(this.FuseThink));

        // Arm the fuse.
        self.pev.nextthink = g_Engine.time + SPORE_FUSE_TIME;
    }

    // -------------------------------------------------------
    //  Touch: handle world bounce vs. entity contact
    // -------------------------------------------------------
    void BounceTouch(CBaseEntity@ pOther)
    {
        if(m_bExploded) return;

        // Direct contact with a living target - detonate immediately.
        if(pOther !is null && (pOther.IsPlayer() || pOther.IsMonster()))
        {
            Explode();
            return;
        }

        // World geometry bounce.
        // MOVETYPE_BOUNCE handles velocity reflection automatically.
        // We only need to count bounces and manage sound/arming.
        m_iBounces++;

        // Prevent sound spam on rapid sliding contact.
        float flNow = g_Engine.time;
        if(flNow - m_flLastBounceTime > 0.25f)
        {
            m_flLastBounceTime = flNow;
            // Slightly pitch-shift for variety.
            int iPitch = 90 + Math.RandomLong(-8, 8);
            g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_BODY, SPORE_GRN_SND_BOUNCE, 0.6f, ATTN_NORM, 0, iPitch);
        }

        // After enough bounces, arm a very short detonation delay so the
        // grenade finishes rolling and blows up locally.
        if(m_iBounces == SPORE_MAX_BOUNCES)
            self.pev.nextthink = g_Engine.time + SPORE_ARMED_FUSE;
    }

    // -------------------------------------------------------
    //  Think: fuse expired, detonate
    // -------------------------------------------------------
    void FuseThink()
    {
        Explode();
    }

    // -------------------------------------------------------
    //  Explode: blast, visuals, and schedule DoT cloud ticks
    // -------------------------------------------------------
    void Explode()
    {
        if(m_bExploded) return;
        m_bExploded = true;

        Vector pos = self.pev.origin;

        // --- Sound ---
        // Use null edict so the sound isn't silenced when the entity is removed.
        g_SoundSystem.PlaySound(null, CHAN_WEAPON, SPORE_GRN_SND_EXPLODE, 1.0f, ATTN_NORM, 0, 95);

        // --- Radius damage: initial acid blast ---
        CBasePlayer@ pOwner = g_PlayerFuncs.FindPlayerByIndex(m_iOwnerIndex);
        if(pOwner !is null)
            g_WeaponFuncs.RadiusDamage(pos, pOwner.pev, pOwner.pev, m_flDamage, m_flRadius, CLASS_PLAYER, DMG_ACID);
        else
            g_WeaponFuncs.RadiusDamage(pos, self.pev, self.pev, m_flDamage, m_flRadius, CLASS_PLAYER, DMG_ACID);

        // --- Green dynamic light that persists for the cloud lifetime ---
        float cloudLifetime = SPORE_DOT_TICKS * SPORE_DOT_INTERVAL;
        NetworkMessage dlight(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
            dlight.WriteByte(TE_DLIGHT);
            dlight.WriteCoord(pos.x);
            dlight.WriteCoord(pos.y);
            dlight.WriteCoord(pos.z);
            dlight.WriteByte(25);                           // Radius / 10.
            dlight.WriteByte(30);                           // R.
            dlight.WriteByte(220);                          // G (heavy green).
            dlight.WriteByte(30);                           // B.
            dlight.WriteByte(uint8(cloudLifetime * 10));    // Life * 0.1s.
            dlight.WriteByte(3);                            // Decay rate.
        dlight.End();

        // --- Central glow burst on detonation ---
        NetworkMessage centerGlow(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
            centerGlow.WriteByte(TE_SPRITE);
            centerGlow.WriteCoord(pos.x);
            centerGlow.WriteCoord(pos.y);
            centerGlow.WriteCoord(pos.z);
            centerGlow.WriteShort(g_EngineFuncs.ModelIndex(SPORE_GRN_SPRITE_GLOW));
            centerGlow.WriteByte(18);   // Scale * 10.
            centerGlow.WriteByte(200);  // Brightness.
        centerGlow.End();

        // --- Outward spore particle spray ---
        BurstSporeParticles(pos);

        // --- Lingering smoke cloud ---
        NetworkMessage smoke(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
            smoke.WriteByte(TE_SMOKE);
            smoke.WriteCoord(pos.x);
            smoke.WriteCoord(pos.y);
            smoke.WriteCoord(pos.z);
            smoke.WriteShort(g_EngineFuncs.ModelIndex(SPORE_GRN_SPRITE_SMOKE));
            smoke.WriteByte(90);   // Scale * 10.
            smoke.WriteByte(5);    // Framerate.
        smoke.End();

        // --- Ground Scorch ---
        NetworkMessage decal(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
            decal.WriteByte(TE_WORLDDECAL);
            decal.WriteCoord(pos.x);
            decal.WriteCoord(pos.y);
            decal.WriteCoord(pos.z - 8);
            decal.WriteByte(g_EngineFuncs.DecalIndex("{scorch1"));
        decal.End();

        // --- Schedule DoT cloud ticks ---
        // Each tick re-emits particles (keeping the cloud alive visually)
        // and applies a smaller radius-damage pulse.
        for(int i = 1; i <= SPORE_DOT_TICKS; i++)
        {
            float tickTime = SPORE_DOT_INTERVAL * i;
            g_Scheduler.SetTimeout("SporeGrenadeDotTick", tickTime,
                pos, m_iOwnerIndex, m_flDotDamage, m_flRadius * 0.7f);
        }

        g_EntityFuncs.Remove(self);
    }

    // -------------------------------------------------------
    //  BurstSporeParticles: 4-way radial spray on detonation
    // -------------------------------------------------------
    private void BurstSporeParticles(Vector pos)
    {
        // Four directional trails, evenly spread around the impact point.
        for(int i = 0; i < 4; i++)
        {
            float angle = (Math.PI * 0.5f) * i;
            Vector endPt;
            endPt.x = pos.x + cos(angle) * 70.0f;
            endPt.y = pos.y + sin(angle) * 70.0f;
            endPt.z = pos.z + Math.RandomFloat(15.0f, 45.0f);

            NetworkMessage trail(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
                trail.WriteByte(TE_SPRITETRAIL);
                trail.WriteCoord(pos.x);
                trail.WriteCoord(pos.y);
                trail.WriteCoord(pos.z);
                trail.WriteCoord(endPt.x);
                trail.WriteCoord(endPt.y);
                trail.WriteCoord(endPt.z);
                trail.WriteShort(g_EngineFuncs.ModelIndex(SPORE_GRN_SPRITE_CLOUD));
                trail.WriteByte(10);   // Count.
                trail.WriteByte(18);   // Life in 0.1s.
                trail.WriteByte(3);    // Scale in 0.1s.
                trail.WriteByte(22);   // Velocity along vector * 10.
                trail.WriteByte(18);   // Random scatter velocity * 10.
            trail.End();
        }

        // Upward geyser burst for the spore cloud rising effect.
        Vector topPt = pos + Vector(0, 0, 80);
        NetworkMessage geyser(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
            geyser.WriteByte(TE_SPRITETRAIL);
            geyser.WriteCoord(pos.x);
            geyser.WriteCoord(pos.y);
            geyser.WriteCoord(pos.z);
            geyser.WriteCoord(topPt.x);
            geyser.WriteCoord(topPt.y);
            geyser.WriteCoord(topPt.z);
            geyser.WriteShort(g_EngineFuncs.ModelIndex(SPORE_GRN_SPRITE_CLOUD));
            geyser.WriteByte(14);  // Count.
            geyser.WriteByte(20);  // Life.
            geyser.WriteByte(4);   // Scale.
            geyser.WriteByte(30);  // Velocity along vector * 10.
            geyser.WriteByte(20);  // Random scatter * 10.
        geyser.End();
    }
}

// ============================================================
//  SporeGrenadeDotTick
//  Global function called by the scheduler for each DoT pulse
//  after the initial detonation. Re-emits cloud particles and
//  applies a smaller acid damage pulse each tick.
// ============================================================
void SporeGrenadeDotTick(Vector pos, int iOwnerIndex, float flDamage, float flRadius)
{
    // --- Visual: drifting spore wisps to keep cloud alive ---
    Vector driftPt;
    driftPt.x = pos.x + Math.RandomFloat(-50.0f, 50.0f);
    driftPt.y = pos.y + Math.RandomFloat(-50.0f, 50.0f);
    driftPt.z = pos.z + Math.RandomFloat(20.0f, 60.0f);

    NetworkMessage wisp(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
        wisp.WriteByte(TE_SPRITETRAIL);
        wisp.WriteCoord(pos.x);
        wisp.WriteCoord(pos.y);
        wisp.WriteCoord(pos.z);
        wisp.WriteCoord(driftPt.x);
        wisp.WriteCoord(driftPt.y);
        wisp.WriteCoord(driftPt.z);
        wisp.WriteShort(g_EngineFuncs.ModelIndex(SPORE_GRN_SPRITE_CLOUD));
        wisp.WriteByte(5);    // Count - fewer than burst for a subtle linger.
        wisp.WriteByte(10);   // Life.
        wisp.WriteByte(2);    // Scale.
        wisp.WriteByte(12);   // Velocity along vector * 10.
        wisp.WriteByte(10);   // Random scatter * 10.
    wisp.End();

    // --- Visual: rolling smoke puff, offset slightly so it drifts ---
    NetworkMessage smoke(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pos);
        smoke.WriteByte(TE_SMOKE);
        smoke.WriteCoord(pos.x + Math.RandomFloat(-20.0f, 20.0f));
        smoke.WriteCoord(pos.y + Math.RandomFloat(-20.0f, 20.0f));
        smoke.WriteCoord(pos.z + Math.RandomFloat(0.0f, 30.0f));
        smoke.WriteShort(g_EngineFuncs.ModelIndex(SPORE_GRN_SPRITE_SMOKE));
        smoke.WriteByte(Math.RandomLong(30, 55)); // Random scale.
        smoke.WriteByte(8);
    smoke.End();

    // --- Damage: acid pulse ---
    CBasePlayer@ pOwner = g_PlayerFuncs.FindPlayerByIndex(iOwnerIndex);
    if(pOwner !is null)
        g_WeaponFuncs.RadiusDamage(pos, pOwner.pev, pOwner.pev, flDamage, flRadius, CLASS_PLAYER, DMG_ACID);
    else
    {
        // Fallback if owner is no longer valid (disconnected, dead, etc.).
        // Create a dummy pev reference from the world for attribution.
        CBaseEntity@ pWorld = g_EntityFuncs.Instance(0);
        if(pWorld !is null)
            g_WeaponFuncs.RadiusDamage(pos, pWorld.pev, pWorld.pev, flDamage, flRadius, CLASS_PLAYER, DMG_ACID);
    }
}
