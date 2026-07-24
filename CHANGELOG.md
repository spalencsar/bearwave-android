# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-07-24

### Added
- Added Android Auto category icons for Top Stations, Worldwide, Favorites, and Recent.
- Added favorite controls directly to the Android Auto player, including live updates of the Favorites and Recent folders.
- Added Android Auto station preparation, search playback, and queue navigation support.
- Added deterministic KDE-style initial logos for stations with missing, broken, or very low-resolution artwork.
- Added automatic discovery of higher-resolution station artwork from official homepages, including touch icons, large favicons, web app manifests, and suitable Open Graph images.
- Added DNS-based Radio Browser server discovery and automatic failover across available API nodes.
- Added a persistent last-known-good country cache for the Flutter catalog and Android Auto.
- Added local German and Dutch country names based on ISO country codes, with English API names retained for the English UI and as a fallback.

### Changed
- Improved Android Auto loading, buffering, retry, queue, and playback-state reporting.
- Android Auto now keeps the media session available after Stop, while normal smartphone stop behavior remains unchanged.
- Station logos are now rendered consistently across station cards and player views, with images below 64 pixels replaced by the initials fallback.
- Homepage artwork discovery uses bounded requests, safe redirects, limited concurrency, and a per-session cache before falling back to Google favicons or generated initials.
- Radio Browser requests now retry transient network failures and HTTP 429/502/503/504 responses up to three times, temporarily avoiding failed nodes.
- Country lists are sorted and searchable by their localized names in the Flutter catalog; Android Auto Worldwide uses the selected BearWave language as well.

### Fixed
- Fixed Android Auto Play, Pause, Stop, Next, Previous, station switching, and active media-app behavior.
- Fixed stale ICY titles and artist artwork remaining visible after switching stations.
- Prevented delayed cover-art results from a previous station from replacing the current station artwork.
- Stations without current ICY metadata now show the fallback title and station artwork instead of metadata retained from the previous stream.
- Fixed catalog and Android Auto Worldwide failures caused by transient Radio Browser HTTP 503 responses when another node or cached country data is available.

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
