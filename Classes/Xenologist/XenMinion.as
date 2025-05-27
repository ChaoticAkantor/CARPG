string strXenMinionSoundCreate = "debris/beamstart7.wav";

// models, sounds, and sprites for Xen creatures. (Yawn)
string strPitdroneModel = "models/pit_drone.mdl";
string strPitdroneModelGibs = "models/pit_drone_gibs.mdl";
string strPitdroneModelSpike = "models/pit_drone_spike.mdl";
string strPitdroneSpikeTrail = "sprites/spike_trail.spr";
string strPitdroneSoundAttackSpike1 = "pitdrone/pit_drone_attack_spike1.wav";
string strPitdroneSoundAlert1 = "pitdrone/pit_drone_alert1.wav";
string strPitdroneSoundAlert2 = "pitdrone/pit_drone_alert2.wav"; 
string strPitdroneSoundAlert3 = "pitdrone/pit_drone_alert3.wav"; 
string strPitdroneSoundIdle1 = "pitdrone/pit_drone_idle1.wav";
string strPitdroneSoundIdle2 = "pitdrone/pit_drone_idle2.wav";
string strPitdroneSoundIdle3 = "pitdrone/pit_drone_idle3.wav";
string strPitdroneSoundDie1 = "pitdrone/pit_drone_die1.wav";
string strPitdroneSoundDie2 = "pitdrone/pit_drone_die2.wav";
string strPitdroneSoundDie3 = "pitdrone/pit_drone_die3.wav";
string strPitdroneSoundBite2 = "bullchicken/bc_bite2.wav";
string strPitdroneSoundPain1 = "pitdrone/pit_drone_pain1.wav";
string strPitdroneSoundPain2 = "pitdrone/pit_drone_pain2.wav";
string strPitdroneSoundPain3 = "pitdrone/pit_drone_pain3.wav";
string strPitdroneSoundPain4 = "pitdrone/pit_drone_pain4.wav";
string strPitdroneSoundMelee1 = "pitdrone/pit_drone_melee_attack1.wav";
string strPitdroneSoundMelee2 = "pitdrone/pit_drone_melee_attack2.wav";
string strPitdroneSoundEat = "pitdrone/pit_drone_eat.wav";

string strGonomeModel = "models/gonome.mdl";
string strGonomeSpriteSpit = "sprites/blood_chnk.spr";
string strGonomeSoundSpit1 = "bullchicken/bc_spihit1.wav";
string strGonomeSoundDeath2 = "gonome/gonome_death2.wav";
string strGonomeSoundDeath3 = "gonome/gonome_death3.wav";
string strGonomeSoundDeath4 = "gonome/gonome_death4.wav";
string strGonomeSoundIdle1 = "gonome/gonome_idle1.wav";
string strGonomeSoundIdle2 = "gonome/gonome_idle2.wav";
string strGonomeSoundIdle3 = "gonome/gonome_idle3.wav";
string strGonomeSoundPain1 = "gonome/gonome_pain1.wav";
string strGonomeSoundPain2 = "gonome/gonome_pain2.wav";
string strGonomeSoundPain3 = "gonome/gonome_pain3.wav";
string strGonomeSoundPain4 = "gonome/gonome_pain4.wav";
string strGonomeSoundMelee1 = "gonome/gonome_melee1.wav";
string strGonomeSoundMelee2 = "gonome/gonome_melee2.wav";
string strGonomeSoundRun = "gonome/gonome_run.wav";
string strGonomeSoundEat = "gonome/gonome_eat.wav";

