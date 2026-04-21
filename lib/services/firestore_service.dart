
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/banner.dart';
import '../models/category.dart';
import '../models/product_model.dart';
import '../models/order.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //- - - - - - - - - - - - - - - - - - - -
  // Stream-based Read Operations
  //- - - - - - - - - - - - - - - - - - - -

  /// Returns a stream of all banners for real-time updates.
  Stream<List<Banner>> getBannersStream() {
    return _db
        .collection('banners')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Banner.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Returns a stream of all categories for real-time updates.
  Stream<List<Category>> getCategoriesStream() {
    return _db
        .collection('categories')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Category.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Returns a stream of all products for real-time updates.
  Stream<List<Product>> getProductsStream() {
    return _db
        .collection('products')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Returns a stream of featured products for real-time updates.
  Stream<List<Product>> getFeaturedProductsStream() {
    return _db
        .collection('products')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Returns a stream of products filtered by category for real-time updates.
  Stream<List<Product>> getProductsByCategoryStream(String categoryId) {
    return _db
        .collection('products')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromJson(doc.data()))
              .toList(),
        );
  }

  //- - - - - - - - - - - - - - - - - - - -
  //- - - - - - - - - - - - - - - - - - - -

  Future<List<Product>> getFeaturedProducts() async {
    final snapshot = await _db
        .collection('products')
        .get();
    return snapshot.docs
        .map((doc) => Product.fromJson(doc.data()))
        .toList();
  }

  Future<Product> getProduct(String productId) async {
    final doc = await _db.collection('products').doc(productId).get();
    return Product.fromJson(doc.data()!);
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final snapshot = await _db
        .collection('products')
        .get();
    return snapshot.docs
        .map((doc) => Product.fromJson(doc.data()))
        .toList();
  }

  Future<List<Banner>> getBanners() async {
    final snapshot = await _db.collection('banners').get();
    return snapshot.docs
        .map((doc) => Banner.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<Product>> getProducts() async {
    final snapshot = await _db.collection('products').get();
    return snapshot.docs
        .map((doc) => Product.fromJson(doc.data()))
        .toList();
  }

  Future<List<Category>> getCategories() async {
    final snapshot = await _db.collection('categories').get();
    return snapshot.docs
        .map((doc) => Category.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Category> getCategory(String categoryId) async {
    final doc = await _db.collection('categories').doc(categoryId).get();
    return Category.fromMap(doc.data()!, doc.id);
  }

  //- - - - - - - - - - - - - - - - - - - -
  // Product CUD Operations
  //- - - - - - - - - - - - - - - - - - - -

  Future<void> addProduct(Product product) {
    return _db.collection('products').add(product.toJson());
  }

  Future<void> updateProduct(Product product) {
    return _db.collection('products').doc(product.id).update(product.toJson());
  }

  Future<void> deleteProduct(String productId) {
    return _db.collection('products').doc(productId).delete();
  }

  //- - - - - - - - - - - - - - - - - - - -
  // Category CUD Operations
  //- - - - - - - - - - - - - - - - - - - -

  Future<void> addCategory(Category category) {
    return _db.collection('categories').add(category.toMap());
  }

  Future<void> updateCategory(Category category) {
    return _db
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());
  }

  Future<void> deleteCategory(String categoryId) {
    return _db.collection('categories').doc(categoryId).delete();
  }

  //- - - - - - - - - - - - - - - - - - - -
  // Banner CUD Operations
  //- - - - - - - - - - - - - - - - - - - -

  Future<void> addBanner(Banner banner) {
    return _db.collection('banners').add(banner.toMap());
  }

  Future<void> updateBanner(Banner banner) {
    return _db.collection('banners').doc(banner.id).update(banner.toMap());
  }

  Future<void> deleteBanner(String bannerId) {
    return _db.collection('banners').doc(bannerId).delete();
  }

  //- - - - - - - - - - - - - - - - - - - -
  //- - - - - - - - - - - - - - - - - - - -

  Stream<List<Order>> getOrdersStream() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Order.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  Future<Order> addOrder(Order order) async {
    final ref = _db.collection('orders').doc();
    final data = order.toJson();
    data['id'] = ref.id;
    await ref.set(data);
    return Order.fromJson(data);
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await _db.collection('orders').doc(id).update({'status': status});
  }
}

