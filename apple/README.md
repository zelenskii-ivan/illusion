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

## Live Activity
Виджет-расширение `IllUsionWidget` показывает статус подключения и таймер
сессии на экране блокировки и в Dynamic Island. Атрибуты общие
(`Shared/VPNActivityAttributes.swift`), управление — `LiveActivityController`,
вызывается из `TunnelManager` при смене состояния. Требуется iOS 16.1+
и `NSSupportsLiveActivities` (уже задан в `project.yml`).

## Fastlane (CI / TestFlight)
```bash
cd apple
bundle install
bundle exec fastlane test     # тесты на симуляторе
bundle exec fastlane beta     # сборка + загрузка в TestFlight
```
Перед `beta` задайте переменные окружения: `FASTLANE_APPLE_ID`,
`FASTLANE_TEAM_ID`, ключ App Store Connect API
(`APP_STORE_CONNECT_API_KEY_ID/ISSUER_ID/KEY`), а также `MATCH_GIT_URL`
и `MATCH_PASSWORD` для подписей через `match`.

## Доступность
Ключевые контролы (кнопка подключения, переключатели, строки серверов,
статус, статистика) имеют VoiceOver labels/values/hints. Текст использует
системные стили шрифтов и масштабируется через Dynamic Type.

## Примечания
- Backend по умолчанию — Debug `http://localhost:8787`, Release
  `https://api.illusion.vpn` (см. `AppConfig`, build setting `ILLUSION_API_BASE_URL`).
- Приватные ключи WireGuard генерируются на устройстве (`WireGuardKeys`),
  на сервер уходит только публичный ключ.
