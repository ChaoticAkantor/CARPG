string strBloodlustStartSound = "garg/gar_pain1.wav";
string strBloodlustEndSound = "player/breathe2.wav";
string strBloodlustHitSound = "debris/bustflesh1.wav";
string strBloodlustActiveSound = "player/heartbeat1.wav";

float flBloodlustEnergyCost = 2.0f; // Energy drain per 0.5s.
float flBaseArmorConversion = 1.0f; // Base armor to health conversion whilst bloodlust is active.
float flArmorConversionPerLevel = 0.05f; // bonus conversion per level.
float flBaseDamageLifesteal = 0.30f; // % base damage dealt returned as health.
float flLifestealPerLevel = 0.005f; // % bonus lifesteal per level.
float flMeleeLifestealMult = flBaseDamageLifesteal * 2; // Double lifesteal whilst holding melee weapons.
const float flToggleCooldownBloodlust = 0.5f; // Cooldown between toggles.

// For stats menu.
float flBloodlustOverhealBase = flBaseArmorConversion;
float flBloodlustOverhealBonus = 0.0f;

const Vector BLOODLUST_COLOR = Vector(255, 0, 0); // Red glow.

dictionary g_PlayerBloodlusts;

class BloodlustData
{
    private bool m_bActive = false;
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flNextGlowUpdate = 0.0f;
    private float m_flGlowUpdateInterval = 0.1f;
    private ClassStats@ m_pStats = null;

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }
    
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetArmorConversionBonus()
    {
        float bonus = flBaseArmorConversion;
        
        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();
            bonus += (level * flArmorConversionPerLevel);
        }

        return bonus;
    }

    void ToggleBloodlust(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < flToggleCooldownBloodlust)
            return;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerRPGData.exists(steamID))
            return;

        PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
        if(data is null)
            return;

        if(!m_bActive)
        {
            // Convert current max armor to bonus health.
            float currentArmor = pPlayer.pev.armortype;
            float conversionBonus = GetArmorConversionBonus();
            pPlayer.pev.max_health += (currentArmor * conversionBonus);

            flBloodlustOverhealBonus = (m_pStats.GetLevel() * flArmorConversionPerLevel); // Store for stat menu.
            flBloodlustOverhealBonus = flBloodlustOverhealBonus - flBloodlustOverhealBase;
            //pPlayer.pev.armortype = 0; // Disabled armor removal for now.
            //pPlayer.pev.armorvalue = 0; // Disabled armor removal for now.

            // Activate
            m_bActive = true;
            m_flLastDrainTime = currentTime;
            ApplyGlow(pPlayer);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBloodlustStartSound, 1.0f, ATTN_NORM, 0, PITCH_NORM);
            g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBloodlustActiveSound, 0.5f, ATTN_NORM, SND_FORCE_LOOP);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Bloodlust Activated!\n");
        }
        else
        {
            DeactivateBloodlust(pPlayer);
        }

        m_flLastToggleTime = currentTime;
    }

    void Update(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
        {
            DeactivateBloodlust(pPlayer);
            return;
        }

        if(m_pStats is null)
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_BERSERKER)
                {
                    @m_pStats = data.GetCurrentClassStats();
                }
            }
        }

        if(!m_bActive)
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastDrainTime >= 0.5f) // Interval for energy drain.
        {
            // Only drain energy
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerClassResources.exists(steamID))
            {
                dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                if(resources !is null)
                {
                    float current = float(resources['current']);
                    current -= flBloodlustEnergyCost; // Energy Drain.
                    
                    if(current <= 0)
                    {
                        current = 0;
                        DeactivateBloodlust(pPlayer); // Deactivate if we run out of energy.
                        RemoveGlow(pPlayer); // Remove glow effect failsafe.
                    }
                    
                    resources['current'] = current;
                }
            }

            m_flLastDrainTime = currentTime;
        }

        // Update glow effect
        if(currentTime >= m_flNextGlowUpdate)
        {
            ApplyGlow(pPlayer);
            m_flNextGlowUpdate = currentTime + m_flGlowUpdateInterval;
        }
    }

    float GetLifestealAmount(bool isMelee)
    {
        float baseAmount = flBaseDamageLifesteal;
        
        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();
            baseAmount += (level * flLifestealPerLevel);
        }

        return isMelee ? (baseAmount * flMeleeLifestealMult) : baseAmount;
    }

    float ProcessLifesteal(CBasePlayer@ pPlayer, float damageDealt, bool isMelee)
    {
        if(!m_bActive || pPlayer is null)
            return 0.0f;

        // Check if player died
        if(!pPlayer.IsAlive())
        {
            DeactivateBloodlust(pPlayer);
            return 0.0f;
        }

        float lifestealMult = GetLifestealAmount(isMelee);
        float healAmount = damageDealt * lifestealMult;

        pPlayer.pev.health = Math.min(pPlayer.pev.health + healAmount, pPlayer.pev.max_health);
        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBloodlustHitSound, 0.6f, ATTN_NORM, 0, PITCH_NORM);

        return healAmount;
    }

    void DeactivateBloodlust(CBasePlayer@ pPlayer)
    {
        if(!m_bActive)
            return;

        if(pPlayer !is null)
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null)
                {
                    m_bActive = false;
                    data.CalculateStats(pPlayer);
                    RemoveGlow(pPlayer);
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBloodlustActiveSound, 0.0f, ATTN_NORM, SND_STOP);
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBloodlustEndSound, 1.0f, ATTN_NORM, SND_FORCE_SINGLE, PITCH_LOW);
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Bloodlust Deactivated!\n");
                }
            }
        }
    }

    private void ApplyGlow(CBaseEntity@ target)
    {
        if(target is null)
            return;
            
        // Apply glow shell
        target.pev.renderfx = kRenderFxGlowShell;
        target.pev.rendermode = kRenderNormal;
        target.pev.renderamt = 4; // Shell thickness.
        target.pev.rendercolor = BLOODLUST_COLOR;

        // Add dynamic light
        NetworkMessage msg(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY);
            msg.WriteByte(TE_DLIGHT);
            msg.WriteCoord(target.pev.origin.x);
            msg.WriteCoord(target.pev.origin.y);
            msg.WriteCoord(target.pev.origin.z);
            msg.WriteByte(15); // Radius.
            msg.WriteByte(int(BLOODLUST_COLOR.x));
            msg.WriteByte(int(BLOODLUST_COLOR.y));
            msg.WriteByte(int(BLOODLUST_COLOR.z));
            msg.WriteByte(1); // Life in 0.1s.
            msg.WriteByte(0); // Decay rate.
        msg.End();
    }

    private void RemoveGlow(CBaseEntity@ target)
    {
        if(target is null)
            return;
            
        target.pev.renderfx = kRenderFxNone;
        target.pev.rendermode = kRenderNormal;
        target.pev.rendercolor = Vector(0, 0, 0);
    }
}