string strAlienGruntModel = "models/agruntf.mdl";
string strAlienGruntModelGibs = "models/fleshgibs.mdl";
string strAlienGruntMuzzleFlash = "sprites/muz4.spr";
string strAlienGruntSoundIdle1 = "agrunt/ag_idle1.wav";
string strAlienGruntSoundIdle2 = "agrunt/ag_idle2.wav";
string strAlienGruntSoundIdle3 = "agrunt/ag_idle3.wav";
string strAlienGruntSoundIdle4 = "agrunt/ag_idle4.wav";
string strAlienGruntSoundDie1 = "agrunt/ag_die1.wav";
string strAlienGruntSoundDie4 = "agrunt/ag_die4.wav";
string strAlienGruntSoundDie5 = "agrunt/ag_die5.wav";
string strAlienGruntSoundPain1 = "agrunt/ag_pain1.wav";
string strAlienGruntSoundPain2 = "agrunt/ag_pain2.wav";
string strAlienGruntSoundPain3 = "agrunt/ag_pain3.wav";
string strAlienGruntSoundPain4 = "agrunt/ag_pain4.wav";
string strAlienGruntSoundPain5 = "agrunt/ag_pain5.wav";
string strAlienGruntSoundAttack1 = "agrunt/ag_attack1.wav";
string strAlienGruntSoundAttack2 = "agrunt/ag_attack2.wav";
string strAlienGruntSoundAttack3 = "agrunt/ag_attack3.wav";
string strAlienGruntSoundAlert1 = "agrunt/ag_alert1.wav";
string strAlienGruntSoundAlert3 = "agrunt/ag_alert3.wav";
string strAlienGruntSoundAlert4 = "agrunt/ag_alert4.wav";
string strAlienGruntSoundAlert5 = "agrunt/ag_alert5.wav";

dictionary g_XenologistMinions;

enum XenType
{
    XEN_PITDRONE = 0,
    XEN_GONOME = 1,
    XEN_ALIENGRUNT = 2
}

const array<string> XEN_NAMES = 
{
    "Pit Drone",
    "Gonome",
    "Alien Grunt"
    
};

const array<string> XEN_ENTITIES = 
{
    "monster_pitdrone",
    "monster_gonome",
    "monster_alien_grunt"
    
};

const array<int> XEN_COSTS = 
{
    25,  // Pitdrone.
    50,  // Gonome.
    75   // Alien Grunt.
};

// Health modifiers for each Xen creature type, applied AFTER scaling.
const array<float> XEN_HEALTH_MODS = 
{
    1.0f,    // Pitdrone.
    1.15f,    // Gonome. 15% more health.
    1.30f     // Alien Grunt. 30% more health.
};

class XenMinionData
{
    private XenMinionMenu@ m_pMenu;
    private array<EHandle> m_hMinions;
    private array<int> m_CreatureTypes; // Store type of each minion. Since we have to use a different method here than in RobotMinion.
    private bool m_bActive = false;
    private float m_flBaseHealth = 100.0;
    private float m_flHealthScale = 0.10; // Health % scaling per level.
    private float m_flDamageScale = 0.08; // Damage % scaling per level.
    private int m_iMinionResourceCost = 1; // Cost to summon specific minion.
    private float m_flReservePool = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flLastMessageTime = 0.0f;
    private float m_flToggleCooldown = 1.0f;
    private ClassStats@ m_pStats = null;

    bool IsActive() 
    { 
        string steamID = g_EngineFuncs.GetPlayerAuthId(g_EntityFuncs.Instance(0).edict());
        if(g_PlayerClassResources.exists(steamID))
        {
            dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
            if(resources !is null)
            {
                float maxReserve = float(resources['max']) - m_flReservePool;
                return maxReserve <= 0;
            }
        }
        return false;
    }

    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    int GetMinionCount() { return m_hMinions.length(); }

    float GetReservePool() { return m_flReservePool; }

    bool HasStats() { return m_pStats !is null; }
    array<EHandle>@ GetMinions() { return m_hMinions; }

    XenMinionData() 
    {
        @m_pMenu = XenMinionMenu(this);
    }

    void SpawnXenMinion(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
            return;

        m_pMenu.ShowXenMinionMenu(pPlayer); // Show menu.
    }

