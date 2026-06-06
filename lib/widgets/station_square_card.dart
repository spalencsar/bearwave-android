import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/radio_station.dart';
import '../theme/bearwave_theme.dart';

class StationSquareCard extends StatelessWidget {
  final RadioStation station;
  final VoidCallback onTap;
  final bool isPlaying;

  const StationSquareCard({
    super.key,
    required this.station,
    required this.onTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork Square
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: BearWaveTheme.panel,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isPlaying
                    ? Border.all(color: BearWaveTheme.accent, width: 2)
                    : Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: station.favicon != null && station.favicon!.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: station.favicon!,
                        fit: BoxFit.cover,
                        memCacheWidth: 300,
                        placeholder: (context, url) => _buildDefaultIcon(),
                        errorWidget: (context, url, error) => _buildDefaultIcon(),
                      )
                    : _buildDefaultIcon(),
              ),
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              station.name.trim(),
              style: const TextStyle(
                color: BearWaveTheme.textMain,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Subtitle
            Text(
              station.country ?? station.tags ?? 'Internet Radio',
              style: TextStyle(
                color: BearWaveTheme.textMuted.withValues(alpha: 0.8),
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      color: BearWaveTheme.card,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
