import 'package:flutter/material.dart';
import 'bearwave_shimmer.dart';
import '../../theme/bearwave_theme.dart';

class StationCardSkeleton extends StatelessWidget {
  const StationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BearWaveShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BearWaveTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BearWaveTheme.cardBorder),
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 48, height: 48, borderRadius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 150, height: 16),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 100, height: 12),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const ShimmerBox(width: 32, height: 32, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}
