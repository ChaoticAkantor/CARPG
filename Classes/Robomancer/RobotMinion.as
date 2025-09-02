string strRobogruntSoundCreate = "weapons/mine_deploy.wav";

// Minion Models.
string strRobogruntModel = "models/rgrunt.mdl";
string strRobogruntModelF = "models/rgruntf.mdl";

string strRobogruntRope = "sprites/rope.spr";
string strRobogruntModelChromegibs = "models/chromegibs.mdl";
string strRobogruntModelComputergibs = "models/computergibs.mdl";

//  Death Sounds.
string strRobogruntSoundDeath = "turret/tu_die.wav";
string strRobogruntSoundDeath2 = "turret/tu_die2.wav";

// Interaction Sounds.
string strRobogruntSoundButton2 = "buttons/button2.wav";
string strRobogruntSoundButton3 = "buttons/button3.wav";

//  Alert Sounds.
string strRobogruntSoundBeam = "debris/beamstart14.wav";

// Repair (Wrench heal) Sound.
string strRobogruntSoundRepair = "debris/metal6.wav";

// Weapons Sounds.
string strRobogruntSoundMP5 = "hgrunt/gr_mgun1.wav";
string strRobogruntSoundM16 = "weapons/m16_3round.wav";
string strRobogruntSoundReload = "hgrunt/gr_reload1.wav";

// Kick. 
string strRobogruntSoundKick = "zombie/claw_miss2.wav";

dictionary g_PlayerMinions;

enum MinionType // Minion gun type. Not all are supported.
{
    MINION_MP5 = 3, // MP5 + HG.
    MINION_SHOTGUN = 10, // Shotgun + HG.
    MINION_M16 = 5 // M16 + GL.
}

const array<string> MINION_NAMES = 
{
    "MP5 Robogrunt",      // Keyvalue weapons(0).
    "Shotgun Robogrunt",  // Keyvalue weapons(8).
    "M16 Robogrunt"       // Keyvalue weapons(4).
};

const array<int> MINION_COSTS = 
{
    1,  // MP5.
    1,  // Shotgun.
    2   // M16.
};

// Structure to track minion type.
class MinionInfo
{
    EHandle hMinion;
    int type;
    
    MinionInfo() { type = 0; }
    MinionInfo(EHandle h, int t) { hMinion = h; type = t; }
}

class MinionData
{
    private MinionMenu@ m_pMenu;
    private array<MinionInfo> m_hMinions;
    private bool m_bActive = false;
    private float m_flBaseHealth = 100.0; // Base health of Robogrunts.
    private float m_flHealthScale = 0.18; // Health % scaling per level. Robogrunts are armored.
    private float m_flHealthRegen = 0.005; // Health recovery % per second of Robogrunts.
    private float m_flDamageScale = 0.10; // Damage % scaling per level.
    private int m_iMinionResourceCost = 1; // Initialisation cost to summon 1 minion.
    private float m_flReservePool = 0.0f;
    private float m_flLastToggleTime = 0.0f;
    private float m_flLastMessageTime = 0.0f;
    private float m_flToggleCooldown = 1.0f;
    private ClassStats@ m_pStats = null;

    bool IsActive() 
    { 
        // Clean invalid minions first.
        for(int i = m_hMinions.length() - 1; i >= 0; i--)
        {
            if(!m_hMinions[i].hMinion.IsValid())
            {
                m_hMinions.removeAt(i);
            }
        }
        
        // The minions are active if there are any in the list.
        return m_hMinions.length() > 0;
    }

    void Initialize(ClassStats@ stats) { @m_pStats = stats; }

    int GetMinionCount() { return m_hMinions.length(); }

    float GetReservePool() { return m_flReservePool; }

    float GetMinionRegen() { return m_flHealthRegen; }

    bool HasStats() { return m_pStats !is null; }
    
    array<MinionInfo>@ GetMinions() { return m_hMinions; }

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
        
        // First clean up invalid minions to make sure we have an accurate count.
        for(int i = m_hMinions.length() - 1; i >= 0; i--)
        {
            if(!m_hMinions[i].hMinion.IsValid())
            {
                m_hMinions.removeAt(i);
            }
        }

