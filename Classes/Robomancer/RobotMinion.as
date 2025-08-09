string strRobogruntSoundCreate = "weapons/mine_deploy.wav";

// Minion Models.
string strRobogruntModel = "models/rgrunt.mdl";
string strRobogruntModelF = "models/rgruntf.mdl";

string strRobogruntRope = "sprites/rope.spr";
string strRobogruntModelChromegibs = "models/chromegibs.mdl";
string strRobogruntModelComputergibs = "models/computergibs.mdl";

// Minion Sounds.
//  Death.
string strRobogruntSoundDeath = "turret/tu_die.wav";
string strRobogruntSoundDeath2 = "turret/tu_die2.wav";

// Interaction.
string strRobogruntSoundButton2 = "buttons/button2.wav";
string strRobogruntSoundButton3 = "buttons/button3.wav";

//  Alert.
string strRobogruntSoundBeam = "debris/beamstart14.wav";

// Repair (Wrench heal).
string strRobogruntSoundRepair = "debris/metal6.wav";

// Weapons.
string strRobogruntSoundMP5 = "hgrunt/gr_mgun1.wav";
string strRobogruntSoundM16 = "weapons/m16_3round.wav";
string strRobogruntSoundReload = "hgrunt/gr_reload1.wav";

// Kick. 
string strRobogruntSoundKick = "zombie/claw_miss2.wav";

// Flags
const int SF_MONSTER_START_ACTIVE = 32;  // Start active without trigger

dictionary g_PlayerMinions;

enum MinionType // Minion gun type. Not all are supported.
{
    MINION_MP5 = 3, // MP5 + HG
    MINION_SHOTGUN = 10, // Shotgun + HG
    MINION_M16 = 5 // M16 + GL
}

const array<string> MINION_NAMES = 
{
    "MP5 Robogrunt",      // Keyvalue weapons(0)
    "Shotgun Robogrunt",  // Keyvalue weapons(8)
    "M16 Robogrunt"       // Keyvalue weapons(4)
};

const array<int> MINION_COSTS = 
{
    1,  // MP5
    2,  // Shotgun
    2   // M16
};

class MinionData
{
    private MinionMenu@ m_pMenu;
    private array<EHandle> m_hMinions;
    private bool m_bActive = false;
    private float m_flBaseHealth = 100.0; // Base health of Robogrunts.
    private float m_flHealthScale = 0.08; // Health % scaling per level. Robogrunts have natural armor and don't get health increases per tier like Xeno.
    private float m_flHealthRegen = 0.01; // Health recovery % per second of Robogrunts.
    private float m_flDamageScale = 0.1; // Damage % scaling per level.
    private int m_iMinionResourceCost = 1; // Cost to summon 1 minion. Init.
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

    float GetMinionRegen() { return m_flHealthRegen; }

    bool HasStats() { return m_pStats !is null; }
    
    array<EHandle>@ GetMinions() { return m_hMinions; }

    MinionData() 
    {
        @m_pMenu = MinionMenu(this);
    }

    void SpawnMinion(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        float currentTime = g_Engine.time;
        if(currentTime - m_flLastToggleTime < m_flToggleCooldown)
            return;

        m_pMenu.ShowRobotMinionMenu(pPlayer); // Show menu.
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
        if(current < MINION_COSTS[minionType])
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Not enough reserve for " + MINION_NAMES[minionType] + "!\n");
            return;
        }

        // Initialize stats if needed
        if(m_pStats is null)
        {
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_ENGINEER)
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

        float scaledHealth = GetScaledHealth();
        float scaledDamage = GetScaledDamage();
        
        dictionary keys;
        keys["origin"] = vecSrc.ToString();
        keys["angles"] = Vector(0, pPlayer.pev.angles.y, 0).ToString();
        keys["targetname"] = "_minion_" + pPlayer.entindex();
        keys["displayname"] = string(pPlayer.pev.netname) + "'s " + MINION_NAMES[minionType];
        keys["weapons"] = "" + (minionType == 0 ? MINION_MP5 : 
                               minionType == 1 ? MINION_SHOTGUN : 
                               MINION_M16);
        keys["health"] = string(scaledHealth);
        keys["scale"] = "1";
        keys["friendly"] = "1";
        keys["spawnflag"] = "32";
        keys["is_player_ally"] = "1";
        keys["skin"] = "2";

