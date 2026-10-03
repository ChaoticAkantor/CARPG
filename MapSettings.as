const string CARPG_MAP_SETTINGS_PATH = "scripts/plugins/store/map_settings.txt";

enum CARPGMapMode
{
    CARPG_MAP_NO_CHANGE = 0,
    CARPG_MAP_BALANCED = 1,
    CARPG_MAP_DISABLED = 2
}

class CARPGMapRule
{
    string pattern;
    int mode;
    float ammoMultiplier;
    float hpRecoveryMultiplier;
    float apRecoveryMultiplier;
    float hurtDelayMultiplier;

    CARPGMapRule(const string& in mapPattern, int mapMode, float ammoMultiplierValue,
        float hpMultiplierValue, float apMultiplierValue, float hurtMultiplierValue)
    {
        pattern = mapPattern;
        mode = mapMode;
        ammoMultiplier = ammoMultiplierValue;
        hpRecoveryMultiplier = hpMultiplierValue;
        apRecoveryMultiplier = apMultiplierValue;
        hurtDelayMultiplier = hurtMultiplierValue;
    }
}

array<CARPGMapRule@> g_CARPGMapRules;
string g_szCARPGMapName;
string g_szCARPGMatchedMapPattern;
int g_iCARPGCurrentMapMode = CARPG_MAP_NO_CHANGE;
float g_flCARPGAmmoMultiplier = 1.0f;
float g_flCARPGHPRecoveryMultiplier = 1.0f;
float g_flCARPGAPRecoveryMultiplier = 1.0f;
float g_flCARPGHurtDelayMultiplier = 1.0f;

void WriteDefaultCARPGMapSettings(File@ file)
{
    if(file is null || !file.IsOpen())
        return;

    file.Write("# CARPG Map Rules: ammoMultiplier, hpRecoveryMultiplier, apRecoveryMultiplier, hurtDelayMultiplier\n");
    file.Write("# Modes: 0 = No change, 1 = Applies balance settings, 2 = Disable CARPG on map.\n");
    file.Write("# Prefix rules end in _. Exact map overrides start with =, e.g. =hl_c00a.\n");
    file.Write("th_ 1 10 2 2 3\n");
    file.Write("aom_ 1 10 2 2 3\n");
    file.Write("aomdc_ 1 10 2 2 3\n");
    file.Write("hl_ 1 2 1.2 1.2 1\n");
    file.Write("of_ 1 2 1.2 1.2 1\n");
    file.Write("bs_ 1 2 1.2 1.2 1\n");
    file.Close();
}

void LoadCARPGMapSettings()
{
    g_CARPGMapRules.resize(0);

    File@ file = g_FileSystem.OpenFile(CARPG_MAP_SETTINGS_PATH, OpenFile::READ);
    if(file is null || !file.IsOpen())
    {
        @file = g_FileSystem.OpenFile(CARPG_MAP_SETTINGS_PATH, OpenFile::WRITE);
        WriteDefaultCARPGMapSettings(file);
        @file = g_FileSystem.OpenFile(CARPG_MAP_SETTINGS_PATH, OpenFile::READ);
    }

    if(file !is null && file.IsOpen())
    {
        while(!file.EOFReached())
        {
            string line;
            file.ReadLine(line);
            if(line.IsEmpty() || line.SubString(0, 1) == "#")
                continue;

            array<string>@ fields = line.Split(" ");
            if(fields.length() < 6)
                continue;

            string pattern = fields[0].ToLowercase();
            int mode = atoi(fields[1]);
            if(pattern.IsEmpty() || mode < CARPG_MAP_NO_CHANGE || mode > CARPG_MAP_DISABLED)
                continue;

            bool isExact = pattern.StartsWith("=");
            string mapPattern = isExact ? pattern.SubString(1) : pattern;
            if(mapPattern.IsEmpty())
                continue;

            CARPGMapRule@ rule = CARPGMapRule(isExact ? "=" + mapPattern : mapPattern, mode,
                atof(fields[2]), atof(fields[3]), atof(fields[4]), atof(fields[5]));
            g_CARPGMapRules.insertLast(rule);
        }
        file.Close();
    }
    else
    {
        g_Game.AlertMessage(at_console, "CARPG: Could not open map settings file " + CARPG_MAP_SETTINGS_PATH + "\n");
    }

    RefreshCurrentCARPGMapSettings();
}

