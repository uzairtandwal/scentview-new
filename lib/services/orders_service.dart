import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/product_model.dart';
import 'api_service.dart';

import 'package:scentview/utils/url_utils.dart';

class OrdersService with ChangeNotifier {
  static const _storageKey = 'orders_v1';
  final List<Order> _orders = [];
  
  // ✅ Base URL from UrlUtils
  final String _baseUrl = '${UrlUtils.domainUrl}/api/v1';

  List<Order> get orders => List.unmodifiable(_orders.reversed);

  // 1. API se Orders Load karna
  Future<void> fetchOrders() async {
    final token = ApiService.authToken;
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> list = [];
        
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          list = decoded['data'] ?? [];
        }
        
        _orders.clear();
        _orders.addAll(list.map((e) => Order.fromJson(Map<String, dynamic>.from(e))));
        notifyListeners();
        _save(); 
      }
    } catch (e) {
      if (kDebugMode) print('Fetch Orders Error: $e');
    }
  }

  // ✅ Admin ke liye saaray orders fetch karna
  Future<void> fetchAdminOrders() async {
    final token = ApiService.authToken;
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> list = [];
        
        if (decoded is Map && decoded.containsKey('data')) {
          list = decoded['data'] ?? [];
        } else if (decoded is List) {
          list = decoded;
        }
        
        _orders.clear();
        _orders.addAll(list.map((e) => Order.fromJson(Map<String, dynamic>.from(e))));
        notifyListeners();
        _save(); 
      }
    } catch (e) {
      if (kDebugMode) print('Fetch Admin Orders Error: $e');
    }
  }

  Future<Order?> placeOrder(Map<String, dynamic> orderData, String idempotencyKey) async {
    if (kDebugMode) print('------------------------------------------');
    if (kDebugMode) print('🔥 ORDERS_SERVICE: placeOrder STARTING!');
    if (kDebugMode) print('------------------------------------------');
    String? token = ApiService.authToken;
    
    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');
      ApiService.authToken = token; 
    }

    if (token == null) {
      if (kDebugMode) print('❌ Error: No Auth Token found');
      return null;
    }

    try {
      if (kDebugMode) print('📦 Sending Order Data with Key: $idempotencyKey');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Idempotency-Key': idempotencyKey, // 🔥 CRITICAL
        },
        body: jsonEncode(orderData), 
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) print('✅ Order Response: $data');
        
        await fetchOrders(); 
        return _orders.isNotEmpty ? _orders.last : null;
      } else {
        if (kDebugMode) {
          print('❌ Server Error: ${response.statusCode}');
          print('❌ Response Body: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Place Order Error: $e');
      return null;
    }
  }

  // Local Storage Logic
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _orders..clear()..addAll(list.map(Order.fromJson));
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_orders.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
