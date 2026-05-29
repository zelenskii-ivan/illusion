using System.Collections.Generic;
using System.IO;
using System.Text.Json;

namespace IllUsionVPN.Models;

public sealed class AppSettings
{
    public bool KillSwitch { get; set; } = true;
    public bool AlwaysOn { get; set; } = false;
    public bool AutoConnectUntrustedWiFi { get; set; } = false;
    public bool MultihopEnabled { get; set; } = false;
    public bool ObfuscationEnabled { get; set; } = false;
    public bool BlockAdsAndTrackers { get; set; } = true;
    public string CustomDns { get; set; } = "";
    public List<string> SplitTunnelExcludedApps { get; set; } = new();
    public int PreferredMtu { get; set; } = 1420;

    private static string FilePath
    {
        get
        {
            var dir = Path.Combine(
                System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData),
                "IllUsionVPN");
            Directory.CreateDirectory(dir);
            return Path.Combine(dir, "settings.json");
        }
    }

    public static AppSettings Load()
    {
        try
        {
            if (File.Exists(FilePath))
                return JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(FilePath)) ?? new AppSettings();
        }
        catch { /* ignore corrupt settings */ }
        return new AppSettings();
    }

    public void Save()
    {
        File.WriteAllText(FilePath, JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true }));
    }
}
