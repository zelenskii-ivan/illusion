using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using IllUsionVPN.Models;
using IllUsionVPN.ViewModels;

namespace IllUsionVPN.Views;

public sealed partial class HomePage : Page
{
    private MainViewModel Vm => App.ViewModel;

    public HomePage()
    {
        InitializeComponent();
        Vm.PropertyChanged += (_, _) => DispatcherQueue.TryEnqueue(Render);
        Loaded += async (_, _) =>
        {
            Render();
            await Vm.BootstrapAsync();
        };
    }

    private async void ConnectButton_Click(object sender, RoutedEventArgs e)
    {
        await Vm.ToggleConnectionAsync();
    }

    private void Render()
    {
        StatusText.Text = Vm.Status.Title();
        ConnectLabel.Text = Vm.Status == ConnectionStatus.Connected ? "Отключить" : "Подключить";
        StatusDot.Fill = new SolidColorBrush(Vm.Status switch
        {
            ConnectionStatus.Connected => Colors.LimeGreen,
            ConnectionStatus.Connecting or ConnectionStatus.Disconnecting => Colors.Orange,
            ConnectionStatus.Failed => Colors.OrangeRed,
            _ => Colors.Gray
        });

        if (Vm.SelectedServer is { } s)
        {
            ServerFlag.Text = s.Flag ?? "🌐";
            ServerCity.Text = s.City;
            ServerCountry.Text = s.Country;
            ServerLatency.Text = s.LatencyLabel;
        }
    }
}