    void SpawnSpecificMinion(CBasePlayer@ pPlayer, int minionType)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;

        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        int current = int(resources['current']);

        // Check resources for spawning new minion.
        if(current < XEN_COSTS[minionType])
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Not enough reserve for " + XEN_NAMES[minionType] + "!\n");
            return;
        }

        // Initialize stats if needed
        if(m_pStats is null)
        {
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_XENOLOGIST) // Changed from ENGINEER
                {
                    @m_pStats = data.GetCurrentClassStats();
                }
            }
        }

        Vector vecSrc = pPlayer.GetGunPosition();
        Vector spawnForward, spawnRight, spawnUp;
        g_EngineFuncs.AngleVectors(pPlayer.pev.v_angle, spawnForward, spawnRight, spawnUp);
        
        vecSrc = vecSrc + (spawnForward * 64);
        vecSrc.z -= 32;

        // Keep existing health/damage multipliers
        float scaledHealth = GetScaledHealth(minionType);
        float scaledDamage = GetScaledDamage();
        
        dictionary keys;
        keys["origin"] = vecSrc.ToString();
        keys["angles"] = Vector(0, pPlayer.pev.v_angle.y, 0).ToString();
        keys["targetname"] = "_xenminion_" + pPlayer.entindex();
        keys["displayname"] = string(pPlayer.pev.netname) + "'s " + XEN_NAMES[minionType];
        keys["health"] = string(scaledHealth);
        keys["scale"] = "0.75"; // Make them slightly smaller to reduce blocking.
        keys["friendly"] = "1";
        keys["spawnflag"] = "32";
        keys["is_player_ally"] = "1";

        CBaseEntity@ pNewMinion = g_EntityFuncs.CreateEntity(XEN_ENTITIES[minionType], keys, true);
        if(pNewMinion !is null)
        {
            // Make them glow green.
            pNewMinion.pev.renderfx = kRenderFxGlowShell; // Glow shell.
            pNewMinion.pev.rendermode = kRenderNormal; // Render mode.
            pNewMinion.pev.renderamt = 1; // Shell thickness.
            pNewMinion.pev.rendercolor = Vector(25, 100, 25); // Green.

            g_EntityFuncs.DispatchSpawn(pNewMinion.edict()); // Dispatch the entity.
            m_hMinions.insertLast(EHandle(pNewMinion)); // Insert into minion list.
            m_CreatureTypes.insertLast(minionType); // Store type alongside handle.
            m_bActive = true;

            m_flReservePool += XEN_COSTS[minionType]; // Add to reserve pool when minion is created.
            current -= XEN_COSTS[minionType]; // Subtract from current resources.
            resources['current'] = current;

            g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_WEAPON, strXenMinionSoundCreate, 1.0f, ATTN_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, XEN_NAMES[minionType] + " summoned!\n");
        }
    }

    private void UpdateMinionStats(CBaseEntity@ pMinion)
    {
        if(pMinion is null)
            return;
            
        float scaledHealth = GetScaledHealth();
        float scaledDamage = GetScaledDamage();

        pMinion.pev.max_health = scaledHealth;
    }

    void XenUpdate(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        // Remove invalid Minions and check frags.
        for(int i = m_hMinions.length() - 1; i >= 0; i--)
        {
            CBaseEntity@ pExistingMinion = m_hMinions[i].GetEntity();
            
            if(pExistingMinion is null)
            {
                // Return costs to individual reserve pool
                m_flReservePool -= XEN_COSTS[m_CreatureTypes[i]];
                m_hMinions.removeAt(i);
                m_CreatureTypes.removeAt(i);
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Creature bled out!\n");
                continue;
            }

            // Check if minion has gained a frag
            if(pExistingMinion.pev.frags > 0)
            {
                pPlayer.pev.frags += 1;
                pExistingMinion.pev.frags = 0;
            }
        }

        m_bActive = (m_hMinions.length() > 0);

        // Update stats reference for stat menu.
        if(m_pStats is null)
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_XENOLOGIST) // Changed from ENGINEER
                {
                    @m_pStats = data.GetCurrentClassStats();
                }
            }
        }
    }

    void DestroyAllMinions(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !m_bActive)
            return;

        uint MinionCount = m_hMinions.length();
        if(MinionCount == 0)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No Creatures to destroy!\n");
            return;
        }

        // Destroy all Minions from last to first
        for(int i = MinionCount - 1; i >= 0; i--)
        {
            CBaseEntity@ pExistingMinion = m_hMinions[i].GetEntity();
            if(pExistingMinion !is null)
            {
                // Use Killed to destroy active minions naturally.
                pExistingMinion.Killed(pPlayer.pev, GIB_ALWAYS); // Ensure gibbing, incase they are in dying state and revivable.
                m_hMinions.removeAt(i);
                m_CreatureTypes.removeAt(i);
            }
        }

        // Reset individual reserve pool
        m_flReservePool = 0.0f;
        
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "All Creatures destroyed!\n");
        m_bActive = false;
    }

        void HealAllMinions(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !m_bActive)
            return;

        if(m_hMinions.length() == 0)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No Creatures to heal!\n");
            return;
        }

        string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if(!g_PlayerClassResources.exists(steamID))
            return;

        dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
        float currentEnergy = float(resources['current']);

        if(currentEnergy <= 0)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No remaining reserve!\n");
            return;
        }

        // Heal % of max health per energy point spent.
        float healPercent = 0.02f; // % to heal per energy point spent.
        int minionsHealed = 0; // Count how many minions were healed.

        for(uint i = 0; i < m_hMinions.length(); i++)
        {
            CBaseEntity@ pMinion = m_hMinions[i].GetEntity();
            if(pMinion !is null)
            {
                float maxHealth = pMinion.pev.max_health;
                float currentHealth = pMinion.pev.health;
                
                if(currentHealth < maxHealth)
                {
                    float healAmount = maxHealth * (healPercent * currentEnergy);
                    pMinion.pev.health = Math.min(currentHealth + healAmount, maxHealth);
                    minionsHealed++;
                }
            }
        }

        if(minionsHealed > 0)
        {
            // Consume all current energy
            resources['current'] = 0;
            g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_ITEM, strPitdroneSoundEat, 1.0f, ATTN_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Healed all Creatures!\n");
        }
        else
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "All Creatures at full health!\n");
        }
    }

    float GetScaledHealth(int creatureType = 0) // Default to Pitdrone health mod
    {
        if(m_pStats is null)
            return m_flBaseHealth * XEN_HEALTH_MODS[creatureType];

        float level = m_pStats.GetLevel();
        float flScaledHealth = m_flBaseHealth * (1.0f + (float(level) * m_flHealthScale));
        return (flScaledHealth) * XEN_HEALTH_MODS[creatureType] + m_flBaseHealth;
    }

    float GetScaledDamage() // Damage scaling works a little differently, through MonsterTakeDamage.
    {
        if(m_pStats is null)
            return 0.0f; // Technically should never be zero, but is always null when we have no minions.

        float level = m_pStats.GetLevel();
        float flScaledDamage = (float(level) * m_flDamageScale); // Essentially just increasing the multiplier per level as there is no base damage.
        return flScaledDamage;
    }

    void TeleportMinions(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        if(m_hMinions.length() == 0)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No Creatures to teleport!\n");
            return;
        }

        Vector playerPos = pPlayer.pev.origin;
        Vector spawnForward, spawnRight, spawnUp;
        float radius = 60.0f;
        float angleStep = (180.0f / m_hMinions.length());

        for(uint i = 0; i < m_hMinions.length(); i++)
        {
            CBaseEntity@ pMinion = m_hMinions[i].GetEntity();
            if(pMinion !is null)
            {
                float angle = angleStep * i;
                g_EngineFuncs.AngleVectors(Vector(0, angle, 0), spawnForward, spawnRight, spawnUp);
                Vector offset = spawnForward * radius;
                pMinion.pev.origin = playerPos + offset;
                pMinion.pev.angles = pPlayer.pev.angles;
            }
        }

    g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_STATIC, strXenMinionSoundCreate, 1.0f, ATTN_NORM);
    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Creatures teleported!\n");
    }
}

