# AGENTS.md — BearWave Flutter (Android)

## Project Overview

BearWave is a KDE-focused internet radio streaming app for Android, built with Flutter.
This is the mobile port of the desktop Qt6/QML/KDE app at https://github.com/spalencsar/bearwave.
Application ID: `de.nerdbear.bearwave`
License: GPL-3.0-or-later

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Analyze for issues
flutter analyze

# Run tests
flutter test
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart 3.12+) |
| State Management | Provider + ChangeNotifier |
| Audio Playback | just_audio |
| Background Audio | audio_service |
| HTTP Client | http (dart:http) |
| Persistence | SharedPreferences |
| Cast Support | cast_plus |
| Image Caching | cached_network_image |
| App Icon | flutter_launcher_icons |
| API | Radio Browser API (all.api.radio-browser.info) |

## Architecture

```
Data Flow:
RadioBrowserApi (HTTP) → Providers (State) → Screens/Widgets (UI)

Persistence:
SharedPreferences ← StorageService ← Providers

Audio:
BearWaveAudioHandler (audio_service + just_audio) → PlayerProvider → PlayerBar / StationCard

Cast:
CastService (cast_plus) → PlayerProvider / CastDialog
```

### Pattern: Provider + ChangeNotifier

The app uses the **Provider** package with **ChangeNotifier** for state management.
There are 3 providers:

1. **StationsProvider** — manages station lists, favorites, countries, search, filtering
2. **PlayerProvider** — manages audio playback state, current station, volume
3. **CastService** — manages Google Cast discovery, connection, and remote playback

All are injected via `MultiProvider` in `main.dart`.

## Project Structure

```
lib/
├── main.dart                    # Entry point, provider setup
├── app.dart                     # MaterialApp, bottom nav, app shell
├── models/
│   ├── radio_station.dart       # RadioStation data model (83 lines)
│   └── country.dart             # Country data model (27 lines)
├── providers/
│   ├── stations_provider.dart   # Station data + favorites + search (225 lines)
│   └── player_provider.dart     # Audio + Cast playback state (150 lines)
├── screens/
│   ├── home_screen.dart         # Main browsing: Top/DE/NL/search (177 lines)
│   ├── world_screen.dart        # Country grid + country station list (215 lines)
│   ├── favorites_screen.dart    # Favorited stations list (99 lines)
│   ├── history_screen.dart      # Recently played stations (99 lines)
│   ├── about_screen.dart        # App info, version, license (125 lines)
│   ├── expanded_player_sheet.dart # Full player controls (288 lines)
│   └── station_search_delegate.dart # Search UI delegate (141 lines)
├── services/
│   ├── radio_browser_api.dart   # HTTP client for Radio Browser API (77 lines)
│   ├── bearwave_audio_handler.dart # Background audio + Android Auto (522 lines)
│   ├── cast_service.dart        # Google Cast discovery/playback (211 lines)
│   └── storage_service.dart     # SharedPreferences persistence (74 lines)
├── theme/
│   └── bearwave_theme.dart      # Colors, ThemeData, utilities (159 lines)
└── widgets/
    ├── station_card.dart        # Individual station row (199 lines)
    ├── player_bar.dart          # Bottom persistent player (200 lines)
    ├── cast_dialog.dart         # Google Cast device picker (210 lines)
    ├── country_grid.dart        # Country selection grid (87 lines)
    ├── genre_chips.dart         # Genre filter chips (89 lines)
    ├── search_bar.dart          # Search input + button (53 lines)
    └── add_station_dialog.dart  # Manual station add dialog (86 lines)
```

**Total: 25 Dart files, ~3,750 lines of code.**

## Key Files — Detailed Reference

### `lib/main.dart`
Entry point. Initializes `StorageService` (SharedPreferences), starts `AudioService` with `BearWaveAudioHandler`, wraps app in `MultiProvider` with `CastService`, `StationsProvider`, and `PlayerProvider`.

### `lib/app.dart`
Main app shell (`BearWaveApp` StatefulWidget). Contains:
- `BottomNavigationBar` with 4 tabs: Home, World, Favorites, History
- `PlayerBar` at the bottom (persistent mini-player)
- Loads favorites and recent stations on init

