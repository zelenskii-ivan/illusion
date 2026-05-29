namespace IllUsionVPN.Models;

public enum ConnectionStatus
{
    Disconnected,
    Connecting,
    Connected,
    Disconnecting,
    Failed
}

public static class ConnectionStatusExtensions
{
    public static string Title(this ConnectionStatus s) => s switch
    {
        ConnectionStatus.Disconnected => "Не защищено",
        ConnectionStatus.Connecting => "Подключение…",
        ConnectionStatus.Connected => "Защищено",
        ConnectionStatus.Disconnecting => "Отключение…",
        ConnectionStatus.Failed => "Ошибка",
        _ => ""
    };

    public static bool IsBusy(this ConnectionStatus s) =>
        s is ConnectionStatus.Connecting or ConnectionStatus.Disconnecting;
}
