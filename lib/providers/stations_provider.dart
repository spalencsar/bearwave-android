import 'package:flutter/foundation.dart';
import '../models/radio_station.dart';
import '../models/country.dart';
import '../services/radio_browser_api.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

class StationsProvider extends ChangeNotifier {
  final RadioBrowserApi _api = RadioBrowserApi();
  final StorageService _storage;

  List<RadioStation> _stations = [];
  List<RadioStation> _filteredStations = [];
  List<RadioStation> _favorites = [];
  List<RadioStation> _recentStations = [];
  List<Country> _countries = [];
  
  bool _loading = false;
  String _lastError = '';
  String _filterQuery = '';

  SettingsProvider _settings;

  StationsProvider(this._settings) : _storage = _settings.storageService;

  void updateSettings(SettingsProvider settings) {
    if (_settings.defaultCountry != settings.defaultCountry) {
      _settings = settings;
      // When default country changes, you might want to reload if on home screen
    } else {
      _settings = settings;
    }
  }

  List<RadioStation> get stations => _filteredStations;
  List<RadioStation> get favorites => _favorites;
  List<RadioStation> get recentStations => _recentStations;
  List<Country> get countries => _countries;
  bool get loading => _loading;
  String get lastError => _lastError;
  bool get canResume => _storage.canResume;
  String get lastStationName => _storage.lastStationName;

  Future<void> loadFavorites() async {
    _favorites = await _storage.loadFavorites();
    _syncFavoriteStatus();
    notifyListeners();
  }

  Future<void> loadRecentStations() async {
    _recentStations = await _storage.loadRecentStations();
    notifyListeners();
  }

  void setFilterQuery(String query) {
    _filterQuery = query;
    _applyFilter();
  }

  void _applyFilter() {
    if (_filterQuery.trim().isEmpty) {
      _filteredStations = List.from(_stations);
    } else {
      final lowerQuery = _filterQuery.toLowerCase();
      _filteredStations = _stations.where((s) =>
          s.name.toLowerCase().contains(lowerQuery) ||
          (s.tags?.toLowerCase().contains(lowerQuery) ?? false) ||
          (s.country?.toLowerCase().contains(lowerQuery) ?? false))
          .toList();
    }
    notifyListeners();
  }

  void _syncFavoriteStatus() {
    for (var station in _stations) {
      station.isFavorite = _favorites.any((f) =>
          (f.uuid != null && f.uuid == station.uuid) ||
          (f.uuid == null && f.urlResolved == station.urlResolved));
    }
  }

  int _currentOffset = 0;
  static const int _pageSize = 50;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  Future<List<RadioStation>> Function(int limit, int offset)? _currentLoadFn;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  Future<void> _loadInitial() async {
    if (_currentLoadFn == null) return;
    _setLoading(true);
    _currentOffset = 0;
    _hasMore = true;
    try {
      _stations = await _currentLoadFn!(_pageSize, _currentOffset);
      if (_stations.length < _pageSize) _hasMore = false;
      _currentOffset += _pageSize;
      
      _syncFavoriteStatus();
      _applyFilter();
      _lastError = '';
    } catch (e) {
      _lastError = e.toString();
    }
    _setLoading(false);
  }

  Future<void> loadMoreStations() async {
    if (_isLoadingMore || !_hasMore || _currentLoadFn == null) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      final newStations = await _currentLoadFn!(_pageSize, _currentOffset);
      if (newStations.isEmpty) {
        _hasMore = false;
      } else {
        if (newStations.length < _pageSize) _hasMore = false;
        _stations.addAll(newStations);
        _currentOffset += _pageSize;
        _syncFavoriteStatus();
        _applyFilter();
        _lastError = '';
      }
    } catch (e) {
      _lastError = e.toString();
    }
    
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadTopStations() async {
    _currentLoadFn = (limit, offset) => _api.getTopStations(limit: limit, offset: offset);
    await _loadInitial();
  }

  Future<void> loadGermanStations() async {
    _currentLoadFn = (limit, offset) => _api.getGermanStations(limit: limit, offset: offset);
    await _loadInitial();
  }

  Future<void> loadDutchStations() async {
    _currentLoadFn = (limit, offset) => _api.getDutchStations(limit: limit, offset: offset);
    await _loadInitial();
  }

  Future<void> loadByCountryCode(String countryCode) async {
    _currentLoadFn = (limit, offset) => _api.getByCountryCode(countryCode, limit: limit, offset: offset);
    await _loadInitial();
  }

  Future<void> loadByTag(String tag) async {
    _currentLoadFn = (limit, offset) => _api.getByTag(tag, limit: limit, offset: offset);
    await _loadInitial();
  }

  Future<void> loadWorldStations() async {
    _currentLoadFn = (limit, offset) => _api.getWorldStations(limit: limit, offset: offset);
    await _loadInitial();
  }

  Future<void> loadCountries() async {
    _setLoading(true);
    try {
      _countries = await _api.getCountries();
      _lastError = '';
    } catch (e) {
      _lastError = e.toString();
    }
    _setLoading(false);
  }

  Future<void> searchStations(String query) async {
    if (query.isEmpty) return;
    _currentLoadFn = (limit, offset) => _api.search(query, limit: limit, offset: offset);
    await _loadInitial();
  }

  Future<void> toggleFavorite(RadioStation station) async {
    final existingIndex = _favorites.indexWhere((f) =>
        (f.uuid != null && f.uuid == station.uuid) ||
        (f.uuid == null && f.urlResolved == station.urlResolved));

    if (existingIndex >= 0) {
      _favorites.removeAt(existingIndex);
      station.isFavorite = false;
    } else {
      station.isFavorite = true;
      _favorites.add(station);
    }

    _favorites.sort((a, b) => a.name.compareTo(b.name));
    await _storage.saveFavorites(_favorites);
    notifyListeners();
  }

  Future<void> addManualStation(String name, String url, String country) async {
    final station = RadioStation(
      name: name,
      url: url,
      urlResolved: url,
      country: country.isEmpty ? 'Manual' : country,
      codec: 'unknown',
      bitrate: 0,
      votes: 0,
      isOnline: true,
    );
    _stations.insert(0, station);
    _applyFilter();
  }

  void sortStations(String mode) {
    switch (mode) {
      case 'name':
        _stations.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'bitrate':
        _stations.sort((a, b) => (b.bitrate ?? 0).compareTo(a.bitrate ?? 0));
        break;
      case 'votes':
        _stations.sort((a, b) => (b.votes ?? 0).compareTo(a.votes ?? 0));
        break;
    }
    _applyFilter();
  }

  Future<void> refresh() async {
    _lastError = '';
    if (_currentLoadFn != null) {
      await _loadInitial();
    } else {
      await loadCountries();
    }
  }

  void clearError() {
    _lastError = '';
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }
}