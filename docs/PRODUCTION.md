# Production Checklist — IllUsion VPN (iOS)

Что уже сделано в коде и что осталось до релиза в App Store.

## ✅ Сделано (клиент iOS)

- [x] Конфигурация окружений (`AppConfig`): разные backend для Debug/Release
      через build setting `ILLUSION_API_BASE_URL`.
- [x] Безопасное хранение токена в **Keychain** (`KeychainStore`) вместо UserDefaults.
- [x] Аутентификация: экран входа (`LoginView`), `AuthService`, гейтинг,
      восстановление сессии, выход из аккаунта.
- [x] Сетевой слой: таймауты, повторы с экспоненциальной задержкой,
      типизированные ошибки, обработка 401 (сброс сессии).
- [x] Логирование через `os.Logger` (без утечки секретов).
- [x] **PrivacyInfo.xcprivacy** (обязательно для App Store): tracking = false,
      объявлены Required Reason API (UserDefaults).
- [x] App Transport Security: прод — только HTTPS, localhost разрешён для разработки.
- [x] Статистика трафика (rx/tx) из расширения через `handleAppMessage`.
- [x] Релизные настройки сборки (whole-module optimization, `-O`).
- [x] Юнит-тесты ключевой логики (конфиг сессии, статистика, настройки).
- [x] Демо-режим для симулятора (UI без реального туннеля).

## ⏳ Осталось: клиент

- [ ] **X25519 для ключей**: сейчас `WireGuardKeys` использует CryptoKit Curve25519.
      Проверить полную совместимость публичного ключа с форматом WireGuard
      (рекомендуется свериться с `Curve25519.KeyAgreement` ↔ wg base64).
- [ ] Хранить приватный ключ WireGuard в Keychain App Group, а расширению
      передавать ссылку, а не сам ключ в `providerConfiguration`.
- [ ] Split tunneling по приложениям (только MDM/managed) или по доменам.
- [ ] Реальная обфускация-транспорт (обёртка поверх WireGuard).
- [ ] Локализация (RU/EN), Dynamic Type, VoiceOver.
- [ ] Иконка приложения (1024×1024) и Launch Screen-брендинг.
- [ ] Онбординг и экран подписки (StoreKit 2).
- [ ] Push-уведомления о статусе/истечении подписки (опц.).

## 🔧 Осталось: backend / инфраструктура

- [ ] Реальные WireGuard-узлы; выдача **эфемерных пиров** на сессию,
      ротация ключей, лимиты по тарифу.
- [ ] Координация multi-hop (вход → выход) на стороне сервера.
- [ ] HTTPS с валидным сертификатом на `api.illusion.vpn` (+ опц. SSL pinning).
- [ ] Реальная авторизация (OAuth/Email magic link), refresh-токены.
- [ ] Биллинг и валидация покупок (App Store Server Notifications v2).
- [ ] Мониторинг, алерты, rate limiting, защита от абьюза.
- [ ] No-logs политика на узлах (только метаданные для биллинга).

## 📦 Релиз в App Store

- [ ] Платный Apple Developer Program + App ID с **Network Extensions** capability.
- [ ] Provisioning profiles для app и extension (один Team ID).
- [ ] App Privacy «Nutrition Label» в App Store Connect.
- [ ] **Export Compliance**: VPN использует шифрование → подготовить
      самоклассификацию/CCATS или соответствующее заявление
      (`ITSAppUsesNonExemptEncryption`).
- [ ] Юридические документы: Политика конфиденциальности и Условия использования
      (обязательны для VPN-приложений; ссылки в приложении и в App Store).
- [ ] Возрастной рейтинг, описание, скриншоты, ключевые слова.
- [ ] Соответствие гайдлайнам Apple §5.4 (VPN-приложения).

## CI/CD (рекомендация)

- [ ] GitHub Actions: `xcodegen generate` → `xcodebuild test` на PR.
- [ ] Fastlane: `match` (подписи), `gym` (сборка), `pilot` (TestFlight).
- [ ] Версионирование: bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`.
