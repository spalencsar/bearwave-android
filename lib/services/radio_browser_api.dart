import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/country.dart';
import '../models/radio_station.dart';

typedef RadioBrowserServerResolver = Future<List<String>> Function();
typedef RadioBrowserRetryDelay = Future<void> Function(Duration duration);

/// Resolves and temporarily tracks healthy Radio Browser API servers.
///
/// Radio Browser explicitly recommends resolving `all.api.radio-browser.info`
/// and retrying a failed request on the next returned server. Instances of
/// [RadioBrowserApi] share the default pool so a server that just returned a
/// transient error is also avoided by parallel catalog and Android Auto calls.
class RadioBrowserServerPool {
  RadioBrowserServerPool({
    RadioBrowserServerResolver? resolver,
    DateTime Function()? now,
    Random? random,
    this.shuffleServers = true,
    this.cacheDuration = const Duration(minutes: 30),
    this.failureCooldown = const Duration(minutes: 1),
  }) : _resolver = resolver ?? _resolveServers,
       _now = now ?? DateTime.now,
       _random = random ?? Random();

  static const String fallbackHost = 'all.api.radio-browser.info';

  final RadioBrowserServerResolver _resolver;
  final DateTime Function() _now;
  final Random _random;
  final bool shuffleServers;
  final Duration cacheDuration;
  final Duration failureCooldown;

  List<String> _cachedServers = const [];
  DateTime? _resolvedAt;
  Future<List<String>>? _resolutionInProgress;
  final Map<String, DateTime> _unhealthyUntil = {};

  Future<List<String>> candidates() async {
    final servers = await _servers();
    final now = _now();
    _unhealthyUntil.removeWhere((_, until) => !until.isAfter(now));

    var available = servers
        .where((host) => !_unhealthyUntil.containsKey(host))
        .toList();
    if (available.isEmpty) {
      // Do not turn a temporary cooldown into a complete outage.
      available = List<String>.from(servers);
    }
    if (shuffleServers && available.length > 1) {
      available.shuffle(_random);
    }
    if (!available.contains(fallbackHost)) {
      available.add(fallbackHost);
    }
    return available;
  }

  void markFailure(String host) {
    _unhealthyUntil[host] = _now().add(failureCooldown);
  }

  void markSuccess(String host) {
    _unhealthyUntil.remove(host);
  }

  Future<List<String>> _servers() {
    final now = _now();
    if (_cachedServers.isNotEmpty &&
        _resolvedAt != null &&
        now.difference(_resolvedAt!) < cacheDuration) {
      return Future.value(_cachedServers);
    }

    final existing = _resolutionInProgress;
    if (existing != null) return existing;

    final resolution = _resolveAndCache();
    _resolutionInProgress = resolution;
    return resolution.whenComplete(() {
      if (identical(_resolutionInProgress, resolution)) {
        _resolutionInProgress = null;
      }
    });
  }

  Future<List<String>> _resolveAndCache() async {
    List<String> resolved;
    try {
      resolved = await _resolver();
    } catch (_) {
      resolved = const [];
    }

    final servers = <String>[];
    for (final value in resolved) {
      final host = _normalizeServerHost(value);
      if (host != null && !servers.contains(host)) {
        servers.add(host);
      }
    }

    _cachedServers = servers.isEmpty ? const [fallbackHost] : servers;
    _resolvedAt = _now();
    return _cachedServers;
  }

  static String? _normalizeServerHost(String value) {
    var host = value.trim().toLowerCase();
    if (host.endsWith('.')) {
      host = host.substring(0, host.length - 1);
    }
    if (host == fallbackHost) return host;
    if (!host.endsWith('.api.radio-browser.info')) return null;

    final prefix = host.substring(
      0,
      host.length - '.api.radio-browser.info'.length,
    );
    if (prefix.isEmpty || prefix.contains('.')) return null;
    return host;
  }

  static Future<List<String>> _resolveServers() async {
    final addresses = await InternetAddress.lookup(
      fallbackHost,
    ).timeout(const Duration(seconds: 3));
    final reverseLookups = addresses.map((address) async {
      try {
        final reversed = await address.reverse().timeout(
          const Duration(seconds: 2),
        );
        return reversed.host;
      } catch (_) {
        return null;
      }
    });
    final hosts = await Future.wait(reverseLookups);
    return hosts.whereType<String>().toList();
  }
}

class RadioBrowserApi {
  RadioBrowserApi({
    this.client,
    RadioBrowserServerPool? serverPool,
    RadioBrowserRetryDelay? retryDelay,
  }) : _serverPool = serverPool ?? _defaultServerPool,
       _retryDelay = retryDelay ?? Future<void>.delayed;

  static const String userAgent = 'BearWave/1.0';
  static const String baseUrl =
      'https://${RadioBrowserServerPool.fallbackHost}/json';
  static const String _countriesCacheKey = 'radioBrowserCountriesCache';
  static const int _maxAttempts = 3;
  static final RadioBrowserServerPool _defaultServerPool =
      RadioBrowserServerPool();

  final http.Client? client;
  final RadioBrowserServerPool _serverPool;
  final RadioBrowserRetryDelay _retryDelay;

  Future<List<RadioStation>> getTopStations({
    int limit = 50,
    int offset = 0,
  }) async {
    return _getStations('/stations/topvote/$limit?offset=$offset');
  }

  Future<List<RadioStation>> getGermanStations({
    int limit = 50,
    int offset = 0,
  }) async {
    return _getStations(
      '/stations/bycountrycodeexact/DE'
      '?limit=$limit&order=votes&reverse=true&offset=$offset',
    );
  }