        CBaseEntity@ pNewMinion = g_EntityFuncs.CreateEntity("monster_robogrunt", keys, true);
        if(pNewMinion !is null)
        {
            // Make them glow green.
            pNewMinion.pev.renderfx = kRenderFxGlowShell; // Effect.
            pNewMinion.pev.rendermode = kRenderNormal; // Render mode.
            pNewMinion.pev.renderamt = 1; // Shell thickness.
            pNewMinion.pev.rendercolor = Vector(20, 180, 20); // Green.

            g_EntityFuncs.DispatchSpawn(pNewMinion.edict()); // Dispatch the entity.

            m_hMinions.insertLast(EHandle(pNewMinion)); //Insert into minion list.
            m_bActive = true; // Set ability as "active".
            
            m_flReservePool += MINION_COSTS[minionType]; // Add to reserve pool when minion is created.
            current -= MINION_COSTS[minionType]; // Subtract from current resources.
            resources['current'] = current;

            g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_WEAPON, strRobogruntSoundCreate, 1.0f, ATTN_NORM);
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, MINION_NAMES[minionType] + " deployed!\n");
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

    void Update(CBasePlayer@ pPlayer)
    {
        if(!m_bActive || pPlayer is null)
            return;

        // Remove invalid Minions and check frags.
        for(int i = m_hMinions.length() - 1; i >= 0; i--)
        {
            CBaseEntity@ pExistingMinion = m_hMinions[i].GetEntity();
            
            // First get the name while minion still exists.
            string name = pExistingMinion !is null ? string(pExistingMinion.pev.targetname) : "";
            
            if(pExistingMinion is null) // Only count them if truly dead and not in revivable state.
            {
                // Find minion type and reduce pool before removing from array.
                for(uint j = 0; j < MINION_NAMES.length(); j++)
                {
                    if(name.Find(MINION_NAMES[j]) >= 0)
                    {
                        m_flReservePool -= MINION_COSTS[j];
                        break;
                    }
                }
                
                m_hMinions.removeAt(i);
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Robot destroyed!\n");
                continue;
            }

            // Check if minion has gained a frag.
            if(pExistingMinion.pev.frags > 0)
            {
                // Add frag to player.
                pPlayer.pev.frags += 1;
                // Reset minion's frag counter.
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
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_ENGINEER)
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
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No Robots to destroy!\n");
            return;
        }

        // Destroy all Minions from last to first.
        for(int i = MinionCount - 1; i >= 0; i--)
        {
            CBaseEntity@ pExistingMinion = m_hMinions[i].GetEntity();
            if(pExistingMinion !is null)
            {
                // Use Killed to destroy active minions naturally.
                pExistingMinion.Killed(pPlayer.pev, GIB_ALWAYS); // Ensure gibbing, incase they are in dying state and revivable.
                m_hMinions.removeAt(i);
            }
        }

        // Reset reserve pool after destroying all minions
        m_flReservePool = 0.0f;
        
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "All Robots destroyed!\n");
        m_bActive = false;
    }

    void MinionRegen()
    {
        for(uint i = 0; i < m_hMinions.length(); i++)
        {
            CBaseEntity@ pMinion = m_hMinions[i].GetEntity();
            if(pMinion !is null)
            {
                float flHealAmount = pMinion.pev.max_health * m_flHealthRegen; // Calculate amount from max health.

                if(pMinion.pev.health < pMinion.pev.max_health)
                {
                    pMinion.pev.health = Math.min(pMinion.pev.health + flHealAmount, pMinion.pev.max_health); // Add health.

                    if(pMinion.pev.health > pMinion.pev.max_health) 
                        pMinion.pev.health = pMinion.pev.max_health; // Clamp to max health.
                }
            }
        }
    }

    float GetScaledHealth() // Health scaling for minions.
    {
        if(m_pStats is null)
            return m_flBaseHealth;

        float level = m_pStats.GetLevel();
        float flScaledHealth = m_flBaseHealth * (1.0f + (float(level) * m_flHealthScale));
        return flScaledHealth + m_flBaseHealth;
    }

    float GetScaledDamage() // Damage scaling works a little differently, through MonsterTakeDamage.
    {
        if(m_pStats is null)
            return 1.0f; // Technically should never be null, but would always be null when we have no minions.

        float level = m_pStats.GetLevel();
        float flScaledDamage = (float(level) * m_flDamageScale); // Essentially just increasing the multiplier per level.
        return flScaledDamage;
    }

    void TeleportMinions(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
            return;

        if(m_hMinions.length() == 0)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "No Robots to teleport!\n");
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

        g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_STATIC, strRobogruntSoundBeam, 1.0f, ATTN_NORM);
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Robots teleported!\n");
    }
}

