import 'product_model.dart';

class OrderItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  factory OrderItem.fromProduct(Product p, {int quantity = 1}) => OrderItem(
    id: p.id,
    name: p.name,
    price: p.price,
    quantity: quantity,
    imageUrl: p.imageUrl,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
    'imageUrl': imageUrl,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id']?.toString() ?? '', 
    name: json['name'] as String? ?? 'No Name',
    price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
    imageUrl: json['imageUrl'] as String?,
  );
}

class Order {
  final String id;
  final DateTime createdAt;
  final List<OrderItem> items;
  final double total;
  final String status; 
  final String paymentMethod;
  final String shippingAddress;

  Order({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.total,
    this.status = 'Placed',
    required this.paymentMethod,
    required this.shippingAddress,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
    'total': total,
    'status': status,
    'paymentMethod': paymentMethod,
    'shippingAddress': shippingAddress,
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    // Sab fields ko safe bana diya hai
    id: json['id']?.toString() ?? '', 
    createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    items: (json['items'] as List?)
            ?.map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
            .toList() ?? [],
    total: double.tryParse(json['total']?.toString() ?? json['total_amount']?.toString() ?? '0') ?? 0.0,
    status: json['status'] as String? ?? 'Placed',
    paymentMethod: json['payment_method'] ?? json['paymentMethod'] ?? 'COD',
    shippingAddress: json['shipping_address'] ?? json['shippingAddress'] ?? 'No Address',
  );
}
