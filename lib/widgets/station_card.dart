
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/radio_station.dart';
import '../theme/bearwave_theme.dart';

class StationCard extends StatelessWidget {
  final RadioStation station;
  final bool isCurrent;
  final bool isPlaying;
  final String? currentIcyTitle;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onPlayTap;

  const StationCard({
    super.key,
    required this.station,
    this.isCurrent = false,
    this.isPlaying = false,
    this.currentIcyTitle,
    this.onTap,
    this.onFavoriteTap,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: BearWaveTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? BearWaveTheme.accent
              : BearWaveTheme.cardBorder,
          width: isCurrent ? 1.5 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: BearWaveTheme.accent.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            highlightColor: BearWaveTheme.accent.withValues(alpha: 0.1),
            splashColor: BearWaveTheme.accent.withValues(alpha: 0.2),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildFavicon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (isCurrent &&
                                    currentIcyTitle != null &&
                                    currentIcyTitle!.isNotEmpty)
                                ? currentIcyTitle!
                                : station.name,
                            style: TextStyle(
                              color: isCurrent
                                  ? BearWaveTheme.accent
                                  : BearWaveTheme.textMain,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _buildSubtitle(),
                            style: const TextStyle(
                              color: BearWaveTheme.textMuted,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildControls(),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildFavicon() {
    final logoUrl = station.faviconOrFallbackUrl;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: BearWaveTheme.bgB,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: logoUrl != null && logoUrl.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.contain, // Fit contain is better for logos
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
          padding: const EdgeInsets.all(12.0),
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

  Widget _buildControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            station.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: station.isFavorite
                ? BearWaveTheme.warn
                : BearWaveTheme.textMuted,
            size: 24,
          ),
          onPressed: onFavoriteTap,
        ),
        GestureDetector(
          onTap: onPlayTap ?? onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrent
                  ? BearWaveTheme.accent.withValues(alpha: 0.2)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              (isCurrent && isPlaying)
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: isCurrent
                  ? BearWaveTheme.accent
                  : BearWaveTheme.textMain,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (station.country != null && station.country!.isNotEmpty) {
      parts.add(station.country!);
    }
    if (station.codec != null &&
        station.codec != 'unknown' &&
        station.codec!.isNotEmpty) {
      parts.add(station.codec!.toUpperCase());
    }
    return parts.join(' • ');
  }
}
