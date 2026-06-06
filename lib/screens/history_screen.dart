import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stations_provider.dart';
import '../providers/player_provider.dart';
import '../theme/bearwave_theme.dart';
import '../widgets/station_card.dart';
import '../l10n/translations.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: BearWaveTheme.spaceGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/app/bearwave.png', height: 24),
            const SizedBox(width: 8),
            Text(
              Translations.get(context, 'history'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: BearWaveTheme.textMain,
        elevation: 0,
      ),
      body: Consumer2<StationsProvider, PlayerProvider>(
        builder: (context, stationsProvider, playerProvider, child) {
          final recentStations = stationsProvider.recentStations;

          if (recentStations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.history,
                    size: 64,
                    color: BearWaveTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Translations.get(context, 'historyEmptyTitle'),
                    style: const TextStyle(
                      color: BearWaveTheme.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Translations.get(context, 'historyEmptySubtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: BearWaveTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: recentStations.length,
            itemBuilder: (context, index) {
              final station = recentStations[index];
              final isCurrent = playerProvider.currentStation?.urlResolved == station.urlResolved;

              return StationCard(
                station: station,
                isCurrent: isCurrent,
                isPlaying: isCurrent && playerProvider.isPlaying,
                currentIcyTitle: isCurrent ? playerProvider.currentIcyMetadata?.info?.title : null,
                onTap: () {
                  if (isCurrent) {
                    playerProvider.togglePlayPause();
                  } else {
                    playerProvider.playStation(station);
                  }
                },
                onFavoriteTap: () {
                  stationsProvider.toggleFavorite(station);
                },
                onPlayTap: () {
                  if (isCurrent) {
                    playerProvider.togglePlayPause();
                  } else {
                    playerProvider.playStation(station);
                  }
                },
              );
            },
          );
        },
      ),
    ));
  }
}