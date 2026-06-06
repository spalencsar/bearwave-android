import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/player_provider.dart';
import '../providers/stations_provider.dart';
import '../services/radio_browser_api.dart';
import '../theme/bearwave_theme.dart';
import '../widgets/station_card.dart';
import '../widgets/skeletons/station_card_skeleton.dart';
import '../l10n/translations.dart';

class StationSearchDelegate extends SearchDelegate<RadioStation?> {
  final RadioBrowserApi _api = RadioBrowserApi();
  final BuildContext context;

  StationSearchDelegate(this.context);

  @override
  String get searchFieldLabel => Translations.get(context, 'searchHint');


  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: BearWaveTheme.panel,
        foregroundColor: BearWaveTheme.textMain,
        elevation: 0,
      ),
      scaffoldBackgroundColor: BearWaveTheme.spaceDark,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: BearWaveTheme.textMuted),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(color: BearWaveTheme.textMain, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) return buildSuggestions(context);

    return Container(
      decoration: const BoxDecoration(gradient: BearWaveTheme.spaceGradient),
      child: FutureBuilder<List<RadioStation>>(
        future: _api.search(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 6,
              itemBuilder: (context, index) => const StationCardSkeleton(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${Translations.get(context, 'searchFailed')}${snapshot.error}',
                style: const TextStyle(color: BearWaveTheme.warn),
              ),
            );
          }
          
          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return Center(
              child: Text(
                Translations.get(context, 'noStationsFound'),
                style: const TextStyle(color: BearWaveTheme.textMuted),
              ),
            );
          }

          return Consumer2<StationsProvider, PlayerProvider>(
            builder: (context, stationsProvider, playerProvider, child) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final station = results[index];
                  final isCurrent = playerProvider.currentStation?.urlResolved == station.urlResolved;
                  
                  // Ensure favorite status is synced locally
                  station.isFavorite = stationsProvider.favorites.any((f) => f.urlResolved == station.urlResolved);

                  return StationCard(
                    station: station,
                    isCurrent: isCurrent,
                    isPlaying: isCurrent && playerProvider.isPlaying,
                    onTap: () {
                      if (isCurrent) {
                        playerProvider.togglePlayPause();
                      } else {
                        playerProvider.playStation(station);
                      }
                      close(context, station);
                    },
                    onPlayTap: () {
                      if (isCurrent) {
                        playerProvider.togglePlayPause();
                      } else {
                        playerProvider.playStation(station);
                      }
                    },
                    onFavoriteTap: () {
                      stationsProvider.toggleFavorite(station);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isNotEmpty) {
      return buildResults(context);
    }
    return Container(
      decoration: const BoxDecoration(gradient: BearWaveTheme.spaceGradient),
      child: Center(
        child: Text(
          Translations.get(context, 'searchPrompt'),
          style: const TextStyle(color: BearWaveTheme.textMuted),
        ),
      ),
    );
  }
}
