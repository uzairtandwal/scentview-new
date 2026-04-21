import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart'; 
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:scentview/services/auth_service.dart';
import 'package:scentview/services/orders_service.dart'; 
import 'package:scentview/services/cart_service.dart';
import 'package:scentview/services/compare_service.dart'; // ✅ Added
import 'firebase_options.dart';
import 'app.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Platform-specific database factory initialization
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 🔥 STEP 2: Token generate karne ka kaam yahan add kiya hai
    await _setupFCM();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => OrdersService()),
          ChangeNotifierProvider(create: (_) => CartService()),
          ChangeNotifierProvider(create: (_) => CompareService()), // ✅ Added
        ],
        child: const ScentViewApp(),
      ),
    );

  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error: ${e.toString()}')),
        ),
      ),
    );
  }
}

// 🔥 STEP 2 (NEW FUNCTION): Token nikaalne ka un-cut logic
Future<void> _setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // 2. Unique Token lena
    String? token = await messaging.getToken();
    
    debugPrint("=========================================");
    debugPrint("🚀 USER FCM TOKEN: $token");
    debugPrint("=========================================");
    
  
  }
}
