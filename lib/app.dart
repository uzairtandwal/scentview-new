import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scentview/admin/admin_home_screen.dart';
import 'package:scentview/admin/orders_dashboard.dart';
import 'package:scentview/admin/banners_screen.dart';
import 'package:scentview/admin/categories_screen.dart';
import 'package:scentview/admin/products_screen.dart';
import 'package:scentview/models/product_model.dart';
import 'package:scentview/services/auth_service.dart';
import 'package:scentview/ui/cart_screen.dart';
import 'package:scentview/ui/main_app_screen.dart';
import 'package:scentview/ui/mode_selection_screen.dart';
import 'package:scentview/ui/product_detail_screen.dart';
import 'package:scentview/ui/checkout_screen.dart';
import 'package:scentview/ui/login_screen.dart';
import 'package:scentview/ui/registration_screen.dart';
import 'package:scentview/ui/splash_screen.dart';
import 'package:scentview/ui/profile_screen.dart';
import 'package:scentview/ui/search_results_screen.dart';
import 'package:scentview/theme/app_theme.dart';

class ScentViewApp extends StatelessWidget {
  const ScentViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScentView',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthGate(),
      routes: {
        MainAppScreen.routeName: (context) => const MainAppScreen(),
        AdminHomeScreen.routeName: (context) => const AdminHomeScreen(),
        AdminOrdersDashboard.routeName: (context) => const AdminOrdersDashboard(),
        CartScreen.routeName: (context) => const CartScreen(),
        CheckoutScreen.routeName: (context) => const CheckoutScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegistrationScreen.routeName: (context) => const RegistrationScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        '/mode-selection': (context) => const ModeSelectionScreen(),
        '/admin/banners': (context) => const BannersScreen(),
        '/admin/categories': (context) => const CategoriesScreen(),
        '/admin/products': (context) => const ProductsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == ProductDetailScreen.routeName) {
          final args = settings.arguments as Map<String, dynamic>;
          final product = args['product'] as Product;
          final allProducts = args['allProducts'] as List<Product>;
          return MaterialPageRoute(
            builder: (context) {
              return ProductDetailScreen(
                product: product,
                allProducts: allProducts,
              );
            },
          );
        }

        if (settings.name == SearchResultsScreen.routeName) {
          final query = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => SearchResultsScreen(query: query),
          );
        }

        return null;
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // HIDDEN: Bypassing splash for direct home access
  final bool _showSplash = false; 

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Provider.of<AuthService>(context, listen: false).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    // HIDDEN: Logic kept but bypassed to show MainAppScreen directly
    

    // HIDDEN: Bypassing Auth check to show MainAppScreen directly
    return const MainAppScreen();

    
  }
}
