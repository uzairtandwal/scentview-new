import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class CartService with ChangeNotifier {
  final List<Product> _items = [];
  final List<Product> _savedItems = []; // ✅ Save for Later list

  // ✅ Coupon & Discount Variables
  double _discountAmount = 0.0;
  String? _appliedCouponCode;

  List<Product> get items => _items;
  List<Product> get uniqueItems {
    final Map<dynamic, Product> unique = {};
    for (var item in _items) {
      unique[item.id] = item;
    }
    return unique.values.toList();
  }
  List<Product> get savedItems => _savedItems;

  // ✅ 1. Subtotal (Sale price use karte huye total)
  double get subtotal {
    return _items.fold(0.0, (sum, current) {
      final effectivePrice = (current.salePrice != null &&
              current.salePrice! > 0 &&
              current.salePrice! < current.price)
          ? current.salePrice!
          : current.price;
      return sum + effectivePrice;
    });
  }

  // ✅ 2. Total Price (Discount nikaal kar final payment)
  double get totalPrice {
    double finalAmount = subtotal - _discountAmount;
    return finalAmount > 0 ? finalAmount : 0.0;
  }

  double get discountAmount => _discountAmount;
  String? get appliedCouponCode => _appliedCouponCode;
  int get itemCount => _items.length;

  // ================= COUPON LOGIC =================

  // ✅ Discount apply karne ka function
  void applyDiscount(double amount, String code) {
    _discountAmount = amount;
    _appliedCouponCode = code;
    notifyListeners();
  }

  // ✅ Discount reset karne ka function
  void resetDiscount() {
    _discountAmount = 0.0;
    _appliedCouponCode = null;
    notifyListeners();
  }

  // ================= CART OPERATIONS =================

  void add(Product product, {int quantity = 1}) {
    for (int i = 0; i < quantity; i++) {
      _items.add(product);
    }
    notifyListeners();
  }

  void remove(Product product) {
    _items.remove(product);
    notifyListeners();
  }

  // ✅ ID ke zariye poora item group khatam karna
  void removeItem(dynamic productId) {
    _items.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  // ================= SAVE FOR LATER LOGIC =================

  void saveForLater(Product product) {
    // Cart se saare ek jaise items nikalo
    _items.removeWhere((item) => item.id == product.id);
    
    // Agar saved list mein nahi hai to add karo
    if (!_savedItems.any((item) => item.id == product.id)) {
      _savedItems.add(product);
    }
    notifyListeners();
  }

  void moveToCart(Product product) {
    // Saved list se hatao
    _savedItems.removeWhere((item) => item.id == product.id);
    // Cart mein wapas dalo
    add(product);
    notifyListeners();
  }

  // ================= QUANTITY LOGIC =================

  void updateQuantity(Product product, int quantity) {
    final currentQuantity = getQuantity(product);

    if (quantity <= 0) {
      _items.removeWhere((item) => item.id == product.id);
    } else if (quantity < currentQuantity) {
      // Jitne kam karne hain, utne instances remove karo
      int toRemove = currentQuantity - quantity;
      for (int i = 0; i < toRemove; i++) {
        int index = _items.indexWhere((item) => item.id == product.id);
        if (index != -1) _items.removeAt(index);
      }
    } else if (quantity > currentQuantity) {
      // Jitne badhane hain, utne add karo
      for (int i = 0; i < quantity - currentQuantity; i++) {
        _items.add(product);
      }
    }
    notifyListeners();
  }

  int getQuantity(Product product) {
    return _items.where((item) => item.id == product.id).length;
  }

  void clear() {
    _items.clear();
    resetDiscount(); // Cart khali to discount bhi khatam
    notifyListeners();
  }
}
