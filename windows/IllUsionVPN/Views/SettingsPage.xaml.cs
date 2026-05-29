using Microsoft.UI.Xaml.Controls;
using IllUsionVPN.Models;
using IllUsionVPN.ViewModels;

namespace IllUsionVPN.Views;

public sealed partial class SettingsPage : Page
{
    private AppSettings Settings => App.ViewModel.Settings;
    private bool _loaded;

    public SettingsPage()
    {
        InitializeComponent();
        Loaded += (_, _) =>
        {
            KillSwitch.IsOn = Settings.KillSwitch;
            AlwaysOn.IsOn = Settings.AlwaysOn;
            AutoWifi.IsOn = Settings.AutoConnectUntrustedWiFi;
            Multihop.IsOn = Settings.MultihopEnabled;
            Obfuscation.IsOn = Settings.ObfuscationEnabled;
            AdBlock.IsOn = Settings.BlockAdsAndTrackers;
            CustomDns.Text = Settings.CustomDns;
            _loaded = true;
        };
    }

    private void OnToggle(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
    {
        if (!_loaded) return;
        Settings.KillSwitch = KillSwitch.IsOn;
        Settings.AlwaysOn = AlwaysOn.IsOn;
        Settings.AutoConnectUntrustedWiFi = AutoWifi.IsOn;
        Settings.MultihopEnabled = Multihop.IsOn;
        Settings.ObfuscationEnabled = Obfuscation.IsOn;
        Settings.BlockAdsAndTrackers = AdBlock.IsOn;
        Settings.Save();
    }

    private void OnDnsChanged(object sender, TextChangedEventArgs e)
    {
        if (!_loaded) return;
        Settings.CustomDns = CustomDns.Text;
        Settings.Save();
    }
}
