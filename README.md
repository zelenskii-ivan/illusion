# IllUsion VPN

Современный, быстрый и приватный VPN на базе протокола **WireGuard**.
Нативные клиенты для **iOS** (SwiftUI + NetworkExtension) и **Windows** (.NET 8 + WinUI 3),
а также лёгкий backend для списка серверов, аутентификации и измерения задержек.

> Статус: ранняя стадия разработки (scaffolding). Туннель на iOS/Windows подключается
> через официальные компоненты WireGuard; бизнес-логика и UI готовы к доработке.

## Возможности

- ⚡️ **WireGuard** — современный протокол, минимальная задержка и высокая скорость.
- 🛡️ **Kill Switch** — блокировка трафика при разрыве туннеля.
- 🎯 **Split Tunneling** — выбор приложений/маршрутов в обход VPN.
- 🌐 **Multi-hop (Double VPN)** — цепочка из двух серверов для дополнительной приватности.
- 🥷 **Обфускация (анти-DPI)** — маскировка WireGuard-трафика.
- 📶 **Авто-подключение** на недоверенных Wi‑Fi сетях.
- 🚀 **Умный выбор сервера** по самой низкой задержке (ping).
- 🔒 **Always-On** — постоянная защита.
- 🧱 **Кастомный DNS + блокировка рекламы/трекеров**.

## Структура репозитория

```
IllUsion/
├── apple/          # iOS / macOS клиент (SwiftUI, NetworkExtension)
├── windows/        # Windows клиент (.NET 8, WinUI 3)
├── backend/        # API серверов, auth, latency (Node.js)
├── shared/         # Общие схемы данных и контракты API
└── docs/           # Архитектура и описание функций
```

## Быстрый старт

### Backend (мок API)
```bash
cd backend
npm install
npm run dev
# API на http://localhost:8787
```

### iOS / macOS
Откройте `apple/` в Xcode 15+. Требуется аккаунт разработчика Apple
с правом на NetworkExtension (Personal VPN / Packet Tunnel).

### Windows
Откройте `windows/IllUsionVPN.sln` в Visual Studio 2022 (.NET 8, Windows App SDK).

Подробнее — в [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Лицензия
WireGuard — зарегистрированная торговая марка Jason A. Donenfeld.
Этот проект использует WireGuard как протокол.
