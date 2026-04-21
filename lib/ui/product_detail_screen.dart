import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:scentview/models/product_model.dart';
import 'package:scentview/ui/widgets/product_card.dart';
import 'package:scentview/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:scentview/services/cart_service.dart';
import 'package:scentview/services/auth_service.dart';
import 'package:scentview/ui/login_screen.dart';
import 'package:scentview/ui/main_app_screen.dart';
import 'package:iconsax/iconsax.dart';

class ProductDetailScreen extends StatefulWidget {
  static const routeName = '/product-detail';
  final Product product;
  final List<Product> allProducts;

  const ProductDetailScreen({
    required this.product,
    required this.allProducts,
    Key? key,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int _selectedImageIndex = 0;
  int _quantity = 1;
  bool _isFavorite = false;
  late final List<String> _imageUrls;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _imageUrls = [widget.product.imageUrl];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // HIDDEN: Login check bypassed to allow Guest Checkout
  bool _ensureAuthenticated() {
    return true; // Always return true for Guest support
    
  }

  void _openWhatsApp() async {
    const phoneNumber = "+923079417399";
    final onSale = widget.product.salePrice != null &&
        widget.product.salePrice! > 0 &&
        widget.product.salePrice! < widget.product.price;
    final price = onSale ? widget.product.salePrice! : widget.product.price;

    final StringBuffer buffer = StringBuffer();
    buffer.writeln("Assalamu Alaikum! I'm interested in this product:");
    buffer.writeln("*Name:* ${widget.product.name}");
    buffer.writeln("*Price:* PKR ${price.toStringAsFixed(0)}");
    buffer.writeln("");
    buffer.writeln("Can you please provide more details?");

    final url = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(buffer.toString())}';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _addToCart() {
    // Guest can now add to cart
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.add(widget.product, quantity: _quantity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to Cart: ${widget.product.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: AppTheme.accentColor,
          onPressed: () => Navigator.pushNamed(context, '/cart'),
        ),
      ),
    );
  }

  void _buyNow() {
    _addToCart();
    Navigator.pushNamed(context, '/checkout');
  }

  @override
  Widget build(BuildContext context) {
    final bool onSale = widget.product.salePrice != null &&
        widget.product.salePrice! > 0 &&
        widget.product.salePrice! < widget.product.price;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product.name.toUpperCase()),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.black : Colors.black),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Action Buttons ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _addToCart,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black, width: 1.2),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'ADD TO CART',
                            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _buyNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'BUY IT NOW',
                            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // ── Main App Navigation ──────────────────────────────────────────
              Material(
                color: Colors.white,
                child: Consumer<CartService>(
                  builder: (context, cart, _) {
                    return SizedBox(
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NavItem(icon: Iconsax.home, label: 'Home', onTap: () => _goToPage(0)),
                          _NavItem(icon: Iconsax.shop, label: 'Shop', onTap: () => _goToPage(1)),
                          _NavItem(
                            icon: Iconsax.shopping_cart, 
                            label: 'Cart', 
                            badgeCount: cart.itemCount,
                            onTap: () => _goToPage(2),
                          ),
                          _NavItem(icon: Iconsax.login, label: 'Login', onTap: () => _goToPage(3)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _openWhatsApp,
        backgroundColor: const Color(0xFF25D366),
        elevation: 4,
        child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Gallery
            Container(
              height: 400,
              width: double.infinity,
              color: const Color(0xFFF9F9F9),
              child: CachedNetworkImage(
                imageUrl: widget.product.imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.black)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand
                  if (widget.product.brand != null)
                    Text(widget.product.brand!.toUpperCase(),
                        style: AppTheme.bodySans.copyWith(letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
                  
                  const SizedBox(height: 8),
                  
                  // Name
                  Text(widget.product.name, style: AppTheme.headingSerif.copyWith(fontSize: 28)),

                  const SizedBox(height: 16),

                  // Price
                  if (onSale)
                    Row(
                      children: [
                        Text(
                          'Rs ${widget.product.price.toStringAsFixed(0)}',
                          style: AppTheme.bodySans.copyWith(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rs ${widget.product.salePrice!.toStringAsFixed(0)}',
                          style: AppTheme.priceStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Rs ${widget.product.price.toStringAsFixed(0)}',
                      style: AppTheme.priceStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
                    ),

                  const SizedBox(height: 32),
                  
                  const Divider(color: AppTheme.borderColor),
                  
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Text('QUANTITY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            _qtyBtn(Icons.remove, () => setState(() => _quantity > 1 ? _quantity-- : null)),
                            SizedBox(width: 40, child: Center(child: Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold)))),
                            _qtyBtn(Icons.add, () => setState(() => _quantity++)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  // Description
                  const Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.description ?? 'No description available.',
                    style: AppTheme.bodySans.copyWith(height: 1.6, color: Colors.black87),
                  ),

                  const SizedBox(height: 40),
                  
                  // Attributes Table
                  _buildAttrRow('SCENT FAMILY', widget.product.scentFamily ?? 'N/A'),
                  _buildAttrRow('SIZE', widget.product.size ?? 'N/A'),
                  _buildAttrRow('CATEGORY', widget.product.category ?? 'N/A'),

                  const SizedBox(height: 60),
                  
                  // Related Products
                  const Text('RELATED PRODUCTS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
                  const SizedBox(height: 24),
                  _RelatedProducts(product: widget.product, allProducts: widget.allProducts),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor)),
        child: Icon(icon, size: 16),
      ),
    );
  }

  void _goToPage(int index) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MainAppScreen(initialIndex: index)),
      (route) => false,
    );
  }

  Widget _buildAttrRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text(value.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: AppTheme.secondaryColor, size: 24),
              if (badgeCount != null && badgeCount! > 0)
                Positioned(
                  top: -6,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, height: 1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.secondaryColor),
          ),
        ],
      ),
    );
  }
}

class _RelatedProducts extends StatelessWidget {
  final Product product;
  final List<Product> allProducts;

  const _RelatedProducts({required this.product, required this.allProducts});

  @override
  Widget build(BuildContext context) {
    final related = allProducts.where((p) => p.category == product.category && p.id != product.id).toList();
    if (related.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: related.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (ctx, i) => SizedBox(width: 180, child: ProductCard(product: related[i], isCompact: true, onTap: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: related[i], allProducts: allProducts)));
        })),
      ),
    );
  }
}
