# Передовые функции IllUsion VPN

| Функция | Что делает | iOS | Windows | Где в коде |
|---|---|---|---|---|
| **WireGuard** | Современный быстрый протокол | ✅ | ✅ | `Session.wgQuickConfig` / `Session.ToWgQuickConfig` |
| **Kill Switch** | Блокирует трафик при разрыве туннеля | ✅ `includeAllNetworks` | ✅ WFP | `TunnelManager` / `TunnelService` |
| **Split Tunneling** | Исключение приложений/маршрутов из VPN | ✅ `excludedRoutes` | ✅ AllowedIPs | `AppSettings.splitTunnelExcludedApps` |
| **Multi-hop** | Маршрут через 2 сервера | ✅ | ✅ | `AppViewModel.connect` (exitServer) |
| **Обфускация** | Маскировка трафика (анти-DPI) | ✅ | ✅ | `AppSettings.obfuscationEnabled` |
| **Авто-Wi-Fi** | Включение на недоверенных сетях | ✅ on-demand | ✅ | `buildOnDemandRules` |
| **Умный сервер** | Авто-выбор по наименьшему пингу | ✅ | ✅ | `LatencyProbe` + `selectFastestServer` |
| **Always-On** | Постоянная защита | ✅ | ✅ | `AppSettings.alwaysOn` |
| **DNS / Ad-block** | Кастомный DNS и блокировка трекеров | ✅ | ✅ | `AppSettings.customDNS / blockAds` |

## Что нужно доделать до продакшена

1. **Реальные WireGuard-узлы** и выдача эфемерных пиров на backend
   (сейчас `POST /api/session` возвращает мок-ключи).
2. **Windows: X25519** — заменить заглушку в `WireGuardKeys.cs` на `NSec`/libsodium.
3. **Windows: установка туннеля** через `wireguard.dll` (`InstallTunnel`)
   с UAC-повышением прав.
4. **iOS: split tunnel по приложениям** доступен только в managed-конфигурациях
   (MDM); для App Store — split по маршрутам/доменам.
5. **Обфускация**: интеграция транспорта (например, обёртка поверх WireGuard).
6. **Авторизация и подписки** (StoreKit / Microsoft Store).
7. Иконки, локализация, аналитика (без логов трафика).

## Принципы приватности
- Приватные ключи генерируются на устройстве, не покидают его.
- Эфемерные ключи на сессию с ротацией.
- No-logs: журналируется только метаинформация для биллинга.
