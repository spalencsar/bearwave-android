import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/stations_provider.dart';
import '../theme/bearwave_theme.dart';
import '../screens/expanded_player_sheet.dart';

class PlayerBar extends StatelessWidget {
  final VoidCallback? onTap;

  const PlayerBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, StationsProvider>(
      builder: (context, player, stationsProvider, child) {
        if (player.currentStation == null) {
          return const SizedBox.shrink();
        }

        final station = player.currentStation!;
        final isFavorite = stationsProvider.favorites.any(
          (f) => f.urlResolved == station.urlResolved,
        );

        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: BearWaveTheme.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const ExpandedPlayerSheet(),
                      );
                      if (onTap != null) onTap!();
                    },
                    highlightColor: BearWaveTheme.accent.withValues(alpha: 0.1),
                    splashColor: BearWaveTheme.accent.withValues(alpha: 0.2),
                    child: Row(
                      children: [
                        _buildFavicon(player),
                        const SizedBox(width: 12),
                        _buildInfo(player),
                        // Heart Icon
                        IconButton(
                          onPressed: () =>
                              stationsProvider.toggleFavorite(station),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                          ),
                          color: isFavorite
                              ? const Color(0xFFFF4B4B)
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                        // Play/Pause Button
                        GestureDetector(
                          onTap: player.togglePlayPause,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: BearWaveTheme.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              player.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 28,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavicon(PlayerProvider player) {
    if (player.currentStation == null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: BearWaveTheme.panel,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.radio, color: BearWaveTheme.textMuted),
      );
    }

    final coverUrl = player.currentCoverUrl;
    final fallbackUrl = player.currentStation!.favicon;
    
    final bool hasValidCover = coverUrl != null && coverUrl.startsWith('http');
    final bool hasValidFavicon = fallbackUrl != null && fallbackUrl.startsWith('http');

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: BearWaveTheme.panel,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: (hasValidCover || hasValidFavicon)
            ? CachedNetworkImage(
                imageUrl: hasValidCover ? coverUrl : fallbackUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 150,
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
          padding: const EdgeInsets.all(8.0),
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

  Widget _buildInfo(PlayerProvider player) {
    final metadataTitle = player.currentIcyMetadata?.info?.title;
    final hasMetadata = metadataTitle != null && metadataTitle.isNotEmpty;
    final displayTitle = hasMetadata
        ? metadataTitle
        : player.currentStation!.name;
    final displaySubtitle = hasMetadata
        ? player.currentStation!.name
        : (player.currentStation!.country ?? 'Internet Radio');

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayTitle,
            style: const TextStyle(
              color: BearWaveTheme.textMain,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            displaySubtitle,
            style: TextStyle(
              color: BearWaveTheme.textMuted.withValues(alpha: 0.8),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
