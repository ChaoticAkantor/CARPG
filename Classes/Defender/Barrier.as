string strBarrierToggleSound = "debris/glass2.wav";
string strBarrierHitSound = "debris/glass1.wav";
string strBarrierBreakSound = "debris/bustglass2.wav";
string strBarrierActiveSound = "ambience/alien_powernode.wav";

string strBarrierBeamSprite = "sprites/zbeam4.spr";

const Vector BARRIER_COLOR = Vector(130, 200, 255); // R G B.
const float BARRIER_PROTECTION_RANGE = 2400.0f; // Range in units for the barrier protection to work.

dictionary g_PlayerBarriers; // Dictionary to store player Barrier data.
dictionary g_ProtectedPlayers; // Dictionary to track which players are currently protected by barriers and by who.

class BarrierData
{
    private ClassStats@ m_pStats = null;
    private bool m_bActive = false;
    private float m_flBarrierDamageReduction = 1.00f; // Base damage reduction.
    private float m_flToggleCooldown = 0.5f; // 1 second cooldown between toggles.
    private float m_flBarrierDurabilityMultiplier = 1.0f; // % of total damage dealt to shield, lower = tougher.
    private float m_flLastDrainTime = 0.0f;
    private float m_flBarrierReflectDamageMultiplier = 0.5f; // Base damage reflect multiplier, how much of the damage is reflected back to attacker.
    private float m_flBarrierReflectDamageScaling = 0.04f; // How much % to scale damage reflection per level.
    private float m_flLastToggleTime = 0.0f;
    private float m_flGlowUpdateInterval = 0.1f;
    private float m_flLastProtectionUpdateTime = 0.0f;
    private float m_flProtectionUpdateInterval = 0.5f; // How often to update which players are protected.

    private float m_flRefundAmount = 0.0f;
    private float m_flRefundTimeLeft = 0.0f;
    private float m_flStoredEnergy = 0.0f;
    private float m_flRefundTime = 5.0f; // Time to refund energy, total / this.
    private float m_flRefundInterval = 1.0f; // Intervals to give refunded energy.
    private float m_flLastRefundStartTime = 0.0f; // Track when the last refund started.

