import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'widgets/product_card.dart';
import 'product_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  static const routeName = '/search-results';
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<List<Product>> _productsFuture;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _productsFuture = _apiService.fetchProducts();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  List<Product> _processResults(List<Product> allProducts) {
    if (widget.query.isEmpty) return allProducts.take(10).toList();

    final q = widget.query.trim().toLowerCase();
    
    final matches = allProducts.where((p) {
      final name = p.name.toLowerCase();
      final desc = (p.description ?? '').toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList();

    // Take top 7 matches
    final topMatches = matches.take(7).toList();
    final matchedIds = topMatches.map((m) => m.id).toSet();

    final extra = allProducts.where((p) => !matchedIds.contains(p.id)).toList();
    
    // Attempt to pick products from same categories as matches
    if (topMatches.isNotEmpty) {
      final mainCategories = topMatches.map((m) => m.category?.toLowerCase()).toSet();
      extra.sort((a, b) {
        final aIn = mainCategories.contains(a.category?.toLowerCase()) ? 0 : 1;
        final bIn = mainCategories.contains(b.category?.toLowerCase()) ? 0 : 1;
        return aIn.compareTo(bIn);
      });
    }

    final topExtra = extra.take(3).toList();

    // Combine: 7 matches + 3 extra = 10 total
    return [...topMatches, ...topExtra];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SEARCH: ${widget.query.toUpperCase()}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.5),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }
            if (snapshot.hasError) {
              return _buildError(snapshot.error.toString());
            }
            
            final allData = snapshot.data ?? [];
            if (allData.isEmpty) {
              return _buildEmpty();
            }

            final results = _processResults(allData);
            
            if (results.isEmpty) return _buildEmpty();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: results.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ProductCard(
                    product: results[index],
                    isCompact: false,
                    showFavorite: true,
                    showQuickAdd: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(
                          product: results[index],
                          allProducts: allData,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator(color: Colors.black));
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.wifi_square, size: 40, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, style: const TextStyle(color: Colors.grey)),
          TextButton(onPressed: () => setState(() => _productsFuture = _apiService.fetchProducts()), child: const Text('Retry'))
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.search_status, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No results found for "${widget.query}"'),
        ],
      ),
    );
  }
}
