# Virtual Closet — Mobile

> Your closet, curated. — Flutter + Supabase virtual wardrobe app.

For environment setup (`.env`, Supabase migrations, fonts) and the full project structure, see [SETUP.md](SETUP.md).

## Prerequisites

```bash
flutter --version   # requires 3.19+
flutter pub get
```

Make sure `.env` has valid `SUPABASE_URL` / `SUPABASE_ANON_KEY` values before building — see [SETUP.md](SETUP.md#2-configure-environment).

## Running in development

```bash
flutter devices          # list available targets
flutter run               # run on the first connected device/emulator
flutter run -d linux       # run on a specific device (linux, chrome, <device-id>, ...)
```

## Building the app

### Android

```bash
# APK (sideload / manual install)
flutter build apk --release

# Split per ABI — smaller APKs, one per CPU architecture
flutter build apk --release --split-per-abi

# App Bundle (required for Play Store)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/` (APK) or `build/app/outputs/bundle/release/` (AAB).

### iOS

Requires macOS + Xcode.

```bash
flutter build ipa
```

Output: `build/ios/archive/`.

### Desktop

```bash
flutter build linux --release
flutter build macos --release
flutter build windows --release
```

### Web

```bash
flutter build web --release
```

Output: `build/web/`.

## Verifying a build

```bash
flutter analyze   # static analysis
flutter test      # unit tests
```
