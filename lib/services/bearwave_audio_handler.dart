import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/radio_station.dart';
import 'radio_browser_api.dart';
import 'storage_service.dart';

class BearWaveAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final RadioBrowserApi _api = RadioBrowserApi();
  RadioStation? _currentStation;
  int _retryAttempts = 0;
  static const int maxRetryAttempts = 5;
  /// Blocks auto-retry after intentional pause/stop (e.g. Android Auto).
  bool _heldByUser = false;
  bool _isLoadingSource = false;

  final StorageService _storage = StorageService();
  bool _storageInitialized = false;

  static const String _folderTopId = 'top';
  static const String _folderWorldId = 'world';
  static const String _folderFavoritesId = 'favorites';
  static const String _folderRecentId = 'recent';
  static const String _stationIdPrefix = 'station:';

  // Android Auto content style hints
  static const String _groupTitleKey =
      'android.media.browse.DESCRIPTION_EXTRAS_KEY_content_style_group_title_hint';
  static const String _contentStylePlayableKey =
      'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT';
  static const int _contentStyleGrid = 2;

  final Map<String, RadioStation> _stationCache = {};
  List<RadioStation> _currentQueue = [];
  int _currentQueueIndex = -1;

  // CustomAction for Favorites in Android Auto
  static const String _customActionFavorite = 'toggle_favorite';
  static const MediaControl _favoriteCustomControl = MediaControl(
    androidIcon: 'drawable/ic_action_heart',
    label: 'Favorit',
    action: MediaAction.custom,
    customAction: CustomMediaAction(name: _customActionFavorite),
  );

  // Expose for UI
  AudioPlayer get player => _player;
  RadioStation? get currentStation => _currentStation;

  BearWaveAudioHandler() {
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {
        _scheduleRetry();
      },
    );

    // Update Media Notification when ICY metadata changes
    _player.icyMetadataStream.listen((metadata) {
      if (metadata != null && metadata.info?.title != null) {
        final icyTitle = metadata.info!.title!;
        final item = mediaItem.value;
        if (item != null && icyTitle.isNotEmpty) {
          // ICY title becomes the main title (e.g. "Artist - Track")
          // The station name stays in the artist field for Android Auto subtitle
          mediaItem.add(item.copyWith(
            title: icyTitle,
            artist: _currentStation?.name ?? item.artist,
          ));
        }
      }
    });
  }

  void updateCoverArt(String? url) {
    final item = mediaItem.value;
    if (item != null) {
      Uri? artUri;
      if (url != null && url.isNotEmpty) {
        artUri = Uri.parse(url);
      } else if (_currentStation != null) {
        artUri = _getStationImage(_currentStation!);
      }
      mediaItem.add(item.copyWith(artUri: artUri));
    }
  }

  Future<void> playStation(RadioStation station) async {
    _currentStation = station;
    _retryAttempts = 0;
    _heldByUser = false;

    final url = station.urlResolved.isNotEmpty
        ? station.urlResolved
        : station.url;

    if (url.isEmpty) return;

    final item = _stationToMediaItem(station).copyWith(id: url);
    mediaItem.add(item);
    queue.add([item]);
    _currentQueue = [station];
    _currentQueueIndex = 0;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.pause],
        processingState: AudioProcessingState.loading,
        playing: false,
        queueIndex: 0,
      ),
    );

    try {
      _isLoadingSource = true;
      await _player.setVolume(1.0);
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
      await play();
    } catch (e) {
      _scheduleRetry();
    } finally {
      _isLoadingSource = false;
    }
  }

  @override
  Future<void> play() async {
    _heldByUser = false;
    _retryAttempts = 0;
    if (_currentStation != null && (_player.processingState == ProcessingState.idle || _player.processingState == ProcessingState.completed)) {
      final url = _currentStation!.urlResolved.isNotEmpty
          ? _currentStation!.urlResolved
          : _currentStation!.url;
      if (url.isNotEmpty) {
        try {
          _isLoadingSource = true;
          playbackState.add(
            playbackState.value.copyWith(
              controls: [MediaControl.pause],
              processingState: AudioProcessingState.loading,
              playing: true,
            ),
          );
          await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
        } catch (_) {} finally {
          _isLoadingSource = false;
        }
      }
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    // Live radio: stop the socket, but mark as user-held so auto-retry does not
    // restart the stream (that broke Android Auto pause/stop).
    _heldByUser = true;
    _retryAttempts = maxRetryAttempts;
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.play],
        processingState: AudioProcessingState.ready,
        playing: false,
      ),
    );
  }

  @override
  Future<void> stop() async {
    _heldByUser = false;
    _retryAttempts = maxRetryAttempts;
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.play],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // --- Android Auto / MediaBrowserService Implementation ---

  Future<void> _ensureStorage() async {
    if (!_storageInitialized) {
      await _storage.init();
      _storageInitialized = true;
    }
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    await _ensureStorage();

    if (parentMediaId == AudioService.browsableRootId) {
      return [
        _folderItem(
          id: _folderTopId,
          title: 'Top Sender',
          subtitle: 'Die beliebtesten Sender weltweit',
          iconDrawable: 'ic_aa_home',
        ),
        _folderItem(
          id: _folderWorldId,
          title: 'Weltweit',
          subtitle: 'Länder & Regionen',
          iconDrawable: 'ic_aa_world',
        ),
        _folderItem(
          id: _folderFavoritesId,
          title: 'Favoriten',
          subtitle: 'Gespeicherte Sender',
          iconDrawable: 'ic_aa_heart',
        ),
        _folderItem(
          id: _folderRecentId,
          title: 'Verlauf',
          subtitle: 'Zuletzt gehört',
          iconDrawable: 'ic_aa_history',
        ),
      ];
    }

    if (parentMediaId == _folderWorldId) {
      final countries = await _api.getCountries();
      // Sort alphabetically by name
      countries.sort((a, b) => a.name.compareTo(b.name));
      
      return countries.map((country) {
        return _folderItem(
          id: 'country:${country.code}',
          title: country.name,
          subtitle: '${country.stationCount} Sender',
          iconDrawable: 'ic_aa_world',
        );
      }).toList();
    }

    if (parentMediaId == _folderTopId) {
      final stations = await _api.getTopStations(limit: 50);
      _currentQueue = stations;
      return _stationsToMediaItems(stations);
    }

    if (parentMediaId.startsWith('country:')) {
      final code = parentMediaId.split(':').last;
      final stations = await _api.getByCountryCode(code, limit: 50);
      _currentQueue = stations;
      return _stationsToMediaItems(stations);
    }

    if (parentMediaId == _folderFavoritesId) {
      final favorites = await _storage.loadFavorites();
      _currentQueue = favorites;
      return _stationsToMediaItems(favorites);
    }

    if (parentMediaId == _folderRecentId) {
      final recent = await _storage.loadRecentStations();
      _currentQueue = recent;
      return _stationsToMediaItems(recent);
    }

    return [];
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    await _ensureStorage();

    final station = await _stationFromMediaId(mediaId);
    if (station != null) {
      return _stationToMediaItem(station);
    }
    return null;
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    await _ensureStorage();

    final station = await _stationFromMediaId(mediaId, extras: extras);
    if (station == null) {
      return;
    }

    _currentStation = station;
    // Update queue index if station is in current queue
    final idx = _currentQueue.indexWhere(
        (s) => (s.urlResolved.isNotEmpty ? s.urlResolved : s.url) ==
                (station.urlResolved.isNotEmpty ? station.urlResolved : station.url));
    if (idx >= 0) _currentQueueIndex = idx;

    final url = station.urlResolved.isNotEmpty
        ? station.urlResolved
        : station.url;
    if (url.isEmpty) {
      return;
    }

    final item = _stationToMediaItem(station).copyWith(id: url);
    mediaItem.add(item);
    queue.add([item]);
    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.pause],
        processingState: AudioProcessingState.loading,
        playing: false,
        queueIndex: 0,
      ),
    );

    await _player.setVolume(1.0);
    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    await play();
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    final station = _stationFromMediaItem(mediaItem);
    if (station != null) {
      await playStation(station);
      return;
    }
    await playFromMediaId(mediaItem.id, mediaItem.extras);
  }

  @override
  Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
    final title = extras?['title'] as String? ?? uri.toString();
    await playStation(
      RadioStation(
        name: title,
        url: uri.toString(),
        urlResolved: uri.toString(),
      ),
    );
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }
    final stations = await _api.search(trimmedQuery);
    return _stationsToMediaItems(stations);
  }

  @override
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final results = await search(query, extras);
    if (results.isEmpty) {
      return;
    }
    await playFromMediaId(results.first.id);
  }

  MediaItem _folderItem({
    required String id,
    required String title,
    required String subtitle,
    String? iconDrawable,
  }) {
    return MediaItem(
      id: id,
      title: title,
      playable: false,
      displaySubtitle: subtitle,
      artUri: Uri.parse(
        iconDrawable != null
            ? 'android.resource://de.nerdbear.bearwave/drawable/$iconDrawable'
            : 'android.resource://de.nerdbear.bearwave/mipmap/ic_launcher',
      ),
      extras: {
        'android.media.browse.CONTENT_STYLE_BROWSABLE_HINT': 1,
        'android.media.browse.CONTENT_STYLE_PLAYABLE_HINT': 2,
      },
    );
  }

  List<MediaItem> _stationsToMediaItems(List<RadioStation> stations, {String? groupTitle}) {
    return stations.map((s) => _stationToMediaItem(s, groupTitle: groupTitle)).toList();
  }

  @override
  Future<void> skipToNext() async {
    if (_currentQueue.isEmpty) return;
    final nextIndex = (_currentQueueIndex + 1) % _currentQueue.length;
    _currentQueueIndex = nextIndex;
    await playStation(_currentQueue[nextIndex]);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentQueue.isEmpty) return;
    final prevIndex = (_currentQueueIndex - 1 + _currentQueue.length) % _currentQueue.length;
    _currentQueueIndex = prevIndex;
    await playStation(_currentQueue[prevIndex]);
  }

  MediaItem _stationToMediaItem(RadioStation station, {String? groupTitle}) {
    final url = station.urlResolved.isNotEmpty
        ? station.urlResolved
        : station.url;
    final id = _stationMediaId(station);
    _stationCache[id] = station;
    return MediaItem(
      id: id,
      album: 'BearWave',
      title: station.name,
      // Use station name as artist so Android Auto always shows it as subtitle.
      // When ICY metadata arrives, title changes to "Artist - Track" but
      // artist (station name) remains visible underneath.
      artist: station.name,
      genre: station.tags,
      artUri: _getStationImage(station),
      playable: true,
      displaySubtitle: _stationSubtitle(station),
      displayDescription: url,
      isLive: true,
      extras: {
        'name': station.name,
        'url': station.url,
        'urlResolved': station.urlResolved,
        if (station.uuid != null) 'uuid': station.uuid!,
        if (station.homepage != null) 'homepage': station.homepage!,
        if (station.favicon != null) 'favicon': station.favicon!,
        if (station.country != null) 'country': station.country!,
        if (station.tags != null) 'tags': station.tags!,
        if (station.codec != null) 'codec': station.codec!,
        if (station.bitrate != null) 'bitrate': station.bitrate!,
        if (station.votes != null) 'votes': station.votes!,
        if (station.isOnline != null) 'isOnline': station.isOnline!,
        _contentStylePlayableKey: _contentStyleGrid,
        // ignore: use_null_aware_elements
        if (groupTitle != null) _groupTitleKey: groupTitle,
      },
    );
  }

  Uri _getStationImage(RadioStation station) {
    // 1. Use the favicon directly from the Radio Browser API.
    //    Most stations have usable PNG/JPG logos. Even .ico files
    //    are handled by Android in most cases.
    if (station.favicon != null && station.favicon!.startsWith('http')) {
      return Uri.parse(station.favicon!);
    }

    // 2. No favicon available — try Google Favicon Proxy via homepage.
    if (station.homepage != null && station.homepage!.startsWith('http')) {
      final encodedUrl = Uri.encodeComponent(station.homepage!);
      return Uri.parse('https://t0.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=$encodedUrl&size=256');
    }

    // 3. Fallback: BearWave App Logo
    return Uri.parse('android.resource://de.nerdbear.bearwave/mipmap/ic_launcher');
  }

  String _stationMediaId(RadioStation station) {
    final url = station.urlResolved.isNotEmpty
        ? station.urlResolved
        : station.url;
    final key = station.uuid?.isNotEmpty == true ? station.uuid! : url;
    return '$_stationIdPrefix${base64Url.encode(utf8.encode(key))}';
  }

  Future<RadioStation?> _stationFromMediaId(
    String mediaId, {
    Map<String, dynamic>? extras,
  }) async {
    final stationFromExtras = _stationFromExtras(extras);
    if (stationFromExtras != null) {
      return stationFromExtras;
    }

    final cachedStation = _stationCache[mediaId];
    if (cachedStation != null) {
      return cachedStation;
    }

    if (mediaId.startsWith(_stationIdPrefix)) {
      final encoded = mediaId.substring(_stationIdPrefix.length);
      try {
        final key = utf8.decode(base64Url.decode(encoded));
        final cachedByKey = _stationCache.values.where((station) {
          final url = station.urlResolved.isNotEmpty
              ? station.urlResolved
              : station.url;
          return station.uuid == key || url == key;
        }).firstOrNull;
        if (cachedByKey != null) {
          return cachedByKey;
        }
      } catch (_) {
        return null;
      }
    }

    return _stationFromStoredLists(mediaId);
  }

  RadioStation? _stationFromMediaItem(MediaItem item) {
    return _stationFromExtras(item.extras) ?? _stationCache[item.id];
  }

  RadioStation? _stationFromExtras(Map<String, dynamic>? extras) {
    if (extras == null) {
      return null;
    }

    final name = extras['name'] as String?;
    final url = extras['url'] as String?;
    final urlResolved = extras['urlResolved'] as String?;
    final playableUrl = urlResolved?.isNotEmpty == true ? urlResolved : url;
    if (name == null ||
        name.isEmpty ||
        playableUrl == null ||
        playableUrl.isEmpty) {
      return null;
    }

    return RadioStation(
      uuid: extras['uuid'] as String?,
      name: name,
      url: url ?? playableUrl,
      urlResolved: urlResolved ?? playableUrl,
      homepage: extras['homepage'] as String?,
      favicon: extras['favicon'] as String?,
      country: extras['country'] as String?,
      tags: extras['tags'] as String?,
      codec: extras['codec'] as String?,
      bitrate: extras['bitrate'] as int?,
      votes: extras['votes'] as int?,
      isOnline: extras['isOnline'] as bool?,
    );
  }

  Future<RadioStation?> _stationFromStoredLists(String mediaId) async {
    String searchKey = mediaId;
    if (mediaId.startsWith(_stationIdPrefix)) {
      try {
        final encoded = mediaId.substring(_stationIdPrefix.length);
        searchKey = utf8.decode(base64Url.decode(encoded));
      } catch (_) {}
    }

    final favorites = await _storage.loadFavorites();
    final recent = await _storage.loadRecentStations();
    final allStations = [...favorites, ...recent];
    return allStations.where((station) {
      final url = station.urlResolved.isNotEmpty
          ? station.urlResolved
          : station.url;
      return station.uuid == searchKey || url == searchKey || url == mediaId;
    }).firstOrNull;
  }

  String _stationSubtitle(RadioStation station) {
    final parts = <String>[];
    if (station.country != null && station.country!.isNotEmpty) {
      parts.add(station.country!);
    }
    if (station.codec != null && station.codec!.isNotEmpty) {
      parts.add(station.codec!.toUpperCase());
    }
    if (station.bitrate != null && station.bitrate! > 0) {
      parts.add('${station.bitrate} kbps');
    }
    return parts.isEmpty ? 'Internet Radio' : parts.join(' • ');
  }

  // --- End Android Auto ---

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  double get volume => _player.volume;

  void _scheduleRetry() {
    if (_heldByUser) return;
    if (_currentStation == null || _retryAttempts >= maxRetryAttempts) return;

    final delayMs = 1000 * (1 << _retryAttempts); // 1s, 2s, 4s, 8s, 16s
    Future.delayed(Duration(milliseconds: delayMs), () async {
      if (_heldByUser) return;
      if (!_player.playing && _retryAttempts < maxRetryAttempts) {
        _retryAttempts++;
        final url = _currentStation!.urlResolved.isNotEmpty
            ? _currentStation!.urlResolved
            : _currentStation!.url;
        if (url.isNotEmpty) {
          try {
            await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
            await play();
          } catch (e) {
            _scheduleRetry();
          }
        }
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final hasQueue = _currentQueue.length > 1;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (hasQueue) MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          if (hasQueue) MediaControl.skipToNext,
          _favoriteCustomControl,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.playFromSearch,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        androidCompactActionIndices: hasQueue ? const [0, 1, 2] : const [0],
        processingState: _player.processingState == ProcessingState.idle
            ? (_isLoadingSource
                ? AudioProcessingState.loading
                : (_heldByUser ? AudioProcessingState.ready : AudioProcessingState.idle))
            : const {
                ProcessingState.idle: AudioProcessingState.idle,
                ProcessingState.loading: AudioProcessingState.loading,
                ProcessingState.buffering: AudioProcessingState.buffering,
                ProcessingState.ready: AudioProcessingState.ready,
                ProcessingState.completed: AudioProcessingState.completed,
              }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == _customActionFavorite) {
      await _toggleFavorite();
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentStation != null) {
      final favorites = await _storage.loadFavorites();
      final isFav = favorites.any((s) => s.urlResolved == _currentStation!.urlResolved);
      if (isFav) {
        favorites.removeWhere((s) => s.urlResolved == _currentStation!.urlResolved);
      } else {
        favorites.add(_currentStation!);
      }
      await _storage.saveFavorites(favorites);
    }
  }
}
