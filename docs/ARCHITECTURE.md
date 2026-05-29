# Архитектура IllUsion VPN

## Обзор

```
┌──────────────┐     HTTPS      ┌──────────────┐
│  iOS client  │ ─────────────► │              │
│ (SwiftUI +   │                │   Backend    │
│  NE Tunnel)  │                │  (server list│
└──────┬───────┘                │   auth, ping)│
       │ WireGuard (UDP 51820)  └──────┬───────┘
       │                               │
┌──────┴───────┐     HTTPS             │ provisions
│  Windows     │ ─────────────────────►│
│  client      │                       ▼
│ (WinUI 3 +   │              ┌──────────────────┐
│  WG service) │ ───WG UDP──► │  WireGuard nodes │
└──────────────┘              │  (multi-hop)     │
                              └──────────────────┘
```

## Компоненты

### 1. Backend (`backend/`)
- Node.js (Express). На старте — мок-данные.
- Эндпоинты:
  - `GET  /api/servers` — список серверов (страна, город, нагрузка, флаги функций).
  - `POST /api/auth/login` — аутентификация (JWT, заглушка).
  - `POST /api/session` — выдача WireGuard-конфига для выбранного сервера.
  - `GET  /api/ping-targets` — адреса для замера задержки на клиенте.
- В проде: выдача эфемерных пиров (короткоживущие ключи), биллинг/подписки,
  координация multi-hop (вход → выход).

### 2. Общие контракты (`shared/`)
- `schema/server.json` — JSON Schema модели сервера.
- `schema/session.json` — JSON Schema туннельной сессии (конфиг WireGuard).
- Клиенты iOS/Windows реализуют эти модели нативно (Codable / record).

### 3. iOS / macOS (`apple/`)
- **App target** (SwiftUI): UI, состояние, общение с backend, управление через
  `NETunnelProviderManager`.
- **PacketTunnel extension**: `NEPacketTunnelProvider` + WireGuardKit поднимает
  туннель. Конфиг передаётся через `providerConfiguration`.
- Продвинутые функции:
  - Kill Switch → `includeAllNetworks` + `NEOnDemandRule`.
  - On-demand (авто-Wi‑Fi) → `NEOnDemandRuleConnect` с `ssidMatch`.
  - Split tunnel → `excludedRoutes` / `includedRoutes`.
  - DNS / ad-block → `NEDNSSettings` + список заблокированных доменов.

### 4. Windows (`windows/`)
- **WinUI 3** приложение (UI + ViewModels, MVVM).
- **Tunnel service**: интеграция с `tunnel.dll` из WireGuard для Windows
  (встраиваемый туннель как Windows-сервис).
- Kill Switch через WFP (Windows Filtering Platform), которое WireGuard
  включает флагом конфигурации.

## Поток подключения

1. Клиент логинится (`/api/auth/login`) → JWT.
2. Загружает серверы (`/api/servers`), меряет ping локально.
3. Пользователь жмёт Connect → клиент запрашивает `/api/session` с `serverId`
   (и `exitServerId` для multi-hop).
4. Backend возвращает WireGuard-конфиг (interface + peer(s)).
5. Клиент сохраняет конфиг в системный VPN-профиль и поднимает туннель.

## Безопасность
- Приватные ключи WireGuard генерируются на устройстве; backend хранит только публичные.
- Эфемерные ключи на сессию, ротация при переподключении.
- Нет логов трафика; журналируется только метаинформация для биллинга.
