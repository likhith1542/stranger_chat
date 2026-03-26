# STRANGER — Offline P2P Anonymous Chat

<p align="center">
  <a href="https://github.com/likhith1542/stranger_chat/releases/latest">
    <img src="https://img.shields.io/github/v/release/likhith1542/stranger_chat?color=00FFB2&style=flat-square" alt="Latest Release"/>
  </a>
  <a href="https://github.com/likhith1542/stranger_chat/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/likhith1542/stranger_chat?color=FF5F87&style=flat-square" alt="License"/>
  </a>
  <img src="https://img.shields.io/badge/platform-Android-brightgreen?style=flat-square" alt="Platform"/>
  <img src="https://img.shields.io/badge/built%20with-Flutter-02569B?style=flat-square" alt="Flutter"/>
  <img src="https://img.shields.io/badge/encryption-X25519%20%2B%20AES--256--GCM-00FFB2?style=flat-square" alt="Encryption"/>
</p>

> *"What if Omegle worked without the internet?"*

**STRANGER** is a fully decentralized, serverless, anonymous chat app for Android. No accounts. No cloud. No data leaves your local network. Chat with strangers nearby using Bluetooth + WiFi Direct — no router required.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📡 **Peer Discovery** | BLE-based automatic peer discovery — no router required |
| 🔗 **Instant Connect** | Tap to connect with accept/reject flow |
| 💬 **Real-time Chat** | Low-latency messaging over WiFi Direct |
| 🔐 **E2E Encryption** | X25519 key exchange + AES-256-GCM per session |
| 🕵️ **Anonymous Mode** | Random identity on first launch (`Neon_Wolf_4821`) |
| 🔁 **Regenerate Identity** | New anonymous name with one tap |
| 🏷️ **Interest Tags** | Local-only tag matching to find similar strangers |
| 🗑️ **Auto-Delete** | Chat history wiped automatically on disconnect |
| 🚫 **Block User** | Ignore peers permanently (stored locally only) |
| 🌙 **Dark Mode** | Cyberpunk-noir UI with animated radar scanner |

---

## 📡 How It Works

```
DISCOVERY
  Both devices: startAdvertising() + startDiscovery()
  Transport: BLE (Bluetooth Low Energy) — no router needed
  Range: ~100m

       ↓ peer found

CONNECTION
  Initiator: requestConnection()
  Receiver:  Accept / Reject dialog
  Transport: WiFi Direct (~250 Mbps once connected)

       ↓ connected

ENCRYPTION (automatic, ~200ms)
  1. Both generate fresh X25519 keypair
  2. Exchange public keys over the connection
  3. ECDH → shared secret → HKDF → AES-256-GCM key
  4. Keys are ephemeral — never stored, lost on disconnect

       ↓ encrypted channel ready

CHAT
  Every message: AES-256-GCM encrypted payload
  Delivery:      Sent over WiFi Direct via Nearby Connections
  Storage:       Hive (on-device only)
  On disconnect: All messages auto-wiped from device
```

### Privacy Guarantees
- ❌ No signup, login, or account
- ❌ No cloud database, API, or external server of any kind
- ❌ No GPS or location data collected
- ✅ Messages encrypted before leaving your device
- ✅ Encryption keys are ephemeral — new keys every session
- ✅ Chat history auto-wiped on disconnect
- ✅ Block list stored locally, never reported anywhere

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) |
| P2P Transport | Google Nearby Connections API |
| Encryption | `cryptography` — X25519 + AES-256-GCM + HKDF-SHA256 |
| State Management | Riverpod 2 (StateNotifier pattern) |
| Local Storage | Hive (on-device NoSQL) |
| UI Fonts | Orbitron + Space Mono (Google Fonts) |
| Animations | flutter_animate |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0` — [install guide](https://docs.flutter.dev/get-started/install)
- Android Studio or VS Code with Flutter extension
- **Two physical Android devices** (API 21 / Android 5.0+)

> ⚠️ **Physical devices required.** Android emulators do not support real BLE or WiFi Direct. You need two real phones to test discovery and messaging.

### Clone & Run

```bash
git clone https://github.com/likhith1542/stranger_chat.git
cd stranger_chat
flutter pub get
flutter run --release
```

### Build APK

```bash
# Recommended: split by ABI (arm64, x86_64 — smaller files)
flutter build apk --release --split-per-abi

# Universal APK (single file, works on all devices)
flutter build apk --release

# Find your APKs here:
ls build/app/outputs/flutter-apk/
```

---

## 🔐 Permissions

| Permission | Why |
|------------|-----|
| `BLUETOOTH` / `BLUETOOTH_ADMIN` | BLE discovery (Android ≤11) |
| `BLUETOOTH_SCAN` / `ADVERTISE` / `CONNECT` | BLE discovery (Android 12+) |
| `ACCESS_FINE_LOCATION` | Required by Android as prerequisite for BLE scanning (≤12) |
| `NEARBY_WIFI_DEVICES` | WiFi Direct data channel (Android 13+) |
| `ACCESS_WIFI_STATE` / `CHANGE_WIFI_STATE` | WiFi Direct transport |
| `RECORD_AUDIO` | Microphone (requested, reserved for future use) |

> 📍 Location permission is **never used for GPS tracking** — Android mandates it as a system prerequisite for any BLE/WiFi scan. No coordinates are ever read or stored.

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry, Hive adapter registration
├── models/
│   ├── user_model.dart          # Peer + ConnectionStatus
│   └── message_model.dart       # Message + status/type enums
├── services/
│   ├── identity_service.dart    # Random identity generator + persistence
│   ├── p2p_service.dart         # Nearby Connections engine + packet router
│   ├── encryption_service.dart  # X25519 + AES-256-GCM session manager
│   └── storage_service.dart     # Hive message CRUD
├── providers/
│   └── app_providers.dart       # All Riverpod providers + notifiers
├── screens/
│   ├── splash_screen.dart       # Animated boot sequence + permission gate
│   ├── home_screen.dart         # Radar scan UI + peer list
│   └── chat_screen.dart         # Real-time encrypted chat
├── widgets/
│   ├── radar_scanner.dart       # Custom radar CustomPainter animation
│   ├── message_bubble.dart      # Chat bubbles with status indicators
│   ├── peer_card.dart           # Peer list card
│   ├── connection_overlay.dart  # Connecting... animation
│   └── interest_tags.dart       # Interest tag picker bottom sheet
└── utils/
    └── app_theme.dart           # Cyberpunk-noir dark theme
```

---

## 🔮 Roadmap

- [ ] WiFi Direct without BLE (AP mode, no router)
- [ ] Image sharing (compressed, P2P)
- [ ] iOS support
- [ ] Multi-session (chat with multiple strangers simultaneously)
- [ ] Emoji reactions

---

## 🤝 Contributing

PRs welcome. Please open an issue first for major changes.

```bash
git checkout -b feature/your-feature
git commit -m "feat: description"
git push origin feature/your-feature
# → open Pull Request
```

---

## 📄 License

MIT — see [LICENSE](LICENSE)

---

*Built as part of the [#30AppsIn30Days](https://twitter.com/search?q=%2330AppsIn30Days) challenge · [@likhith1542](https://github.com/likhith1542)*