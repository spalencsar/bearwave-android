import 'package:bearwave/models/radio_station.dart';
import 'package:bearwave/providers/stations_provider.dart';
import 'package:flutter_test/flutter_test.dart';

RadioStation _station({
  required String name,
  int? bitrate,
  bool? isOnline,
}) {
  return RadioStation(
    name: name,
    url: 'http://example.com/$name',
    urlResolved: 'http://example.com/$name',
    bitrate: bitrate,
    isOnline: isOnline,
  );
}

void main() {
  group('StationsProvider.applyListPreferences', () {
    test('filters offline stations when alwaysTryToConnect is false', () {
      final input = [
        _station(name: 'ok', isOnline: true),
        _station(name: 'down', isOnline: false),
        _station(name: 'unknown'),
      ];

      final result = StationsProvider.applyListPreferences(
        input,
        alwaysTryToConnect: false,
        preferLowBitrate: false,
      );

      expect(result.map((s) => s.name), ['ok', 'unknown']);
    });

    test('keeps offline stations when alwaysTryToConnect is true', () {
      final input = [
        _station(name: 'ok', isOnline: true),
        _station(name: 'down', isOnline: false),
      ];

      final result = StationsProvider.applyListPreferences(
        input,
        alwaysTryToConnect: true,
        preferLowBitrate: false,
      );

      expect(result.map((s) => s.name), ['ok', 'down']);
    });

    test('sorts by bitrate ascending when preferLowBitrate is true', () {
      final input = [
        _station(name: 'high', bitrate: 320),
        _station(name: 'low', bitrate: 64),
        _station(name: 'mid', bitrate: 128),
        _station(name: 'unknown'),
      ];

      final result = StationsProvider.applyListPreferences(
        input,
        alwaysTryToConnect: true,
        preferLowBitrate: true,
      );

      expect(result.map((s) => s.name), ['low', 'mid', 'high', 'unknown']);
    });

    test('filter + sort combine correctly', () {
      final input = [
        _station(name: 'high-down', bitrate: 320, isOnline: false),
        _station(name: 'mid-ok', bitrate: 128, isOnline: true),
        _station(name: 'low-ok', bitrate: 64, isOnline: true),
        _station(name: 'unknown-ok', isOnline: true),
      ];

      final result = StationsProvider.applyListPreferences(
        input,
        alwaysTryToConnect: false,
        preferLowBitrate: true,
      );

      expect(result.map((s) => s.name), ['low-ok', 'mid-ok', 'unknown-ok']);
    });

    test('does not mutate the original list', () {
      final input = [
        _station(name: 'high', bitrate: 320),
        _station(name: 'low', bitrate: 64),
      ];
      final originalOrder = input.map((s) => s.name).toList();

      StationsProvider.applyListPreferences(
        input,
        alwaysTryToConnect: true,
        preferLowBitrate: true,
      );

      expect(input.map((s) => s.name), originalOrder);
    });

    test('empty input stays empty', () {
      final result = StationsProvider.applyListPreferences(
        const [],
        alwaysTryToConnect: false,
        preferLowBitrate: true,
      );
      expect(result, isEmpty);
    });
  });

  group('RadioStation.fromJson lastcheckok', () {
    test('maps lastcheckok 1/0 to isOnline', () {
      final online = RadioStation.fromJson({
        'name': 'A',
        'url': 'http://a',
        'url_resolved': 'http://a',
        'lastcheckok': 1,
      });
      final offline = RadioStation.fromJson({
        'name': 'B',
        'url': 'http://b',
        'url_resolved': 'http://b',
        'lastcheckok': 0,
      });

      expect(online.isOnline, isTrue);
      expect(offline.isOnline, isFalse);
    });

    test('accepts string and bool lastcheckok values', () {
      final fromString = RadioStation.fromJson({
        'name': 'C',
        'url': 'http://c',
        'url_resolved': 'http://c',
        'lastcheckok': '1',
      });
      final fromBool = RadioStation.fromJson({
        'name': 'D',
        'url': 'http://d',
        'url_resolved': 'http://d',
        'lastcheckok': true,
      });
      final fromFalseString = RadioStation.fromJson({
        'name': 'E',
        'url': 'http://e',
        'url_resolved': 'http://e',
        'lastcheckok': '0',
      });

      expect(fromString.isOnline, isTrue);
      expect(fromBool.isOnline, isTrue);
      expect(fromFalseString.isOnline, isFalse);
    });

    test('parses stationuuid, bitrate and votes robustly', () {
      final station = RadioStation.fromJson({
        'stationuuid': 'abc-123',
        'name': 'Test FM',
        'url': 'http://stream',
        'url_resolved': 'http://stream/resolved',
        'bitrate': '192',
        'votes': 42.0,
        'lastcheckok': 1,
      });

      expect(station.uuid, 'abc-123');
      expect(station.bitrate, 192);
      expect(station.votes, 42);
      expect(station.isOnline, isTrue);
      expect(station.urlResolved, 'http://stream/resolved');
    });

    test('falls back to url when url_resolved missing', () {
      final station = RadioStation.fromJson({
        'name': 'Fallback',
        'url': 'http://only-url',
      });
      expect(station.urlResolved, 'http://only-url');
    });
  });
}
