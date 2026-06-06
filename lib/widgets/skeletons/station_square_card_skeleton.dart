import 'package:flutter/material.dart';
import 'bearwave_shimmer.dart';

class StationSquareCardSkeleton extends StatelessWidget {
  const StationSquareCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return BearWaveShimmer(
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(
              width: 150,
              height: 150,
              borderRadius: 20,
            ),
            const SizedBox(height: 12),
            const ShimmerBox(width: 120, height: 16),
            const SizedBox(height: 8),
            const ShimmerBox(width: 80, height: 12),
          ],
        ),
      ),
    );
  }
}
