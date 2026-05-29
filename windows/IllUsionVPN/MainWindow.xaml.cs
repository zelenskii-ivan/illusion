using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using IllUsionVPN.Views;

namespace IllUsionVPN;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        ExtendsContentIntoTitleBar = true;
        ContentFrame.Navigate(typeof(HomePage));
    }

    private void Nav_SelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        if (args.SelectedItem is not NavigationViewItem item) return;
        switch (item.Tag as string)
        {
            case "home": ContentFrame.Navigate(typeof(HomePage)); break;
            case "servers": ContentFrame.Navigate(typeof(ServersPage)); break;
            case "settings": ContentFrame.Navigate(typeof(SettingsPage)); break;
        }
    }
}
