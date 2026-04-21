import 'dart:convert';
import 'package:scentview/utils/url_utils.dart';

class Product {
  final dynamic id;
  final String name;
  final String? description;
  final double price;
  final double? salePrice;
  final String imageUrl;
  final List<String> images;
  final bool isFeatured;
  final bool isSlider;
  final String? badgeText;
  final String? category;
  final String? scentFamily;
  final String? brand;
  final String? size;
  final int quantity;
  final String? notesTop;
  final String? notesMiddle;
  final String? notesBase;
  final String? sku;
  final bool isActive;
  final List<String> tags; // Added tags

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.salePrice,
    required this.imageUrl,
    this.images = const [],
    this.isFeatured = false,
    this.isSlider = false,
    this.badgeText,
    this.category,
    this.scentFamily,
    this.brand,
    this.size,
    this.quantity = 0,
    this.notesTop,
    this.notesMiddle,
    this.notesBase,
    this.sku,
    this.isActive = true,
    this.tags = const [], // Added tags
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle images list from JSON
    List<String> imagesList = [];
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        imagesList = List<String>.from(json['image_urls']);
      } else if (json['image_urls'] is String) {
        try {
          imagesList = List<String>.from(jsonDecode(json['image_urls']));
        } catch (_) {}
      }
    }

    // Handle tags list from JSON
    List<String> tagsList = [];
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tagsList = List<String>.from(json['tags']);
      } else if (json['tags'] is String) {
        try {
          tagsList = List<String>.from(jsonDecode(json['tags']));
        } catch (_) {}
      }
    }

    String? rawImg = json['image_url']?.toString();
    String finalImg = "";
    
    if (rawImg != null && rawImg.isNotEmpty && rawImg != "null") {
      finalImg = rawImg.startsWith('http') ? rawImg : (UrlUtils.toAbsoluteUrl(rawImg) ?? '');
    }

    return Product(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      salePrice: json['sale_price'] != null ? double.tryParse(json['sale_price'].toString()) : null,
      imageUrl: finalImg,
      images: imagesList,
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      isSlider: json['is_slider'] == 1 || json['is_slider'] == true,
      badgeText: json['badge_text']?.toString(),
      category: json['category']?.toString(),
      scentFamily: json['scent_family']?.toString(),
      brand: json['brand']?.toString(),
      size: json['size']?.toString(),
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      notesTop: json['notes_top']?.toString(),
      notesMiddle: json['notes_middle']?.toString(),
      notesBase: json['notes_base']?.toString(),
      sku: json['sku']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      tags: tagsList,
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
      images: map['images_json'] != null 
          ? List<String>.from(jsonDecode(map['images_json'])) 
          : [],
      category: map['category'],
      scentFamily: map['scent_family'],
      brand: map['brand'],
      size: map['size'],
      quantity: map['quantity'] ?? 0,
      notesTop: map['notes_top'],
      notesMiddle: map['notes_middle'],
      notesBase: map['notes_base'],
      isFeatured: map['is_featured'] == 1,
      tags: map['tags_json'] != null 
          ? List<String>.from(jsonDecode(map['tags_json'])) 
          : [],
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
      'images_json': jsonEncode(images),
      'category': category,
      'scent_family': scentFamily,
      'brand': brand,
      'size': size,
      'quantity': quantity,
      'notes_top': notesTop,
      'notes_middle': notesMiddle,
      'notes_base': notesBase,
      'is_featured': isFeatured ? 1 : 0,
      'tags_json': jsonEncode(tags),
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
      'category': category,
      'scent_family': scentFamily,
      'brand': brand,
      'size': size,
      'quantity': quantity,
      'notes_top': notesTop,
      'notes_middle': notesMiddle,
      'notes_base': notesBase,
      'is_featured': isFeatured,
      'is_slider': isSlider,
      'badge_text': badgeText,
      'sku': sku,
      'is_active': isActive,
      'tags': tags,
    }..removeWhere((key, value) => value == null);
  }

  Product copyWith({
    dynamic id,
    String? name,
    String? description,
    double? price,
    double? salePrice,
    String? imageUrl,
    List<String>? images,
    bool? isFeatured,
    bool? isSlider,
    String? badgeText,
    String? category,
    String? scentFamily,
    String? brand,
    String? size,
    int? quantity,
    String? notesTop,
    String? notesMiddle,
    String? notesBase,
    String? sku,
    bool? isActive,
    List<String>? tags,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      isFeatured: isFeatured ?? this.isFeatured,
      isSlider: isSlider ?? this.isSlider,
      badgeText: badgeText ?? this.badgeText,
      category: category ?? this.category,
      scentFamily: scentFamily ?? this.scentFamily,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      notesTop: notesTop ?? this.notesTop,
      notesMiddle: notesMiddle ?? this.notesMiddle,
      notesBase: notesBase ?? this.notesBase,
      sku: sku ?? this.sku,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
    );
  }
}