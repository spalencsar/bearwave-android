import 'package:flutter/material.dart';
import 'bearwave_shimmer.dart';
import '../../theme/bearwave_theme.dart';

class CountryCardSkeleton extends StatelessWidget {
  const CountryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BearWaveShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: BearWaveTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BearWaveTheme.cardBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const ShimmerBox(width: 32, height: 24, borderRadius: 4),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 80, height: 14),
                  const SizedBox(height: 6),
                  const ShimmerBox(width: 50, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
