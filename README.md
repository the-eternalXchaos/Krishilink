<div align="center">

	<img src="lib/src/core/assets/images/krishilink.png" alt="KrishiLink Logo" height="88" />

	<h1>KrishiLink</h1>

	<p>
		A modern marketplace connecting farmers and buyers in Nepal — with secure payments (eSewa & Khalti), chat, maps, and AI-powered disease detection.
	</p>

	<p>
		<img src="https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter" alt="Flutter" />
		<img src="https://img.shields.io/badge/Dart-3.x-0175C2.svg?logo=dart" alt="Dart" />
		<img src="https://img.shields.io/badge/State%20Mgmt-GetX-success" alt="GetX" />
		<img src="https://img.shields.io/badge/License-MIT-informational" alt="License" />
	</p>

</div>

## ✨ Features

- Buyer & Farmer flows with role-based navigation
- Product catalog, search, and reviews
- Order management (buyer & farmer) with status tracking
- Secure payments via backend-integrated eSewa and Khalti (WebView)
- Live chat between buyer and farmer, with cached names and history
- Maps and delivery location picker
- Push notifications (Firebase Messaging) and local notifications
- AI-powered plant disease detection

## 🖼️ Screenshots

<p align="center">
	<img src="flutter_01.png" alt="Flutter Showcase" height="320" />
	<img src="lib/src/core/assets/images/login_background.jpg" alt="Login" height="320" />
	<img src="lib/src/core/assets/images/tomato_early_blight.jpg" alt="Disease Detection Example" height="320" />
</p>

> Note: Images above are representative assets/screens. Replace or add more snapshots as needed.

## 🧩 Tech Stack

- Flutter, Dart
- GetX (state, DI, routes)
- Dio (networking), WebView
- Firebase (Core, Auth, Messaging), Local Notifications
- Google Maps & Places

## 🔐 Payments (Backend-driven)

This app integrates payments via your backend endpoints, not the SDK directly:

- eSewa: `POST /api/Payment/initiatePaymentForEsewa` → auto-submitted form in WebView → backend success/failure callbacks
- Khalti: `POST /api/Payment/initiatePaymentForKhalti` → open returned paymentUrl in WebView → backend `khaltiResponse` callback

Key URLs are defined in `lib/src/core/constants/api_constants.dart` and rendered through `PaymentWebViewScreen`.

If you plan to use direct PSP keys at runtime, see `lib/src/features/payment/data/payment_keys.dart` (supports `--dart-define` overrides for `KHALTI_PUBLIC_KEY` / `KHALTI_SECRET_KEY`).

## 🚀 Getting Started

Prerequisites:

- Flutter SDK installed
- A running backend (see `ApiConstants.baseUrl`)

Run app:

```bash
flutter pub get
flutter run
```

Optional defines (if you choose to override test keys):

```bash
flutter run \
	--dart-define=KHALTI_PUBLIC_KEY=live_public_key_xxx \
	--dart-define=KHALTI_SECRET_KEY=live_secret_key_xxx
```

## 📁 Project Docs

- Architecture: `ARCHITECTURE.md`
- Migration notes: `MIGRATION_README.md`, `MIGRATION_STRATEGY.md`, `MIGRATION_CHECKLIST.md`
- Full file inventory: `FILE_INVENTORY.md`
- Payment notes: `KHALTI_DIRECT_PAYMENT_GUIDE.md`

## 🧭 Folder Highlights

- `lib/features` — Screens & feature modules (auth, buyer, payment, product, etc.)
- `lib/src/core` — Shared constants, networking, errors, assets
- `lib/src/features/payment` — Backend services and WebView flow

## 🤝 Contributing

PRs and issues are welcome. Please follow existing patterns (GetX, Dio) and keep commits scoped and descriptive.

## 📜 License

MIT — see `LICENSE` (or add one if not present).

