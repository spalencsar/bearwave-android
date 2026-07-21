# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-07-21

### Added
- Data & network preferences to sort station lists by low bitrate (saving mobile data) and filter out offline stations.

### Changed
- Improved playback buffer settings slider behavior (re-applies only on release instead of dragging).

### Fixed
- Fixed Android Auto media playback controls to correctly support pause and stop actions.
- Fixed an issue where the media player notification and Android Auto screen unexpectedly closed when pausing live streams.
- Reset playback retry attempts on manual play command, fixing issues with resuming after a network error or pause.

## [1.0.0] - 2026-06-06

### Added
- Initial release of BearWave for Android.
- KDE-styled Material Design UI inspired by the desktop app.
- Live stream playback of internet radio stations powered by `just_audio` and `audio_service`.
- Full integration with the Radio Browser API for station discovery.
- Search, filtering, and favorites list for radio stations.
- Google Cast and Chromecast discovery and playback support.
- Android Auto integration with station browsing and playback.
- Dark mode theme matching the KDE desktop aesthetics.
- Multi-language support (English, German/Deutsch, and Dutch/Nederlands).
