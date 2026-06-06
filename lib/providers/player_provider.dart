import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/radio_station.dart';
import '../services/bearwave_audio_handler.dart';
import '../services/storage_service.dart';
import '../services/cast_service.dart';
import '../services/cover_art_service.dart';
import 'stations_provider.dart';
import 'settings_provider.dart';

class PlayerProvider extends ChangeNotifier {
  final BearWaveAudioHandler _audioService;
  final StorageService _storage;
  final CastService _castService;
  final CoverArtService _coverArtService;
  SettingsProvider _settingsProvider;
  
  RadioStation? _currentStation;
  bool _isPlaying = false;
  IcyMetadata? _currentIcyMetadata;
  String? _currentCoverUrl;
  bool _wasConnected = false;

  PlayerProvider(this._audioService, this._storage, StationsProvider stationsProvider, this._castService, this._coverArtService, this._settingsProvider) {
    _audioService.player.playingStream.listen((playing) {
      if (!_castService.isConnected) {
        _isPlaying = playing;
        notifyListeners();
      }
    });

    _castService.addListener(_onCastStateChanged);
    
    _audioService.player.icyMetadataStream.listen((metadata) async {
      _currentIcyMetadata = metadata;
      
      // Attempt to fetch cover art if enabled
      if (metadata != null && metadata.info?.title != null && _settingsProvider.showMetadataCover) {
        final title = metadata.info!.title!;
        final url = await _coverArtService.fetchCoverArt(title, _settingsProvider.coverQuality);
        _currentCoverUrl = url;
        _audioService.updateCoverArt(url ?? _currentStation?.faviconOrFallbackUrl);
      } else {
        _currentCoverUrl = null;
        _audioService.updateCoverArt(_currentStation?.faviconOrFallbackUrl);
      }
      
      notifyListeners();
    });
  }

  void updateSettings(SettingsProvider settings) {
    _settingsProvider = settings;
    // We could refetch the cover if the quality changed, but it will update on the next song anyway.
  }

  void _onCastStateChanged() {
    final isConnected = _castService.isConnected;
    if (isConnected && !_wasConnected) {
      // Just connected: transfer playback if playing locally
      if (_currentStation != null && _audioService.player.playing) {
        playStation(_currentStation!);
      }
    } else if (!isConnected && _wasConnected) {
      // Just disconnected: resume playback locally if we were playing
      if (_isPlaying && _currentStation != null) {
        playStation(_currentStation!);
      }
    }
    _wasConnected = isConnected;
  }

  RadioStation? get currentStation => _currentStation;
  bool get isPlaying => _isPlaying;
  IcyMetadata? get currentIcyMetadata => _currentIcyMetadata;
  String? get currentCoverUrl => _currentCoverUrl;
  bool get canResume => _storage.canResume;
  BearWaveAudioHandler get audioService => _audioService;

  Future<void> playStation(RadioStation station) async {
    _currentStation = station;
    
    if (_castService.isConnected) {
      // Cast playback
      if (_audioService.player.playing) {
        await _audioService.pause(); // Stop local playback if any without destroying the service
      }
      final url = station.urlResolved.isNotEmpty ? station.urlResolved : station.url;
      final artworkUrl = station.favicon != null && station.favicon!.startsWith('http') ? station.favicon! : 'https://raw.githubusercontent.com/spalencsar/bearwave/main/assets/bearwave_logo.png';
      await _castService.playStream(url, station.name, artworkUrl);
      _isPlaying = true;
      notifyListeners();
    } else {
      // Local playback
      await _audioService.playStation(station);
    }
    
    await _storage.recordRecentStation(station);
    await _storage.saveState(
      lastStationName: station.name,
      lastStationUrl: station.urlResolved.isNotEmpty ? station.urlResolved : station.url,
      volume: _audioService.volume,
    );
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_currentStation == null) return;
    
    if (_castService.isConnected) {
      if (_isPlaying) {
        _castService.stop();
        _isPlaying = false;
        notifyListeners();
      } else {
        await playStation(_currentStation!);
      }
      return;
    }

    if (_audioService.player.playing) {
      await _audioService.pause();
    } else {
      await _audioService.play();
    }
  }

  Future<void> stop() async {
    if (_castService.isConnected) {
      _castService.stop();
    }
    
    _isPlaying = false;
    _currentStation = null;
    await _audioService.stop(); // Kill the background service
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    if (_castService.isConnected) {
      _castService.setVolume(volume);
    }
    
    // Always update local audioService volume to keep the UI Slider state in sync
    await _audioService.setVolume(volume);
    
    await _storage.saveState(
      lastStationName: _currentStation?.name ?? '',
      lastStationUrl: _currentStation?.urlResolved ?? '',
      volume: volume,
    );
    notifyListeners();
  }

  double get volume => _audioService.volume;

  Future<void> resumeLastStation() async {
    final url = _storage.lastStationUrl;
    final name = _storage.lastStationName;
    if (url.isEmpty) return;

    final station = RadioStation(
      name: name.isEmpty ? 'Last played' : name,
      url: url,
      urlResolved: url,
    );
    await playStation(station);
  }

  @override
  void dispose() {
    _audioService.player.dispose();
    super.dispose();
  }
}