    private array<string> m_ProtectedPlayers; // Array of steamIDs for players this barrier is protecting.

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }
    ClassStats@ GetStats() {return m_pStats;}
    float GetBaseDamageReduction() { return m_flBarrierDamageReduction; }
    float GetBarrierDurabilityMultiplier() { return m_flBarrierDurabilityMultiplier; }
    
    // Check if the barrier can protect teammates.
    bool CanProtectTeammates() 
    { 
        return HasStats() && m_pStats.HasUnlockedPerk1();
    }
    
    // Get all players currently protected by this barrier.
    array<string>@ GetProtectedPlayers() { return m_ProtectedPlayers; }
    
    // Check if this barrier is protecting a specific player.
    bool IsProtectingPlayer(string steamID)
    {
        if (!m_bActive || !CanProtectTeammates())
            return false;
            
        return m_ProtectedPlayers.find(steamID) >= 0;
    }

    float GetScaledDamageReflection()
    {
        if(m_pStats is null)
            return m_flBarrierReflectDamageMultiplier; // Return base if no stats.
        
        // Scale reflect damage based on level.
        return m_flBarrierReflectDamageMultiplier * (1.0f + (m_pStats.GetLevel() * m_flBarrierReflectDamageScaling));
    }
    
    void HandleBarrier(CBasePlayer@ pPlayer, CBaseEntity@ attacker, float incomingDamage, float& out modifiedDamage)
    {
        if(pPlayer is null || attacker is null)
            return;
            
        // Calculate damage reduction.
        float reduction = GetDamageReduction();
        float blockedDamage = incomingDamage * reduction;
        modifiedDamage = incomingDamage - blockedDamage;
        
        // Don't apply damage reflection if the attacker is the player themselves
        // or another player protected by this barrier
        bool skipReflection = false;
        
        // Check if attacker is the barrier owner (self-damage)
        if(attacker is pPlayer)
        {
            skipReflection = true;
        }
        else 
        {
            // Check if attacker is another player protected by this barrier
            CBasePlayer@ attackerPlayer = cast<CBasePlayer@>(attacker);
            if(attackerPlayer !is null)
            {
                string attackerSteamID = g_EngineFuncs.GetPlayerAuthId(attackerPlayer.edict());
                
                if(g_ProtectedPlayers.exists(attackerSteamID))
                {
                    string barrierOwnerSteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
                    string protectorSteamID = string(g_ProtectedPlayers[attackerSteamID]);
                    
                    if(protectorSteamID == barrierOwnerSteamID)
                    {
                        // Attacker is protected by this player's barrier
                        skipReflection = true;
                    }
                }
            }
        }
        
        // Only apply damage reflection if it's not self or protected player
        if(!skipReflection)
        {
            // Apply damage reflection as a specific damage type.
            float reflectDamage = incomingDamage * GetScaledDamageReflection();
            attacker.TakeDamage(pPlayer.pev, pPlayer.pev, reflectDamage, DMG_TIMEBASED); // Apply the damage with the player as the attacker.
        }
        
        // Play hit sound with random pitch.
        int randomPitch = int(Math.RandomFloat(80.0f, 120.0f));
        g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_ITEM, strBarrierHitSound, 1.0f, 0.8f, 0, randomPitch);
        
        // Visual effects.
        Vector origin = pPlayer.pev.origin; // Player as origin.
        
        // Create ricochet effect.
        NetworkMessage ricMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
        ricMsg.WriteByte(TE_ARMOR_RICOCHET);
        ricMsg.WriteCoord(origin.x);
        ricMsg.WriteCoord(origin.y);
        ricMsg.WriteCoord(origin.z);
        ricMsg.WriteByte(1); // Scale.
        ricMsg.End();
        
        // Add effect to chip off chunks as barrier takes damage.
        NetworkMessage breakMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, origin);
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
        
        // Drain barrier health (energy).
        DrainEnergy(pPlayer, blockedDamage);
    }
    
    // Handle protection for a player being protected by someone else's barrier.
    void HandleProtectedDamage(CBasePlayer@ protectedPlayer, CBasePlayer@ barrierOwner, CBaseEntity@ attacker, float incomingDamage, float& out modifiedDamage)
    {
        if(protectedPlayer is null || barrierOwner is null || attacker is null)
            return;
            
        // Calculate damage reduction (same as direct barrier).
        float reduction = GetDamageReduction();
        float blockedDamage = incomingDamage * reduction;
        modifiedDamage = incomingDamage - blockedDamage;
        
        // Check if the attacker is the barrier owner or another protected player before applying reflection
        string attackerSteamID = "";
        CBasePlayer@ attackerPlayer = cast<CBasePlayer@>(attacker);
        
        if(attackerPlayer !is null)
        {
            attackerSteamID = g_EngineFuncs.GetPlayerAuthId(attackerPlayer.edict());
            
            // Don't reflect damage if the attacker is the barrier owner.
            if(attackerSteamID == g_EngineFuncs.GetPlayerAuthId(barrierOwner.edict()))
            {
                // Still play visual/sound effects to show barrier is working.
                int randomPitch = int(Math.RandomFloat(80.0f, 120.0f));
                g_SoundSystem.PlaySound(protectedPlayer.edict(), CHAN_ITEM, strBarrierHitSound, 1.0f, 0.8f, 0, randomPitch);
                
                // Drain energy from the barrier owner (still costs energy to block friendly fire).
                DrainEnergy(barrierOwner, blockedDamage * 0.5); // Reduce energy cost for friendly fire.
                
                // Create ricochet effect
                Vector origin = protectedPlayer.pev.origin;
                NetworkMessage ricMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
                ricMsg.WriteByte(TE_ARMOR_RICOCHET);
                ricMsg.WriteCoord(origin.x);
                ricMsg.WriteCoord(origin.y);
                ricMsg.WriteCoord(origin.z);
                ricMsg.WriteByte(1); // Scale.
                ricMsg.End();
                
                return; // Skip reflection.
            }
            
            // Check if attacker is also protected by this barrier.
            if(g_ProtectedPlayers.exists(attackerSteamID))
            {
                string protectorSteamID = string(g_ProtectedPlayers[attackerSteamID]);
                if(protectorSteamID == g_EngineFuncs.GetPlayerAuthId(barrierOwner.edict()))
                {
                    // Attacker is also protected by the same barrier, don't reflect damage.
                    // Still play effects.
                    int randomPitch = int(Math.RandomFloat(80.0f, 120.0f));
                    g_SoundSystem.PlaySound(protectedPlayer.edict(), CHAN_ITEM, strBarrierHitSound, 1.0f, 0.8f, 0, randomPitch);
                    
                    // Still drain energy.
                    DrainEnergy(barrierOwner, blockedDamage * 0.5);
                    
                    // Create ricochet effect.
                    Vector origin = protectedPlayer.pev.origin;
                    NetworkMessage ricMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
                    ricMsg.WriteByte(TE_ARMOR_RICOCHET);
                    ricMsg.WriteCoord(origin.x);
                    ricMsg.WriteCoord(origin.y);
                    ricMsg.WriteCoord(origin.z);
                    ricMsg.WriteByte(1); // Scale.
                    ricMsg.End();
                    
                    return; // Skip reflection.
                }
            }
        }

        // Apply damage reflection for non-friendly attackers.
        float reflectDamage = incomingDamage * GetScaledDamageReflection();
        attacker.TakeDamage(protectedPlayer.pev, barrierOwner.pev, reflectDamage, DMG_SLOWFREEZE);
        
        // Play hit sound with random pitch.
        int randomPitch = int(Math.RandomFloat(80.0f, 120.0f));
        g_SoundSystem.PlaySound(protectedPlayer.edict(), CHAN_ITEM, strBarrierHitSound, 1.0f, 0.8f, 0, randomPitch);
        
        // Origin for visual effects, direct towards protected, not barrier owner.
        Vector origin = protectedPlayer.pev.origin;
        
        // Create ricochet effect.
        NetworkMessage ricMsg(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, origin);
        ricMsg.WriteByte(TE_ARMOR_RICOCHET);
        ricMsg.WriteCoord(origin.x);
        ricMsg.WriteCoord(origin.y);
        ricMsg.WriteCoord(origin.z);
        ricMsg.WriteByte(1); // Scale.
        ricMsg.End();
        
        /* - Disabled this for now, not quite sure if it fits.
        // Draw a beam effect connecting the protected player to the barrier owner.
        NetworkMessage beamMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
        beamMsg.WriteByte(TE_BEAMENTPOINT);
        beamMsg.WriteShort(barrierOwner.entindex());
        beamMsg.WriteCoord(protectedPlayer.pev.origin.x);
        beamMsg.WriteCoord(protectedPlayer.pev.origin.y);
        beamMsg.WriteCoord(protectedPlayer.pev.origin.z + 16);
        beamMsg.WriteShort(g_EngineFuncs.ModelIndex(strBarrierBeamSprite));
        beamMsg.WriteByte(0); // framestart.
        beamMsg.WriteByte(0); // framerate.
        beamMsg.WriteByte(2); // life.
        beamMsg.WriteByte(5); // width.
        beamMsg.WriteByte(0); // noise.
        beamMsg.WriteByte(int(BARRIER_COLOR.x)); // r.
        beamMsg.WriteByte(int(BARRIER_COLOR.y)); // g.
        beamMsg.WriteByte(int(BARRIER_COLOR.z)); // b.
        beamMsg.WriteByte(128); // brightness.
        beamMsg.WriteByte(0); // speed.
        beamMsg.End();
        */

        // Add effect to chip off chunks as barrier takes damage for protected player.
        NetworkMessage protectedbreakMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, origin);
        protectedbreakMsg.WriteByte(TE_BREAKMODEL);
        protectedbreakMsg.WriteCoord(origin.x);
        protectedbreakMsg.WriteCoord(origin.y);
        protectedbreakMsg.WriteCoord(origin.z);
        protectedbreakMsg.WriteCoord(3); // Size.
        protectedbreakMsg.WriteCoord(3); // Size.
        protectedbreakMsg.WriteCoord(3); // Size.
        protectedbreakMsg.WriteCoord(0); // Gib vel pos Forward/Back.
        protectedbreakMsg.WriteCoord(0); // Gib vel pos Left/Right.
        protectedbreakMsg.WriteCoord(5); // Gib vel pos Up/Down.
        protectedbreakMsg.WriteByte(20); // Gib random speed and direction.
        protectedbreakMsg.WriteShort(g_EngineFuncs.ModelIndex(strRobogruntModelChromegibs));
        protectedbreakMsg.WriteByte(2); // Count.
        protectedbreakMsg.WriteByte(10); // Lifetime.
        protectedbreakMsg.WriteByte(1); // Sound Flags.
        protectedbreakMsg.End();
        
        // Drain energy from the barrier owner.
        DrainEnergy(barrierOwner, blockedDamage);
    }

    void Initialize(ClassStats@ stats)
    {
        @m_pStats = stats;
    }

    void ToggleBarrier(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
        {
            return;
        }

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Barrier on cooldown!\n");
            return;
        }

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
        {
            return;
        }
            
        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        if(resources is null)
        {
            return;
        }

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
            
            // Check if this player was being protected by someone else's barrier,
            // and remove that protection since they're activating their own,
            string playerSteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            HandlePlayerActivatedOwnBarrier(playerSteamID);

            // Activate.
            m_bActive = true;
            m_flLastDrainTime = currentTime;
            ToggleGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierToggleSound, 1.0f, ATTN_NORM, SND_FORCE_SINGLE, 0, PITCH_NORM);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.5f, ATTN_NORM, SND_FORCE_LOOP, 100);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Activated!\n");
        }
        else // MANUAL DEACTIVATION.
        {
            StartResourceRefund(pPlayer); // Start refund.

            // Deactivate Manually.
            m_bActive = false;
            ToggleGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.0f, ATTN_NORM, SND_STOP, 100);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierBreakSound, 1.0f, ATTN_NORM, SND_FORCE_SINGLE, 0, PITCH_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Refunded!\n"); // MANUALLY SHATTERED.
            EffectBarrierShatter(pPlayer.pev.origin);
            
            // Remove protection from all protected players with visual effects.
            RemoveAllProtections(pPlayer, false); // false means show visual effects.
        }

        m_flLastToggleTime = currentTime;
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

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;
            
        // Update protection list if perk is unlocked.
        float currentTime = g_Engine.time;
        if (CanProtectTeammates() && currentTime - m_flLastProtectionUpdateTime >= m_flProtectionUpdateInterval)
        {
            m_flLastProtectionUpdateTime = currentTime;
            UpdateProtectionList(pPlayer);
        }
    }
    
    // Scan for nearby players to protect
    private void UpdateProtectionList(CBasePlayer@ barrierOwner)
    {
        if (barrierOwner is null || !CanProtectTeammates())
            return;
            
        string ownerSteamID = g_EngineFuncs.GetPlayerAuthId(barrierOwner.edict());
        Vector ownerPos = barrierOwner.pev.origin;
        
        // Make a temporary copy of the protection list to track players who went out of range
        array<string> previouslyProtectedPlayers = m_ProtectedPlayers;
        
        // Clear current protection list
        m_ProtectedPlayers.resize(0);
        
        // Find nearby players to protect
        for (int i = 1; i <= g_Engine.maxClients; i++) 
        {
            CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex(i);
            if (pTarget is null || !pTarget.IsConnected() || !pTarget.IsAlive() || pTarget is barrierOwner)
                continue;
                
            string targetSteamID = g_EngineFuncs.GetPlayerAuthId(pTarget.edict());
            
            // Skip players who already have an active barrier
            if (g_PlayerBarriers.exists(targetSteamID))
            {
                BarrierData@ targetBarrier = cast<BarrierData@>(g_PlayerBarriers[targetSteamID]);
                if (targetBarrier !is null && targetBarrier.IsActive())
                {
                    // If this player was previously protected by us, remove that protection
                    if (previouslyProtectedPlayers.find(targetSteamID) >= 0)
                    {
                        // They activated their own barrier, so remove our protection
                        if (g_ProtectedPlayers.exists(targetSteamID) && 
                            string(g_ProtectedPlayers[targetSteamID]) == ownerSteamID)
                        {
                            g_ProtectedPlayers.delete(targetSteamID);
                        }
                    }
                    continue;
                }
            }
            
            // Skip players who are already being protected by another player's barrier
            if (g_ProtectedPlayers.exists(targetSteamID) && string(g_ProtectedPlayers[targetSteamID]) != ownerSteamID)
                continue;
                
            // Check distance
            float distance = (pTarget.pev.origin - ownerPos).Length();
            if (distance <= BARRIER_PROTECTION_RANGE)
            {
                // Check if this player is newly protected
                bool wasAlreadyProtected = previouslyProtectedPlayers.find(targetSteamID) >= 0;
                
                // Add to protection list
                m_ProtectedPlayers.insertLast(targetSteamID);
                
                // Register this player as being protected
                g_ProtectedPlayers[targetSteamID] = ownerSteamID;
                
                // Only apply visual effect if they weren't already protected by us
                if (!wasAlreadyProtected)
                {
                    // Apply visual effect to show protection
                    ApplyProtectionGlow(pTarget);
                }
                else
                {
                    // If they were already protected, just make sure the glow is still active without playing effects
                    // This ensures the glow is maintained without constantly playing the effect
                    pTarget.pev.renderfx = kRenderFxGlowShell;
                    pTarget.pev.rendermode = kRenderNormal;
                    pTarget.pev.rendercolor = BARRIER_COLOR;
                    pTarget.pev.renderamt = 3; // Thinner glow for protected players
                }
            }
            else if (g_ProtectedPlayers.exists(targetSteamID) && string(g_ProtectedPlayers[targetSteamID]) == ownerSteamID)
            {
                // Player went out of range, remove protection
                g_ProtectedPlayers.delete(targetSteamID);
                RemoveProtectionEffects(pTarget);
            }
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
        if(m_bActive)
        {
            m_bActive = false;
            ToggleGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierActiveSound, 0.0f, ATTN_NORM, SND_STOP, 100); // Stop looping sound here too.
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierBreakSound, 1.0f, ATTN_NORM, SND_FORCE_SINGLE, 0, PITCH_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Ice Shield Shattered!\n"); // SHATTERED - DESTROYED.
            EffectBarrierShatter(pPlayer.pev.origin);
            
            // Remove protection from all protected players with visual effects
            RemoveAllProtections(pPlayer, false); // false means show visual effects
        }
        
        // Cancel any ongoing refunds.
        if(pPlayer !is null)
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            CancelRefunds(steamID);
        }
    }
    
    // Remove all protected players when barrier is deactivated.
    void RemoveAllProtections(CBasePlayer@ barrierOwner, bool useQuiet = true)
    {
        if (!CanProtectTeammates() || m_ProtectedPlayers.length() == 0)
            return;
            
        for (uint i = 0; i < m_ProtectedPlayers.length(); i++)
        {
            string targetSteamID = m_ProtectedPlayers[i];
            
            // Remove this player from the protection registry
            if (g_ProtectedPlayers.exists(targetSteamID))
                g_ProtectedPlayers.delete(targetSteamID);
                
            // Remove visual effect with break animation.
            for (int j = 1; j <= g_Engine.maxClients; j++)
            {
                CBasePlayer@ pTarget = g_PlayerFuncs.FindPlayerByIndex(j);
                if (pTarget !is null && g_EngineFuncs.GetPlayerAuthId(pTarget.edict()) == targetSteamID)
                {
                    if (useQuiet)
                        RemoveProtectionEffectsQuiet(pTarget);
                    else
                        RemoveProtectionEffects(pTarget);
                    break;
                }
            }
        }
        
        // Clear protection list
        m_ProtectedPlayers.resize(0);
    }
    
    // Apply barrier glow effect to protected players
    private void ApplyProtectionGlow(CBasePlayer@ pPlayer)
    {
        if (pPlayer is null)
            return;
            
        // Apply a less intense glow than the main barrier
        pPlayer.pev.renderfx = kRenderFxGlowShell;
        pPlayer.pev.rendermode = kRenderNormal;
        pPlayer.pev.rendercolor = BARRIER_COLOR;
        pPlayer.pev.renderamt = 3; // Thinner glow for protected players
        
        // Add visual effect to show protection being applied
        EffectProtectionApply(pPlayer.pev.origin);
        
        // Play barrier sound with lower volume
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBarrierToggleSound, 0.7f, ATTN_NORM, 0, PITCH_NORM);
        
        // Show protection message to player
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Protected by teammate's Ice Shield!\n");
    }
    
    // Effect for when protection is applied
    private void EffectProtectionApply(Vector origin)
    {
        // Create smaller version of barrier toggle effect
        NetworkMessage breakMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, origin);
            breakMsg.WriteByte(TE_BREAKMODEL);
            breakMsg.WriteCoord(origin.x);
            breakMsg.WriteCoord(origin.y);
            breakMsg.WriteCoord(origin.z);
            breakMsg.WriteCoord(3); // Size
            breakMsg.WriteCoord(3); // Size
            breakMsg.WriteCoord(3); // Size
            breakMsg.WriteCoord(0); // Gib vel pos Forward/Back
            breakMsg.WriteCoord(0); // Gib vel pos Left/Right
            breakMsg.WriteCoord(0); // Gib vel pos Up/Down
            breakMsg.WriteByte(10); // Gib random speed and direction
            breakMsg.WriteShort(g_EngineFuncs.ModelIndex(strRobogruntModelChromegibs));
            breakMsg.WriteByte(5); // Count - fewer particles
            breakMsg.WriteByte(10); // Lifetime
            breakMsg.WriteByte(1); // Sound Flags
            breakMsg.End();
    }
    
    // Remove barrier effects from protected player with shield breaking effect.
    private void RemoveProtectionEffects(CBasePlayer@ pPlayer)
    {
        if (pPlayer is null)
            return;
            
        // Reset rendering.
        pPlayer.pev.renderfx = kRenderFxNone;
        pPlayer.pev.rendermode = kRenderNormal;
        pPlayer.pev.renderamt = 255;
        pPlayer.pev.rendercolor = Vector(255, 255, 255);
        
        // Apply barrier break visual effect.
        EffectBarrierShatter(pPlayer.pev.origin);
        
        // Play break sound with lower volume for protection.
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierBreakSound, 0.7f, ATTN_NORM, 0, PITCH_NORM);
        
        // Notify player that protection is gone.
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No longer protected by Ice Shield!\n");
    }
    
    // Remove barrier glow effect without barrier break effect (for checks).
    private void RemoveProtectionEffectsQuiet(CBasePlayer@ pPlayer)
    {
        if (pPlayer is null)
            return;
            
        // Reset rendering.
        pPlayer.pev.renderfx = kRenderFxNone;
        pPlayer.pev.rendermode = kRenderNormal;
        pPlayer.pev.renderamt = 255;
        pPlayer.pev.rendercolor = Vector(255, 255, 255);
        
        // Notify player that protection is gone.
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No longer protected by Ice Shield!\n");
    }
    
    // Remove a specific player from protection.
    void RemovePlayerFromProtection(string playerSteamID)
    {
        // Find and remove player from the protection list.
        int index = m_ProtectedPlayers.find(playerSteamID);
        if (index >= 0)
        {
            m_ProtectedPlayers.removeAt(index);
            
            // Find player and remove visual effects.
            for (int i = 1; i <= g_Engine.maxClients; i++)
            {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if (pPlayer !is null && g_EngineFuncs.GetPlayerAuthId(pPlayer.edict()) == playerSteamID)
                {
                    RemoveProtectionEffects(pPlayer);
                    break;
                }
            }
        }
    }
    
    // Handle a player activating their own barrier.
    void HandlePlayerActivatedOwnBarrier(string playerSteamID)
    {
        // If this player is being protected by someone else, remove that protection.
        if (g_ProtectedPlayers.exists(playerSteamID))
        {
            string protectorSteamID = string(g_ProtectedPlayers[playerSteamID]);
            if (g_PlayerBarriers.exists(protectorSteamID))
            {
                BarrierData@ protectorBarrier = cast<BarrierData@>(g_PlayerBarriers[protectorSteamID]);
                if (protectorBarrier !is null)
                {
                    protectorBarrier.RemovePlayerFromProtection(playerSteamID);
                }
            }
            
            // Remove from global protection list.
            g_ProtectedPlayers.delete(playerSteamID);
        }
    }
    
    bool IsRefundValid(float startTime)
    {
        return startTime >= m_flLastRefundStartTime;
    }
    
    void CancelRefunds(string steamID)
    {
        // Update the last refund start time to invalidate any current refunds.
        m_flLastRefundStartTime = g_Engine.time + 0.1f; // Add a small buffer to ensure all new refunds have a newer timestamp.
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

    void StartResourceRefund(CBasePlayer@ pPlayer)
    {
        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;
            
        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        if(resources is null)
            return;
            
        m_flRefundAmount = float(resources['current']); // Store current energy.
        resources['current'] = 0; // Empty energy.
        
        // Update the refund start time.
        m_flLastRefundStartTime = g_Engine.time;
        
        if(m_flRefundAmount > 0)
        {
            float refundPerTick = m_flRefundAmount / m_flRefundTime;
            g_Scheduler.SetInterval("BarrierRefund", m_flRefundInterval, int(m_flRefundTime), steamID, refundPerTick, m_flLastRefundStartTime);
        }
    }
}