class XenMinionMenu 
{
    private CTextMenu@ m_pMenu;
    private XenMinionData@ m_pOwner;
    
    XenMinionMenu(XenMinionData@ owner) 
    {
        @m_pOwner = owner;
    }
    
    void ShowXenMinionMenu(CBasePlayer@ pPlayer) 
    {
        if(pPlayer is null) return;
        
        @m_pMenu = CTextMenu(TextMenuPlayerSlotCallback(this.MenuCallback));
        m_pMenu.SetTitle("[Xen Creatures Control Menu]\n");
        
        for(uint i = 0; i < XEN_NAMES.length(); i++) 
        {
            m_pMenu.AddItem("Summon " + XEN_NAMES[i] + " (Cost: " + XEN_COSTS[i] + ")\n", any(i));
        }
        
        if(m_pOwner.GetMinionCount() > 0) 
        {
            m_pMenu.AddItem("Teleport All\n", any(98));
            m_pMenu.AddItem("Heal All (Consumes all remaining Reserve)\n", any(97));
            m_pMenu.AddItem("Kill All\n", any(99));
        }
        
        m_pMenu.Register();
        m_pMenu.Open(0, 0, pPlayer);
    }
    
    private void MenuCallback(CTextMenu@ menu, CBasePlayer@ pPlayer, int page, const CTextMenuItem@ item) 
    {
        if(item !is null && pPlayer !is null) 
        {
            int choice;
            item.m_pUserData.retrieve(choice);
            
            if(choice == 99) 
            {
                // Destroy all minions.
                m_pOwner.DestroyAllMinions(pPlayer);
            }
            else if(choice == 98)
            {
                // Teleport existing minions.
                m_pOwner.TeleportMinions(pPlayer);
            }
            else if(choice == 97)
            {
                // Heal all minions.
                m_pOwner.HealAllMinions(pPlayer);
            }
            else if(choice >= 0 && uint(choice) < XEN_NAMES.length())
            {
                // Spawn new minion.
                m_pOwner.SpawnSpecificMinion(pPlayer, choice);
            }
        }
    }
}

