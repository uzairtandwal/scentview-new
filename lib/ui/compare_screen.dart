import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/compare_service.dart';

class CompareScreen extends StatelessWidget {
  static const routeName = '/compare';
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compareService = Provider.of<CompareService>(context);
    final items = compareService.compareList;
    final hasItems = items.length >= 2;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Compare Perfumes',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        // Clear only shows when there's something to clear
        actions: [
          if (hasItems)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () => compareService.clearCompare(),
                icon: Icon(Iconsax.trash, size: 16,
                    color: theme.colorScheme.error),
                label: Text(
                  'Clear',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: hasItems
          ? _CompareBody(items: items)
          : _EmptyState(),
    );
  }
}

// ─── Compare Body ─────────────────────────────────────────────────────────────
class _CompareBody extends StatelessWidget {
  final List<dynamic> items;
  const _CompareBody({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Pre-compute prices for highlight logic
    final prices = items
        .map((p) => (p.price) as double)
        .toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // ── Product Headers ───────────────────────────────
          _ProductHeaders(items: items, theme: theme),

          const SizedBox(height: 20),

          // ── Compare Rows ──────────────────────────────────
          _CompareSection(
            label: 'Pricing',
            rows: [
              _CompareRowData(
                label: 'Price',
                values: items
                    .map((p) =>
                        'PKR ${(p.price).toStringAsFixed(0)}')
                    .toList()
                    .cast<String>(),
                // Highlight lowest price index
                highlightIndex: prices.indexOf(minPrice),
                highlightGood: true,
              ),
              _CompareRowData(
                label: 'On Sale',
                values: items
                    .map((p) => false ? '✓ Yes' : '✗ No')
                    .toList()
                    .cast<String>(),
                highlightIndex: items
                    .indexWhere((p) => false),
                highlightGood: true,
              ),
            ],
            theme: theme,
          ),

          const SizedBox(height: 12),

          _CompareSection(
            label: 'Product Info',
            rows: [
              _CompareRowData(
                label: 'Category',
                values: items
                    .map((p) => p.category?.toString() ?? 'N/A')
                    .toList()
                    .cast<String>(),
              ),
              _CompareRowData(
                label: 'Badge',
                values: items
                    .map((p) => p.badgeText ?? '—')
                    .toList()
                    .cast<String>(),
              ),
              _CompareRowData(
                label: 'Availability',
                values: items.map((p) {
                  final qty = p.quantity;
                  if (qty == null) return 'In Stock';
                  if (qty == 0) return 'Out of Stock';
                  if (qty <= 10) return 'Only $qty left';
                  return 'In Stock';
                }).toList().cast<String>(),
                highlightIndex: items.indexWhere((p) =>
                    p.quantity == null || p.quantity! > 0),
                highlightGood: true,
              ),
            ],
            theme: theme,
          ),
        ],
      ),
    );
  }
}

// ─── Product Headers ──────────────────────────────────────────────────────────
class _ProductHeaders extends StatelessWidget {
  final List<dynamic> items;
  final ThemeData theme;

  const _ProductHeaders({required this.items, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: items.map((p) {
          final imageUrl = ApiService.toAbsoluteUrl(p.imageUrl);
          return Expanded(
            child: Column(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 110,
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                // Name
                Text(
                  p.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 4),

                // Price pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PKR ${(p.price).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Compare Section ──────────────────────────────────────────────────────────
class _CompareSection extends StatelessWidget {
  final String label;
  final List<_CompareRowData> rows;
  final ThemeData theme;

  const _CompareSection({
    required this.label,
    required this.rows,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Rows
          ...rows.asMap().entries.map((entry) {
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                if (entry.key != 0)
                  Divider(
                    height: 1,
                    color:
                        theme.colorScheme.outline.withValues(alpha: 0.1),
                    indent: 16,
                    endIndent: 16,
                  ),
                _CompareRow(data: entry.value, theme: theme),
                if (isLast) const SizedBox(height: 4),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Compare Row Data ─────────────────────────────────────────────────────────
class _CompareRowData {
  final String label;
  final List<String> values;
  final int highlightIndex;
  final bool highlightGood; // green = good, red = bad

  const _CompareRowData({
    required this.label,
    required this.values,
    this.highlightIndex = -1,
    this.highlightGood = true,
  });
}

// ─── Compare Row ──────────────────────────────────────────────────────────────
class _CompareRow extends StatelessWidget {
  final _CompareRowData data;
  final ThemeData theme;

  const _CompareRow({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final highlightColor = data.highlightGood
        ? const Color(0xFF2E7D32)
        : theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          SizedBox(
            width: 90,
            child: Text(
              data.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Values
          ...data.values.asMap().entries.map((entry) {
            final isHighlighted = entry.key == data.highlightIndex;
            return Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isHighlighted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: highlightColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: highlightColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: highlightColor,
                        ),
                      ),
                    )
                  else
                    Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.75),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.copy, size: 40, color: primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Nothing to compare',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add at least 2 perfumes from the\nshop to compare them side by side.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Iconsax.shop, size: 18),
              label: const Text(
                'Go to Shop',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
