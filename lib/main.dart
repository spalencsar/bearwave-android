import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/bearwave_audio_handler.dart';
import 'services/cast_service.dart';
import 'services/cover_art_service.dart';
import 'providers/stations_provider.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  await storageService.init();

  final audioHandler = await AudioService.init(
    builder: () => BearWaveAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'de.nerdbear.bearwave.channel.audio',
      androidNotificationChannelName: 'BearWave Audio Playback',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      androidBrowsableRootExtras: {
        'android.media.browse.SEARCH_SUPPORTED': true,
      },
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CastService(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService),
        ),
        Provider(
          create: (_) => CoverArtService(),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, StationsProvider>(
          create: (context) => StationsProvider(Provider.of<SettingsProvider>(context, listen: false)),
          update: (context, settings, previous) => previous!..updateSettings(settings),
        ),
        ChangeNotifierProxyProvider3<StationsProvider, CastService, SettingsProvider, PlayerProvider>(
          create: (context) => PlayerProvider(
            audioHandler,
            storageService,
            context.read<StationsProvider>(),
            context.read<CastService>(),
            context.read<CoverArtService>(),
            context.read<SettingsProvider>(),
          ),
          update: (context, stations, castService, settings, previous) => previous!..updateSettings(settings),
        ),
      ],
      child: const BearWaveApp(),
    ),
  );
}