import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../colors.dart';
import '../spacing.dart';

class SteplySkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SteplySkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = SteplyRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: SteplyColors.divider.withOpacity(0.4),
      highlightColor: SteplyColors.cloudWhite,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: SteplyColors.divider,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Card-shaped skeleton for place cards
class SteplyCardSkeleton extends StatelessWidget {
  final bool showImage;

  const SteplyCardSkeleton({super.key, this.showImage = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SteplyColors.cloudWhite,
        borderRadius: BorderRadius.circular(SteplyRadius.xl),
        border: Border.all(color: SteplyColors.divider.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage)
            SteplySkeleton(
              height: 140,
              borderRadius: SteplyRadius.xl,
            ),
          Padding(
            padding: const EdgeInsets.all(SteplySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SteplySkeleton(height: 16, width: 180),
                SizedBox(height: SteplySpacing.sm),
                SteplySkeleton(height: 12, width: 240),
                SizedBox(height: 4),
                SteplySkeleton(height: 12, width: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
