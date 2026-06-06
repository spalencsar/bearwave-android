# BearWave Android

KDE-focused internet radio streaming app for Android, built with Flutter.

This is the mobile port of the desktop Qt6/QML/KDE app at https://github.com/spalencsar/bearwave.

[![License: GPL--3.0--or--later](https://img.shields.io/badge/license-GPL--3.0--or--later-lightgrey)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B)](https://flutter.dev)

## Features

- Internet radio via the Radio Browser API
- Browse stations by Top, Germany, Netherlands
- World view with country grid and genre tags
- Local search and filtering by name, genre, country
- Sorting by name, bitrate, votes
- Favorites with persistent storage
- Manual station add
- Resume last station and volume
- Background playback support
- **Android Auto** integration with browsable Top, Germany, Netherlands, Worldwide, Favorites, Recent, and search results
- Android Auto Now Playing support via MediaSession metadata, queue, playback state, and media callbacks
- **Google Cast / Chromecast** support (stream directly to smart speakers)
- Dark theme matching the KDE desktop app

## Screenshots

*Coming soon*

## Quick Start

### Prerequisites

- Flutter SDK >= 3.38.4
- Dart SDK >= 3.12.1
- Java 17 (JDK 17 OpenJDK)
- Android SDK

### Installation

```bash
# Clone the repository
git clone https://github.com/spalencsar/bearwave-android.git
cd bearwave-android

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Build APK

```bash
# Debug APK
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk

# Release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android Auto Testing

For real car head units, prefer a release APK. Debug or shell-installed builds can be filtered differently from DHU tests.

```bash
flutter build apk --release
adb install -r -i com.android.vending build/app/outputs/flutter-apk/app-release.apk
```

The Android Auto experience is served by `BearWaveAudioHandler` through `audio_service` / `MediaBrowserService`. It exposes browsable radio categories, search results, MediaSession metadata, a one-item playback queue, and prepare/play callbacks for the Now Playing screen.

### Arch Linux Setup

```bash
# Install Java 17
sudo pacman -S jdk17-openjdk

# Configure Flutter to use Java 17
flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk

# Verify setup
flutter doctor
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart 3.12+) |
| State Management | Provider + ChangeNotifier |
| Audio Playback | just_audio |
| Background Audio | audio_service |
| HTTP Client | http |
| Persistence | SharedPreferences |
| Cast Support | cast_plus |
| Image Caching | cached_network_image |
| API | Radio Browser API |

## Architecture

```
RadioBrowserApi (HTTP) → Providers (State) → Screens/Widgets (UI)
SharedPreferences ← StorageService ← Providers
BearWaveAudioHandler (audio_service + just_audio) → PlayerProvider → PlayerBar / StationCard
CastService (cast_plus) → PlayerProvider / CastDialog
```

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── models/
│   ├── radio_station.dart
│   └── country.dart
├── providers/
│   ├── stations_provider.dart
│   └── player_provider.dart
├── screens/
│   ├── home_screen.dart
│   ├── world_screen.dart
│   ├── favorites_screen.dart
│   ├── history_screen.dart
│   ├── about_screen.dart
│   ├── expanded_player_sheet.dart
│   └── station_search_delegate.dart
├── services/
│   ├── radio_browser_api.dart
│   ├── bearwave_audio_handler.dart
│   ├── cast_service.dart
│   └── storage_service.dart
├── theme/
│   └── bearwave_theme.dart
└── widgets/
    ├── station_card.dart
    ├── player_bar.dart
    ├── cast_dialog.dart
    ├── country_grid.dart
    ├── genre_chips.dart
    ├── search_bar.dart
    └── add_station_dialog.dart
```

## API

BearWave uses the [Radio Browser API](https://api.radio-browser.info/) with DNS-based server selection via `all.api.radio-browser.info`. This automatically routes to the nearest available server.

## Current Status

- `flutter analyze` is expected to report no issues.
- `flutter test` currently contains only a placeholder smoke test.
- Android Auto works through `audio_service`, but real head units should be tested separately from DHU because filtering and callback behavior can differ.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the GNU GPL-3.0-or-later. See [LICENSE](LICENSE) for details.

## Credits

- Original desktop app by Sebastian Palencsar
- Radio Browser API by radio-browser.info
- Built with Flutter
