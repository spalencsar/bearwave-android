import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radio_station.dart';

class StorageService {
  static const String _favoritesKey = 'favorites';
  static const String _lastStationNameKey = 'lastStationName';
  static const String _lastStationUrlKey = 'lastStationUrl';
  static const String _volumeKey = 'volume';
  static const String _recentStationsKey = 'recentStations';
  static const int _recentLimit = 20;

  static const String _languageKey = 'language';
  static const String _defaultCountryKey = 'defaultCountry';
  static const String _autoplayKey = 'autoplayOnStartup';
  static const String _resumeBluetoothKey = 'resumeBluetooth';
  static const String _bufferKey = 'playbackBuffer';
  static const String _showCoverKey = 'showCover';
  static const String _coverQualityKey = 'coverQuality';
  static const String _alwaysConnectKey = 'alwaysConnect';
  static const String _preferLowBitrateKey = 'preferLowBitrate';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<RadioStation>> loadFavorites() async {
    final String? data = _prefs.getString(_favoritesKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList
        .map((json) => RadioStation.fromStorageJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFavorites(List<RadioStation> favorites) async {
    final jsonList = favorites.map((s) => s.toJson()).toList();
    await _prefs.setString(_favoritesKey, json.encode(jsonList));
  }

  Future<void> saveState({
    required String lastStationName,
    required String lastStationUrl,
    required double volume,
  }) async {
    await _prefs.setString(_lastStationNameKey, lastStationName);
    await _prefs.setString(_lastStationUrlKey, lastStationUrl);
    await _prefs.setDouble(_volumeKey, volume);
  }

  String get lastStationName => _prefs.getString(_lastStationNameKey) ?? '';
  String get lastStationUrl => _prefs.getString(_lastStationUrlKey) ?? '';
  double get volume => _prefs.getDouble(_volumeKey) ?? 0.5;
  bool get canResume => lastStationUrl.isNotEmpty;

  String get language => _prefs.getString(_languageKey) ?? 'de';
  Future<void> setLanguage(String lang) async => await _prefs.setString(_languageKey, lang);

  String get defaultCountry => _prefs.getString(_defaultCountryKey) ?? 'DE';
  Future<void> setDefaultCountry(String code) async => await _prefs.setString(_defaultCountryKey, code);

  bool get autoplayOnStartup => _prefs.getBool(_autoplayKey) ?? false;
  Future<void> setAutoplayOnStartup(bool val) async => await _prefs.setBool(_autoplayKey, val);

  bool get resumeAfterBluetoothDisconnect => _prefs.getBool(_resumeBluetoothKey) ?? false;
  Future<void> setResumeAfterBluetoothDisconnect(bool val) async => await _prefs.setBool(_resumeBluetoothKey, val);

  int get playbackBuffer => _prefs.getInt(_bufferKey) ?? 30;
  Future<void> setPlaybackBuffer(int val) async => await _prefs.setInt(_bufferKey, val);

  bool get showMetadataCover => _prefs.getBool(_showCoverKey) ?? true;
  Future<void> setShowMetadataCover(bool val) async => await _prefs.setBool(_showCoverKey, val);

  String get coverQuality => _prefs.getString(_coverQualityKey) ?? 'medium';
  Future<void> setCoverQuality(String val) async => await _prefs.setString(_coverQualityKey, val);

  bool get alwaysTryToConnect => _prefs.getBool(_alwaysConnectKey) ?? true;
  Future<void> setAlwaysTryToConnect(bool val) async => await _prefs.setBool(_alwaysConnectKey, val);

  bool get preferLowBitrate => _prefs.getBool(_preferLowBitrateKey) ?? false;
  Future<void> setPreferLowBitrate(bool val) async => await _prefs.setBool(_preferLowBitrateKey, val);

  Future<List<RadioStation>> loadRecentStations() async {
    final String? data = _prefs.getString(_recentStationsKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList
        .map((json) => RadioStation.fromStorageJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> recordRecentStation(RadioStation station) async {
    final recent = await loadRecentStations();
    
    recent.removeWhere((s) =>
        (s.uuid != null && s.uuid == station.uuid) ||
        (s.uuid == null && s.urlResolved == station.urlResolved));
    
    recent.insert(0, station);
    
    if (recent.length > _recentLimit) {
      recent.removeRange(_recentLimit, recent.length);
    }

    final jsonList = recent.map((s) => s.toJson()).toList();
    await _prefs.setString(_recentStationsKey, json.encode(jsonList));
  }
}