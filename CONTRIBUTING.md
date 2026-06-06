# Contributing to BearWave Android

Thank you for your interest in contributing to BearWave Android!

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/bearwave-android.git
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Development Setup

### Prerequisites
- Flutter SDK >= 3.38.4
- Dart SDK >= 3.12.1
- Java 17 (JDK 17 OpenJDK recommended)
- Android SDK (installed via `flutter doctor`)

### Java Configuration (Arch Linux)
```bash
sudo pacman -S jdk17-openjdk
flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk
```

### Verify Setup
```bash
flutter doctor
flutter analyze  # Should show no errors
```

## Project Architecture

This is a Flutter app using **Provider** for state management. Key concepts:

- **Models** (`lib/models/`) — Data classes with JSON serialization
- **Services** (`lib/services/`) — API, audio, storage, and Cast utilities
- **Providers** (`lib/providers/`) — ChangeNotifiers holding app state
- **Screens** (`lib/screens/`) — Full-page views
- **Widgets** (`lib/widgets/`) — Reusable UI components
- **Theme** (`lib/theme/`) — Colors and design tokens

Read `AGENTS.md` for detailed architecture documentation.

## Code Style

### Dart
- Follow the [Dart style guide](https://dart.dev/effective-dart/style)
- Use `flutter_lints` rules (already configured in `analysis_options.yaml`)
- Always use `const` constructors where possible
- Prefer `final` over `var`
- No `print()` in production code

### Naming Conventions
- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Variables/Functions:** `camelCase`
- **Constants:** `camelCase`
- **Private members:** `_` prefix

### Widget Guidelines
- Use `StatelessWidget` for display-only components
- Use `StatefulWidget` only when managing local UI state (animations, text input)
- Access state via `Consumer`/`Consumer2` from Provider
- Pass data through constructors, not global state

### File Organization
- One class per file (except small data models)
- Group by feature type (models, services, providers, screens, widgets)
- Theme constants in `theme/bearwave_theme.dart`

## Making Changes

### Adding a New Feature
1. Create the necessary files in the appropriate directory
2. Follow existing patterns (see `AGENTS.md` for examples)
3. Ensure `flutter analyze` shows no errors
4. Test on a real device or emulator
5. Submit a pull request

### Adding a New Screen
1. Create `lib/screens/my_screen.dart`
2. Add to navigation in `app.dart`
3. Access providers via `Consumer<StationsProvider>` / `Consumer<PlayerProvider>`

### Adding a New Widget
1. Create `lib/widgets/my_widget.dart`
2. Keep it self-contained — receive data via constructor
3. Use `BearWaveTheme` constants for all colors

### Modifying the API
1. Edit `lib/services/radio_browser_api.dart`
2. Never hardcode individual servers — use `all.api.radio-browser.info`
3. Follow the existing method pattern
4. Test with `curl` first to verify the endpoint works

### Changing the Theme
1. Edit color constants in `lib/theme/bearwave_theme.dart`
2. All widgets reference these constants — changes propagate automatically

## Testing

### Running Tests
```bash
flutter test
```

### Manual Testing
- Test on a real Android device when possible
- Test with poor network conditions
- Test with no network (should show error, not crash)
- Test audio playback, pause, resume, stop
- Test favorites (add, remove, persist across restart)
- Test resume (last station should be restored)
- Test Android Auto browsing, search, station start, and Now Playing on DHU and, when possible, a real car head unit
- Test Google Cast discovery, connect, playback, stop, volume, and disconnect

### Android Auto Testing
Real car head units can behave differently from Desktop Head Unit (DHU), especially for debug or shell-installed builds. For realistic local testing, build and install a release APK with installer attribution:

```bash
flutter build apk --release
adb install -r -i com.android.vending build/app/outputs/flutter-apk/app-release.apk
```

If Android Auto hangs while opening a station, capture logcat around the selection and inspect `BearWaveAudioHandler` callbacks: `getChildren()`, `prepareFromMediaId()`, `playFromMediaId()`, `playMediaItem()`, and `playFromSearch()`.

## Submitting Changes

1. Ensure `flutter analyze` shows no errors
2. Test your changes thoroughly
3. Write a clear commit message
4. Push to your fork
5. Create a pull request with a description of changes

### Pull Request Guidelines
- Keep PRs focused on one feature or fix
- Include screenshots/video for UI changes
- Reference any related issues
- Ensure the app builds: `flutter build apk --debug`
- For Android Auto changes, also verify `flutter build apk --release`

## Reporting Issues

When reporting bugs, please include:
- Device model and Android version
- Flutter version (`flutter --version`)
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

## Code of Conduct

Be respectful, constructive, and inclusive. We're building something cool together.
