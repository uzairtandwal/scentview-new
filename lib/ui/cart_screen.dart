import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../services/cart_service.dart';
import '../services/api_service.dart';
import 'checkout_screen.dart';
import '../theme/app_theme.dart';

class CartScreen extends StatelessWidget {
  static const routeName = '/cart';
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cart, _) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('MY CART'),
          ),
          body: cart.items.isEmpty
              ? _EmptyCart()
              : _CartBody(cart: cart),
        );
      },
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.shopping_bag, size: 60, color: Colors.black26),
          const SizedBox(height: 24),
          Text('YOUR CART IS EMPTY', style: AppTheme.headingSerif.copyWith(fontSize: 18)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/main-app', (route) => false, arguments: 1),
            child: const Text('START SHOPPING'),
          ),
        ],
      ),
    );
  }
}

class _CartBody extends StatelessWidget {
  final CartService cart;
  const _CartBody({required this.cart});

  @override
  Widget build(BuildContext context) {
    final uniqueProducts = cart.uniqueItems;
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            itemCount: uniqueProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) {
              final product = uniqueProducts[i];
              return _CartItemCard(
                product: product,
                quantity: cart.getQuantity(product),
                cart: cart,
              );
            },
          ),
        ),
        _CheckoutSection(cart: cart),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final dynamic product;
  final int quantity;
  final CartService cart;

  const _CartItemCard({
    required this.product,
    required this.quantity,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiService.toAbsoluteUrl(product.imageUrl);
    final bool onSale = product.salePrice != null && product.salePrice! > 0 && product.salePrice! < product.price;
    final double effectivePrice = onSale ? product.salePrice! : product.price;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            color: const Color(0xFFF9F9F9),
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                : const Icon(Icons.image_outlined),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name.toUpperCase(), style: AppTheme.headingSerif.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Rs ${effectivePrice.toStringAsFixed(0)}', style: AppTheme.priceStyle.copyWith(fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _qtyBtn(Icons.remove, () => cart.updateQuantity(product, quantity - 1)),
                      SizedBox(width: 30, child: Center(child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)))),
                      _qtyBtn(Icons.add, () => cart.updateQuantity(product, quantity + 1)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.trash, size: 18, color: Colors.black54),
            onPressed: () => cart.removeItem(product.id),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor)),
        child: Icon(icon, size: 14),
      ),
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  final CartService cart;
  const _CheckoutSection({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL AMOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text('Rs ${cart.totalPrice.toStringAsFixed(0)}', style: AppTheme.priceStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, CheckoutScreen.routeName),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                child: const Text('PROCEED TO CHECKOUT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