  Future<List<RadioStation>> getDutchStations({
    int limit = 50,
    int offset = 0,
  }) async {
    return _getStations(
      '/stations/bycountrycodeexact/NL'
      '?limit=$limit&order=votes&reverse=true&offset=$offset',
    );
  }

  Future<List<RadioStation>> getByCountryCode(
    String countryCode, {
    int limit = 50,
    int offset = 0,
  }) async {
    return _getStations(
      '/stations/bycountrycodeexact/${countryCode.toUpperCase()}'
      '?limit=$limit&order=votes&reverse=true&offset=$offset',
    );
  }

  Future<List<RadioStation>> getByTag(
    String tag, {
    int limit = 50,
    int offset = 0,
  }) async {
    final encodedTag = Uri.encodeComponent(tag);
    return _getStations(
      '/stations/bytag/$encodedTag'
      '?limit=$limit&order=votes&reverse=true&offset=$offset',
    );
  }

  Future<List<RadioStation>> getWorldStations({
    int limit = 50,
    int offset = 0,
  }) async {
    return _getStations(
      '/stations'
      '?hidebroken=true&limit=$limit&order=votes&reverse=true&offset=$offset',
    );
  }

  Future<List<RadioStation>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final encodedQuery = Uri.encodeComponent(query);
    return _getStations(
      '/stations/search'
      '?name=$encodedQuery&hidebroken=true&limit=$limit'
      '&order=votes&reverse=true&offset=$offset',
    );
  }

  Future<List<Country>> getCountries() async {
    try {
      final response = await _get('/countries', resourceName: 'countries');
      final countries = _parseCountries(response.body);
      await _saveCountriesCache(countries);
      return countries;
    } catch (_) {
      final cachedCountries = await _loadCountriesCache();
      if (cachedCountries.isNotEmpty) {
        return cachedCountries;
      }
      rethrow;
    }
  }

  Future<List<RadioStation>> _getStations(String endpoint) async {
    final response = await _get(endpoint, resourceName: 'stations');
    final List<dynamic> data = json.decode(response.body) as List<dynamic>;
    return data
        .map(
          (entry) =>
              RadioStation.fromJson(Map<String, dynamic>.from(entry as Map)),
        )
        .where(
          (station) =>
              station.name.isNotEmpty && station.urlResolved.isNotEmpty,
        )
        .toList();
  }

  Future<http.Response> _get(
    String endpoint, {
    required String resourceName,
  }) async {
    final candidates = await _serverPool.candidates();
    final attempts = candidates.take(_maxAttempts).toList();
    while (attempts.isNotEmpty && attempts.length < _maxAttempts) {
      // A resolver may temporarily expose only one node. Retrying the same
      // route after a short delay still recovers brief gateway overloads.
      attempts.add(attempts.last);
    }
    int? lastStatusCode;
    Object? lastNetworkError;

    for (var index = 0; index < attempts.length; index++) {
      final host = attempts[index];
      final url = Uri.parse('https://$host/json$endpoint');

      try {
        final request = client == null
            ? http.get(url, headers: const {'User-Agent': userAgent})
            : client!.get(url, headers: const {'User-Agent': userAgent});
        final response = await request.timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          _serverPool.markSuccess(host);
          return response;
        }

        lastStatusCode = response.statusCode;
        if (!_isRetryableStatus(response.statusCode)) {
          throw Exception(
            'Failed to load $resourceName: ${response.statusCode}',
          );
        }
        _serverPool.markFailure(host);
      } on TimeoutException catch (error) {
        lastNetworkError = error;
        _serverPool.markFailure(host);
      } on SocketException catch (error) {
        lastNetworkError = error;
        _serverPool.markFailure(host);
      } on HandshakeException catch (error) {
        lastNetworkError = error;
        _serverPool.markFailure(host);
      } on HttpException catch (error) {
        lastNetworkError = error;
        _serverPool.markFailure(host);
      } on http.ClientException catch (error) {
        lastNetworkError = error;
        _serverPool.markFailure(host);
      }

      if (index + 1 < attempts.length) {
        await _retryDelay(_retryDuration(index));
      }
    }

    if (lastStatusCode != null) {
      throw Exception('Failed to load $resourceName: $lastStatusCode');
    }
    throw Exception('Failed to load $resourceName: $lastNetworkError');
  }

  static bool _isRetryableStatus(int statusCode) {
    return statusCode == 429 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  static Duration _retryDuration(int retryIndex) {
    return Duration(milliseconds: retryIndex == 0 ? 250 : 750);
  }

  static List<Country> _parseCountries(String body) {
    final List<dynamic> data = json.decode(body) as List<dynamic>;
    return data
        .map(
          (entry) => Country.fromJson(Map<String, dynamic>.from(entry as Map)),
        )
        .where((country) => country.name.isNotEmpty && country.stationCount > 0)
        .toList();
  }

  static Future<void> _saveCountriesCache(List<Country> countries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = countries
          .map(
            (country) => {
              'name': country.name,
              'iso_3166_1': country.code,
              'stationcount': country.stationCount,
            },
          )
          .toList();
      await prefs.setString(_countriesCacheKey, json.encode(data));
    } catch (_) {
      // A cache write must never turn a successful API response into a failure.
    }
  }

  static Future<List<Country>> _loadCountriesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final data = prefs.getString(_countriesCacheKey);
      if (data == null || data.isEmpty) return const [];
      return _parseCountries(data);
    } catch (_) {
      return const [];
    }
  }
}
