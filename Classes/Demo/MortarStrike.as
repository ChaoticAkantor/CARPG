float flMortarStrikeDelay = 3.0f;
float flMortarStrikeEnergyCost = 100.0f;
const float flMortarStrikeRange = 1024.0f;
float flMortarStrikeDamage = 80.0f; // base damage of each explosion.
float MORTAR_DAMAGE_SCALE = 0.20f; // 10% damage increase per level
float flMortarStrikeDamageRadius = 512.0f;
int iBaseNumExplosions = 10; // Base number of clusters.
int iExplosionsScalingNum = 2; // Extra clusters per 5 levels.

const string strMortarStrikeSetSound = "weapons/mine_deploy.wav";
const string strMortarStrikeChargeSound = "weapons/mine_charge.wav";
const string strMortarStrikeLaunchSound = "weapons/mortar.wav";
const string strMortarStrikeAirSound = "weapons/mortar.wav";
const string strMortarStrikeImpactSound = "weapons/mortarhit.wav";
const string strMortarStrikeTargetSprite = "sprites/laserbeam.spr";
const string strMortarStrikeImpactSprite = "sprites/zerogxplode.spr";
const string strMortarStrikeSmokeSprite = "sprites/steam1.spr";
const string strMortarStrikeGlowSprite = "sprites/glow01.spr";

dictionary g_PlayerMortarStrikes;

class MortarStrikeData
{
    private float m_flCooldown = 2.0f;
    private float m_flLastUseTime = 0.0f;
    private ClassStats@ m_pStats = null;

    bool HasStats() { return m_pStats !is null; }
    
    void SetStats(ClassStats@ stats) 
    { 
        @m_pStats = stats; 
    }
    
    void Initialize(ClassStats@ stats)
    {
        @m_pStats = stats;
    }

    bool IsOnCooldown(CBasePlayer@ pPlayer)
    {
        float currentTime = g_Engine.time;
        if(currentTime - m_flLastUseTime < m_flCooldown)
        {
            float remainingCooldown = m_flCooldown - (currentTime - m_flLastUseTime);
            //g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Mortar Strike on cooldown: " + int(remainingCooldown) + " seconds\n");
            return true;
        }
        return false;
    }

