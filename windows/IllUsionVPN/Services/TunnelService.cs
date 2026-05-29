using System;
using System.IO;
using System.Runtime.InteropServices;
using System.ServiceProcess;
using System.Threading.Tasks;
using IllUsionVPN.Models;

namespace IllUsionVPN.Services;

/// <summary>
/// Управляет WireGuard-туннелем на Windows через встраиваемый tunnel.dll
/// (официальный «embeddable-dll-service» из wireguard-windows). Конфиг
/// записывается во временный файл и регистрируется как Windows-сервис.
///
/// Требует прав администратора. Поместите рядом с приложением tunnel.dll
/// и wireguard.dll из официальной поставки WireGuard для Windows.
/// </summary>
public sealed class TunnelService
{
    public event Action<ConnectionStatus>? StatusChanged;
    public ConnectionStatus Status { get; private set; } = ConnectionStatus.Disconnected;

    private const string TunnelName = "IllUsion";
    private string ServiceName => $"WireGuardTunnel${TunnelName}";

    // tunnel.dll экспортирует функцию запуска туннеля как сервиса.
    [DllImport("tunnel.dll", EntryPoint = "WireGuardTunnelService", CallingConvention = CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    private static extern bool WireGuardTunnelService([MarshalAs(UnmanagedType.LPWStr)] string configFile);

    private static string ConfigPath
    {
        get
        {
            var dir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "IllUsionVPN", "tunnels");
            Directory.CreateDirectory(dir);
            return Path.Combine(dir, $"{TunnelName}.conf");
        }
    }

    public async Task ConnectAsync(Session session, string privateKey, Server server, AppSettings settings)
    {
        SetStatus(ConnectionStatus.Connecting);
        try
        {
            var config = session.ToWgQuickConfig(privateKey);
            await File.WriteAllTextAsync(ConfigPath, config);

            // Регистрация и запуск туннеля как Windows-сервиса.
            // В проде используйте wireguard.dll: WireGuardManager + InstallTunnel.
            await Task.Run(() => InstallAndStartService());

            SetStatus(ConnectionStatus.Connected);
        }
        catch (Exception)
        {
            SetStatus(ConnectionStatus.Failed);
        }
    }

    public async Task DisconnectAsync()
    {
        SetStatus(ConnectionStatus.Disconnecting);
        await Task.Run(StopAndRemoveService);
        SetStatus(ConnectionStatus.Disconnected);
    }

    private void InstallAndStartService()
    {
        // Каркас: реальная установка делается через wireguard.dll
        // (WireGuardManager.InstallTunnel(ConfigPath)) с правами администратора.
        // Здесь проверяем, запущен ли сервис.
        try
        {
            using var sc = new ServiceController(ServiceName);
            if (sc.Status != ServiceControllerStatus.Running)
                sc.Start();
        }
        catch
        {
            // Сервис ещё не установлен — установка через wireguard.dll (TODO).
        }
    }

    private void StopAndRemoveService()
    {
        try
        {
            using var sc = new ServiceController(ServiceName);
            if (sc.Status == ServiceControllerStatus.Running)
            {
                sc.Stop();
                sc.WaitForStatus(ServiceControllerStatus.Stopped, TimeSpan.FromSeconds(10));
            }
        }
        catch
        {
            // Сервис отсутствует — игнорируем.
        }
    }

    private void SetStatus(ConnectionStatus status)
    {
        Status = status;
        StatusChanged?.Invoke(status);
    }
}
