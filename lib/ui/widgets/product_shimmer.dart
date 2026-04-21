import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Matches ProductCard layout exactly:
/// - Flex 7 image area
/// - Flex 3 info area (name + price placeholders)
/// - Uses theme colors — dark mode ready
class ProductShimmer extends StatelessWidget {
  final bool isCompact;

  const ProductShimmer({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ Theme-aware shimmer colors
    final baseColor = theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: isCompact ? 6 : 7,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white, // shimmer paints over this
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
              ),
            ),

            // ── Info Placeholder (flex 3 — matches ProductCard) ───
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  isCompact ? 6 : 8,
                  12,
                  isCompact ? 6 : 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Name placeholder
                    Container(
                      height: isCompact ? 11 : 13,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),

                    Container(
                      height: isCompact ? 10 : 12,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Drop-in grid helper — replaces GridView content while loading
/// Usage:
/// ```dart
/// isLoading
///   ? const ProductShimmerGrid()
///   : GridView.builder(...)
/// ```
class ProductShimmerGrid extends StatelessWidget {
  final int itemCount;
  final bool isCompact;
  final EdgeInsets? padding;

  const ProductShimmerGrid({
    super.key,
    this.itemCount = 6,
    this.isCompact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => ProductShimmer(isCompact: isCompact),
    );
  }
}
