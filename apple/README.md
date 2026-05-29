# IllUsion VPN — iOS / macOS клиент

SwiftUI + NetworkExtension (Packet Tunnel) + WireGuardKit.

## Сборка

Проект генерируется через [XcodeGen](https://github.com/yonaskolb/XcodeGen)
из `project.yml` (так его удобно держать в git без бинарного `.pbxproj`).

```bash
brew install xcodegen
cd apple
xcodegen generate
open IllUsionVPN.xcodeproj
```

### Вариант A — быстрый запуск UI в симуляторе (демо-режим) ✅
По умолчанию приложение собирается **без расширения-туннеля**, поэтому
запускается в любом iOS-симуляторе без Apple Developer аккаунта:

1. `xcodegen generate && open IllUsionVPN.xcodeproj`
2. Выберите схему **IllUsionVPN** и любой симулятор → ⌘R.

В симуляторе автоматически включается **демо-режим** (`AppEnvironment.isDemoMode`):
- список серверов берётся из `Resources/bundledServers.json` (backend не нужен);
- кнопка подключения имитирует полный цикл connect/disconnect;
- все экраны и настройки работают.

Демо-режим можно принудительно включить и на устройстве переменной
окружения схемы `ILLUSION_DEMO=1`.

### Вариант B — реальный WireGuard-туннель (устройство)
1. В `project.yml` раскомментируйте зависимость
   `IllUsionVPN → dependencies: - target: PacketTunnelProvider`.
2. Укажите свой **Team ID** (`settings.base.DEVELOPMENT_TEAM`).
3. Включите capability **Network Extensions → Packet Tunnel** и **App Groups**
   (`group.com.illusion.vpn`) для обоих таргетов.
4. `xcodegen generate` и запустите на реальном устройстве
   (NetworkExtension не работает в симуляторе).

## Структура

```
apple/
├── project.yml                  # описание проекта для XcodeGen
├── IllUsionVPN/                 # основное приложение
│   ├── IllUsionVPNApp.swift      # точка входа
│   ├── Models/                   # Server, Session, AppSettings, ConnectionState
│   ├── Services/                 # APIClient, TunnelManager, LatencyProbe, WireGuardKeys, AppEnvironment
│   ├── ViewModels/AppViewModel.swift
│   ├── Design/Theme.swift        # дизайн-система
│   ├── Resources/                # bundledServers.json, Assets.xcassets, PrivacyInfo.xcprivacy
│   └── Views/                    # SwiftUI экраны (вкл. LoginView)
├── IllUsionVPNTests/            # юнит-тесты (Session, TunnelStats, Settings)
└── PacketTunnelProvider/        # расширение туннеля (WireGuardKit)
```

## Примечания
- Backend по умолчанию — `http://localhost:8787` (см. `APIClient.baseURL`).
  Для устройства замените на доступный по сети адрес/домен.
- Приватные ключи WireGuard генерируются на устройстве (`WireGuardKeys`),
  на сервер уходит только публичный ключ.