### `lib/services/radio_browser_api.dart`
**API Base URL:** `https://all.api.radio-browser.info/json`
This uses DNS-based load balancing — `all.api.radio-browser.info` resolves to the nearest available server automatically. This is the same approach as the desktop Qt app.

**Endpoints used:**
| Method | API Path |
|--------|----------|
| `getTopStations(limit)` | `/json/stations/topvote/{limit}` |
| `getGermanStations()` | `/json/stations/bycountrycodeexact/DE?limit=50&order=votes&reverse=true` |
| `getDutchStations()` | `/json/stations/bycountrycodeexact/NL?limit=50&order=votes&reverse=true` |
| `getByCountryCode(code)` | `/json/stations/bycountrycodeexact/{code}` |
| `getByTag(tag)` | `/json/stations/bytag/{tag}` |
| `getWorldStations(limit)` | `/json/stations?hidebroken=true&limit={limit}&order=votes&reverse=true` |
| `search(query)` | `/json/stations/search?name={query}&hidebroken=true&limit=50&order=votes&reverse=true` |
| `getCountries()` | `/json/countries` |

**Timeout:** 10 seconds per request.
**User-Agent:** `BearWave/1.0`

**IMPORTANT:** Never hardcode a specific server like `de1.api.radio-browser.info`. Always use `all.api.radio-browser.info` which does DNS-based server selection. If the API is down, the app should show an error, not crash.

### `lib/services/bearwave_audio_handler.dart`
Wraps `just_audio`'s `AudioPlayer` inside `audio_service`'s `BaseAudioHandler`. Key behaviors:
- Auto-retry on playback failure: max 2 attempts, 1200ms delay between retries
- Exposes the underlying `AudioPlayer` for UI playback and ICY metadata streams
- `playStation(RadioStation)` sets media item, stream URL, and starts playback
- Updates media notifications when ICY metadata changes
- Implements Android Auto / MediaBrowserService browsing for Top, DE, NL, Worldwide, Favorites, and Recent stations
- Supports Android Auto search via Radio Browser API results
- Publishes `MediaItem`, queue, and `PlaybackState` for Android Auto's Now Playing screen
- Implements `playFromMediaId()`, `prepareFromMediaId()`, `playMediaItem()`, `playFromSearch()`, `playFromUri()`, and `seek()`
- Uses short station media IDs plus `MediaItem.extras` and an in-memory station cache for Android Auto callbacks
- `setVolume(double)` clamps to 0.0–1.0

### `lib/services/cast_service.dart`
Manages Google Cast support via `cast_plus`. Key behaviors:
- Discovers Cast devices on demand
- Starts the Default Media Receiver (`CC1AD845`)
- Sends `LOAD`, `STOP`, and receiver volume messages
- Queues a pending stream until the Cast transport ID is available

### `lib/services/storage_service.dart`
Persistence via `SharedPreferences`. Keys and data:

| Key | Type | Content |
|-----|------|---------|
| `favorites` | JSON string | Array of station objects |
| `lastStationName` | String | Name of last played station |
| `lastStationUrl` | String | URL of last played station |
| `volume` | Double | Last volume (default: 0.5) |
| `recentStations` | JSON string | Array of station objects (max 20) |

### `lib/providers/stations_provider.dart`
Central data provider. Manages:
- `_stations` — raw station list from API
- `_filteredStations` — stations after filter query applied
- `_favorites` — favorited stations
- `_recentStations` — recently played (max 20)
- `_countries` — country list for World view
- `_loading` — loading state
- `_lastError` — last error message

All load methods (e.g., `loadTopStations()`) call the API, update `_stations`, sync favorite status, apply filters, and emit `notifyListeners()`.

`setFilterQuery(String)` filters stations by name, tags, or country (case-insensitive).

### `lib/providers/player_provider.dart`
Manages local and Cast playback. Listens to the underlying audio player's `playingStream` for local state changes and to `CastService` for Cast connection changes. On `playStation()`:
1. Sets `_currentStation`
2. Plays locally via `BearWaveAudioHandler` or remotely via `CastService`
3. Records station in recent history
4. Saves state (last station, volume) for resume

