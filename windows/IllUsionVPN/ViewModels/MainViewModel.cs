using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using IllUsionVPN.Models;
using IllUsionVPN.Services;

namespace IllUsionVPN.ViewModels;

public sealed partial class MainViewModel : ObservableObject
{
    private readonly TunnelService _tunnel = new();

    [ObservableProperty] private ObservableCollection<Server> servers = new();
    [ObservableProperty] private Server? selectedServer;
    [ObservableProperty] private Server? exitServer;
    [ObservableProperty] private ConnectionStatus status = ConnectionStatus.Disconnected;
    [ObservableProperty] private bool isLoading;
    [ObservableProperty] private string? errorMessage;

    public AppSettings Settings { get; } = AppSettings.Load();

    public MainViewModel()
    {
        _tunnel.StatusChanged += s => Status = s;
    }

    public async Task BootstrapAsync()
    {
        await LoginAsync();
        await RefreshServersAsync();
    }

    private async Task LoginAsync()
    {
        try { await ApiClient.Shared.LoginAsync("demo@illusion.vpn", "demo"); }
        catch (System.Exception e) { ErrorMessage = e.Message; }
    }

    [RelayCommand]
    public async Task RefreshServersAsync()
    {
        IsLoading = true;
        try
        {
            var fetched = await ApiClient.Shared.FetchServersAsync();
            var ranked = await LatencyProbe.RankAsync(fetched);
            Servers = new ObservableCollection<Server>(ranked);
            SelectedServer ??= ranked.FirstOrDefault();
        }
        catch (System.Exception e) { ErrorMessage = e.Message; }
        finally { IsLoading = false; }
    }

    [RelayCommand]
    public void SelectFastestServer()
    {
        SelectedServer = Servers.OrderBy(s => s.LatencyMs ?? int.MaxValue).FirstOrDefault();
    }

    [RelayCommand]
    public async Task ToggleConnectionAsync()
    {
        if (Status is ConnectionStatus.Connected or ConnectionStatus.Connecting)
            await _tunnel.DisconnectAsync();
        else
            await ConnectAsync();
    }

    private async Task ConnectAsync()
    {
        if (SelectedServer is null) { ErrorMessage = "Выберите сервер"; return; }
        try
        {
            var keys = WireGuardKeys.Generate();
            var exitId = Settings.MultihopEnabled ? ExitServer?.Id : null;
            var session = await ApiClient.Shared.CreateSessionAsync(
                SelectedServer.Id, exitId, keys.PublicKeyBase64);
            await _tunnel.ConnectAsync(session, keys.PrivateKeyBase64, SelectedServer, Settings);
        }
        catch (System.Exception e) { ErrorMessage = e.Message; }
    }

    public string StatusTitle => Status.Title();
}
