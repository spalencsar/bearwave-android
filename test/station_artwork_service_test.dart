import 'package:bearwave/models/radio_station.dart';
import 'package:bearwave/services/station_artwork_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('parseStationArtworkHtml', () {
    test('prefers touch icons and resolves relative URLs', () {
      final page = parseStationArtworkHtml('''
        <html>
          <head>
            <link rel="icon" sizes="32x32" href="/favicon-32.png">
            <link href="icons/touch.png" rel="apple-touch-icon" sizes="180x180">
            <link rel="manifest" href="/site.webmanifest">
            <meta content="/social.jpg" property="og:image">
          </head>
        </html>
        ''', Uri.parse('https://radio.example/sub/page'));

      expect(page.candidates.map((candidate) => candidate.uri.toString()), [
        'https://radio.example/sub/icons/touch.png',
        'https://radio.example/favicon-32.png',
        'https://radio.example/social.jpg',
      ]);
      expect(page.candidates.last.requireSquare, isTrue);
      expect(
        page.manifestUris.single.toString(),
        'https://radio.example/site.webmanifest',
      );
    });

    test('ignores local network and data URLs', () {
      final page = parseStationArtworkHtml('''
        <link rel="icon" href="http://127.0.0.1/private.png">
        <link rel="icon" href="http://192.168.1.4/private.png">
        <link rel="icon" href="data:image/png;base64,abc">
        ''', Uri.parse('https://radio.example/'));

      expect(page.candidates, isEmpty);
    });
  });

  group('parseStationArtworkManifest', () {
    test('sorts larger manifest icons first', () {
      final candidates = parseStationArtworkManifest('''
        {
          "icons": [
            {"src": "icon-192.png", "sizes": "192x192"},
            {"src": "/icon-512.png", "sizes": "512x512"}
          ]
        }
        ''', Uri.parse('https://radio.example/app/site.webmanifest'));

      expect(candidates.map((candidate) => candidate.uri.toString()), [
        'https://radio.example/icon-512.png',
        'https://radio.example/app/icon-192.png',
      ]);
    });

    test('returns no candidates for malformed JSON', () {
      expect(
        parseStationArtworkManifest(
          'not-json',
          Uri.parse('https://radio.example/site.webmanifest'),
        ),
        isEmpty,
      );
    });
  });

  test(
    'discovery reads a homepage and manifest only once per session',
    () async {
      var homepageRequests = 0;
      var manifestRequests = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/site.webmanifest') {
          manifestRequests++;
          return http.Response(
            '{"icons":[{"src":"/icon-512.png","sizes":"512x512"}]}',
            200,
            request: request,
          );
        }
        homepageRequests++;
        return http.Response(
          '''
        <link rel="icon" href="/favicon.png" sizes="128x128">
        <link rel="manifest" href="/site.webmanifest">
        ''',
          200,
          request: request,
        );
      });
      final service = StationArtworkService(client: client);
      final station = RadioStation(
        name: 'Test Radio',
        url: 'https://stream.example/live',
        urlResolved: 'https://stream.example/live',
        homepage: 'https://radio.example/',
      );

      final first = await service.discover(station);
      final second = await service.discover(station);

      expect(first.map((candidate) => candidate.uri.toString()), [
        'https://radio.example/icon-512.png',
        'https://radio.example/favicon.png',
        'https://radio.example/favicon.ico',
      ]);
      expect(identical(first, second), isTrue);
      expect(homepageRequests, 1);
      expect(manifestRequests, 1);
    },
  );

  test('does not follow redirects into local networks', () async {
    final client = MockClient(
      (request) async => http.Response(
        '',
        302,
        headers: {'location': 'http://127.0.0.1/private'},
        request: request,
      ),
    );
    final service = StationArtworkService(client: client);
    final station = RadioStation(
      name: 'Redirect Radio',
      url: 'https://stream.example/live',
      urlResolved: 'https://stream.example/live',
      homepage: 'https://radio.example/',
    );

    expect(await service.discover(station), isEmpty);
  });

  test('builds the existing Google fallback after local discovery', () {
    final uri = googleFaviconUri('https://radio.example/home');

    expect(uri, isNotNull);
    expect(uri!.host, 't0.gstatic.com');
    expect(uri.queryParameters['size'], '256');
    expect(uri.queryParameters['url'], 'https://radio.example/home');
  });
}
