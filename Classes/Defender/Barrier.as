string strBarrierToggleSound = "debris/glass2.wav";
string strBarrierHitSound = "debris/glass1.wav";
string strBarrierBreakSound = "debris/bustglass2.wav";
string strBarrierActiveSound = "ambience/alien_powernode.wav";

string strBarrierReflectDamageSprite = "sprites/snow.spr";

const Vector BARRIER_COLOR = Vector(130, 200, 255); // R G B.
const float BARRIER_PROTECTION_RANGE = 2400.0f; // Range in units for the barrier protection to work.

dictionary g_PlayerBarriers; // Dictionary to store player Barrier data.

class BarrierData
{
    private ClassStats@ m_pStats = null;
    private bool m_bActive = false;
    private float m_flBarrierDamageReduction = 1.00f; // Base damage reduction, anything lower will not block all damage to HP/AP.
    private float m_flToggleCooldown = 0.5f; // Cooldown between toggles.
    private float m_flBarrierDurabilityMultiplier = 1.0f; // % of total incoming damage dealt to shield, used to make shield tougher or weaker overall.
    private float m_flBarrierReflectDamageScalingAtMaxLevel = 1.5f; // Damage damage reflection at max level.
    private float m_flBarrierReflectFreeze = 0.99f; // Reduction of animation speed for enemies frozen by damage reflection.
    private float m_flBarrierReflectBaseFreezeDuration = 2.0f; // Freeze effect base duration (in seconds).
    private float m_flBarrierReflectFreezeDurationAtMaxLevel = 8.00f; // Freeze effect added duration at max level (in seconds).
    private float m_flBarrierActiveRechargePenalty = 0.20f; // Ability recharge rate when barrier is active.
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flGlowUpdateInterval = 0.1f;

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }

    ClassStats@ GetStats() {return m_pStats;}
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }
    
    float GetBaseDamageReduction() { return m_flBarrierDamageReduction; }
    float GetBarrierDurabilityMultiplier() { return m_flBarrierDurabilityMultiplier; }
    
    float GetScaledDamageReflection()
    {
        if(m_pStats is null)
            return 0.0f; // Return base if no stats.
        
        // Scale damage reflected based on level.
        int level = m_pStats.GetLevel();
        float scalingPerLevel = m_flBarrierReflectDamageScalingAtMaxLevel / g_iMaxLevel;
        return scalingPerLevel * level;
    }

    float GetBarrierReflectFreeze() { return 1.0f - m_flBarrierReflectFreeze; } // Freeze animation speed reduction.
    float GetBarrierReflectFreezeInverse() { return m_flBarrierReflectFreeze * 100.0f;} // For stat display, to show inverse value.

    float GetBarrierReflectFreezeDuration() // Total duration to freeze enemies for.
    { 
        if(m_pStats is null)
            return m_flBarrierReflectFreezeDurationAtMaxLevel; // Return base if no stats.

            int level = m_pStats.GetLevel();
            float freezeDurationPerLevel = m_flBarrierReflectFreezeDurationAtMaxLevel / g_iMaxLevel;
            float barrierFreeze = 0.0f;
            barrierFreeze = m_flBarrierReflectBaseFreezeDuration + (freezeDurationPerLevel * level);
        
        return barrierFreeze; 
    }

    float GetActiveRechargePenalty() { return m_flBarrierActiveRechargePenalty; } // Ability recharge penalty when active.

    void HandleBarrier(CBasePlayer@ pPlayer, CBaseEntity@ attacker, float incomingDamage, float& out modifiedDamage)
    {
        if(pPlayer is null || attacker is null)
            return;
            
        // Calculate damage reduction.
        float reduction = GetDamageReduction();
        float blockedDamage = incomingDamage * reduction;
        modifiedDamage = incomingDamage - blockedDamage;
        
        // Don't apply damage reflection if the attacker is the player themselves.
        // or another player protected by this barrier.
        bool skipReflection = false;
        
        // Check if attacker is the barrier owner (self-damage).
        if(attacker is pPlayer)
        {
            skipReflection = true;
        }
        
        // Only apply damage reflection if it's not self.
        if(!skipReflection)
        {
            // Apply damage reflection as a specific damage type and proc the debuff.
            float reflectDamage = incomingDamage * GetScaledDamageReflection();
            attacker.TakeDamage(pPlayer.pev, pPlayer.pev, reflectDamage, DMG_FREEZE); // Apply the damage with the player as the attacker.

            // Alter framerate for a Freeze effect on the enemy that is hit.
            CBaseMonster@ FreezeTarget = cast<CBaseMonster@>(attacker);
            if(FreezeTarget !is null)
            {
                if (FreezeTarget.pev.framerate >= 1.0f) // Only apply if not already frozen.
                {
                    FreezeTarget.pev.framerate = GetBarrierReflectFreeze(); // Apply freeze effect by reducing animation speed.
                    g_Scheduler.SetTimeout("RemoveFreezeEffect", GetBarrierReflectFreezeDuration(), attacker.entindex());
                }
            }
        }

        // Play barrier damage chunks effect on player.
        EffectBarrierDamage(pPlayer.pev.origin, pPlayer);
        
        // Drain barrier health (energy).
        DrainEnergy(pPlayer, blockedDamage);
    }

    void ToggleBarrier(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Barrier on cooldown!\n");
            return;
        }

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(g_PlayerClassResources.exists(steamID))
        {
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            if(resources !is null)
            {

                if(!m_bActive)
                {
                    // Check energy - require FULL energy to activate,
                    float currentEnergy = float(resources['current']);
                    float maxEnergy = float(resources['max']);
                    
                    if(currentEnergy < maxEnergy)
                    {
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield recharging...\n");
                        return;
                    }

                    // Activate.
                    m_bActive = true;
                    m_flLastDrainTime = currentTime;
                    ToggleGlow(pPlayer);
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierToggleSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.5f, ATTN_NORM, SND_FORCE_LOOP, 100);
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Activated!\n");
                }
                else // MANUAL DEACTIVATION.
                {
                    // Deactivate Manually.
                    m_bActive = false;
                    ToggleGlow(pPlayer);
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierBreakSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.0f, ATTN_NORM, SND_STOP, 100);
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Shattered!\n"); // MANUALLY SHATTERED.
                    EffectBarrierShatter(pPlayer.pev.origin);
                }
            }
        }

        m_flLastToggleTime = 0.0f;
    }

    float GetDamageReduction()
    {
        if(m_pStats is null)
            return 0.0f;
            
        return m_flBarrierDamageReduction; // Now always 100% damage reduction to player.
    }

    void Update(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        ToggleGlow(pPlayer); // Handle glow state.

        if(!pPlayer.IsAlive()) // Deactivate if player dies.
        {
            DeactivateBarrier(pPlayer);
            ToggleGlow(pPlayer);
            return;
        }
    }
    
    void DrainEnergy(CBasePlayer@ pPlayer, float blockedDamage)
    {
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;

        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        float current = float(resources['current']);
        
        // Drain energy proportional to damage blocked.
        float energyCost = (blockedDamage * m_flBarrierDurabilityMultiplier); // Damage taken to energy drain scale factor.
        current -= energyCost;
        
        if(current <= 0)
        {
            current = 0;
            DeactivateBarrier(pPlayer);
        }
        
        resources['current'] = current;
    }

    void DeactivateBarrier(CBasePlayer@ pPlayer) // Called when DESTROYED, NOT MANUALLY DEACTIVATED.
    {
        if(pPlayer is null)
            return;

        if(m_bActive)
        {
            m_bActive = false;
            ToggleGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierBreakSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.0f, ATTN_NORM, SND_STOP, 100); // Stop looping sound here too.
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Shattered!\n"); // SHATTERED - DESTROYED.
            EffectBarrierShatter(pPlayer.pev.origin);
        }
    }


    private void ToggleGlow(CBasePlayer@ pPlayer)
    {
        // Apply glow shell to player based on if ability is active or not.
        if(pPlayer is null)
            return;

        if(m_bActive)
        {
            // Apply glow shell if ability is active.
            pPlayer.pev.renderfx = kRenderFxGlowShell;
            pPlayer.pev.rendermode = kRenderNormal;
            pPlayer.pev.rendercolor = BARRIER_COLOR;
            pPlayer.pev.renderamt = 5; // Thickness.
        }
        else
        {
            // Remove glow shell if ability is inactive.
            pPlayer.pev.renderfx = kRenderFxNone;
            pPlayer.pev.rendermode = kRenderNormal;
            pPlayer.pev.renderamt = 255;
            pPlayer.pev.rendercolor = Vector(255, 255, 255);
        }
    }

    private void EffectBarrierShatter(Vector origin)
    {
        // Add effect to shatter barrier.
        NetworkMessage breakMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, origin);
            breakMsg.WriteByte(TE_BREAKMODEL);
            breakMsg.WriteCoord(origin.x);
            breakMsg.WriteCoord(origin.y);
            breakMsg.WriteCoord(origin.z);
            breakMsg.WriteCoord(5); // Size.
            breakMsg.WriteCoord(5); // Size.
            breakMsg.WriteCoord(5); // Size.
            breakMsg.WriteCoord(0); // Gib vel pos Forward/Back.
            breakMsg.WriteCoord(0); // Gib vel pos Left/Right.
            breakMsg.WriteCoord(5); // Gib vel pos Up/Down.
            breakMsg.WriteByte(25); // Gib random speed and direction.
            breakMsg.WriteShort(g_EngineFuncs.ModelIndex(strRobogruntModelChromegibs));
            breakMsg.WriteByte(15); // Count.
            breakMsg.WriteByte(10); // Lifetime.
            breakMsg.WriteByte(1); // Sound Flags.
            breakMsg.End();
    }

    void EffectBarrierDamage(Vector origin, CBaseEntity@ entity)
    {
        if(entity is null)
            return;

        // Add effect to chip off chunks as barrier takes damage.
        NetworkMessage breakMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            breakMsg.WriteByte(TE_BREAKMODEL);
            breakMsg.WriteCoord(origin.x);
            breakMsg.WriteCoord(origin.y);
            breakMsg.WriteCoord(origin.z);
            breakMsg.WriteCoord(3); // Size.
            breakMsg.WriteCoord(3); // Size.
            breakMsg.WriteCoord(3); // Size.
            breakMsg.WriteCoord(0); // Gib vel pos Forward/Back.
            breakMsg.WriteCoord(0); // Gib vel pos Left/Right.
            breakMsg.WriteCoord(5); // Gib vel pos Up/Down.
            breakMsg.WriteByte(20); // Gib random speed and direction.
            breakMsg.WriteShort(g_EngineFuncs.ModelIndex(strRobogruntModelChromegibs));
            breakMsg.WriteByte(2); // Count.
            breakMsg.WriteByte(10); // Lifetime.
            breakMsg.WriteByte(1); // Sound Flags.
            breakMsg.End();

        // Play hit sound with random pitch.
        int randomPitch = int(Math.RandomFloat(80.0f, 120.0f));

        // Play sound at the entity's position.
        g_SoundSystem.PlaySound(entity.edict(), CHAN_ITEM, strBarrierHitSound, 1.0f, 0.8f, 0, randomPitch);
    }

    void ApplyReflectDamage(Vector origin, CBaseEntity@ target)
    {
        if(target is null)
            return;

            // Add glow shell effect to entity taking damage.
            target.pev.renderfx = kRenderFxGlowShell;
            target.pev.rendermode = kRenderNormal;
            target.pev.rendercolor = BARRIER_COLOR;
            target.pev.renderamt = 10; // Thickness.

        // Also add dynamic light effect to entity.
        NetworkMessage glowreflectMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            glowreflectMsg.WriteByte(TE_DLIGHT);
            glowreflectMsg.WriteCoord(origin.x);
            glowreflectMsg.WriteCoord(origin.y);
            glowreflectMsg.WriteCoord(origin.z);
            glowreflectMsg.WriteByte(16); // Radius in 0.1 units.
            glowreflectMsg.WriteByte(uint8(BARRIER_COLOR.x)); // Red.
            glowreflectMsg.WriteByte(uint8(BARRIER_COLOR.y)); // Green.
            glowreflectMsg.WriteByte(uint8(BARRIER_COLOR.z)); // Blue.
            glowreflectMsg.WriteByte(3); // Life in 0.1s.
            glowreflectMsg.WriteByte(2); // Fade speed.
            glowreflectMsg.End();

        // Offsets for sprite trail.
        Vector originOffset = target.pev.origin;
        originOffset.z += 32; // Offset to top of entity.

        Vector endPoint = originOffset;
        endPoint.z += 10; // Trail moves upward.

        // Create sprite trail effect for snow/ice particles.
        NetworkMessage snowmsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
            snowmsg.WriteByte(TE_SPRITETRAIL);
            snowmsg.WriteCoord(origin.x);
            snowmsg.WriteCoord(origin.y);
            snowmsg.WriteCoord(origin.z);
            snowmsg.WriteCoord(endPoint.x);
            snowmsg.WriteCoord(endPoint.y);
            snowmsg.WriteCoord(endPoint.z);
            snowmsg.WriteShort(g_EngineFuncs.ModelIndex(strBarrierReflectDamageSprite));
            snowmsg.WriteByte(3);   // Count.
            snowmsg.WriteByte(1);   // Life in 0.1's.
            snowmsg.WriteByte(3);   // Scale in 0.1's.
            snowmsg.WriteByte(25);  // Velocity along vector in 10's.
            snowmsg.WriteByte(15);  // Random velocity in 10's.
            snowmsg.End();
    }
}

void RemoveFreezeEffect(int attackerIndex)
{
    CBaseEntity@ attacker = g_EntityFuncs.Instance(attackerIndex);
    if(attacker is null)
        return;

    CBaseMonster@ FreezeTarget = cast<CBaseMonster@>(attacker);
    if(FreezeTarget !is null)
    {
        FreezeTarget.pev.framerate = 1.0f; // Reset animation speed to normal.
            
        // Remove the glow shell effect.
        FreezeTarget.pev.renderfx = kRenderFxNone;
        FreezeTarget.pev.rendermode = kRenderNormal;
        FreezeTarget.pev.renderamt = 0;
    }   
}