import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'widgets/product_card.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  static const routeName = '/products';
  final List<Product>? initialProducts;
  final String? screenTitle;

  const ProductListScreen({
    super.key,
    this.initialProducts,
    this.screenTitle,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final Set<String> _favoriteIds = {};

  void _toggleFavorite(Product product) {
    setState(() {
      if (_favoriteIds.contains(product.id)) {
        _favoriteIds.remove(product.id);
      } else {
        _favoriteIds.add(product.id.toString());
      }
    });
  }

  void _addToCart(Product product) {
    final cart = Provider.of<CartService>(context, listen: false);
    cart.add(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to Cart: ${product.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.initialProducts ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.screenTitle?.toUpperCase() ?? 'COLLECTION'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: products.isEmpty
          ? const Center(child: Text('NO PRODUCTS FOUND'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1, // LUXURY: 1 product per row
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95, // MATCH HOME/SHOP
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  isCompact: false,
                  isFavorite: _favoriteIds.contains(product.id),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        product: product,
                        allProducts: products,
                      ),
                    ),
                  ),
                  showFavorite: true,
                  onFavoriteTap: () => _toggleFavorite(product),
                  showQuickAdd: true,
                  onQuickAddTap: () => _addToCart(product),
                );
              },
            ),
    );
  }
}
