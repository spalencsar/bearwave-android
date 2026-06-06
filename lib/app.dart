import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/stations_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/player_provider.dart';
import 'theme/bearwave_theme.dart';
import 'screens/home_screen.dart';
import 'screens/world_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/history_screen.dart';
import 'screens/station_search_delegate.dart';
import 'l10n/translations.dart';
import 'widgets/player_bar.dart';

class BearWaveApp extends StatefulWidget {
  const BearWaveApp({super.key});

  @override
  State<BearWaveApp> createState() => _BearWaveAppState();
}

class _BearWaveAppState extends State<BearWaveApp> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final stationsProvider = context.read<StationsProvider>();
      await stationsProvider.loadFavorites();
      await stationsProvider.loadRecentStations();
      
      if (mounted) {
        final settings = context.read<SettingsProvider>();
        if (settings.autoplayOnStartup && stationsProvider.recentStations.isNotEmpty) {
          final player = context.read<PlayerProvider>();
          // Only play if not already playing (to prevent multiple starts)
          if (player.currentStation == null) {
            player.playStation(stationsProvider.recentStations.first);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BearWave',
      debugShowCheckedModeBanner: false,
      theme: BearWaveTheme.theme,
      home: Builder(
        builder: (builderContext) {
          return Container(
            decoration: const BoxDecoration(gradient: BearWaveTheme.spaceGradient),
            child: Scaffold(
              extendBody: true,
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  Expanded(
                    child: _buildCurrentScreen(),
                  ),
                  PlayerBar(
                    onTap: () {},
                  ),
                ],
              ),
              bottomNavigationBar: _buildBottomNavBar(builderContext),
            ),
          );
        }
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentTabIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const WorldScreen();
      case 2:
        return const FavoritesScreen();
      case 3:
        return const Scaffold(); // Placeholder for dedicated search screen
      case 4:
        return const HistoryScreen();
      default:
        return const HomeScreen();
    }
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentTabIndex,
      backgroundColor: BearWaveTheme.panel,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: BearWaveTheme.accent,
      unselectedItemColor: BearWaveTheme.textMuted,
      onTap: (index) {
        if (index == 3) {
          // Open the SearchDelegate instead of a placeholder screen
          // Actually, since SearchDelegate is an overlay, we could just launch it and not change index.
          // Or we can create a dedicated SearchScreen widget. For now, let's just launch the delegate
          // and revert the index if it was selected.
          showSearch(context: context, delegate: StationSearchDelegate(context));
          return;
        }
        setState(() {
          _currentTabIndex = index;
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: Translations.get(context, 'home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.language_outlined),
          activeIcon: const Icon(Icons.language),
          label: Translations.get(context, 'world'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.favorite_outline),
          activeIcon: const Icon(Icons.favorite),
          label: Translations.get(context, 'favorites'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.search),
          label: Translations.get(context, 'search'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history),
          label: Translations.get(context, 'history'),
        ),
      ],
    );
  }
}