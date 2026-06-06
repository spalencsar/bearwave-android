import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/bearwave_theme.dart';

class BearWaveShimmer extends StatelessWidget {
  final Widget child;

  const BearWaveShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: BearWaveTheme.panel,
      highlightColor: BearWaveTheme.cardHover,
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
