import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:scentview/models/product_model.dart';
import 'package:scentview/services/cart_service.dart';
import 'package:scentview/ui/cart_screen.dart';

class ProductDetailBottomBar extends StatelessWidget {
  final Product product;
  const ProductDetailBottomBar({required this.product, super.key});

  // ── WhatsApp ───────────────────────────────────────────────────────────────
  Future<void> _openWhatsApp(BuildContext context) async {
    final phone = '+923001234567'; // ← replace with your business number
    final msg = Uri.encodeComponent(
      'Hi! I\'m interested in "${product.name}" — PKR ${product.price.toStringAsFixed(0)}',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open WhatsApp'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── Add to cart ────────────────────────────────────────────────────────────
  void _addToCart(BuildContext context) {
    final cart = Provider.of<CartService>(context, listen: false);
    cart.add(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Iconsax.tick_circle,
                color: const Color(0xFF2E7D32), size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Added to cart!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Buy now ────────────────────────────────────────────────────────────────
  void _buyNow(BuildContext context) {
    final cart = Provider.of<CartService>(context, listen: false);
    cart.add(product);
    Navigator.of(context).pushNamed(CartScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // ── WhatsApp button ───────────────────────────
              _WhatsAppButton(
                onTap: () => _openWhatsApp(context),
                theme: theme,
              ),

              const SizedBox(width: 10),

              // ── Add to Cart ───────────────────────────────
              Expanded(
                child: _OutlineButton(
                  icon: Iconsax.shopping_cart,
                  label: 'Add to Cart',
                  color: primary,
                  theme: theme,
                  onTap: () => _addToCart(context),
                ),
              ),

              const SizedBox(width: 10),

              // ── Buy Now ───────────────────────────────────
              Expanded(
                child: _FilledButton(
                  icon: Iconsax.card,
                  label: 'Buy Now',
                  color: primary,
                  onTap: () => _buyNow(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── WhatsApp Button ──────────────────────────────────────────────────────────
class _WhatsAppButton extends StatelessWidget {
  final VoidCallback onTap;
  final ThemeData theme;

  const _WhatsAppButton({
    required this.onTap,
    required this.theme,
  });

  static const _green = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _green.withValues(alpha: 0.1),
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          child: const FaIcon(
            FontAwesomeIcons.whatsapp,
            color: _green,
            size: 30,
          ),
        ),
      ),
    );
  }
}

// ─── Outline Button (Add to Cart) ────────────────────────────────────────────
class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ThemeData theme;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: color.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filled Button (Buy Now) ──────────────────────────────────────────────────
class _FilledButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FilledButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.zero,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        highlightColor: Colors.white.withValues(alpha: 0.15),
        splashColor: Colors.white.withValues(alpha: 0.2),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
