import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stations_provider.dart';
import '../providers/player_provider.dart';
import '../theme/bearwave_theme.dart';
import '../widgets/station_card.dart';
import '../l10n/translations.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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
              Translations.get(context, 'favorites'),
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
          final favorites = stationsProvider.favorites;

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_border,
                    size: 64,
                    color: BearWaveTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Translations.get(context, 'favoritesEmptyTitle'),
                    style: const TextStyle(
                      color: BearWaveTheme.textMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Translations.get(context, 'favoritesEmptySubtitle'),
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

          return RefreshIndicator(
            onRefresh: () => stationsProvider.loadFavorites(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final station = favorites[index];
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
            ),
          );
        },
      ),
    ));
  }
}