void BarrierRefund(string steamID, float refundAmount, float startTime)
{
    // Check if this refund is still valid.
    if(g_PlayerBarriers.exists(steamID))
    {
        BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
        if(barrier !is null && barrier.IsRefundValid(startTime))
        {
            // Check if the player is still playing as Defender.
            if(g_PlayerRPGData.exists(steamID))
            {        
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_DEFENDER)
                {
                    if(g_PlayerClassResources.exists(steamID))
                    {
                        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                        if(resources !is null)
                        {
                            float current = float(resources['current']);
                            float maxEnergy = float(resources['max']);
                            float newAmount = Math.min(current + refundAmount, maxEnergy);
                            resources['current'] = newAmount;
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we get here, the refund should be canceled.
    g_Scheduler.RemoveTimer(g_Scheduler.GetCurrentFunction());
}

// Remove barrier glow effect from protected player without visual effects (used for checks).
void RemoveProtectionEffectsQuiet(CBasePlayer@ pPlayer)
{
    if (pPlayer is null)
        return;
        
    // Reset rendering.
    pPlayer.pev.renderfx = kRenderFxNone;
    pPlayer.pev.rendermode = kRenderNormal;
    pPlayer.pev.renderamt = 255;
    pPlayer.pev.rendercolor = Vector(255, 255, 255);
    
    // Notify player that protection is gone.
    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No longer protected by Ice Shield!\n");
}

// Check if a player is being protected by another player's barrier
bool IsPlayerProtectedByBarrier(CBasePlayer@ pPlayer, CBaseEntity@ attacker)
{
    if(pPlayer is null)
        return false;
        
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    
    // If player has an active barrier, they can't be protected by others.
    if(g_PlayerBarriers.exists(steamID))
    {
        BarrierData@ ownBarrier = cast<BarrierData@>(g_PlayerBarriers[steamID]);
        if(ownBarrier !is null && ownBarrier.IsActive())
            return false;
    }
    
    // Check if player is being protected.
    if(g_ProtectedPlayers.exists(steamID))
    {
        string protectorSteamID = string(g_ProtectedPlayers[steamID]);
        
        // Verify the protector still has an active barrier.
        if(g_PlayerBarriers.exists(protectorSteamID))
        {
            BarrierData@ protectorBarrier = cast<BarrierData@>(g_PlayerBarriers[protectorSteamID]);
            if(protectorBarrier !is null && protectorBarrier.IsActive() && protectorBarrier.CanProtectTeammates())
                return true;
        }
        
        // If we reached here, the protection is no longer valid, so remove it.
        g_ProtectedPlayers.delete(steamID);
        
        // Find player and remove visual effects without showing break effect.
        for(int i = 1; i <= g_Engine.maxClients; i++)
        {
            CBasePlayer@ tempPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
            if(tempPlayer !is null && g_EngineFuncs.GetPlayerAuthId(tempPlayer.edict()) == steamID)
            {
                // Use the quiet version that doesn't play visual effects.
                RemoveProtectionEffectsQuiet(tempPlayer);
                break;
            }
        }
    }
    
    return false;
}

// Handle damage for a player protected by someone else's barrier.
void HandleProtectedPlayerDamage(CBasePlayer@ pPlayer, CBaseEntity@ attacker, DamageInfo@ pDamageInfo)
{
    if(pPlayer is null || attacker is null || pDamageInfo is null)
        return;
        
    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(!g_ProtectedPlayers.exists(steamID))
        return;
        
    string protectorSteamID = string(g_ProtectedPlayers[steamID]);
    if(!g_PlayerBarriers.exists(protectorSteamID))
        return;
        
    // Find the protector player.
    CBasePlayer@ protector = null;
    for(int i = 1; i <= g_Engine.maxClients; i++)
    {
        CBasePlayer@ tempPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(tempPlayer !is null && g_EngineFuncs.GetPlayerAuthId(tempPlayer.edict()) == protectorSteamID)
        {
            @protector = tempPlayer;
            break;
        }
    }
    
    if(protector is null)
        return;
        
    BarrierData@ protectorBarrier = cast<BarrierData@>(g_PlayerBarriers[protectorSteamID]);
    if(protectorBarrier !is null && protectorBarrier.IsActive() && protectorBarrier.CanProtectTeammates())
    {
        // Let the barrier handle protection for this player.
        protectorBarrier.HandleProtectedDamage(pPlayer, protector, attacker, pDamageInfo.flDamage, pDamageInfo.flDamage);
    }
}

// Utility function to remove protection effects from a player by steamID.
void RemoveProtectionFromPlayer(string playerSteamID)
{
    // Find the player and remove the visual effects.
    for(int i = 1; i <= g_Engine.maxClients; i++)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && g_EngineFuncs.GetPlayerAuthId(pPlayer.edict()) == playerSteamID)
        {
            // Reset rendering
            pPlayer.pev.renderfx = kRenderFxNone;
            pPlayer.pev.rendermode = kRenderNormal;
            pPlayer.pev.renderamt = 255;
            pPlayer.pev.rendercolor = Vector(255, 255, 255);
            
            // Create break effect
            NetworkMessage breakMsg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, pPlayer.pev.origin);
                breakMsg.WriteByte(TE_BREAKMODEL);
                breakMsg.WriteCoord(pPlayer.pev.origin.x);
                breakMsg.WriteCoord(pPlayer.pev.origin.y);
                breakMsg.WriteCoord(pPlayer.pev.origin.z);
                breakMsg.WriteCoord(3); // Size - smaller than full barrier.
                breakMsg.WriteCoord(3); // Size.
                breakMsg.WriteCoord(3); // Size.
                breakMsg.WriteCoord(0); // Gib vel pos Forward/Back.
                breakMsg.WriteCoord(0); // Gib vel pos Left/Right.
                breakMsg.WriteCoord(5); // Gib vel pos Up/Down.
                breakMsg.WriteByte(15); // Gib random speed and direction - less than full barrier.
                breakMsg.WriteShort(g_EngineFuncs.ModelIndex(strRobogruntModelChromegibs));
                breakMsg.WriteByte(8); // Count - fewer particles than full barrier.
                breakMsg.WriteByte(10); // Lifetime.
                breakMsg.WriteByte(1); // Sound Flags.
                breakMsg.End();
                
            // Play break sound with lower volume.
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBarrierBreakSound, 0.7f, ATTN_NORM, 0, PITCH_NORM);
            
            // Notify player.
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No longer protected by Ice Shield!\n");
            break;
        }
    }
}

// Clean up protection for a player who disconnected or changed class.
void CleanupPlayerBarrierProtection(string playerSteamID)
{
    // If they were protecting others, remove that protection.
    if(g_PlayerBarriers.exists(playerSteamID))
    {
        BarrierData@ barrier = cast<BarrierData@>(g_PlayerBarriers[playerSteamID]);
        if(barrier !is null)
        {
            // Find the player object if possible (might be null if disconnected).
            CBasePlayer@ pPlayer = null;
            for(int i = 1; i <= g_Engine.maxClients; i++)
            {
                CBasePlayer@ tempPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if(tempPlayer !is null && g_EngineFuncs.GetPlayerAuthId(tempPlayer.edict()) == playerSteamID)
                {
                    @pPlayer = tempPlayer;
                    break;
                }
            }
            
            barrier.RemoveAllProtections(pPlayer);
        }
    }
    
    // If they were being protected by someone else, remove that protection.
    if(g_ProtectedPlayers.exists(playerSteamID))
    {
        string protectorSteamID = string(g_ProtectedPlayers[playerSteamID]);
        g_ProtectedPlayers.delete(playerSteamID);
        
        if(g_PlayerBarriers.exists(protectorSteamID))
        {
            BarrierData@ protectorBarrier = cast<BarrierData@>(g_PlayerBarriers[protectorSteamID]);
            if(protectorBarrier !is null)
            {
                protectorBarrier.RemovePlayerFromProtection(playerSteamID);
            }
        }
        
        // Find player and reset rendering if they're still connected.
        for(int i = 1; i <= g_Engine.maxClients; i++)
        {
            CBasePlayer@ tempPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
            if(tempPlayer !is null && g_EngineFuncs.GetPlayerAuthId(tempPlayer.edict()) == playerSteamID)
            {
                // Use the quiet version without effects for cleanup.
                RemoveProtectionEffectsQuiet(tempPlayer);
                break;
            }
        }
    }
}