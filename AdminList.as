const string CARPG_ADMIN_LIST_PATH = "scripts/plugins/store/admins.txt";

array<string> g_AdminList;

void WriteDefaultAdminList(File@ file)
{
    if(file is null || !file.IsOpen())
        return;

    file.Write("# One SteamID per line. These entries preserve the original CARPG admins.\n");
    file.Write("STEAM_0:1:21530096\n");
    file.Write("STEAM_0:0:2883221\n");
    file.Close();
}

void LoadAdminList()
{
    g_AdminList.resize(0);

    File@ file = g_FileSystem.OpenFile(CARPG_ADMIN_LIST_PATH, OpenFile::READ);
    if(file is null || !file.IsOpen())
    {
        @file = g_FileSystem.OpenFile(CARPG_ADMIN_LIST_PATH, OpenFile::WRITE);
        WriteDefaultAdminList(file);
        @file = g_FileSystem.OpenFile(CARPG_ADMIN_LIST_PATH, OpenFile::READ);
    }

    if(file is null || !file.IsOpen())
    {
        g_Game.AlertMessage(at_console, "CARPG: Could not load admin list from " + CARPG_ADMIN_LIST_PATH + "\n");
        return;
    }

    while(!file.EOFReached())
    {
        string steamID;
        file.ReadLine(steamID);
        if(steamID.IsEmpty() || steamID.SubString(0, 1) == "#" || IsAdmin(steamID))
            continue;
        g_AdminList.insertLast(steamID);
    }

    file.Close();
}

void SaveAdminList()
{
    File@ file = g_FileSystem.OpenFile(CARPG_ADMIN_LIST_PATH, OpenFile::WRITE);
    if(file is null || !file.IsOpen())
    {
        g_Game.AlertMessage(at_console, "CARPG: Could not save admin list to " + CARPG_ADMIN_LIST_PATH + "\n");
        return;
    }

    file.Write("# One SteamID per line.\n");
    for(uint i = 0; i < g_AdminList.length(); ++i)
        file.Write(g_AdminList[i] + "\n");
    file.Close();
}

bool IsAdmin(const string& in steamID)
{
    if(steamID.IsEmpty())
        return false;

    for(uint i = 0; i < g_AdminList.length(); ++i)
    {
        if(steamID == g_AdminList[i])
            return true;
    }
    return false;
}

bool AddAdmin(const string& in steamID)
{
    if(steamID.IsEmpty() || IsAdmin(steamID))
        return false;

    g_AdminList.insertLast(steamID);
    SaveAdminList();
    return true;
}

bool RemoveAdmin(const string& in steamID)
{
    if(g_AdminList.length() <= 1)
        return false;

    for(uint i = 0; i < g_AdminList.length(); ++i)
    {
        if(g_AdminList[i] == steamID)
        {
            g_AdminList.removeAt(i);
            SaveAdminList();
            return true;
        }
    }
    return false;
}