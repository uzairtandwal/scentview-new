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
import 'package:carousel_slider/carousel_slider.dart';

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
  int _selectedVariantIndex = 0;
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isFavorite = false;
  late List<String> _imageUrls;
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  void initState() {
    super.initState();
    
    // ✅ Default to 50ml if available in variants
    if (widget.product.variants.isNotEmpty) {
      int index50ml = widget.product.variants.indexWhere((v) => v.size.toLowerCase().contains('50ml'));
      _selectedVariantIndex = (index50ml != -1) ? index50ml : 0;
    }
    
    _initializeGallery(initial: true);
  }

  void _initializeGallery({bool initial = false}) {
    List<String> finalGallery = [];
    
    // 1. Determine Selection
    bool is100mlActive = false;
    if (widget.product.variants.isNotEmpty && _selectedVariantIndex < widget.product.variants.length) {
      is100mlActive = widget.product.variants[_selectedVariantIndex].size.toLowerCase().contains('100ml');
    }

    // 2. Strict Portion Extraction
    if (is100mlActive) {
      // Show ONLY 100ml images if available, else fallback to 100ml main image
      if (widget.product.images100ml.isNotEmpty) {
        finalGallery = List.from(widget.product.images100ml);
      } else if (widget.product.imageUrl100ml != null && widget.product.imageUrl100ml!.isNotEmpty && widget.product.imageUrl100ml != "null") {
        finalGallery = [widget.product.imageUrl100ml!];
      }
    } else {
      // Show ONLY 50ml images if available, else fallback to main image (usually 50ml)
      if (widget.product.images50ml.isNotEmpty) {
        finalGallery = List.from(widget.product.images50ml);
      } else {
        finalGallery = [widget.product.imageUrl];
      }
    }
    
    // Fallback: If everything empty, show main image
    if (finalGallery.isEmpty || (finalGallery.length == 1 && finalGallery[0].isEmpty)) {
      finalGallery = [widget.product.imageUrl];
    }

    setState(() {
      _imageUrls = finalGallery;
      _currentImageIndex = 0; // Reset index to first image of new variant
      
      // Safety Check: Only jump if slider is attached
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_carouselController != null) {
          try {
            _carouselController.jumpToPage(0);
          } catch (_) {}
        }
      });
    });
  }

  double get _currentPrice {
    if (widget.product.variants.isNotEmpty && _selectedVariantIndex < widget.product.variants.length) {
      return widget.product.variants[_selectedVariantIndex].price;
    }
    return widget.product.price;
  }

  String get _currentSize {
    if (widget.product.variants.isNotEmpty && _selectedVariantIndex < widget.product.variants.length) {
      return widget.product.variants[_selectedVariantIndex].size;
    }
    return widget.product.size ?? 'N/A';
  }

  void _openWhatsApp() async {
    const phoneNumber = "+923079417399";
    final onSale = widget.product.salePrice != null && (widget.product.salePrice ?? 0) > 0;
    final price = onSale ? (widget.product.salePrice ?? _currentPrice) : _currentPrice;

    final StringBuffer buffer = StringBuffer();
    buffer.writeln("Assalamu Alaikum! I'm interested in this product:");
    buffer.writeln("*Name:* ${widget.product.name}");
    buffer.writeln("*Price:* PKR ${price.toStringAsFixed(0)}");
    buffer.writeln("");
    buffer.writeln("Can you please provide more details?");

    final url = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(buffer.toString())}';
    try { if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } catch (_) {}
  }

  void _addToCart() {
    final cartService = Provider.of<CartService>(context, listen: false);
    cartService.add(widget.product, quantity: _quantity);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to Cart: ${widget.product.name}'), backgroundColor: Colors.black, behavior: SnackBarBehavior.floating, action: SnackBarAction(label: 'VIEW', textColor: AppTheme.accentColor, onPressed: () => Navigator.pushNamed(context, '/cart'))));
  }

  @override
  Widget build(BuildContext context) {
    final bool onSale = widget.product.salePrice != null && (widget.product.salePrice ?? 0) > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(widget.product.name.toUpperCase())),
      bottomNavigationBar: SafeArea(child: Container(decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.borderColor))), child: Column(mainAxisSize: MainAxisSize.min, children: [Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: SizedBox(height: 48, child: OutlinedButton(onPressed: _addToCart, style: OutlinedButton.styleFrom(foregroundColor: Colors.black, side: const BorderSide(color: Colors.black), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)), child: const Text('ADD TO CART', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))))), const SizedBox(width: 8), Expanded(child: SizedBox(height: 48, child: ElevatedButton(onPressed: () { _addToCart(); Navigator.pushNamed(context, '/checkout'); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)), child: const Text('BUY IT NOW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))))])), Material(color: Colors.white, child: Consumer<CartService>(builder: (context, cart, _) => SizedBox(height: 60, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_NavItem(icon: Iconsax.home, label: 'Home', onTap: () => _goToPage(0)), _NavItem(icon: Iconsax.shop, label: 'Shop', onTap: () => _goToPage(1)), _NavItem(icon: Iconsax.shopping_cart, label: 'Cart', badgeCount: cart.itemCount, onTap: () => _goToPage(2)), _NavItem(icon: Iconsax.login, label: 'Login', onTap: () => _goToPage(3))]))))]))),
      floatingActionButton: FloatingActionButton(onPressed: _openWhatsApp, backgroundColor: const Color(0xFF25D366), child: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white)),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(alignment: Alignment.center, children: [
            Container(color: const Color(0xFFF9F9F9), child: CarouselSlider(carouselController: _carouselController, options: CarouselOptions(height: 450, viewportFraction: 1.0, onPageChanged: (index, _) => setState(() => _currentImageIndex = index)), items: _imageUrls.map((url) => InteractiveViewer(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain, width: MediaQuery.of(context).size.width, placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)), errorWidget: (_, __, ___) => const Icon(Icons.error_outline, size: 40, color: Colors.grey)))).toList())),
            if (_imageUrls.length > 1) ...[Positioned(left: 10, child: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black54, size: 20), onPressed: () => _carouselController.previousPage())), Positioned(right: 10, child: IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 20), onPressed: () => _carouselController.nextPage()))]
          ]),
          if (_imageUrls.length > 1) Container(padding: const EdgeInsets.symmetric(vertical: 16), child: SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: _imageUrls.asMap().entries.map((entry) => GestureDetector(onTap: () => _carouselController.animateToPage(entry.key), child: Container(width: 60, height: 60, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(border: Border.all(color: _currentImageIndex == entry.key ? Colors.black : Colors.transparent, width: 1.5)), child: CachedNetworkImage(imageUrl: entry.value, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.grey[200]))))).toList()))),
          Padding(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.product.brand != null) Text((widget.product.brand ?? "").toUpperCase(), style: AppTheme.bodySans.copyWith(letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
            const SizedBox(height: 8), Text(widget.product.name, style: AppTheme.headingSerif.copyWith(fontSize: 28)),
            const SizedBox(height: 16), Row(children: [if (onSale) ...[Text('Rs ${widget.product.price.toStringAsFixed(0)}', style: AppTheme.bodySans.copyWith(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 18)), const SizedBox(width: 12)], Text('Rs ${_currentPrice.toStringAsFixed(0)}', style: AppTheme.priceStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w700))]),
            const SizedBox(height: 32), const Divider(color: AppTheme.borderColor), const SizedBox(height: 24),
            if (widget.product.variants.isNotEmpty) ...[const Text('SELECT SIZE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)), const SizedBox(height: 12), Wrap(spacing: 12, children: List.generate(widget.product.variants.length, (index) => ChoiceChip(label: Text(widget.product.variants[index].size), selected: _selectedVariantIndex == index, onSelected: (val) { if (val) { setState(() => _selectedVariantIndex = index); _initializeGallery(); } }, selectedColor: Colors.black, backgroundColor: Colors.white, labelStyle: TextStyle(color: _selectedVariantIndex == index ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12), shape: const RoundedRectangleBorder(side: BorderSide(color: AppTheme.borderColor), borderRadius: BorderRadius.zero), showCheckmark: false))), const SizedBox(height: 24)],
            Row(children: [const Text('QUANTITY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)), const Spacer(), Container(decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor)), child: Row(children: [_qtyBtn(Icons.remove, () => setState(() => _quantity > 1 ? _quantity-- : null)), SizedBox(width: 40, child: Center(child: Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold)))), _qtyBtn(Icons.add, () => setState(() => _quantity++))]))]),
            const SizedBox(height: 32), const Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)), const SizedBox(height: 12), Text(widget.product.description ?? 'No description available.', style: AppTheme.bodySans.copyWith(height: 1.6, color: Colors.black87)),
            const SizedBox(height: 40), _buildAttrRow('SCENT FAMILY', widget.product.scentFamily ?? 'N/A'), _buildAttrRow('SIZE', _currentSize), _buildAttrRow('CATEGORY', widget.product.category ?? 'N/A'),
            const SizedBox(height: 60), const Text('RELATED PRODUCTS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)), const SizedBox(height: 24), _RelatedProducts(product: widget.product, allProducts: widget.allProducts), const SizedBox(height: 40)
          ]))
        ]),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: AppTheme.borderColor)), child: Icon(icon, size: 16)));
  void _goToPage(int index) => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => MainAppScreen(initialIndex: index)), (route) => false);
  Widget _buildAttrRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1)), Text(value.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5))]));
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final int? badgeCount;
  const _NavItem({required this.icon, required this.label, required this.onTap, this.badgeCount});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [Stack(clipBehavior: Clip.none, children: [Icon(icon, color: AppTheme.secondaryColor, size: 24), if (badgeCount != null && badgeCount! > 0) Positioned(top: -6, right: -8, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)), constraints: const BoxConstraints(minWidth: 16, minHeight: 16), child: Text('$badgeCount', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, height: 1))))]), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.secondaryColor))]));
}

class _RelatedProducts extends StatelessWidget {
  final Product product; final List<Product> allProducts;
  const _RelatedProducts({required this.product, required this.allProducts});
  @override
  Widget build(BuildContext context) {
    final related = allProducts.where((p) => p.category == product.category && p.id != product.id).toList();
    if (related.isEmpty) return const SizedBox.shrink();
    return SizedBox(height: 280, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: related.length, separatorBuilder: (_, __) => const SizedBox(width: 16), itemBuilder: (ctx, i) => SizedBox(width: 180, child: ProductCard(product: related[i], isCompact: true, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: related[i], allProducts: allProducts)))))));
  }
}
