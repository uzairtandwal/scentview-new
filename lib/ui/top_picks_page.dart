import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/product_card.dart';
import 'widgets/product_shimmer.dart';

class TopPicksPage extends StatefulWidget {
  static const routeName = '/top-picks';
  const TopPicksPage({super.key});

  @override
  State<TopPicksPage> createState() => _TopPicksPageState();
}

class _TopPicksPageState extends State<TopPicksPage> {
  final ApiService _api = ApiService();

  List<Product> _allProducts = [];
  bool _isLoading = true;
  bool _hasError  = false;

  // ── Filter & sort state ────────────────────────────────────────────────────
  String _selectedCategory = 'All';
  double _maxPrice         = 50000;
  String _sortBy           = 'Newest';

  static const _sortOptions = [
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
    'Name A-Z',
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _hasError  = false;
    });
    try {
      final products = await _api.fetchProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _isLoading   = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError  = true;
        _isLoading = false;
      });
    }
  }

  // ── Sorted + filtered list ─────────────────────────────────────────────────
  List<Product> get _displayed {
    var list = _allProducts.where((p) {
      final matchCat = _selectedCategory == 'All' ||
          p.category == _selectedCategory;
      final matchPrice =
          (p.price) <= _maxPrice;
      return matchCat && matchPrice;
    }).toList();

    switch (_sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) =>
            (a.price)
                .compareTo(b.price));
        break;
      case 'Price: High to Low':
        list.sort((a, b) =>
            (b.price)
                .compareTo(a.price));
        break;
      case 'Name A-Z':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return list;
  }

  // ── Sort sheet ─────────────────────────────────────────────────────────────
  void _showSortSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24, 16, 24,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            ..._sortOptions.map((opt) {
              final isSelected = _sortBy == opt;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Iconsax.tick_circle,
                        color: theme.colorScheme.primary, size: 20)
                    : null,
                onTap: () {
                  setState(() => _sortBy = opt);
                  Navigator.pop(context);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Filter sheet ───────────────────────────────────────────────────────────
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        onApply: (cat, price, sort) {
          setState(() {
            _selectedCategory = cat;
            _maxPrice         = price;
            _sortBy           = sort;
          });
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final primary  = theme.colorScheme.primary;
    final products = _displayed;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left_2,
              color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Top Picks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Sort + Filter toolbar ─────────────────────────
          Container(
            color: theme.colorScheme.surface,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Sort button
                Expanded(
                  child: _ToolbarButton(
                    icon: Iconsax.sort,
                    label: _sortBy == 'Newest' ? 'Sort' : _sortBy,
                    isActive: _sortBy != 'Newest',
                    theme: theme,
                    onTap: _showSortSheet,
                  ),
                ),
                const SizedBox(width: 12),
                // Filter button
                Expanded(
                  child: _ToolbarButton(
                    icon: Iconsax.filter_edit,
                    label: _selectedCategory != 'All'
                        ? _selectedCategory
                        : 'Filter',
                    isActive: _selectedCategory != 'All' ||
                        _maxPrice < 50000,
                    theme: theme,
                    onTap: _showFilterSheet,
                  ),
                ),

                // Clear filters — only when active
                if (_selectedCategory != 'All' ||
                    _maxPrice < 50000 ||
                    _sortBy != 'Newest') ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = 'All';
                      _maxPrice         = 50000;
                      _sortBy           = 'Newest';
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Results count ─────────────────────────────────
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
              child: Row(
                children: [
                  Text(
                    '${products.length} item${products.length != 1 ? 's' : ''} found',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),

          // ── Content ───────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: ProductShimmerGrid(itemCount: 6),
                  )
                : _hasError
                    ? _ErrorState(onRetry: _fetchProducts)
                    : products.isEmpty
                        ? _EmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetchProducts,
                            color: primary,
                            child: CustomScrollView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 32),
                                  sliver: SliverGrid(
                                    delegate:
                                        SliverChildBuilderDelegate(
                                      (_, i) => ProductCard(
                                        product: products[i],
                                        isCompact: false,
                                        showQuickAdd: true,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductDetailScreen(
                                              product: products[i],
                                              allProducts:
                                                  _allProducts,
                                            ),
                                          ),
                                        ),
                                      ),
                                      childCount: products.length,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 0.70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ─── Toolbar Button ───────────────────────────────────────────────────────────
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Material(
      color: isActive
          ? primary.withValues(alpha: 0.1)
          : theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? primary
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.shop,
                  size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters.',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.wifi_square,
                  size: 32, color: theme.colorScheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
