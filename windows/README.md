# IllUsion VPN — Windows клиент

.NET 8 + WinUI 3 (Windows App SDK) + WireGuard (`tunnel.dll`).

## Требования
- Windows 10 (1809+) или Windows 11
- Visual Studio 2022 с workload **.NET Desktop** и **Windows App SDK**
- .NET 8 SDK

## Сборка и запуск
```powershell
cd windows
dotnet restore
dotnet build -c Debug
# или откройте IllUsionVPN.sln в Visual Studio 2022 и нажмите F5
```

> Приложение запускается в режиме **unpackaged** (без MSIX) для удобства разработки.

## WireGuard-туннель
Для реального туннеля положите рядом с исполняемым файлом официальные
`tunnel.dll` и `wireguard.dll` из [wireguard-windows](https://git.zx2c4.com/wireguard-windows/about/).
Управление туннелем выполняется через Windows-сервис и требует прав администратора.
См. `Services/TunnelService.cs`.

> Для корректной генерации ключей WireGuard (X25519) в проде подключите
> `NSec.Cryptography` или обвязку libsodium вместо заглушки в `Services/WireGuardKeys.cs`.

## Структура
```
windows/IllUsionVPN/
├── App.xaml(.cs)            # вход, общая MainViewModel
├── MainWindow.xaml(.cs)     # NavigationView + Frame
├── Models/                  # Server, Session, AppSettings, ConnectionState
├── Services/                # ApiClient, TunnelService, LatencyProbe, WireGuardKeys
├── ViewModels/MainViewModel.cs
└── Views/                   # HomePage, ServersPage, SettingsPage
```
