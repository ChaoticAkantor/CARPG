string strMortarStrikeSetSound = "weapons/mine_deploy.wav";
string strMortarStrikeChargeSound = "weapons/mine_charge.wav";
string strMortarStrikeLaunchSound = "weapons/mortar.wav";
string strMortarStrikeAirSound = "weapons/mortar.wav";
string strMortarStrikeImpactSound = "weapons/mortarhit.wav";
string strMortarStrikeTargetSprite = "sprites/laserbeam.spr";
string strMortarStrikeImpactSprite = "sprites/zerogxplode.spr";
string strMortarStrikeSmokeSprite = "sprites/steam1.spr";
string strMortarStrikeGlowSprite = "sprites/glow01.spr";

dictionary g_PlayerMortarStrikes;

class MortarStrikeData
{   
    private float m_flMortarStrikeDelay = 3.0f;
    private float m_flMortarStrikeEnergyCost = 100.0f;
    private float m_flMortarStrikeRange = 1024.0f;
    private float m_flMortarStrikeBaseDamage = 25.0f; // Base damage of each explosion.
    private float m_flMortarStrikeDamageScale = 0.1f; // % Damage increase per level.
    private float m_flMortarStrikeDamageRadius = 512.0f; // Damage radius of each explosion.
    int m_iMortarStrikeBaseExplosions = 3; // Base number of clusters.
    int m_iMortarStrikeExplosionsScaling = 2; // Extra clusters per 2 levels.
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
        
        if(current < m_flMortarStrikeEnergyCost)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Mortar Strike recharging...\n");
            return;
        }
        
        // Get player's view target
        TraceResult tr;
        Vector vecSrc = pPlayer.EyePosition();
        Math.MakeVectors(pPlayer.pev.v_angle);
        Vector vecEnd = vecSrc + g_Engine.v_forward * m_flMortarStrikeRange;
        
        g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr);
        
        // Only allow targeting on the floor
        if(tr.pHit !is null && tr.flFraction < 1.0 && tr.vecPlaneNormal.z >= 0.7)
        {
            // Take energy using resource system
            current -= m_flMortarStrikeEnergyCost;
            resources['current'] = current;
            
            // Start cooldown
            m_flLastUseTime = g_Engine.time;
            
            // Create target marker and effects
            CreateTargetMarker(tr.vecEndPos);

            // Play mortar set and charge sound.
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_ITEM, strMortarStrikeSetSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
            g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_ITEM, strMortarStrikeChargeSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
        
            // Schedule explosion - using method reference from within class
            g_Scheduler.SetTimeout(this, "MortarImpact", m_flMortarStrikeDelay, tr.vecEndPos, @pPlayer);
            
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
            targetMsg.WriteByte(int(m_flMortarStrikeDelay * 5.0));
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
        g_WeaponFuncs.RadiusDamage(position, pAttacker.pev, pAttacker.pev, scaledDamage, m_flMortarStrikeDamageRadius, CLASS_PLAYER, DMG_BLAST);
        
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
            return m_iMortarStrikeBaseExplosions;
            
        return m_iMortarStrikeBaseExplosions + (m_pStats.GetLevel() / 2 * m_iMortarStrikeExplosionsScaling);
    }

    private void CreateDelayedExplosion(Vector position, CBasePlayer@ pAttacker, float damage)
    {  
        CreateExplosionEffect(position);
        g_WeaponFuncs.RadiusDamage(position, pAttacker.pev, pAttacker.pev, damage, m_flMortarStrikeDamageRadius, CLASS_PLAYER, DMG_BLAST);
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
            return m_flMortarStrikeBaseDamage;
            
        float scaledDamage = m_flMortarStrikeBaseDamage * (1.0f + (m_pStats.GetLevel() * m_flMortarDamageScale));
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