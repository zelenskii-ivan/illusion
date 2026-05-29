using Microsoft.UI.Xaml.Controls;
using IllUsionVPN.Models;
using IllUsionVPN.ViewModels;

namespace IllUsionVPN.Views;

public sealed partial class ServersPage : Page
{
    private MainViewModel Vm => App.ViewModel;

    public ServersPage()
    {
        InitializeComponent();
        Loaded += (_, _) =>
        {
            ServerList.ItemsSource = Vm.Servers;
            ServerList.SelectedItem = Vm.SelectedServer;
        };
    }

    private void ServerList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (ServerList.SelectedItem is Server s)
            Vm.SelectedServer = s;
    }

    private async void Refresh_Click(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
    {
        await Vm.RefreshServersAsync();
        ServerList.ItemsSource = Vm.Servers;
    }

    private void Fastest_Click(object sender, Microsoft.UI.Xaml.RoutedEventArgs e)
    {
        Vm.SelectFastestServer();
        ServerList.SelectedItem = Vm.SelectedServer;
    }
}