    void LaunchMortar(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        
        if(IsOnCooldown(pPlayer))
            return;
            
        if(!g_PlayerClassResources.exists(steamId))
            return;
            
        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamId]);
        float current = float(resources['current']);
        
        if(current < flMortarStrikeEnergyCost)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Not enough energy for Mortar Strike!\n");
            return;
        }
        
        // Get player's view target
        TraceResult tr;
        Vector vecSrc = pPlayer.EyePosition();
        Math.MakeVectors(pPlayer.pev.v_angle);
        Vector vecEnd = vecSrc + g_Engine.v_forward * flMortarStrikeRange;
        
        g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr);
        
        // Only allow targeting on the floor
        if(tr.pHit !is null && tr.flFraction < 1.0 && tr.vecPlaneNormal.z >= 0.7)
        {
            // Take energy using resource system
            current -= flMortarStrikeEnergyCost;
            resources['current'] = current;
            
            // Start cooldown
            m_flLastUseTime = g_Engine.time;
            
            // Create target marker and effects
            CreateTargetMarker(tr.vecEndPos);

            // Play mortar set and charge sound.
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_ITEM, strMortarStrikeSetSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_ITEM, strMortarStrikeChargeSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
        
            // Schedule explosion - using method reference from within class
            g_Scheduler.SetTimeout(this, "MortarImpact", flMortarStrikeDelay, tr.vecEndPos, @pPlayer);
            
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Mortar strike incoming!\n");
        }
        else
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Invalid target location!\n");
        }
    }

    private void CreateTargetMarker(Vector position)
    {
        NetworkMessage targetMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            targetMsg.WriteByte(TE_BEAMCYLINDER);
            targetMsg.WriteCoord(position.x);
            targetMsg.WriteCoord(position.y);
            targetMsg.WriteCoord(position.z);
            targetMsg.WriteCoord(position.x);
            targetMsg.WriteCoord(position.y);
            targetMsg.WriteCoord(position.z + 32.0);
            targetMsg.WriteShort(g_EngineFuncs.ModelIndex(strMortarStrikeTargetSprite));
            targetMsg.WriteByte(0);
            targetMsg.WriteByte(0);
            targetMsg.WriteByte(int(flMortarStrikeDelay * 5.0));
            targetMsg.WriteByte(64);
            targetMsg.WriteByte(0);
            targetMsg.WriteByte(255);
            targetMsg.WriteByte(0);
            targetMsg.WriteByte(0);
            targetMsg.WriteByte(255);
            targetMsg.WriteByte(0);
        targetMsg.End();
    }

    private void MortarImpact(Vector position, CBasePlayer@ pAttacker)
    {
        // Play mortar air sound first.
        g_SoundSystem.PlaySound(null, CHAN_WEAPON, strMortarStrikeAirSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
        
        // Schedule the explosions after a short delay.
        g_Scheduler.SetTimeout(this, "CreateMortarExplosions", 2.0f, position, @pAttacker);
    }

    private void CreateMortarExplosions(Vector position, CBasePlayer@ pAttacker)
    {
        // Create cluster of explosions - now using scaled number
        int numExplosions = GetScaledExplosions();
        const float MAX_SCATTER = 300.0f; // Maximum distance from center
        float scaledDamage = GetScaledDamage(); // Damage per explosion.
        
        // Create main explosion
        CreateExplosionEffect(position);
        g_WeaponFuncs.RadiusDamage(position, pAttacker.pev, pAttacker.pev, scaledDamage, flMortarStrikeDamageRadius, CLASS_PLAYER, DMG_BLAST);
        
        // Schedule scattered explosions
        for(int i = 0; i < numExplosions - 1; i++)
        {
            // Random offset from center
            float angle = Math.RandomFloat(0, Math.PI * 2);
            float dist = Math.RandomFloat(32.0f, MAX_SCATTER);
            Vector offset;
            offset.x = cos(angle) * dist;
            offset.y = sin(angle) * dist;
            offset.z = 0;
            
            Vector explosionPos = position + offset;
            
            // Trace down to ensure explosion is on ground
            TraceResult tr;
            g_Utility.TraceLine(explosionPos + Vector(0, 0, 32), explosionPos + Vector(0, 0, -32), ignore_monsters, null, tr);
            
            if(tr.flFraction < 1.0)
            {
                // Delay each explosion slightly
                g_Scheduler.SetTimeout(this, "CreateDelayedExplosion", 0.25 + (0.25 * i), tr.vecEndPos, @pAttacker, scaledDamage);
            }
        }
        
        CreateAfterEffect(position);
    }

    private int GetScaledExplosions()
    {
        if(m_pStats is null)
            return iBaseNumExplosions;
            
        return iBaseNumExplosions + (m_pStats.GetLevel() / 5 * iExplosionsScalingNum);
    }

    private void CreateDelayedExplosion(Vector position, CBasePlayer@ pAttacker, float damage)
    {  
        CreateExplosionEffect(position);
        g_WeaponFuncs.RadiusDamage(position, pAttacker.pev, pAttacker.pev, damage, flMortarStrikeDamageRadius, CLASS_PLAYER, DMG_BLAST);
        CreateAfterEffect(position);
    }

    private void CreateExplosionEffect(Vector position)
    {
        NetworkMessage expMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            expMsg.WriteByte(TE_EXPLOSION);
            expMsg.WriteCoord(position.x);
            expMsg.WriteCoord(position.y);
            expMsg.WriteCoord(position.z);
            expMsg.WriteShort(g_EngineFuncs.ModelIndex(strMortarStrikeImpactSprite));
            expMsg.WriteByte(30);  // Scale
            expMsg.WriteByte(15);  // Framerate
            expMsg.WriteByte(0);   // Flags
        expMsg.End();
    }

    private float GetScaledDamage()
    {
        if(m_pStats is null)
            return flMortarStrikeDamage;
            
        float scaledDamage = flMortarStrikeDamage * (1.0f + (m_pStats.GetLevel() * MORTAR_DAMAGE_SCALE));
        return scaledDamage;
    }

    private void CreateAfterEffect(Vector position)
    {
        // Create smoke and scorch marks.
        NetworkMessage decalMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            decalMsg.WriteByte(TE_WORLDDECAL);
            decalMsg.WriteCoord(position.x);
            decalMsg.WriteCoord(position.y);
            decalMsg.WriteCoord(position.z);
            decalMsg.WriteByte(g_EngineFuncs.DecalIndex("{scorch1"));
        decalMsg.End();
        
        NetworkMessage smokeMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            smokeMsg.WriteByte(TE_SMOKE);
            smokeMsg.WriteCoord(position.x);
            smokeMsg.WriteCoord(position.y);
            smokeMsg.WriteCoord(position.z);
            smokeMsg.WriteShort(g_EngineFuncs.ModelIndex(strMortarStrikeSmokeSprite));
            smokeMsg.WriteByte(100);
            smokeMsg.WriteByte(10);
        smokeMsg.End();
    }
}