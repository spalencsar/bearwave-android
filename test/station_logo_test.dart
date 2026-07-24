import 'package:bearwave/widgets/station_logo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stationInitials', () {
    test('uses the first two words', () {
      expect(stationInitials('Antenne Bayern'), 'AB');
      expect(stationInitials('Radio Paradise'), 'RP');
    });

    test('uses the first two characters for a single word', () {
      expect(stationInitials('1LIVE'), '1L');
      expect(stationInitials('SWR3'), 'SW');
    });

    test('handles whitespace, punctuation, and empty names', () {
      expect(stationInitials('  NPO-Radio 2 '), 'NR');
      expect(stationInitials('---'), 'BW');
    });
  });

  group('isUsableStationLogo', () {
    test('accepts images whose shorter edge meets the threshold', () {
      expect(isUsableStationLogo(width: 64, height: 64), isTrue);
      expect(isUsableStationLogo(width: 512, height: 128), isTrue);
    });

    test('rejects images whose shorter edge is too small', () {
      expect(isUsableStationLogo(width: 32, height: 32), isFalse);
      expect(isUsableStationLogo(width: 512, height: 48), isFalse);
    });

    test('requires social images to be approximately square', () {
      expect(
        isUsableStationLogo(width: 512, height: 512, requireSquare: true),
        isTrue,
      );
      expect(
        isUsableStationLogo(width: 1200, height: 630, requireSquare: true),
        isFalse,
      );
    });
  });
}
