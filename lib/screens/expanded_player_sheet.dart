import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/stations_provider.dart';
import '../models/radio_station.dart';
import '../services/cast_service.dart';
import '../theme/bearwave_theme.dart';
import '../widgets/cast_dialog.dart';

class ExpandedPlayerSheet extends StatelessWidget {
  const ExpandedPlayerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, StationsProvider>(
      builder: (context, player, stationsProvider, child) {
        if (player.currentStation == null) {
          return const SizedBox.shrink();
        }

        final station = player.currentStation!;
        final metadataTitle = player.currentIcyMetadata?.info?.title;
        final hasMetadata = metadataTitle != null && metadataTitle.isNotEmpty;
        final displayTitle = hasMetadata ? metadataTitle : station.name;
        final displaySubtitle = hasMetadata
            ? station.name
            : (station.country ?? 'Internet Radio');

        final isFavorite = stationsProvider.favorites.any(
          (f) => f.urlResolved == station.urlResolved,
        );

        return Scaffold(
          backgroundColor: BearWaveTheme.bgA,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Consumer<CastService>(
                builder: (context, castService, child) {
                  return IconButton(
                    icon: Icon(
                      castService.isConnected ? Icons.cast_connected : Icons.cast,
                      color: castService.isConnected
                          ? BearWaveTheme.accent
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const CastDialog(),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: BearWaveTheme.spaceGradient,
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Artwork
                            Hero(
                              tag: 'player_artwork',
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.65,
                                height: MediaQuery.of(context).size.width * 0.65,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 40,
                                      offset: const Offset(0, 20),
                                    ),
                                    BoxShadow(
                                      color: BearWaveTheme.accent.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 60,
                                      spreadRadius: -10,
                                    ),
                                  ],
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: _buildArtwork(player, station),
                                ),
                              ),
                            ),
        
                            const SizedBox(height: 24),
        
                            // Title, Subtitle and Favorite row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayTitle,
                                        style: const TextStyle(
                                          color: BearWaveTheme.textMain,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                          letterSpacing: -0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        displaySubtitle,
                                        style: TextStyle(
                                          color: BearWaveTheme.textMuted.withValues(alpha: 0.9),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => stationsProvider.toggleFavorite(station),
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                  ),
                                  color: isFavorite
                                      ? BearWaveTheme.accent
                                      : BearWaveTheme.textMuted,
                                  iconSize: 32,
                                ),
                              ],
                            ),
        
                            const SizedBox(height: 32),
        
                            // "LIVE" indicator and Cast
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: BearWaveTheme.accent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: BearWaveTheme.accent.withValues(alpha: 0.5)),
                                  ),
                                  child: const Text(
                                    'LIVE RADIO',
                                    style: TextStyle(
                                      color: BearWaveTheme.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                Consumer<CastService>(
                                  builder: (context, castService, child) {
                                    return IconButton(
                                      icon: Icon(
                                        castService.isConnected
                                            ? Icons.cast_connected
                                            : Icons.cast,
                                        color: castService.isConnected
                                            ? BearWaveTheme.accent
                                            : BearWaveTheme.textMuted,
                                      ),
                                      iconSize: 28,
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => const CastDialog(),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
        
                            const SizedBox(height: 24),
        
                            // Main Controls Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Stop Button
                                IconButton(
                                  onPressed: () {
                                    player.stop();
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.stop_rounded),
                                  color: BearWaveTheme.textMuted,
                                  iconSize: 42,
                                ),
                                const SizedBox(width: 32),
                                // Play/Pause Button
                                GestureDetector(
                                  onTap: player.togglePlayPause,
                                  child: Container(
                                    width: 86,
                                    height: 86,
                                    decoration: BoxDecoration(
                                      color: BearWaveTheme.accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: BearWaveTheme.accent.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      player.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      size: 48,
                                      color: BearWaveTheme.bgA,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 32),
                                // Share or Info Button
                                IconButton(
                                  onPressed: () {}, // Future: Share functionality
                                  icon: const Icon(Icons.share_rounded),
                                  color: BearWaveTheme.textMuted,
                                  iconSize: 32,
                                ),
                              ],
                            ),
        
                            const SizedBox(height: 24),
        
                            // Volume Slider
                            Row(
                              children: [
                                Icon(
                                  Icons.volume_down_rounded,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      thumbColor: Colors.white,
                                      overlayColor: Colors.white.withValues(alpha: 0.1),
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                    ),
                                    child: Slider(
                                      value: player.volume,
                                      min: 0.0,
                                      max: 1.0,
                                      onChanged: (value) => player.setVolume(value),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.volume_up_rounded,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtwork(PlayerProvider player, RadioStation station) {
    final coverUrl = player.currentCoverUrl;
    final fallbackUrl = station.faviconOrFallbackUrl;
    
    final bool hasValidCover = coverUrl != null && coverUrl.startsWith('http');
    final bool hasValidFavicon = fallbackUrl != null && fallbackUrl.startsWith('http');

    return ClipRRect(
      key: ValueKey(hasValidCover ? coverUrl : fallbackUrl),
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: (hasValidCover || hasValidFavicon)
            ? CachedNetworkImage(
                imageUrl: hasValidCover ? coverUrl : fallbackUrl!,
                fit: BoxFit.contain, // Fit contain is better for logos to avoid cropping
                memCacheWidth: 600,
                placeholder: (context, url) => _buildDefaultIcon(),
                errorWidget: (context, url, error) => _buildDefaultIcon(),
              )
            : _buildDefaultIcon(),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      color: BearWaveTheme.panel,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Opacity(
            opacity: 0.5,
            child: Image.asset(
              'assets/app/bearwave.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