        // Check resources for spawning new minion.
        if(current < MINION_COSTS[minionType])
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Not enough points for " + MINION_NAMES[minionType] + "!\n");
            return;
        }
        
        // Calculate max resources and ensure we're within limits.
        float maxEnergy = float(resources['max']);
        if(m_flReservePool + MINION_COSTS[minionType] > maxEnergy)
        {
            g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Maximum Robot Capacity reached!\n");
            return;
        }

        // Initialize stats if needed
        if(m_pStats is null)
        {
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_ROBOMANCER)
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

        CBaseEntity@ pRoboMinion = g_EntityFuncs.CreateEntity("monster_robogrunt", keys, true);
        if(pRoboMinion !is null)
        {   
            // Stuff to set before dispatch.
            // Make them glow green.
            pRoboMinion.pev.renderfx = kRenderFxGlowShell; // Effect.
            pRoboMinion.pev.rendermode = kRenderNormal; // Render mode.
            pRoboMinion.pev.renderamt = 1; // Shell thickness.
            pRoboMinion.pev.rendercolor = Vector(20, 180, 20); // Green.

            g_EntityFuncs.DispatchSpawn(pRoboMinion.edict()); // Dispatch the entity.

            // Stuff to set after dispatch.
            @pRoboMinion.pev.owner = @pPlayer.edict(); // Set owner to spawning player.

            // Cast so we can alter monster float variables.
            CBaseMonster@ pMonster = cast<CBaseMonster@>(pRoboMinion);
            if(pMonster !is null)
            {
                pMonster.m_flFieldOfView = -1.0; // Max their field of view so they become more effective.
                                                //  -1.0 = 360 degrees, 0.0 = 90 degrees, 1.0 = 60 degrees.
            }

            // Store both the minion handle and its type
            MinionInfo info;
            info.hMinion = EHandle(pRoboMinion);
            info.type = minionType;
            m_hMinions.insertLast(info);
            
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
        if(pPlayer is null)
            return;

        // Used to track whether we need to update the reserve pool.
        bool hasRemovedMinions = false;

        // Remove invalid Minions and check frags.
        for(int i = m_hMinions.length() - 1; i >= 0; i--)
        {
            CBaseEntity@ pExistingMinion = m_hMinions[i].hMinion.GetEntity();
            
            // If the minion no longer exists in the game world.
            if(pExistingMinion is null)
            {
                // Remove from our list and update reserve pool.
                m_hMinions.removeAt(i);
                hasRemovedMinions = true;
                continue;
            }
            
            // Cast to CBaseMonster to check monster-specific properties.
            CBaseMonster@ pMonster = cast<CBaseMonster@>(pExistingMinion);
            
            // Check if minion is dead or at very low health.
            if((pMonster !is null && pMonster.pev.deadflag != DEAD_NO) || pExistingMinion.pev.health <= 0)
            {
                // Use Killed to properly destroy the minion.
                pExistingMinion.Killed(pPlayer.pev, GIB_ALWAYS); // Ensure gibbing to remove possibility of revival.
                
                // Also immediately remove from our list to prevent multiple Killed calls.
                m_hMinions.removeAt(i);
                hasRemovedMinions = true;
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
            
            // Ensure max_health is properly set during updates.
            if(pExistingMinion.pev.max_health <= 0)
            {
                pExistingMinion.pev.max_health = GetScaledHealth();
            }
        }

        // If we've removed minions, recalculate the reserve pool.
        if(hasRemovedMinions)
        {
            // Recalculate the reserve pool based on current minions.
            float newReservePool = 0.0f;
            for(uint i = 0; i < m_hMinions.length(); i++)
            {
                int minionType = m_hMinions[i].type;
                if(minionType >= 0 && uint(minionType) < MINION_COSTS.length())
                {
                    newReservePool += MINION_COSTS[minionType];
                }
            }
            
            // Update the reserve pool.
            m_flReservePool = newReservePool;
        }

        // Update stats reference for stat menu.
        if(m_pStats is null)
        {
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data !is null && data.GetCurrentClass() == PlayerClass::CLASS_ROBOMANCER)
                {
                    @m_pStats = data.GetCurrentClassStats();
                }
            }
        }
    }

    void DestroyAllMinions(CBasePlayer@ pPlayer)
    {
        if(pPlayer is null || m_hMinions.length() == 0)
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
            CBaseEntity@ pExistingMinion = m_hMinions[i].hMinion.GetEntity();
            if(pExistingMinion !is null)
            {
                // Use Killed to destroy active minions naturally.
                pExistingMinion.Killed(pPlayer.pev, GIB_ALWAYS); // Ensure gibbing, incase they are in dying state and revivable.
                m_hMinions.removeAt(i);
            }
        }

        // Reset reserve pool after destroying all minions.
        m_flReservePool = 0.0f;
        
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "All Robots destroyed!\n");
    }
    
    // Reset function to clean up all active minions.
    void Reset()
    {
        // Find the player if possible.
        CBasePlayer@ pPlayer = null;
        
        if(m_pStats !is null)
        {
            for(int i = 1; i <= g_Engine.maxClients; i++)
            {
                CBasePlayer@ tempPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if(tempPlayer !is null && tempPlayer.IsConnected())
                {
                    string steamID = g_EngineFuncs.GetPlayerAuthId(tempPlayer.edict());
                    PlayerData@ playerData = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                    if(playerData !is null && playerData.GetCurrentClassStats() is m_pStats)
                    {
                        @pPlayer = tempPlayer;
                        break;
                    }
                }
            }
        }
        
        if(pPlayer !is null)
        {
            DestroyAllMinions(pPlayer);
        }
        else
        {
            // If we can't find the player, just remove all minions directly.
            for(int i = m_hMinions.length() - 1; i >= 0; i--)
            {
                CBaseEntity@ pExistingMinion = m_hMinions[i].hMinion.GetEntity();
                if(pExistingMinion !is null)
                {
                    g_EntityFuncs.Remove(pExistingMinion);
                }
            }
            
            m_hMinions.resize(0);
            m_flReservePool = 0.0f;
        }
    }

    void MinionRegen()
    {
        for(uint i = 0; i < m_hMinions.length(); i++)
        {
            CBaseEntity@ pMinion = m_hMinions[i].hMinion.GetEntity();
            if(pMinion !is null && pMinion.pev.health > 0) // Only regenerate if not "dead".
            {
                // Ensure max_health is properly set.
                if(pMinion.pev.max_health <= 0)
                {
                    pMinion.pev.max_health = GetScaledHealth();
                }
                
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
        float health = m_flBaseHealth * (1.0f + (float(level) * m_flHealthScale));
        
        // Ensure health is never less than base health.
        if(health < m_flBaseHealth)
            health = m_flBaseHealth;
            
        return health;
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
            CBaseEntity@ pMinion = m_hMinions[i].hMinion.GetEntity();
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
                // Destroy all minions.
                m_pOwner.DestroyAllMinions(pPlayer);
            }
            else if(choice == 98)
            {
                // Teleport existing minions.
                m_pOwner.TeleportMinions(pPlayer);
            }
            else if(choice >= 0 && uint(choice) < MINION_NAMES.length())
            {
                // Spawn new minion with selected weapon.
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
            
            // Initialize MinionData if it doesn't exist.
            if(!g_PlayerMinions.exists(steamID))
            {
                MinionData data;
                @g_PlayerMinions[steamID] = data;
            }

            MinionData@ Minion = cast<MinionData@>(g_PlayerMinions[steamID]);
            if(Minion !is null)
            {
                // Check if player switched away from Engineer.
                if(g_PlayerRPGData.exists(steamID))
                {
                    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                    if(data !is null)
                    {
                        if(data.GetCurrentClass() != PlayerClass::CLASS_ROBOMANCER)
                        {
                            // Player is not Engineer, destroy active minions.
                            if(Minion.GetMinionCount() > 0)
                            {
                                Minion.DestroyAllMinions(pPlayer);
                                continue;  // Skip rest of updates.
                            }
                        }
                        else if(!Minion.HasStats())
                        {
                            // Update stats for Engineer
                            Minion.Initialize(data.GetCurrentClassStats());
                        }
                    }
                }
                
                // Make sure resource limits are enforced
                if(g_PlayerClassResources.exists(steamID))
                {
                    dictionary@ resources = cast<dictionary@>(g_PlayerClassResources[steamID]);
                    if(resources !is null)
                    {
                        float maxEnergy = float(resources['max']);
                        if(Minion.GetReservePool() > maxEnergy)
                        {
                            // Over the limit, destroy minions until we're within limits.
                            Minion.DestroyAllMinions(pPlayer);
                        }
                    }
                }

                Minion.MinionRegen(); // Minion Regeneration.

                // Always update scaling values for stats menu.
                Minion.GetScaledHealth();
                Minion.GetScaledDamage();

                // Normal update for active minions.
                Minion.Update(pPlayer);
            }
        }
    }
}