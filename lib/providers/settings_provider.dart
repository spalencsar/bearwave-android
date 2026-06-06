import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;

  late String _language;
  late String _defaultCountry;
  late bool _autoplayOnStartup;
  late bool _resumeAfterBluetoothDisconnect;
  late int _playbackBuffer;
  late bool _showMetadataCover;
  late String _coverQuality;
  late bool _alwaysTryToConnect;
  late bool _preferLowBitrate;

  SettingsProvider(this._storageService) {
    _language = _storageService.language;
    _defaultCountry = _storageService.defaultCountry;
    _autoplayOnStartup = _storageService.autoplayOnStartup;
    _resumeAfterBluetoothDisconnect = _storageService.resumeAfterBluetoothDisconnect;
    _playbackBuffer = _storageService.playbackBuffer;
    _showMetadataCover = _storageService.showMetadataCover;
    _coverQuality = _storageService.coverQuality;
    _alwaysTryToConnect = _storageService.alwaysTryToConnect;
    _preferLowBitrate = _storageService.preferLowBitrate;
  }

  String get language => _language;
  String get defaultCountry => _defaultCountry;
  bool get autoplayOnStartup => _autoplayOnStartup;
  bool get resumeAfterBluetoothDisconnect => _resumeAfterBluetoothDisconnect;
  int get playbackBuffer => _playbackBuffer;
  bool get showMetadataCover => _showMetadataCover;
  String get coverQuality => _coverQuality;
  bool get alwaysTryToConnect => _alwaysTryToConnect;
  bool get preferLowBitrate => _preferLowBitrate;
  StorageService get storageService => _storageService;

  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;
    _language = lang;
    await _storageService.setLanguage(lang);
    notifyListeners();
  }

  Future<void> setDefaultCountry(String countryCode) async {
    if (_defaultCountry == countryCode) return;
    _defaultCountry = countryCode;
    await _storageService.setDefaultCountry(countryCode);
    notifyListeners();
  }

  Future<void> setAutoplayOnStartup(bool val) async {
    if (_autoplayOnStartup == val) return;
    _autoplayOnStartup = val;
    await _storageService.setAutoplayOnStartup(val);
    notifyListeners();
  }

  Future<void> setResumeAfterBluetoothDisconnect(bool val) async {
    if (_resumeAfterBluetoothDisconnect == val) return;
    _resumeAfterBluetoothDisconnect = val;
    await _storageService.setResumeAfterBluetoothDisconnect(val);
    notifyListeners();
  }

  Future<void> setPlaybackBuffer(int val) async {
    if (_playbackBuffer == val) return;
    _playbackBuffer = val;
    await _storageService.setPlaybackBuffer(val);
    notifyListeners();
  }

  Future<void> setShowMetadataCover(bool val) async {
    if (_showMetadataCover == val) return;
    _showMetadataCover = val;
    await _storageService.setShowMetadataCover(val);
    notifyListeners();
  }

  Future<void> setCoverQuality(String val) async {
    if (_coverQuality == val) return;
    _coverQuality = val;
    await _storageService.setCoverQuality(val);
    notifyListeners();
  }

  Future<void> setAlwaysTryToConnect(bool val) async {
    if (_alwaysTryToConnect == val) return;
    _alwaysTryToConnect = val;
    await _storageService.setAlwaysTryToConnect(val);
    notifyListeners();
  }

  Future<void> setPreferLowBitrate(bool val) async {
    if (_preferLowBitrate == val) return;
    _preferLowBitrate = val;
    await _storageService.setPreferLowBitrate(val);
    notifyListeners();
  }
}
