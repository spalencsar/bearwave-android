import 'package:flutter/material.dart';
import '../models/radio_station.dart';
import '../theme/bearwave_theme.dart';
import 'station_logo.dart';

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
              child: StationLogo(station: station, borderRadius: 18),
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
}
