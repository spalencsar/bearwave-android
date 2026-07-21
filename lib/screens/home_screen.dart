import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_station.dart';
import '../providers/stations_provider.dart';
import '../providers/player_provider.dart';
import '../services/radio_browser_api.dart';
import '../theme/bearwave_theme.dart';
import '../widgets/station_card.dart';
import '../widgets/station_square_card.dart';
import '../providers/settings_provider.dart';
import '../l10n/translations.dart';
import '../widgets/genre_chips.dart';
import '../widgets/skeletons/station_card_skeleton.dart';
import '../widgets/skeletons/station_square_card_skeleton.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import '../widgets/error_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedTag;
  final ScrollController _scrollController = ScrollController();

  List<RadioStation>? _topStations;
  List<RadioStation>? _defaultCountryStations;

  late SettingsProvider _settings;

  @override
  void initState() {
    super.initState();
    _settings = context.read<SettingsProvider>();
    _settings.addListener(_onSettingsChanged);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<StationsProvider>().loadMoreStations();
      }
    });

    _loadCarousels();
  }

  void _onSettingsChanged() {
    _loadCarousels();
  }

  Future<void> _loadCarousels() async {
    final api = RadioBrowserApi(); 
    final defaultCountry = _settings.defaultCountry;
    try {
      final top = await api.getTopStations(limit: 20);
      final defaultStations = await api.getByCountryCode(defaultCountry, limit: 20);
      if (mounted) {
        setState(() {
          _topStations = StationsProvider.applyListPreferences(
            top,
            alwaysTryToConnect: _settings.alwaysTryToConnect,
            preferLowBitrate: _settings.preferLowBitrate,
          );
          _defaultCountryStations = StationsProvider.applyListPreferences(
            defaultStations,
            alwaysTryToConnect: _settings.alwaysTryToConnect,
            preferLowBitrate: _settings.preferLowBitrate,
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading carousels: $e');
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onGenreTap(String tag) {
    setState(() {
      if (_selectedTag == tag) {
        _selectedTag = null;
      } else {
        _selectedTag = tag;
        context.read<StationsProvider>().loadByTag(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: BearWaveTheme.spaceGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Image.asset('assets/app/bearwave_line.png', height: 28),
          backgroundColor: Colors.transparent,
          foregroundColor: BearWaveTheme.textMain,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.cast),
              onPressed: () {
                // Future Cast integration
              },
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: BearWaveTheme.bgB,
          child: SafeArea(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings, color: BearWaveTheme.textMain),
                  title: Text(Translations.get(context, 'settings'), style: const TextStyle(color: BearWaveTheme.textMain)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: BearWaveTheme.textMain),
                  title: Text(Translations.get(context, 'about'), style: const TextStyle(color: BearWaveTheme.textMain)),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: BearWaveTheme.textMain),
                  title: Text(Translations.get(context, 'license'), style: const TextStyle(color: BearWaveTheme.textMain)),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: BearWaveTheme.panel,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: const BorderSide(color: BearWaveTheme.cardBorder),
                        ),
                        title: Row(
                          children: [
                            const Icon(Icons.description, color: BearWaveTheme.accent),
                            const SizedBox(width: 12),
                            Text(
                              Translations.get(context, 'license'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        content: const SingleChildScrollView(
                          child: Text(
                            'BearWave is licensed under the GNU GPL-3.0-or-later.\n\n'
                            'This program is free software: you can redistribute it and/or modify '
                            'it under the terms of the GNU General Public License as published by '
                            'the Free Software Foundation, either version 3 of the License, or '
                            '(at your option) any later version.\n\n'
                            'This program is distributed in the hope that it will be useful, '
                            'but WITHOUT ANY WARRANTY; without even the implied warranty of '
                            'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.',
                            style: TextStyle(
                              color: BearWaveTheme.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              Translations.get(context, 'close'),
                              style: const TextStyle(color: BearWaveTheme.accent),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GenreChips(
                genres: GenreChips.defaultGenres,
                selectedTag: _selectedTag,
                onGenreTap: _onGenreTap,
              ),
            ),
            Expanded(
              child: _selectedTag == null
                  ? _buildCarousels()
                  : _buildTagList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousels() {
    return Consumer2<StationsProvider, PlayerProvider>(
      builder: (context, stations, player, child) {
        return RefreshIndicator(
          onRefresh: _loadCarousels,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              if (stations.recentStations.isNotEmpty) ...[
              _buildSectionTitle(Translations.get(context, 'recentStations'), () {}),
              _buildHorizontalList(stations.recentStations, player),
              const SizedBox(height: 24),
            ],
            if (stations.favorites.isNotEmpty) ...[
              _buildSectionTitle(Translations.get(context, 'yourFavorites'), () {}),
              _buildHorizontalList(stations.favorites, player),
              const SizedBox(height: 24),
            ],
            _buildSectionTitle(Translations.get(context, 'topStations'), () {}),
            _buildHorizontalList(_topStations, player),
            const SizedBox(height: 24),
            
            _buildSectionTitle('${Translations.get(context, 'popularIn')}${_settings.defaultCountry}', () {}),
            _buildHorizontalList(_defaultCountryStations, player),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}

  Widget _buildSectionTitle(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: BearWaveTheme.textMain,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              Translations.get(context, 'seeAll'),
              style: const TextStyle(
                color: BearWaveTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<RadioStation>? stationsList, PlayerProvider player) {
    if (stationsList == null) {
      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          itemBuilder: (context, index) => const StationSquareCardSkeleton(),
        ),
      );
    }
    
    if (stationsList.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            Translations.get(context, 'noStationsFound'),
            style: const TextStyle(color: BearWaveTheme.textMuted),
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stationsList.length,
        itemBuilder: (context, index) {
          final station = stationsList[index];
          final isPlaying = player.currentStation?.urlResolved == station.urlResolved;
          
          return StationSquareCard(
            station: station,
            isPlaying: isPlaying,
            onTap: () {
              if (isPlaying) {
                player.togglePlayPause();
              } else {
                player.playStation(station);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildTagList() {
    return Consumer2<StationsProvider, PlayerProvider>(
      builder: (context, stationsProvider, playerProvider, child) {
        if (stationsProvider.lastError.isNotEmpty && stationsProvider.stations.isEmpty) {
          return ErrorView(
            errorMessage: stationsProvider.lastError,
            onRetry: () => stationsProvider.refresh(),
          );
        }

        if (stationsProvider.loading && stationsProvider.stations.isEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: 6,
            itemBuilder: (context, index) => const StationCardSkeleton(),
          );
        }

        final stations = stationsProvider.stations;
        if (stations.isEmpty) {
          return Center(
            child: Text(
              Translations.get(context, 'noStationsFound'),
              style: const TextStyle(color: BearWaveTheme.textMuted),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => stationsProvider.refresh(),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: stations.length + (stationsProvider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
            if (index == stations.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: StationCardSkeleton(),
              );
            }
            final station = stations[index];
            final isCurrent =
                playerProvider.currentStation?.urlResolved ==
                station.urlResolved;

            return StationCard(
              station: station,
              isCurrent: isCurrent,
              isPlaying: isCurrent && playerProvider.isPlaying,
              currentIcyTitle: isCurrent
                  ? playerProvider.currentIcyMetadata?.info?.title
                  : null,
              onTap: () {
                if (isCurrent) {
                  playerProvider.togglePlayPause();
                } else {
                  playerProvider.playStation(station);
                }
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
        ),
      );
    },
  );
}
}