### `lib/models/radio_station.dart`
Data model with dual serialization:
- `fromJson(Map)` — from Radio Browser API (uses `url_resolved` field)
- `fromStorageJson(Map)` — from SharedPreferences (uses `urlResolved` field)
- `toJson()` — for persistence

**Fields:** uuid, name, url, urlResolved, homepage, favicon, country, tags, codec, bitrate, votes, isOnline, isFavorite (mutable)

### `lib/theme/bearwave_theme.dart`
Dark theme matching the KDE desktop app. Key colors:

| Constant | Hex | Usage |
|----------|-----|-------|
| `bgA` | `#0f141b` | Scaffold background (top gradient) |
| `bgB` | `#131b25` | Scaffold background (bottom gradient) |
| `panel` | `#182433` | Card/panel backgrounds |
| `card` | `#1b2a3d` | Station card background |
| `cardHover` | `#223654` | Card hover/pressed state |
| `cardBorder` | `#2d4566` | Default card border |
| `accent` | `#2bb0ff` | Primary accent, buttons, highlights |
| `textMain` | `#eaf1fb` | Primary text |
| `textMuted` | `#9eb1c9` | Secondary/muted text |
| `warn` | `#ff8b8b` | Error messages |

Static utility: `getFlagEmoji(countryCode)` converts ISO 3166-1 alpha-2 to emoji flag.

## Android Configuration

### `android/app/src/main/AndroidManifest.xml`
Permissions:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE"/>
```

The manifest also declares:
- `com.google.android.gms.car.application` metadata with `@xml/automotive_app_desc`
- `com.ryanheise.audioservice.AudioService` as an exported `MediaBrowserService`
- `com.ryanheise.audioservice.MediaButtonReceiver` for media button handling

### `android/app/build.gradle.kts`
| Setting | Value |
|---------|-------|
| applicationId | `de.nerdbear.bearwave` |
| namespace | `de.nerdbear.bearwave` |
| minSdk | Flutter default (currently 24 in local builds) |
| targetSdk | Flutter default (currently 36 in local builds) |
| Java compatibility | 17 |
| Kotlin JVM target | 17 |

### `android/settings.gradle.kts`
| Tool | Version |
|------|---------|
| Android Gradle Plugin | 9.0.1 |
| Kotlin | 2.3.20 |
| Gradle Wrapper | 9.1.0 |

**KNOWN ISSUE:** `bonsoir_android` (transitive via Cast support) and `shared_preferences_android` trigger Kotlin Gradle Plugin warnings during build. This is dependency/framework tooling noise and does not currently block debug or release builds.

## Build Requirements

- **Flutter SDK** >= 3.38.4
- **Dart SDK** >= 3.12.1
- **Java** 17 (NOT 26 — incompatible with Gradle 9.1.0)
  - On Arch: `sudo pacman -S jdk17-openjdk`
  - Configure: `flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk`
- **Android SDK** (installed via `flutter doctor`)

## Running & Testing

```bash
# Run on connected Android device
flutter run

# Run on Linux desktop (for quick UI testing)
flutter run -d linux

# Build debug APK
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk

# Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Run analyzer (no errors expected)
flutter analyze

