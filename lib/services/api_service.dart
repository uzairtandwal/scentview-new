import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:scentview/models/product_model.dart';
import 'package:scentview/models/app_user.dart';
import 'package:scentview/models/category.dart';
import 'package:scentview/models/banner.dart' as model;
import 'package:scentview/models/order.dart';
import 'package:scentview/utils/url_utils.dart';
import 'package:scentview/database/db_helper.dart';

class ApiService {
  final String baseUrl = UrlUtils.domainUrl;
  static String? authToken;
  final DBHelper _dbHelper = DBHelper();

  static void setAuthToken(String? token) { authToken = token; }
  static String? toAbsoluteUrl(String? path) => UrlUtils.toAbsoluteUrl(path);

  Uri _u(String path) {
    final uri = Uri.parse('$baseUrl/api/v1$path');
    if (kDebugMode) debugPrint("🌐 API CALL: $uri");
    return uri;
  }

  Map<String, String> _headers({bool json = false, String? token}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    final activeToken = token ?? authToken;
    if (activeToken != null) headers['Authorization'] = 'Bearer $activeToken';
    return headers;
  }

  // ✅ Smart Extractor for Categories and Lists
  List<dynamic> _extract(dynamic responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is List) return decoded;
      if (decoded is Map) {
        if (decoded.containsKey('data')) {
          if (decoded['data'] is List) return decoded['data'];
          if (decoded['data'] is Map && decoded['data'].containsKey('data')) return decoded['data']['data'];
          return [decoded['data']]; // Single item wrapped
        }
      }
    } catch (e) { if (kDebugMode) debugPrint("❌ JSON Parse Error: $e"); }
    return [];
  }

  // ================ 🛍️ PRODUCT METHODS ================

  Future<List<Product>> fetchProducts({bool forceRefresh = false}) async {
    try {
      final response = await http.get(_u('/products'), headers: _headers());
      final data = _extract(response.body);
      final products = data.map((json) => Product.fromJson(json)).toList();
      if (products.isNotEmpty) await _dbHelper.insertProducts(products);
      return products;
    } catch (e) { return await _dbHelper.getProducts(); }
  }

  Future<List<Product>> fetchFeaturedProducts({bool forceRefresh = false}) async {
    try {
      final response = await http.get(_u('/products/featured'), headers: _headers());
      return _extract(response.body).map((j) => Product.fromJson(j)).toList();
    } catch (e) { return []; }
  }

  Future<List<Product>> fetchProductsLocal() async => await _dbHelper.getProducts();

  // ================ 📁 CATEGORY METHODS ================

  Future<List<Category>> fetchCategories({bool forceRefresh = false}) async {
    try {
      final response = await http.get(_u('/categories'), headers: _headers());
      final data = _extract(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } catch (e) { 
       final local = await _dbHelper.getCategories();
       return local.map((m) => Category.fromJson(m)).toList();
    }
  }

  Future<List<Category>> fetchCategoriesLocal() async {
    final maps = await _dbHelper.getCategories();
    return maps.map((m) => Category.fromJson(m)).toList();
  }

  // ================ 👑 ADMIN CRUD (FAIL-PROOF) ================

  Future<void> addProduct({required String name, required String description, required String price, required String category, bool isFeatured = false, String? scentFamily, String? brand, String? size, String? quantity, String? notesTop, String? notesMiddle, String? notesBase, dynamic imageFile, String? token, String? customerProductName, String? externalImageUrl}) async {
    final request = http.MultipartRequest('POST', _u('/products/add'));
    request.headers.addAll(_headers(token: token));
    request.fields.addAll({'name': name, 'description': description, 'price': price, 'category': category, 'is_featured': isFeatured ? '1' : '0', 'scent_family': scentFamily ?? '', 'brand': brand ?? '', 'size': size ?? '', 'quantity': quantity ?? '100', 'notes_top': notesTop ?? '', 'notes_middle': notesMiddle ?? '', 'notes_base': notesBase ?? '', 'customer_product_name': customerProductName ?? '', 'image_url': externalImageUrl ?? ''});
    if (imageFile != null) request.files.add(await http.MultipartFile.fromPath('main_image', imageFile.path));
    final resp = await http.Response.fromStream(await request.send());
    if (resp.statusCode > 299) throw Exception(jsonDecode(resp.body)['message'] ?? 'Add Failed');
  }

  Future<void> updateProduct({required dynamic id, required String name, required String description, required String price, required String category, bool isFeatured = false, String? scentFamily, String? brand, String? size, String? quantity, String? notesTop, String? notesMiddle, String? notesBase, dynamic imageFile, String? token, String? customerProductName, String? externalImageUrl}) async {
    final request = http.MultipartRequest('POST', _u('/products/update/$id'));
    request.headers.addAll(_headers(token: token));
    request.fields.addAll({'name': name, 'description': description, 'price': price, 'category': category, 'is_featured': isFeatured ? '1' : '0', 'scent_family': scentFamily ?? '', 'brand': brand ?? '', 'size': size ?? '', 'quantity': quantity ?? '100', 'notes_top': notesTop ?? '', 'notes_middle': notesMiddle ?? '', 'notes_base': notesBase ?? '', 'customer_product_name': customerProductName ?? '', 'image_url': externalImageUrl ?? ''});
    if (imageFile != null) request.files.add(await http.MultipartFile.fromPath('main_image', imageFile.path));
    final resp = await http.Response.fromStream(await request.send());
    if (resp.statusCode > 299) throw Exception(jsonDecode(resp.body)['message'] ?? 'Update Failed');
  }

  Future<void> deleteProduct({required dynamic id, String? token}) async {
    final response = await http.post(_u('/products/delete/$id'), headers: _headers(token: token));
    if (response.statusCode > 299) throw Exception('Delete Failed');
  }

  // ================ 🖼️ OTHER ================
  Future<List<model.Banner>> fetchBanners({bool forceRefresh = false}) async {
    try {
      final response = await http.get(_u('/banners'), headers: _headers());
      return _extract(response.body).map((j) => model.Banner.fromJson(j)).toList();
    } catch (e) { return await _dbHelper.getBanners(); }
  }
  Future<List<model.Banner>> fetchBannersLocal() async => await _dbHelper.getBanners();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(_u('/login'), headers: _headers(json: true), body: jsonEncode({'email': email, 'password': password}));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Login Failed');
  }
  Future<void> updateFcmToken(String token) async { try { await http.post(_u('/update-fcm-token'), headers: _headers(json: true), body: jsonEncode({'fcm_token': token})); } catch (_) {} }
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> data) async {
    final res = await http.post(_u('/orders'), headers: _headers(json: true), body: jsonEncode(data));
    return jsonDecode(res.body);
  }
  Future<List<Order>> fetchAdminOrders() async {
    final res = await http.get(_u('/admin/orders'), headers: _headers());
    return _extract(res.body).map((j) => Order.fromJson(j)).toList();
  }
  Future<void> updateOrderStatus(dynamic id, String s) async => await http.post(_u('/admin/orders/$id/status'), headers: _headers(json: true), body: jsonEncode({'status': s}));
  Future<void> createCategory({required String name, dynamic imageFile, String? token}) async {
    final req = http.MultipartRequest('POST', _u('/categories/add'));
    req.headers.addAll(_headers(token: token));
    req.fields['name'] = name;
    if (imageFile != null) req.files.add(await http.MultipartFile.fromPath('main_image', imageFile.path));
    await req.send();
  }
  Future<void> deleteCategory({required dynamic id, String? token}) async => await http.post(_u('/categories/delete/$id'), headers: _headers(token: token));
  Future<List<dynamic>> fetchSubscribers() async {
    final res = await http.get(_u('/subscribers'), headers: _headers());
    return _extract(res.body);
  }
  Future<void> deleteSubscriber(dynamic id) async => await http.post(_u('/subscribers/delete/$id'), headers: _headers());
  Future<void> createBanner({required String title, String? description, String? targetScreen, String? targetId, int? sortOrder, bool isActive = true, dynamic imageFile, String? token}) async {
    final req = http.MultipartRequest('POST', _u('/banners/add'));
    req.headers.addAll(_headers(token: token));
    req.fields.addAll({'title': title, 'is_active': isActive ? '1' : '0'});
    if (imageFile != null) req.files.add(await http.MultipartFile.fromPath('main_image', imageFile.path));
    await req.send();
  }
  Future<void> deleteBanner({required dynamic id, String? token}) async => await http.post(_u('/banners/delete/$id'), headers: _headers(token: token));
  Future<void> updateBanner({required dynamic id, required String title, String? description, String? targetScreen, String? targetId, int? sortOrder, bool isActive = true, String? currentImageUrl, dynamic imageFile, String? token}) async {
    final req = http.MultipartRequest('POST', _u('/banners/update/$id'));
    req.headers.addAll(_headers(token: token));
    req.fields.addAll({'title': title, 'is_active': isActive ? '1' : '0'});
    if (imageFile != null) req.files.add(await http.MultipartFile.fromPath('main_image', imageFile.path));
    await req.send();
  }
  Future<void> updateCategory({required dynamic id, required String name, dynamic imageFile, String? token}) async {
    final req = http.MultipartRequest('POST', _u('/categories/update/$id'));
    req.headers.addAll(_headers(token: token));
    req.fields['name'] = name;
    if (imageFile != null) req.files.add(await http.MultipartFile.fromPath('main_image', imageFile.path));
    await req.send();
  }
}