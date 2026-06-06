import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stations_provider.dart';
import '../providers/player_provider.dart';
import '../theme/bearwave_theme.dart';
import '../widgets/country_grid.dart';
import '../widgets/station_card.dart';
import '../models/country.dart';
import '../widgets/skeletons/country_card_skeleton.dart';
import '../widgets/skeletons/station_card_skeleton.dart';
import '../l10n/translations.dart';
import '../widgets/error_view.dart';

class WorldScreen extends StatefulWidget {
  const WorldScreen({super.key});

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  String? _selectedCountry;
  String _countrySearchText = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StationsProvider>().loadCountries();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<StationsProvider>().loadMoreStations();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onCountrySelected(Country country) {
    setState(() {
      _selectedCountry = country.name;
    });
    context.read<StationsProvider>().loadByCountryCode(country.code);
  }

  void _backToCategories() {
    setState(() {
      _selectedCountry = null;
    });
  }

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
            Expanded(
              child: Text(
                _selectedCountry == null
                    ? Translations.get(context, 'world')
                    : '${Translations.get(context, 'defaultCountry')}: $_selectedCountry',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: BearWaveTheme.textMain,
        elevation: 0,
        leading: _selectedCountry != null 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _backToCategories,
            )
          : null,
      ),
      body: _selectedCountry != null ? _buildStationList() : _buildCountryGrid(),
    ));
  }

  Widget _buildCountryGrid() {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchField(),
        const SizedBox(height: 12),
        Expanded(child: _buildGrid()),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _countrySearchText.isEmpty
                ? Translations.get(context, 'chooseCountry')
                : Translations.get(context, 'filteredCountries'),
            style: const TextStyle(
              color: BearWaveTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        style: const TextStyle(color: BearWaveTheme.textMain),
        decoration: InputDecoration(
          hintText: Translations.get(context, 'searchHint'),
          hintStyle: const TextStyle(color: BearWaveTheme.textMuted),
          prefixIcon: const Icon(Icons.search, color: BearWaveTheme.textMuted),
          filled: true,
          fillColor: BearWaveTheme.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: BearWaveTheme.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: BearWaveTheme.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: BearWaveTheme.accent),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onChanged: (value) {
          setState(() {
            _countrySearchText = value;
          });
        },
      ),
    );
  }

  Widget _buildGrid() {
    return Consumer<StationsProvider>(
      builder: (context, provider, child) {
        if (provider.lastError.isNotEmpty && provider.countries.isEmpty) {
          return ErrorView(
            errorMessage: provider.lastError,
            onRetry: () => provider.loadCountries(),
          );
        }

        if (provider.loading) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 14,
              itemBuilder: (context, index) => const CountryCardSkeleton(),
            ),
          );
        }

        var countries = provider.countries;
        if (_countrySearchText.isNotEmpty) {
          countries = countries.where((c) =>
              c.name.toLowerCase().contains(_countrySearchText.toLowerCase()) ||
              c.code.toLowerCase().contains(_countrySearchText.toLowerCase()))
              .toList();
        }

        if (countries.isEmpty) {
          return Center(
            child: Text(
              Translations.get(context, 'noCountriesFound'),
              style: const TextStyle(color: BearWaveTheme.textMuted),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadCountries(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CountryGrid(
              physics: const AlwaysScrollableScrollPhysics(),
              countries: countries,
              onCountryTap: _onCountrySelected,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStationList() {
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
  );
}
}