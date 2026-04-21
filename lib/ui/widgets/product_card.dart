import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:scentview/models/product_model.dart';
import 'package:scentview/services/api_service.dart';
import 'package:scentview/theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isCompact;
  final VoidCallback onTap;
  final bool showFavorite;
  final bool showQuickAdd;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onQuickAddTap;
  final bool isFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isCompact = false,
    this.showFavorite = true,
    this.showQuickAdd = true,
    this.onFavoriteTap,
    this.onQuickAddTap,
    this.isFavorite = false,
  });

  bool get _isOutOfquantity => product.quantity == 0;
  
  bool get _onSale =>
      product.salePrice != null &&
      product.salePrice! > 0 &&
      product.salePrice! < product.price;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = ApiService.toAbsoluteUrl(product.imageUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: InkWell(
        onTap: _isOutOfquantity ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image Area ──────────────────────────────────
            Expanded(
              flex: isCompact ? 7 : 8,
              child: _ImageSection(
                imageUrl: imageUrl,
                isOutOfquantity: _isOutOfquantity,
                showFavorite: showFavorite,
                isFavorite: isFavorite,
                onFavoriteTap: onFavoriteTap,
                showQuickAdd: showQuickAdd && !_isOutOfquantity,
                onQuickAddTap: onQuickAddTap,
              ),
            ),

            // ── Info Area (NEW LAYOUT: NAME + PRICE ON ONE LINE) ───────────────────
            _InfoSection(
              name: product.name,
              price: product.price,
              salePrice: product.salePrice,
              onSale: _onSale,
              isCompact: isCompact,
              notesTop: product.notesTop,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  final String? imageUrl;
  final bool isOutOfquantity;
  final bool showFavorite;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final bool showQuickAdd;
  final VoidCallback? onQuickAddTap;

  const _ImageSection({
    required this.imageUrl,
    required this.isOutOfquantity,
    required this.showFavorite,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.showQuickAdd,
    required this.onQuickAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _ProductImage(imageUrl: imageUrl),
        if (isOutOfquantity) 
          Container(
            color: Colors.white.withOpacity(0.6),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: Colors.black,
                child: const Text(
                  'OUT OF STOCK',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ),
        if (showFavorite && !isOutOfquantity)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.black : Colors.black45,
                size: 20,
              ),
              onPressed: onFavoriteTap,
            ),
          ),
        if (showQuickAdd && onQuickAddTap != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: InkWell(
              onTap: onQuickAddTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.black.withOpacity(0.8),
                child: const Text(
                  'ADD TO CART',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(color: Color(0xFFF9F9F9), child: Icon(Icons.image_outlined, color: Colors.grey, size: 30));
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) => Container(color: Color(0xFFF9F9F9)),
      errorWidget: (_, __, ___) => Icon(Icons.error_outline),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String name;
  final double price;
  final double? salePrice;
  final bool onSale;
  final bool isCompact;
  final String? notesTop;

  const _InfoSection({
    required this.name,
    required this.price,
    this.salePrice,
    this.onSale = false,
    required this.isCompact,
    this.notesTop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ROW: NAME + PRICE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingSerif.copyWith(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Rs ${price.toStringAsFixed(0)}',
                style: AppTheme.priceStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          
          const SizedBox(height: 8),

          if (notesTop != null && notesTop!.isNotEmpty)
            Text(
              'NOTES: $notesTop'.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySans.copyWith(fontSize: 10, color: Colors.grey[600], letterSpacing: 0.5, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }
}