class MinionMenu 
{
    private CTextMenu@ m_pMenu;
    private MinionData@ m_pOwner;
    
    MinionMenu(MinionData@ owner) 
    {
        @m_pOwner = owner;
    }
    
    void ShowRobotMinionMenu(CBasePlayer@ pPlayer) 
    {
        if(pPlayer is null) return;
        
        @m_pMenu = CTextMenu(TextMenuPlayerSlotCallback(this.MenuCallback));
        m_pMenu.SetTitle("[Robot Control Menu]\n");
        
        // Always show spawn options since limit is now resource-based.
        for(uint i = 0; i < MINION_NAMES.length(); i++) 
        {
            m_pMenu.AddItem("Deploy " + MINION_NAMES[i] + " (Cost: " + MINION_COSTS[i] + ")\n", any(i));
        }
        
        // Add management options if we have minions.
        if(m_pOwner.GetMinionCount() > 0) 
        {
            m_pMenu.AddItem("Teleport All\n", any(98));
            m_pMenu.AddItem("Destroy All\n", any(99));
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
                // Destroy all minions
                m_pOwner.DestroyAllMinions(pPlayer);
            }
            else if(choice == 98)
            {
                // Teleport existing minions
                m_pOwner.TeleportMinions(pPlayer);
            }
            else if(choice >= 0 && uint(choice) < MINION_NAMES.length())
            {
                // Spawn new minion with selected weapon
                m_pOwner.SpawnSpecificMinion(pPlayer, choice);
            }
        }
    }
}

void CheckEngineerMinions()
{   
    const int iMaxPlayers = g_Engine.maxClients;
    for(int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if(pPlayer !is null && pPlayer.IsConnected())
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            
            // Initialize MinionData if it doesn't exist
            if(!g_PlayerMinions.exists(steamID))
            {
                MinionData data;
                @g_PlayerMinions[steamID] = data;
            }

            MinionData@ Minion = cast<MinionData@>(g_PlayerMinions[steamID]);
            if(Minion !is null)
            {
                // Check if player switched away from Engineer
                if(g_PlayerRPGData.exists(steamID))
                {
                    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                    if(data !is null)
                    {
                        if(data.GetCurrentClass() != PlayerClass::CLASS_ENGINEER)
                        {
                            // Player is not Engineer, destroy active minions.
                            if(Minion.IsActive())
                            {
                                Minion.DestroyAllMinions(pPlayer);
                                continue;  // Skip rest of updates
                            }
                        }
                        else if(!Minion.HasStats())
                        {
                            // Update stats for Engineer
                            Minion.Initialize(data.GetCurrentClassStats());
                        }
                    }
                }

                Minion.MinionRegen(); // Minion Regeneration.

                // Always update scaling values for stats menu
                Minion.GetScaledHealth();
                Minion.GetScaledDamage();

                // Normal update for active minions
                Minion.Update(pPlayer);
            }
        }
    }
}