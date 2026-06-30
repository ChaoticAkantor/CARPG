// Sends the MOTD GUI window to the player.
// The title is set via ServerName, text is split into 32-char chunks,
// then the server name is restored when done.
void ShowInfoMOTD(CBasePlayer@ pPlayer, const string& in szTitle, const string& in szMessage)
{
    if(pPlayer is null)
        return;

    // Set the window title bar.
    NetworkMessage title(MSG_ONE_UNRELIABLE, NetworkMessages::ServerName, pPlayer.edict());
    title.WriteString(szTitle);
    title.End();

    // 32-char sending buffer, matching the SCXPM ShowMOTD chunk size.
    uint iChars = 0;
    string szChunk = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

    for(uint i = 0; i < szMessage.Length(); i++)
    {
        szChunk.SetCharAt(iChars, char(szMessage[i]));
        iChars++;
        if(iChars == 32)
        {
            NetworkMessage msg(MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, pPlayer.edict());
            msg.WriteByte(0); // 0 = more data follows.
            msg.WriteString(szChunk);
            msg.End();
            iChars = 0;
        }
    }

    // Send any remaining characters that didn't fill a full chunk.
    if(iChars > 0)
    {
        szChunk.Truncate(iChars);
        NetworkMessage msg(MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, pPlayer.edict());
        msg.WriteByte(0);
        msg.WriteString(szChunk);
        msg.End();
    }

    // 1 = end of MOTD, causes the window to open on the client.
    NetworkMessage endMsg(MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, pPlayer.edict());
    endMsg.WriteByte(1);
    endMsg.WriteString("\n");
    endMsg.End();

    // Restore the actual server name.
    NetworkMessage restore(MSG_ONE_UNRELIABLE, NetworkMessages::ServerName, pPlayer.edict());
    restore.WriteString(g_EngineFuncs.CVarGetString("hostname"));
    restore.End();
}

// Looks up the player's current class and displays its description.
void ShowInfo(CBasePlayer@ pPlayer)
{
    if(pPlayer is null)
        return;

    string steamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if(!g_PlayerRPGData.exists(steamID))
    {
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[CARPG] No class data found.\n");
        return;
    }

    PlayerData@ data = cast<PlayerData@>(g_PlayerRPGData[steamID]);
    if(data is null || data.GetCurrentClass() == PlayerClass::CLASS_NONE)
    {
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK,
            "[CARPG] No class selected. Type 'class' to choose one.\n");
        return;
    }

    string szTitle = "CARPG Info - " + data.GetClassName(data.GetCurrentClass());
        string szDesc = "[XP]\n"
        + "Gain score to earn XP and increase your Class Level, awarding you with Skillpoints and also contributing towards your Rank.\n\n"
        + "[Rank]\n"
        + "Rank increases maximum level of all skills, but less for Ability Skills.\n\n"
        + "[Skills]\n"
        + "Type 'skills' to view your current skills and spend skillpoints.\n\n"
        + "[Class Ability]\n";
                szDesc += GetClassDescription(data.GetCurrentClass());

    ShowInfoMOTD(pPlayer, szTitle, szDesc);
}

