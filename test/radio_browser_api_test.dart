import 'dart:convert';

import 'package:bearwave/services/radio_browser_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

RadioBrowserServerPool _pool(List<String> servers) {
  return RadioBrowserServerPool(
    resolver: () async => servers,
    shuffleServers: false,
  );
}

RadioBrowserApi _api({
  required http.Client client,
  required List<String> servers,
}) {
  return RadioBrowserApi(
    client: client,
    serverPool: _pool(servers),
    retryDelay: (_) async {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'retries a transient station failure on the next resolved server',
    () async {
      final requestedHosts = <String>[];
      final api = _api(
        servers: ['de1.api.radio-browser.info', 'at1.api.radio-browser.info'],
        client: MockClient((request) async {
          requestedHosts.add(request.url.host);
          if (request.url.host == 'de1.api.radio-browser.info') {
            return http.Response('temporarily unavailable', 503);
          }
          return http.Response(
            json.encode([
              {
                'stationuuid': 'station-1',
                'name': 'Working Radio',
                'url': 'https://example.com/stream',
                'url_resolved': 'https://example.com/stream',
              },
            ]),
            200,
          );
        }),
      );

      final stations = await api.getTopStations(limit: 1);

      expect(requestedHosts, [
        'de1.api.radio-browser.info',
        'at1.api.radio-browser.info',
      ]);
      expect(stations.single.name, 'Working Radio');
    },
  );

  test(
    'retries a transient failure when DNS exposes only one server',
    () async {
      var requests = 0;
      final api = _api(
        servers: ['de1.api.radio-browser.info'],
        client: MockClient((_) async {
          requests++;
          if (requests < 3) {
            return http.Response('temporarily unavailable', 503);
          }
          return http.Response('[]', 200);
        }),
      );

      await api.getTopStations(limit: 1);

      expect(requests, 3);
    },
  );

  test('does not retry a non-transient HTTP error', () async {
    var requests = 0;
    final api = _api(
      servers: ['de1.api.radio-browser.info', 'at1.api.radio-browser.info'],
      client: MockClient((_) async {
        requests++;
        return http.Response('not found', 404);
      }),
    );

    await expectLater(
      api.getTopStations(limit: 1),
      throwsA(
        predicate(
          (error) =>
              error.toString() == 'Exception: Failed to load stations: 404',
        ),
      ),
    );
    expect(requests, 1);
  });

  test('returns cached countries when every server is unavailable', () async {
    var failRequests = false;
    final api = _api(
      servers: ['de1.api.radio-browser.info'],
      client: MockClient((_) async {
        if (failRequests) {
          return http.Response('temporarily unavailable', 503);
        }
        return http.Response(
          json.encode([
            {'name': 'Germany', 'iso_3166_1': 'DE', 'stationcount': 1234},
          ]),
          200,
        );
      }),
    );

    final liveCountries = await api.getCountries();
    failRequests = true;
    final cachedCountries = await api.getCountries();

    expect(liveCountries.single.code, 'DE');
    expect(cachedCountries.single.name, 'Germany');
    expect(cachedCountries.single.stationCount, 1234);
  });

  test('keeps the original 503 error when no country cache exists', () async {
    final api = _api(
      servers: ['de1.api.radio-browser.info'],
      client: MockClient(
        (_) async => http.Response('temporarily unavailable', 503),
      ),
    );

    await expectLater(
      api.getCountries(),
      throwsA(
        predicate(
          (error) =>
              error.toString() == 'Exception: Failed to load countries: 503',
        ),
      ),
    );
  });

  test('ignores resolver values outside the Radio Browser domain', () async {
    final requestedHosts = <String>[];
    final api = _api(
      servers: ['malicious.example', 'DE1.API.RADIO-BROWSER.INFO.'],
      client: MockClient((request) async {
        requestedHosts.add(request.url.host);
        return http.Response('[]', 200);
      }),
    );

    await api.getTopStations(limit: 1);

    expect(requestedHosts.single, 'de1.api.radio-browser.info');
  });
}
