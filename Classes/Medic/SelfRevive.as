// Plugin Created by Chaotic Akantor.
// Self-Revive Ability.

string strReviveSound = "items/medshot4.wav"; // Self revive sound.
const int REVIVE_COST = 50; // Energy cost to revive

void HUDCanRevive()
{
    HUDTextParams reviveParams;
    reviveParams.x = -1;
    reviveParams.y = 0.85;
    reviveParams.effect = 0;
    reviveParams.r1 = 0;
    reviveParams.g1 = 255;
    reviveParams.b1 = 0;
    reviveParams.a1 = 255;
    reviveParams.fadeinTime = 0;
    reviveParams.fadeoutTime = 0;
    reviveParams.holdTime = 10;
    reviveParams.channel = 2;
    
    g_PlayerFuncs.HudMessage(null, reviveParams, "Press RELOAD Self-Revive (" + REVIVE_COST + ")\n");
}

void CheckCanRevive()
{
    const int iMaxPlayers = g_Engine.maxClients;
    for (int i = 1; i <= iMaxPlayers; ++i)
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
        if (pPlayer !is null && pPlayer.IsConnected())
        {   
            string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
            
            // Check if player is Medic class
            if(g_PlayerRPGData.exists(steamID))
            {
                PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
                if(data is null || data.GetCurrentClass() != PlayerClass::CLASS_MEDIC)
                    continue;
            }

            if (!pPlayer.IsAlive()) 
            {
                HUDCanRevive();
                
                if ((pPlayer.pev.button & IN_RELOAD) != 0)
                {
                    if(!g_HealingAuras.exists(steamID))
                        continue;

                    HealingAura@ aura = cast<HealingAura@>(g_HealingAuras[steamID]);
                    if(aura is null)
                        continue;

                    if (aura.GetAbilityCharge() >= float(REVIVE_COST))
                    {
                        aura.ConsumeCharge(float(REVIVE_COST));
                        g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_STATIC, strReviveSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
                        pPlayer.Revive();
                    }
                    else
                    {
                        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Need (" + REVIVE_COST + ") to self-revive!\n");
                    }
                }
            }
        }
    }
}