void CheckXenologistMinions()
{   
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            
            // Initialize MinionData if it doesn't exist.
            if(!g_XenologistMinions.exists(steamID)) // Changed from g_PlayerMinions
            {
                XenMinionData data;
                @g_XenologistMinions[steamID] = data;
            }

            XenMinionData@ xenMinion = cast<XenMinionData@>(g_XenologistMinions[steamID]); // Changed cast type
            if(xenMinion !is null)
            {
                // Check if player switched class.
                if(g_PlayerRPGData.exists(steamID))
                {
                    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                    if(data !is null)
                    {
                        if(data.GetCurrentClass() != PlayerClass::CLASS_XENOLOGIST)
                        {
                            // Player is no longer this class, destroy active minions.
                            if(xenMinion.IsActive())
                            {
                                xenMinion.DestroyAllMinions(pPlayer);
                                continue;  // Skip rest of updates.
                            }
                        }
                        else if(!xenMinion.HasStats())
                        {
                            // Update stats.
                            xenMinion.Initialize(data.GetCurrentClassStats());
                        }
                    }
                }

                // Always update scaling values for stats menu.
                xenMinion.GetScaledHealth();
                xenMinion.GetScaledDamage();

                // Normal update for active minions.
                xenMinion.XenUpdate(pPlayer);
            }
        }
    }
}