string strBloodlustStartSound = "garg/gar_pain1.wav";
string strBloodlustEndSound = "player/breathe2.wav";
string strBloodlustHitSound = "debris/bustflesh1.wav";
string strBloodlustActiveSound = "player/heartbeat1.wav";
string strBloodlustSprite = "sprites/blood_chnk.spr";

float flBloodlustEnergyCost = 2.0f; // Energy drain per 0.5s.
float flBaseHPBonus = 0.50f; // Base health bonus whilst bloodlust is active.
float flHPBonusPerLevel = 0.20f; // bonus health per level.
float flBaseDamageLifesteal = 0.35f; // % base damage dealt returned as health. Doubled when bloodlust is active.
float flLifestealPerLevel = 0.01f; // % bonus lifesteal per level. Doubled when bloodlust is active.
float flMeleeLifestealMult = flBaseDamageLifesteal * 2; // Double lifesteal whilst holding melee weapons.
const float flToggleCooldownBloodlust = 0.5f; // Cooldown between toggles.

// For stats menu.
float flBloodlustOverhealBase = flBaseHPBonus;
float flBloodlustOverhealBonus = 0.0f;

const Vector BLOODLUST_COLOR = Vector(255, 0, 0); // Red glow.

dictionary g_PlayerBloodlusts;

class BloodlustData
{
    private bool m_bActive = false;
    private float m_flLastDrainTime = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private ClassStats@ m_pStats = null;

    bool IsActive() { return m_bActive; }
    bool HasStats() { return m_pStats !is null; }
    
    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    float GetHPBonus()
    {
        float bonus = flBaseHPBonus;
        
        if(m_pStats !is null)
        {
            int level = m_pStats.GetLevel();
            bonus += (level * flHPBonusPerLevel);
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
            if(!g_PlayerClassResources.exists(steamID))
                return;
                
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            if(resources is null)
                return;

            float current = float(resources['current']);
            if(current < flBloodlustEnergyCost) // Check energy before activation.
            {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Energy too low!\n");
                return;
            }
        }

        if(!m_bActive)
        {
            // Add bonus health.
            float currentHP = pPlayer.pev.max_health;
            float HPBonus = GetHPBonus();
            pPlayer.pev.max_health += (currentHP * HPBonus);

            flBloodlustOverhealBonus = GetHPBonus(); // Store for stat menu.
            flBloodlustOverhealBonus = flBloodlustOverhealBonus - flBloodlustOverhealBase;

            // Activate.
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
            // Only drain energy.
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
                    }
                    
                    resources['current'] = current;
                }
            }

            m_flLastDrainTime = currentTime;
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

        // Apply melee multiplier first if using melee weapon.
        baseAmount = isMelee ? (baseAmount * flMeleeLifestealMult) : baseAmount;
        
        // Double lifesteal if bloodlust is active.
        return m_bActive ? (baseAmount * 2.0f) : baseAmount;
    }

    float ProcessLifesteal(CBasePlayer@ pPlayer, float damageDealt, bool isMelee)
    {
        if(pPlayer is null)
            return 0.0f;

        // Check for valid stats.
        if(m_pStats is null)
            return 0.0f;

        // Check if player died.
        if(!pPlayer.IsAlive())
        {
            DeactivateBloodlust(pPlayer);
            return 0.0f;
        }

        float lifestealMult = GetLifestealAmount(isMelee);
        float healAmount = damageDealt * lifestealMult;

        pPlayer.pev.health = Math.min(pPlayer.pev.health + healAmount, pPlayer.pev.max_health); // Add lifesteal amount to health.
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
                    RemoveGlow(pPlayer);
                    m_bActive = false;
                    data.CalculateStats(pPlayer);
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strBloodlustActiveSound, 0.0f, ATTN_NORM, SND_STOP);
                    g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_ITEM, strBloodlustEndSound, 1.0f, ATTN_NORM, SND_FORCE_SINGLE, PITCH_LOW);
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Bloodlust Deactivated!\n");
                }
            }
        }
    }

    private void ApplyGlow(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;
            
        // Apply glow shell
        pPlayer.pev.renderfx = kRenderFxGlowShell;
        pPlayer.pev.rendermode = kRenderNormal;
        pPlayer.pev.renderamt = 3; // Shell thickness.
        pPlayer.pev.rendercolor = BLOODLUST_COLOR;
    }

    private void RemoveGlow(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null)
            return;
        
        pPlayer.pev.renderfx = kRenderFxNone;
        pPlayer.pev.rendermode = kRenderNormal;
        pPlayer.pev.renderamt = 255;
        pPlayer.pev.rendercolor = Vector(255, 255, 255);
    }
}