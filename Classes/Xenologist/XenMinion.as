string strXenMinionSoundCreate = "debris/beamstart7.wav";
string strXenMinionSoundTeleport = "houndeye/he_blast1.wav";

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

string strHoundeyeModel = "models/houndeye.mdl";
string strAlienGruntModel = "models/agruntf.mdl";

float flXenReservePool = 0.0f;     // Current reserve used by Xen creatures.
float flXenMaxReservePool = 0.0f;  // Max reserve for Xen creatures.

dictionary g_XenologistMinions;

enum XenType
{
    XEN_PITDRONE = 0,
    XEN_HOUNDEYE = 1,
    XEN_ALIENGRUNT = 2
}

const array<string> XEN_NAMES = 
{
    "Pit Drone",
    "Houndeye",
    "Alien Grunt"
    
};

const array<string> XEN_ENTITIES = 
{
    "monster_pitdrone",
    "monster_houndeye",
    "monster_alien_grunt"
    
};

const array<int> XEN_COSTS = 
{
    25,  // Pitdrone.
    50,  // Houndeye.
    75   // Alien Grunt.
};

// Health modifiers for each Xen creature type, applied AFTER scaling.
const array<float> XEN_HEALTH_MODS = 
{
    1.0f,    // Pitdrone.
    1.0f,    // Houndeye.
    2.0f     // Alien Grunt.
};

float g_flBaseXenHP = 100.0;
float g_flXenHPBonus = 0.0;
float g_flXenDMGBonus = 0.0;
int g_iXenResourceCost = 1;

class XenMinionData
{
    private XenMinionMenu@ m_pMenu;
    private array<EHandle> m_hMinions;
    private array<int> m_CreatureTypes; // Store type of each minion. Since we have to use a different method here than in RobotMinion.
    private bool m_bActive = false;
    private float m_flBaseHealth = g_flBaseXenHP;
    private float m_flHealthScale = 0.33; // Health % scaling per level. Higher for Xenologist.
    private float m_flDamageScale = 0.25; // Damage % scaling per level. Lower for Xenologist.
    private int m_iMinionResourceCost = g_iXenResourceCost; // Cost to summon specific minion.
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
                flXenMaxReservePool = float(resources['max']) - flXenReservePool;
                return flXenMaxReservePool <= 0;
            }
        }
        return false;
    }

    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    int GetMinionCount() { return m_hMinions.length(); }

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
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Not enough energy for " + XEN_NAMES[minionType] + "!\n");
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

        float scaledHealth = GetScaledHealth(minionType); // Pass creature type
        float scaledDamage = GetScaledDamage();
        
        dictionary keys;
        keys["origin"] = vecSrc.ToString();
        keys["angles"] = Vector(0, pPlayer.pev.v_angle.y, 0).ToString();
        keys["targetname"] = "_xenminion_" + pPlayer.entindex();
        keys["displayname"] = string(pPlayer.pev.netname) + "'s " + XEN_NAMES[minionType];
        keys["health"] = string(scaledHealth);
        keys["dmg"] = string(scaledDamage);
        keys["scale"] = "1.0";
        keys["friendly"] = "1";
        keys["spawnflag"] = "32"; // Add SF_MONSTER_NO_REVIVE (16384) along with SF_MONSTER_FRIENDLY (32)
        keys["is_player_ally"] = "1";

        CBaseEntity@ pNewMinion = g_EntityFuncs.CreateEntity(XEN_ENTITIES[minionType], keys, true);
        if(pNewMinion !is null)
        {
            g_EntityFuncs.DispatchSpawn(pNewMinion.edict());
            m_hMinions.insertLast(EHandle(pNewMinion));
            m_CreatureTypes.insertLast(minionType); // Store type alongside handle
            m_bActive = true;

            flXenReservePool += XEN_COSTS[minionType];
            current -= XEN_COSTS[minionType];
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
        pMinion.pev.dmg = scaledDamage;
    }

    void XenUpdate(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        // Remove invalid Minions and check frags.
        for(int i = m_hMinions.length() - 1; i >= 0; i--)
        {
            CBaseEntity@ pExistingMinion = m_hMinions[i].GetEntity();
            
            if(pExistingMinion is null) // // Only count them if truly dead and not in revivable state.
            {
                // Use stored type index to reduce pool.
                flXenReservePool -= XEN_COSTS[m_CreatureTypes[i]];
                m_hMinions.removeAt(i);
                m_CreatureTypes.removeAt(i);
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Creature lost!\n");
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

        // Reset reserve pool after destroying all minions
        flXenReservePool = 0.0;
        
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "All Creatures destroyed!\n");
        m_bActive = false;
    }

    float GetScaledHealth(int creatureType = 0) // Default to Pitdrone health mod
    {
        if(m_pStats is null)
            return m_flBaseHealth * XEN_HEALTH_MODS[creatureType];

        float level = m_pStats.GetLevel();
        g_flXenHPBonus = m_flBaseHealth * (float(level) * m_flHealthScale);
        return (g_flXenHPBonus + m_flBaseHealth) * XEN_HEALTH_MODS[creatureType];
    }

    float GetScaledDamage() // Damage scaling works a little differently, through MonsterTakeDamage.
    {
        if(m_pStats is null)
            return 0.0f; // Technically should never be zero, but is always null when we have no minions.

        float level = m_pStats.GetLevel();
        g_flXenDMGBonus = (float(level) * m_flDamageScale); // Essentially just increasing the multiplier per level.
        return g_flXenDMGBonus;
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

        g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_WEAPON, strXenMinionSoundTeleport, 1.0f, ATTN_NORM);
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
        m_pMenu.SetTitle("Xen Creatures Control Menu\n");
        
        for(uint i = 0; i < XEN_NAMES.length(); i++) 
        {
            m_pMenu.AddItem("Summon " + XEN_NAMES[i] + " (Cost: " + XEN_COSTS[i] + ")\n", any(i));
        }
        
        if(m_pOwner.GetMinionCount() > 0) 
        {
            m_pMenu.AddItem("Teleport Creatures\n", any(98));
            m_pMenu.AddItem("Kill All Creatures\n", any(99));
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

            XenMinionData@ Minion = cast<XenMinionData@>(g_XenologistMinions[steamID]); // Changed cast type
            if(Minion !is null)
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
                            if(Minion.IsActive())
                            {
                                Minion.DestroyAllMinions(pPlayer);
                                continue;  // Skip rest of updates.
                            }
                        }
                        else if(!Minion.HasStats())
                        {
                            // Update stats.
                            Minion.Initialize(data.GetCurrentClassStats());
                        }
                    }
                }

                // Always update scaling values for stats menu.
                Minion.GetScaledHealth();
                Minion.GetScaledDamage();

                // Normal update for active minions.
                Minion.XenUpdate(pPlayer);
            }
        }
    }
}