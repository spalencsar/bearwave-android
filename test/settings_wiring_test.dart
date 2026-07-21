import 'package:bearwave/providers/settings_provider.dart';
import 'package:bearwave/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late SettingsProvider settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    await storage.init();
    settings = SettingsProvider(storage);
  });

  group('SettingsProvider ↔ StorageService', () {
    test('defaults match expected v1 values', () {
      expect(settings.playbackBuffer, 30);
      expect(settings.resumeAfterBluetoothDisconnect, isFalse);
      expect(settings.alwaysTryToConnect, isTrue);
      expect(settings.preferLowBitrate, isFalse);
      expect(settings.autoplayOnStartup, isFalse);
      expect(settings.showMetadataCover, isTrue);
    });

    test('playbackBuffer persists through storage', () async {
      await settings.setPlaybackBuffer(75);
      expect(settings.playbackBuffer, 75);
      expect(storage.playbackBuffer, 75);

      final reloaded = SettingsProvider(storage);
      expect(reloaded.playbackBuffer, 75);
    });

    test('resumeAfterBluetoothDisconnect persists', () async {
      await settings.setResumeAfterBluetoothDisconnect(true);
      expect(settings.resumeAfterBluetoothDisconnect, isTrue);
      expect(storage.resumeAfterBluetoothDisconnect, isTrue);
    });

    test('alwaysTryToConnect and preferLowBitrate persist', () async {
      await settings.setAlwaysTryToConnect(false);
      await settings.setPreferLowBitrate(true);

      expect(settings.alwaysTryToConnect, isFalse);
      expect(settings.preferLowBitrate, isTrue);
      expect(storage.alwaysTryToConnect, isFalse);
      expect(storage.preferLowBitrate, isTrue);

      final reloaded = SettingsProvider(storage);
      expect(reloaded.alwaysTryToConnect, isFalse);
      expect(reloaded.preferLowBitrate, isTrue);
    });

    test('setters are no-ops when value unchanged', () async {
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.setPlaybackBuffer(30); // default
      await settings.setPreferLowBitrate(false); // default
      expect(notifications, 0);

      await settings.setPlaybackBuffer(40);
      await settings.setPreferLowBitrate(true);
      expect(notifications, 2);
    });
  });

  group('StorageService volume / resume keys', () {
    test('saveState and volume round-trip', () async {
      await storage.saveState(
        lastStationName: 'Nerd FM',
        lastStationUrl: 'https://stream.example/nerdfm',
        volume: 0.42,
      );

      expect(storage.lastStationName, 'Nerd FM');
      expect(storage.lastStationUrl, 'https://stream.example/nerdfm');
      expect(storage.volume, closeTo(0.42, 0.0001));
      expect(storage.canResume, isTrue);
    });
  });
}