void RefreshCurrentCARPGMapSettings()
{
    g_szCARPGMapName = string(g_Engine.mapname).ToLowercase();
    g_szCARPGMatchedMapPattern = "";
    g_iCARPGCurrentMapMode = CARPG_MAP_NO_CHANGE;
    g_flCARPGAmmoMultiplier = 1.0f;
    g_flCARPGHPRecoveryMultiplier = 1.0f;
    g_flCARPGAPRecoveryMultiplier = 1.0f;
    g_flCARPGHurtDelayMultiplier = 1.0f;

    int bestSpecificity = -1;
    for(uint i = 0; i < g_CARPGMapRules.length(); ++i)
    {
        CARPGMapRule@ rule = g_CARPGMapRules[i];
        if(rule is null)
            continue;

        bool isExact = rule.pattern.StartsWith("=");
        string mapPattern = isExact ? rule.pattern.SubString(1) : rule.pattern;
        if(isExact && g_szCARPGMapName != mapPattern)
            continue;
        if(!isExact && (g_szCARPGMapName.Length() < mapPattern.Length()
            || g_szCARPGMapName.SubString(0, mapPattern.Length()) != mapPattern))
            continue;

        int specificity = mapPattern.Length();
        if(isExact)
            specificity += 10000;

        if(specificity <= bestSpecificity)
            continue;

        bestSpecificity = specificity;
        g_szCARPGMatchedMapPattern = mapPattern;
        g_iCARPGCurrentMapMode = rule.mode;
        g_flCARPGAmmoMultiplier = rule.ammoMultiplier;
        g_flCARPGHPRecoveryMultiplier = rule.hpRecoveryMultiplier;
        g_flCARPGAPRecoveryMultiplier = rule.apRecoveryMultiplier;
        g_flCARPGHurtDelayMultiplier = rule.hurtDelayMultiplier;
    }
}

bool IsCARPGDisabledOnCurrentMap()
{
    return g_iCARPGCurrentMapMode == CARPG_MAP_DISABLED;
}

string GetCARPGMapModeName(int mode)
{
    if(mode == CARPG_MAP_BALANCED) return "Balanced";
    if(mode == CARPG_MAP_DISABLED) return "Disabled";
    return "No change";
}

void SaveCARPGMapSettings()
{
    File@ file = g_FileSystem.OpenFile(CARPG_MAP_SETTINGS_PATH, OpenFile::WRITE);
    if(file is null || !file.IsOpen())
    {
        g_Game.AlertMessage(at_console, "CARPG: Could not save map settings file " + CARPG_MAP_SETTINGS_PATH + "\n");
        return;
    }

    file.Write("# CARPG map rules: pattern mode ammoMultiplier hpRecoveryMultiplier apRecoveryMultiplier hurtDelayMultiplier\n");
    file.Write("# mode 0 = no balance, 1 = apply balance, 2 = disable CARPG\n");
    file.Write("# Prefix rules end in _. Exact map overrides start with =, e.g. =hl_c00a.\n");
    for(uint i = 0; i < g_CARPGMapRules.length(); ++i)
    {
        CARPGMapRule@ rule = g_CARPGMapRules[i];
        if(rule is null)
            continue;

        file.Write(rule.pattern + " " + rule.mode + " " + rule.ammoMultiplier + " "
            + rule.hpRecoveryMultiplier + " " + rule.apRecoveryMultiplier + " "
            + rule.hurtDelayMultiplier + "\n");
    }
    file.Close();
}

void SetCurrentCARPGMapMode(int mode)
{
    if(mode < CARPG_MAP_NO_CHANGE || mode > CARPG_MAP_DISABLED)
        return;

    CARPGMapRule@ exactRule = null;
    for(uint i = 0; i < g_CARPGMapRules.length(); ++i)
    {
        if(g_CARPGMapRules[i] !is null && g_CARPGMapRules[i].pattern == "=" + g_szCARPGMapName)
        {
            @exactRule = g_CARPGMapRules[i];
            break;
        }
    }

    if(exactRule is null)
    {
        CARPGMapRule@ newRule = CARPGMapRule("=" + g_szCARPGMapName, mode, g_flCARPGAmmoMultiplier,
            g_flCARPGHPRecoveryMultiplier, g_flCARPGAPRecoveryMultiplier, g_flCARPGHurtDelayMultiplier);
        g_CARPGMapRules.insertLast(newRule);
    }
    else
    {
        exactRule.mode = mode;
    }

    SaveCARPGMapSettings();
    RefreshCurrentCARPGMapSettings();
}