// Returns the description string for the given class.
string GetClassDescription(PlayerClass pClass)
{
    switch(pClass)
    {
        case PlayerClass::CLASS_MEDIC:
            return
                "{Heal}.\n\n"
                "Cost all charge to activate.\n"
                "Heals allies (players and friendly NPCs) in a very large radius.\n" 
                "Healing is dealt as a percentage of the target's max health.\n"
                "More skills can be unlocked to add extra effects to this ability.\n"
                "Type skills to spend skillpoints.\n"
                "Type in console: Bind mouse3 \"say UseAbility\" to use your Class Ability.\n";

        case PlayerClass::CLASS_BERSERKER:
            return
                "{Bloodlust}.\n\n"
                "Starts with passive life steal.\n"
                "All bonuses are counted as passives.\n"
                "Activating Bloodlust doubles all HP and healing related bonuses (except for AP conversion).\n"
                "More skills can be unlocked to add extra effects to this ability.\n"
                "Type skills to spend skillpoints.\n"
                "Type in console: Bind mouse3 \"say UseAbility\" to use your Class Ability.\n";

        case PlayerClass::CLASS_ENGINEER:
            return
                "{Sentry Turret}.\n\n"
                "Can be recalled for a cost by activating again.\n"
                "More skills can be unlocked to add extra effects to this ability.\n"
                "Type skills to spend skillpoints.\n"
                "Type in console: Bind mouse3 \"say UseAbility\" to use your Class Ability.\n";

        case PlayerClass::CLASS_ROBOMANCER:
            return
                "{Robogrunts}.\n\n"
                "Can summon friendly Robogrunts and choose their weapon type, HP varies by type.\n"
                "Robogrunts are armored and are resistant to all forms of damage except for explosives and electric.\n"
                "Minion movement and attack speed is increased.\n"
                "Minion limit depends on minion type and points reserved.\n"
                "Can be commanded with Sven NPC keybinds.\n"
                "Minion menu can also be used to teleport or kill all minions.\n"
                "More skills can be unlocked to add extra effects to this ability.\n"
                "Type skills to spend skillpoints.\n"
                "Type in console: Bind mouse3 \"say UseAbility\" to use your Class Ability.\n";

        case PlayerClass::CLASS_XENOMANCER:
            return
                "{Xen Creatures}.\n\n"
                "Can summon different friendly Xen Creatures, HP varies by type.\n"
                "Minion movement and attack speed is increased, varies by type.\n"
                "Minion limit depends on minion type and points reserved.\n"
                "Can be commanded with Sven NPC keybinds.\n"
                "More skills can be unlocked to add extra effects to this ability.\n"
                "Type skills to spend skillpoints.\n"
                "Type in console: Bind mouse3 \"say UseAbility\" to use your Class Ability.\n";

        case PlayerClass::CLASS_NECROMANCER:
            return
                "{Undead Menu}.\n\n"
                "Can summon different friendly Undead Creatures, HP and damage varies by type.\n"
                "Undead Creatures have higher health than other minion types.\n"
                "Minion movement and attack speed is increased, varies by type.\n"
                "Minion limit depends on minion type and points reserved.\n"
                "Can be commanded with Sven NPC keybinds.\n"
                "Minion menu can also be used to teleport or kill all minions.\n"
                "More skills can be unlocked to add extra effects to this ability.\n"
                "Type skills to spend skillpoints.\n"
                "Type in console: Bind mouse3 \"say UseAbility\" to use your Class Ability.\n";

        case PlayerClass::CLASS_DEFENDER:
            return
                "{Ice Shield}.\n\n"
                "Ice Shield will absorb all damage until it shatters, HP depends on skill.\n"
                "Can be deactivated for a cost.\n"
                "More skills can be unlocked to add extra effects to this ability.\n"
                "Type skills to spend skillpoints.\n"
                "Type in console: Bind mouse3 \"say UseAbility\" to use your Class Ability.\n";

        case PlayerClass::CLASS_SHOCKTROOPER:
            return
                "{Super Shockrifle}.\n\n"
                "Equips an improved version of the Shockrifle.\n"
                "Activating the ability whilst holding a Shockrifle will refund half of the ammo as Ability Charge.\n"
                "Alt-fire will restore AP for allies hit by the beams.\n"
                "Type in console: Bind mouse3 \"say UseAbility\" to use your Class Ability.\n";

        case PlayerClass::CLASS_CLOAKER:
            return
                "{Cloak}.\n"
                "Activating Cloak will grant invisibility.\n"
                "More skills can be unlocked to add extra effects to this ability.\n"
                "Type skills to spend skillpoints.\n"
                "Type in console: Bind mouse3 \"say UseAbility\" to use your Class Ability.\n";


        case PlayerClass::CLASS_VANQUISHER:
            return
                "{Dragon's Breath Ammo}.\n\n"
                "Dragon's Breath rounds, which grant added explosive damage to non-throwable weapons.\n"
                "Activating the ability will consume all charge and add more rounds to the ammo pool.\n"
                "Shots consume a number of rounds and multiply damage based on the ammo type used.\n"
                "More skills can be unlocked to add extra effects to this ability.\n"
                "Type skills to spend skillpoints.\n"
                "Type in console: Bind mouse3 \"say UseAbility\" to use your Class Ability.\n";

        case PlayerClass::CLASS_SWARMER:
            return
                "{Super Snark Swarm}.\n\n"
                "Release a small swarm of supercharged Snarks at high velocity to attack enemies.\n"
                "Supercharged Snarks are larger and have increased health and damage.\n"
                "More skills can be unlocked to add extra effects to this ability.\n"
                "Type skills to spend skillpoints.\n"
                "Type in console: Bind mouse3 \"say UseAbility\" to use your Class Ability.\n";

        default:
            return
                "No class is selected.\n\n"
                "Type 'class' in chat to select one.\n"
                "Type in console: Bind mouse3 \"say UseAbility\" to use your Class Ability.\n";
    }
}
