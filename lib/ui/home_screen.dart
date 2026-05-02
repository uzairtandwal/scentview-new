import 'dart:async';
import 'package:flutter/material.dart' hide Category;
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iconsax/iconsax.dart';
import 'package:scentview/models/product_model.dart';
import 'package:scentview/ui/product_list_screen.dart';
import 'package:scentview/theme/app_theme.dart';
import '../models/banner.dart' as model;
import '../models/category.dart';
import '../services/api_service.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/category_card.dart';
import 'widgets/product_card.dart';
import 'widgets/product_shimmer.dart';
import 'product_detail_screen.dart';
import 'main_app_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  final String searchQuery;
  const HomeScreen({super.key, this.searchQuery = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Category> _categories       = [];
  List<Product>  _featuredProducts = [];
  List<model.Banner> _banners      = [];
  List<Product>  _allProducts      = [];
  List<Product>  _filteredProducts = [];
  String? _selectedCategoryId;
  bool    _isLoading               = true;
  bool    _hasError                = false;
  String  _errorMessage            = '';
  bool    _hasShownSalePopup       = false;
  bool    _isTokenSynced           = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _checkAndSyncToken();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _applyFilters();
    }
  }

  Future<void> _checkAndSyncToken() async {
    if (_isTokenSynced) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _api.updateFcmToken(token);
        if (mounted) setState(() => _isTokenSynced = true);
      }
    } catch (_) {}
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    if (!mounted) return;
    _hasShownSalePopup = false;

    // ApiService handles memory cache internally now

    try {
      final localBanners    = await _api.fetchBannersLocal();
      final localCategories = await _api.fetchCategoriesLocal();
      final localProducts   = await _api.fetchProductsLocal();
      final localFeatured   = localProducts.where((p) => p.isFeatured).toList();
      if (mounted && _allProducts.isEmpty && (localProducts.isNotEmpty || localBanners.isNotEmpty)) {
        setState(() {
          _banners         = localBanners;
          _categories      = localCategories;
          _allProducts     = localProducts;
          _featuredProducts = localFeatured;
          _filteredProducts = _computeFiltered(localProducts, localCategories);
          _isLoading       = false;
        });
      }
    } catch (e) { debugPrint("Local Data Error: $e"); }

    try {
      final results = await Future.wait([
        _api.fetchCategories(forceRefresh: forceRefresh).catchError((_) => <Category>[]),
        _api.fetchFeaturedProducts(forceRefresh: forceRefresh).catchError((_) => <Product>[]),
        _api.fetchBanners(forceRefresh: forceRefresh).catchError((_) => <model.Banner>[]),
        _api.fetchProducts(forceRefresh: forceRefresh).catchError((_) => <Product>[]),
      ]).timeout(const Duration(seconds: 45));

      if (!mounted) return;
      final categories = results[0] as List<Category>;
      final featured   = results[1] as List<Product>;
      final banners    = results[2] as List<model.Banner>;
      final all        = results[3] as List<Product>;
      final filtered   = _computeFiltered(all, categories);

      setState(() {
        _categories       = categories;
        _featuredProducts = featured;
        _banners          = banners;
        _allProducts      = all;
        _filteredProducts = filtered;
        _isLoading        = false;
        _hasError         = false;
        if (categories.isEmpty && featured.isEmpty && banners.isEmpty &&
            all.isEmpty && _allProducts.isEmpty) {
          _hasError     = true;
          _errorMessage = "No data received. Please check your connection.";
        }
      });
    } catch (e) {
      debugPrint("Home Data Loading Error: $e");
      if (!mounted) return;
      if (_allProducts.isEmpty) {
        setState(() {
          _hasError     = true;
          _errorMessage = "Connection timeout. Please try again.";
          _isLoading    = false;
        });
      }
    }
  }

  List<Product> _computeFiltered(
      List<Product> products, List<Category> categories) {
    if (widget.searchQuery.isEmpty) {
      return products.where((p) {
        bool matchesCategory = true;
        if (_selectedCategoryId != null) {
          final category = categories.firstWhere(
            (c) => c.id == _selectedCategoryId,
            orElse: () => Category(id: '', name: ''),
          );
          if (category.id.isNotEmpty) {
            matchesCategory =
                p.category?.toLowerCase() == category.name.toLowerCase();
          }
        }
        return matchesCategory;
      }).toList();
    }

    // ── Search Logic (7 matching + 3 extra) ───────────────────────────
    final q = widget.searchQuery.toLowerCase();
    
    // 1. Exact/Partial Name Matches
    final matches = products.where((p) {
      final name = p.name.toLowerCase();
      final desc = (p.description ?? '').toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();

    final topMatches = matches.take(7).toList();
    final matchedIds = topMatches.map((m) => m.id).toSet();

    final extra = products.where((p) => !matchedIds.contains(p.id)).toList();
    final topExtra = extra.take(3).toList();

    return [...topMatches, ...topExtra];
  }

  void _applyFilters() =>
      setState(() => _filteredProducts = _computeFiltered(_allProducts, _categories));

  void _filterByCategory(String? id) {
    if (id == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainAppScreen(initialIndex: 1, initialCategory: 'All')),
        (route) => false,
      );
      return;
    }

    final category = _categories.firstWhere((c) => c.id == id);
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainAppScreen(
          initialIndex: 1,
          initialCategory: category.name,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: () => _loadAllData(forceRefresh: true),
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_isLoading)
                const SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(child: ProductShimmerGrid(itemCount: 6)),
                ),
              if (_hasError && !_isLoading)
                SliverFillRemaining(
                  child: _ErrorState(message: _errorMessage, onRetry: _loadAllData),
                ),
              if (!_isLoading && !_hasError) ...[
                if (widget.searchQuery.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                      ),
                      child: Image.asset(
                        'assets/banner.png.webp',
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: const Color(0xFFF9F9F9),
                          child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                if (_categories.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Shop by Category',
                      subtitle: 'Find your perfect scent family',
                      icon: Iconsax.category,
                      showViewAll: false,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _CategoryList(
                      categories: _categories,
                      products: _allProducts,
                      selectedId: _selectedCategoryId,
                      onSelect: _filterByCategory,
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: widget.searchQuery.isNotEmpty ? 'Search Results' : 'OUTSTANDING FEATURES',
                    subtitle: '',
                    icon: widget.searchQuery.isNotEmpty
                        ? Iconsax.search_normal
                        : Iconsax.shop,
                    showViewAll: false,
                  ),
                ),
                _filteredProducts.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false, child: _NoProducts())
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => ProductCard(
                              product: _filteredProducts[i],
                              isCompact: false,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(
                                    product: _filteredProducts[i],
                                    allProducts: _allProducts,
                                  ),
                                ),
                              ),
                              showQuickAdd: true,
                            ),
                            childCount: _filteredProducts.length > 6 ? 6 : _filteredProducts.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.95,
                          ),
                        ),
                      ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainAppScreen(initialIndex: 1)),
                          (route) => false,
                        ),
                        child: const Text('VIEW ALL PRODUCTS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 20),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<Category> categories;
  final List<Product> products;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _CategoryList({
    required this.categories,
    required this.products,
    required this.selectedId,
    required this.onSelect,
  });

  IconData _getIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('female') || name.contains('women') || name.contains('woman')) return Icons.woman;
    if (name.contains('male') || name.contains('men') || name.contains('man')) return Icons.man;
    if (name.contains('unisex') || name.contains('group')) return Icons.groups;
    return Iconsax.category;
  }

  int _getCount(String categoryName) {
    return products.where((p) => p.category?.toLowerCase() == categoryName.toLowerCase()).length;
  }

  @override
  Widget build(BuildContext context) {
    // Only show Male, Female, Unisex as requested
    final filteredCats = categories.where((c) {
      final n = c.name.toLowerCase();
      return n == 'male' || n == 'female' || n == 'unisex';
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredCats.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, i) {
          final cat = filteredCats[i];
          final isSelected = selectedId == cat.id;
          final count = _getCount(cat.name);
          
          String displayTitle = cat.name;
          if (displayTitle.toLowerCase() == 'male') displayTitle = "Men's";
          if (displayTitle.toLowerCase() == 'female') displayTitle = "Women's";
          if (displayTitle.toLowerCase() == 'unisex') displayTitle = "Unisex";

          return CategoryCard(
            title: displayTitle,
            icon: _getIcon(cat.name),
            isSelected: isSelected,
            productCount: count,
            onTap: () => onSelect(cat.id),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool showViewAll;
  final VoidCallback? onViewAll;

  const _SectionHeader({
    required this.title, required this.subtitle,
    required this.icon, required this.showViewAll, this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
              letterSpacing: 1.5,
              height: 1.1,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
          if (showViewAll && onViewAll != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: onViewAll,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All',
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: AppTheme.primaryColor, size: 10),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoProducts extends StatelessWidget {
  const _NoProducts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Iconsax.search_normal, size: 48, color: AppTheme.secondaryColor),
          SizedBox(height: 16),
          Text('No products found', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.secondaryColor)),
        ]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Iconsax.wifi_square, size: 32, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          const Text('Something went wrong', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppTheme.secondaryColor)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
        ]),
      ),
    );
  }
}