# Run tests
flutter test
```

## Code Conventions

### Dart Style
- Follow official Dart style guide (effective_dart)
- Use `flutter_lints` rules (analysis_options.yaml)
- No `print()` in production code (use logging framework)
- Always use `const` constructors where possible
- Prefer `final` over `var`

### Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Constants: `camelCase` (not SCREAMING_CAPS)
- Private members: `_` prefix

### Widget Pattern
- Stateless widgets for display-only components
- Stateful widgets only when managing local UI state (animation, text input)
- Use `Consumer`/`Consumer2` from Provider to access state
- Never pass Provider down via InheritedWidget manually

### File Organization
- One class per file (except small data models)
- Group by feature type: models/, services/, providers/, screens/, widgets/
- Theme constants in `theme/bearwave_theme.dart`
- Services are utility classes; `CastService` is a `ChangeNotifier` because device discovery and connection state are UI-observed
- Providers are `ChangeNotifier` — hold mutable state

### Error Handling
- API errors shown via `StationsProvider.lastError` → displayed in UI error banner
- Audio errors trigger auto-retry (max 2 attempts, 1200ms delay)
- Network timeout: 10 seconds
- Never throw from UI code — catch and display

## Comparison with Desktop App

| Feature | Desktop (Qt6/QML) | Android (Flutter) |
|---------|-------------------|-------------------|
| UI Framework | QML + KDE Kirigami | Flutter + Material |
| State Management | QProperty/QObject | Provider + ChangeNotifier |
| Audio | QtMultimedia | just_audio |
| Background Audio | MPRIS (Linux) | audio_service (Android Media Session) |
| System Tray | Qt.SystemTrayIcon | Not applicable (Android) |
| Persistence | JSON files in ~/.config | SharedPreferences |
| Cast / Chromecast| Not supported | cast_plus |
| Android Auto | Not applicable | audio_service / MediaBrowserService |
| API | Radio Browser API | Radio Browser API (same) |
| Theme | QML colors in Main.qml | Dart constants in bearwave_theme.dart |

## Common Tasks

### Adding a new screen
1. Create `lib/screens/my_screen.dart` with a `StatelessWidget` or `StatefulWidget`
2. Add to `_buildCurrentScreen()` in `app.dart` or add a new tab
3. Access providers via `Consumer<StationsProvider>` / `Consumer<PlayerProvider>`

### Adding a new widget
1. Create `lib/widgets/my_widget.dart`
2. Keep it self-contained — receive data via constructor, emit events via callbacks
3. Use `BearWaveTheme` constants for colors

### Modifying the API
1. Edit `lib/services/radio_browser_api.dart`
2. All endpoints use base URL `https://all.api.radio-browser.info/json`
3. Never hardcode individual servers (de1, de2, etc.)
4. Timeout is 10 seconds — adjust if needed for slow networks

### Changing the theme
1. Edit color constants in `lib/theme/bearwave_theme.dart`
2. All widgets reference these constants — changes propagate automatically
3. The theme is applied in `BearWaveTheme.theme` getter

### Adding a new API endpoint
1. Add method to `RadioBrowserApi` class
2. Follow pattern: `_getStations('/json/stations/{endpoint}')`
3. Call from a method in `StationsProvider`
4. Add UI trigger in appropriate screen

## Debugging

### API issues
- Test directly: `curl -s "https://all.api.radio-browser.info/json/stations/topvote/3"`
- If DNS fails, try `de1.api.radio-browser.info` directly
- Check `User-Agent` header — some servers block missing UA

### Audio issues
- Audio errors trigger retry (max 2 attempts)
- Check logcat for `just_audio` errors: `flutter run -v`
- Some stream URLs may be geoblocked

### Android Auto issues
- Test with a release APK when using a real car head unit; debug/shell-installed builds may be hidden or behave differently
- Use `adb install -r -i com.android.vending build/app/outputs/flutter-apk/app-release.apk` for local real-car testing
- The Android Auto MediaBrowser hierarchy is provided by `BearWaveAudioHandler.getChildren()`
- If Android Auto hangs on "Auswahl wird abgerufen...", inspect `prepareFromMediaId()`, `playFromMediaId()`, `playMediaItem()`, and logcat for `just_audio` stream errors
- DHU can show apps that a real car head unit filters out; real-car behavior is the deciding test

### Build issues
- Java version mismatch: `flutter doctor --verbose` shows Java version
- Gradle cache: `cd android && ./gradlew clean`
- Full clean: `flutter clean && flutter pub get`

## Dependencies Not Yet Used

The following are declared in `pubspec.yaml` but not imported in code:
- `hive_flutter` — planned for future local database needs
- `shimmer` — planned for loading animations
- `intl` — planned for internationalization

These should be integrated or removed before production release.

## TODO / Known Limitations

- [x] ICY metadata reader for stream title updates
- [ ] No cover art fetching
- [ ] No release signing configuration
- [ ] No tests (only placeholder smoke test)
- [ ] Android Auto support is implemented but still needs broader real-head-unit testing
- [ ] No internationalization (English only)
- [ ] No pull-to-refresh on station lists
- [ ] No error retry button in UI
- [ ] No offline caching of stations
- [ ] `hive_flutter`, `shimmer`, `intl` declared but unused
