using Microsoft.UI.Xaml;
using IllUsionVPN.ViewModels;

namespace IllUsionVPN;

public partial class App : Application
{
    private Window? _window;

    /// <summary>Общая вью-модель приложения, доступна всем страницам.</summary>
    public static MainViewModel ViewModel { get; } = new();

    public App()
    {
        InitializeComponent();
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        _window = new MainWindow();
        _window.Activate();
    }
}
