import 'dart:convert';
import 'package:scentview/utils/url_utils.dart';

class ProductVariant {
  final String size;
  final double price;
  final List<String> images; // Nayi images list variant ke liye

  ProductVariant({required this.size, required this.price, this.images = const []});

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      size: json['size']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
    );
  }

  Map<String, dynamic> toJson() => {'size': size, 'price': price, 'images': images};
}

class Product {
  final dynamic id;
  final String name;
  final String? description;
  final double price;
  final double? salePrice;
  final String imageUrl;
  final String? imageUrl100ml;
  final List<String> images;
  final List<String> images50ml;
  final List<String> images100ml;
  final List<ProductVariant> variants;
  final bool isFeatured;
  final bool isSlider;
  final String? badgeText;
  final String? category;
  final String? scentFamily;
  final String? brand;
  final String? size;
  final int quantity;
  final double? price100ml;
  final int quantity100ml;
  final String? notesTop;
  final String? notesMiddle;
  final String? notesBase;
  final String? sku;
  final bool isActive;
  final List<String> tags; // Added tags
  final String? customerProductName;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.salePrice,
    required this.imageUrl,
    this.imageUrl100ml,
    this.images = const [],
    this.images50ml = const [],
    this.images100ml = const [],
    this.variants = const [],
    this.isFeatured = false,
    this.isSlider = false,
    this.badgeText,
    this.category,
    this.scentFamily,
    this.brand,
    this.size,
    this.quantity = 0,
    this.price100ml,
    this.quantity100ml = 0,
    this.notesTop,
    this.notesMiddle,
    this.notesBase,
    this.sku,
    this.isActive = true,
    this.tags = const [], // Added tags
    this.customerProductName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper to parse JSON images to Absolute URLs
    List<String> _parseImages(dynamic raw) {
      if (raw == null) return [];
      List<String> list = [];
      if (raw is List) {
        list = raw.map((e) => e.toString()).toList();
      } else if (raw is String) {
        try {
          var decoded = jsonDecode(raw);
          if (decoded is List) list = decoded.map((e) => e.toString()).toList();
        } catch (_) {
          list = raw.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',').map((e) => e.trim()).toList();
        }
      }
      return list.map((path) => path.startsWith('http') ? path : (UrlUtils.toAbsoluteUrl(path) ?? '')).where((e) => e.isNotEmpty).toList();
    }

    List<String> imagesList = _parseImages(json['image_urls']);
    List<String> images50 = _parseImages(json['images_50ml']);
    List<String> images100 = _parseImages(json['images_100ml']);

    String? rawImg = json['image_url']?.toString();
    String finalImg = "";
    if (rawImg != null && rawImg.isNotEmpty && rawImg != "null") {
      finalImg = rawImg.startsWith('http') ? rawImg : (UrlUtils.toAbsoluteUrl(rawImg) ?? '');
    }

    String? rawImg100 = json['image_url_100ml']?.toString();
    String? finalImg100;
    if (rawImg100 != null && rawImg100.isNotEmpty && rawImg100 != "null") {
      finalImg100 = rawImg100.startsWith('http') ? rawImg100 : (UrlUtils.toAbsoluteUrl(rawImg100) ?? '');
    }

    // Handle Variants
    List<ProductVariant> variantsList = [];
    if (json['variants'] != null) {
      dynamic rawVariants = json['variants'];
      if (rawVariants is String) { try { rawVariants = jsonDecode(rawVariants); } catch (_) {} }
      if (rawVariants is List) { variantsList = rawVariants.map((v) => ProductVariant.fromJson(v)).toList(); }
    }

    // Fallback: If variants are empty, create from existing price/price100ml
    double mainPrice = double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0;
    if (variantsList.isEmpty) {
      if (mainPrice > 0) variantsList.add(ProductVariant(size: json['size']?.toString() ?? '50ml', price: mainPrice));
      double p100 = double.tryParse(json['price_100ml']?.toString() ?? '0.0') ?? 0.0;
      if (p100 > 0) variantsList.add(ProductVariant(size: '100ml', price: p100));
    }

    return Product(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: mainPrice,
      salePrice: json['sale_price'] != null ? double.tryParse(json['sale_price'].toString()) : null,
      imageUrl: finalImg,
      imageUrl100ml: finalImg100,
      images: imagesList.isEmpty ? [finalImg] : imagesList,
      images50ml: images50,
      images100ml: images100,
      variants: variantsList,
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      isSlider: json['is_slider'] == 1 || json['is_slider'] == true,
      badgeText: json['badge_text']?.toString(),
      category: json['category']?.toString(),
      scentFamily: json['scent_family']?.toString(),
      brand: json['brand']?.toString(),
      size: json['size']?.toString(),
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      price100ml: json['price_100ml'] != null ? double.tryParse(json['price_100ml'].toString()) : null,
      quantity100ml: int.tryParse(json['quantity_100ml']?.toString() ?? '0') ?? 0,
      notesTop: json['notes_top']?.toString(),
      notesMiddle: json['notes_middle']?.toString(),
      notesBase: json['notes_base']?.toString(),
      sku: json['sku']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      tags: [],
      customerProductName: json['customer_product_name']?.toString(),
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'],
      price: double.tryParse(map['price']?.toString() ?? '0.0') ?? 0.0,
      salePrice: map['sale_price'] != null ? double.tryParse(map['sale_price'].toString()) : null,
      imageUrl: map['image_url'] ?? '',
      imageUrl100ml: map['image_url_100ml'],
      images: map['images_json'] != null 
          ? List<String>.from(jsonDecode(map['images_json'])) 
          : [],
      images50ml: map['images_50ml_json'] != null 
          ? List<String>.from(jsonDecode(map['images_50ml_json'])) 
          : [],
      images100ml: map['images_100ml_json'] != null 
          ? List<String>.from(jsonDecode(map['images_100ml_json'])) 
          : [],
      variants: map['variants_json'] != null 
          ? (jsonDecode(map['variants_json']) as List).map((v) => ProductVariant.fromJson(v)).toList()
          : [],
      category: map['category'],
      scentFamily: map['scent_family'],
      brand: map['brand'],
      size: map['size'],
      quantity: map['quantity'] ?? 0,
      price100ml: map['price_100ml'] != null ? double.tryParse(map['price_100ml'].toString()) : null,
      quantity100ml: map['quantity_100ml'] ?? 0,
      notesTop: map['notes_top'],
      notesMiddle: map['notes_middle'],
      notesBase: map['notes_base'],
      isFeatured: map['is_featured'] == 1,
      isSlider: map['is_slider'] == 1,
      badgeText: map['badge_text'],
      sku: map['sku'],
      isActive: map['is_active'] == 1,
      tags: map['tags_json'] != null 
          ? List<String>.from(jsonDecode(map['tags_json'])) 
          : [],
      customerProductName: map['customer_product_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'sale_price': salePrice,
      'image_url': imageUrl,
      'image_url_100ml': imageUrl100ml,
      'images_json': jsonEncode(images),
      'images_50ml_json': jsonEncode(images50ml),
      'images_100ml_json': jsonEncode(images100ml),
      'variants_json': jsonEncode(variants.map((v) => v.toJson()).toList()),
      'category': category,
      'scent_family': scentFamily,
      'brand': brand,
      'size': size,
      'quantity': quantity,
      'price_100ml': price100ml,
      'quantity_100ml': quantity100ml,
      'notes_top': notesTop,
      'notes_middle': notesMiddle,
      'notes_base': notesBase,
      'is_featured': isFeatured ? 1 : 0,
      'is_slider': isSlider ? 1 : 0,
      'badge_text': badgeText,
      'sku': sku,
      'is_active': isActive ? 1 : 0,
      'tags_json': jsonEncode(tags),
      'customer_product_name': customerProductName,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'sale_price': salePrice,
      'image_url': imageUrl,
      'image_url_100ml': imageUrl100ml,
      'category': category,
      'scent_family': scentFamily,
      'brand': brand,
      'size': size,
      'quantity': quantity,
      'price_100ml': price100ml,
      'quantity_100ml': quantity100ml,
      'notes_top': notesTop,
      'notes_middle': notesMiddle,
      'notes_base': notesBase,
      'is_featured': isFeatured,
      'is_slider': isSlider,
      'badge_text': badgeText,
      'sku': sku,
      'is_active': isActive,
      'tags': tags,
      'customer_product_name': customerProductName,
    }..removeWhere((key, value) => value == null);
  }

  Product copyWith({
    dynamic id,
    String? name,
    String? description,
    double? price,
    double? salePrice,
    String? imageUrl,
    String? imageUrl100ml,
    List<String>? images,
    bool? isFeatured,
    bool? isSlider,
    String? badgeText,
    String? category,
    String? scentFamily,
    String? brand,
    String? size,
    int? quantity,
    double? price100ml,
    int? quantity100ml,
    String? notesTop,
    String? notesMiddle,
    String? notesBase,
    String? sku,
    bool? isActive,
    List<String>? tags,
    String? customerProductName,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrl100ml: imageUrl100ml ?? this.imageUrl100ml,
      images: images ?? this.images,
      isFeatured: isFeatured ?? this.isFeatured,
      isSlider: isSlider ?? this.isSlider,
      badgeText: badgeText ?? this.badgeText,
      category: category ?? this.category,
      scentFamily: scentFamily ?? this.scentFamily,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      price100ml: price100ml ?? this.price100ml,
      quantity100ml: quantity100ml ?? this.quantity100ml,
      notesTop: notesTop ?? this.notesTop,
      notesMiddle: notesMiddle ?? this.notesMiddle,
      notesBase: notesBase ?? this.notesBase,
      sku: sku ?? this.sku,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      customerProductName: customerProductName ?? this.customerProductName,
    );
  }
}