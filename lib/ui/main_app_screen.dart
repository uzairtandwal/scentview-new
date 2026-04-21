import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:scentview/theme/app_theme.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../admin/admin_home_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'product_detail_screen.dart';
import 'login_screen.dart'; // Import LoginScreen
import 'shop_screen.dart';
import 'widgets/custom_app_bar.dart';

class MainAppScreen extends StatefulWidget {
  static const routeName = '/main-app';
  final int initialIndex;
  final String initialCategory;
  const MainAppScreen({super.key, this.initialIndex = 0, this.initialCategory = 'All'});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late int _selectedIndex;
  late String _currentCategory;
  late final PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastBackPressTime;
  String _searchQuery = '';
  final ApiService _api = ApiService();
  bool _hasShownSalePopup = false;

  // UPDATED: Added Login item
  static const _navItems = [
    _NavItem(label: 'Home',    icon: Iconsax.home,          activeIcon: Iconsax.home_15),
    _NavItem(label: 'Shop',    icon: Iconsax.shop,           activeIcon: Iconsax.shop5),
    _NavItem(label: 'Cart',    icon: Iconsax.shopping_cart,  activeIcon: Iconsax.shopping_cart5),
    _NavItem(label: 'Login',   icon: Iconsax.login,          activeIcon: Iconsax.login_1),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _currentCategory = widget.initialCategory;
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) _navigateTo(args);
    });
  }

  @override
  void didUpdateWidget(MainAppScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex || oldWidget.initialCategory != widget.initialCategory) {
      _navigateTo(widget.initialIndex, category: widget.initialCategory);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateTo(int index, {String? category}) {
    if (category != null) {
      setState(() => _currentCategory = category);
    }
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleGlobalRefresh() async {
    _hasShownSalePopup = false;
    setState(() {}); 
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing data...'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ),
    );

    try {
      final products = await _api.fetchProducts();
      
    } catch (_) {}
  }

  void _showSalePopupIfNeeded(List<Product> products) {
    
  }

  void _showSaleDialog(Product product, List<Product> allProducts) {
    final discount =
        ((product.price - product.salePrice!) / product.price * 100).round();

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sale',
      barrierColor: AppTheme.primaryColor.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.82, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => SaleDialog(
        product: product,
        discount: discount,
        onViewDeal: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: product,
                allProducts: allProducts,
              ),
            ),
          );
        },
      ),
    );
  }

  bool _handleBackPress() {
    if (_selectedIndex != 0) {
      _navigateTo(0);
      return true;
    }

    final now = DateTime.now();
    final isSecondPress = _lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) <= const Duration(seconds: 2);

    if (isSecondPress) return false;

    _lastBackPressTime = now;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Press back again to exit'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return true;
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      showSearch: _selectedIndex == 1 || _selectedIndex == 0,
      hintText: _selectedIndex == 0 ? 'Search products...' : 'Search fragrances...',
      onRefresh: _handleGlobalRefresh,
      gradientColors: const [AppTheme.primaryColor, AppTheme.secondaryColor],
      onSearchChanged: (_selectedIndex == 0 || _selectedIndex == 1)
          ? (val) => setState(() => _searchQuery = val)
          : null,
      onSubmitted: (val) {
        if (_selectedIndex == 0 || _selectedIndex == 1) {
          setState(() => _searchQuery = val);
        } else {
          // If on other pages, maybe jump to Shop?
          _navigateTo(1);
          setState(() => _searchQuery = val);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(searchQuery: _searchQuery),
      ShopScreen(searchQuery: _searchQuery, initialCategory: _currentCategory),
      const CartScreen(),
      const LoginScreen(), // ADDED: LoginScreen added to pages
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPress();
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (i) => setState(() => _selectedIndex = i),
          children: pages,
        ),
        bottomNavigationBar: _BottomNav(
          selectedIndex: _selectedIndex,
          onTap: _navigateTo,
          navItems: _navItems,
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final user = Provider.of<AuthService>(context).currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'ScentView Guest', style: const TextStyle(color: Colors.white)),
            accountEmail: Text(user?.email ?? 'Welcome to Luxury', style: const TextStyle(color: Colors.white70)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.name?[0].toUpperCase() ?? 'S',
                style: const TextStyle(fontSize: 24, color: AppTheme.primaryColor),
              ),
            ),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Iconsax.home, color: AppTheme.secondaryColor),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(0);
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.shop, color: AppTheme.secondaryColor),
            title: const Text('Shop'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(1);
            },
          ),
          ListTile(
            leading: const Icon(Iconsax.shopping_cart, color: AppTheme.secondaryColor),
            title: const Text('My Cart'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(2);
            },
          ),
          // ADDED: Login item added to Drawer
          ListTile(
            leading: const Icon(Iconsax.login, color: AppTheme.secondaryColor),
            title: const Text('Login'),
            onTap: () {
              Navigator.pop(context);
              _navigateTo(3);
            },
          ),
          const Divider(color: AppTheme.secondaryColor),
          if (user?.role == 'admin')
            ListTile(
              leading: const Icon(Iconsax.setting_2, color: AppTheme.primaryColor),
              title: const Text('Admin Panel', style: TextStyle(color: AppTheme.primaryColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AdminHomeScreen.routeName);
              },
            ),
        ],
      ),
    );
  }
}

class SaleDialog extends StatefulWidget {
  final Product product;
  final int discount;
  final VoidCallback onViewDeal;

  const SaleDialog({
    super.key,
    required this.product,
    required this.discount,
    required this.onViewDeal,
  });

  @override
  State<SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<SaleDialog>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late Timer _timer;
  int _secondsLeft = 2 * 3600 + 47 * 60 + 33;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() { if (_secondsLeft > 0) _secondsLeft--; else _timer.cancel(); });
    });
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.06, vertical: 48),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 48, offset: const Offset(0, 20))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 30, 16, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor])
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('LIMITED TIME SALE!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: AppTheme.secondaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Image.network(widget.product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Iconsax.shop, color: AppTheme.primaryColor)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
                          const SizedBox(height: 4),
                          Text('Rs ${widget.product.price.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppTheme.secondaryColor, fontSize: 12)),
                          Text('Rs ${widget.product.salePrice!.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: ElevatedButton(
                    onPressed: widget.onViewDeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('GRAB THE DEAL!', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> navItems;

  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.navItems,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (_, cart, __) {
        return NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onTap,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryColor.withOpacity(0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: navItems.asMap().entries.map((entry) {
            final i    = entry.key;
            final item = entry.value;

            if (i == 2) {
              return NavigationDestination(
                icon: _CartIcon(
                  icon: item.icon,
                  count: cart.itemCount,
                  isActive: false,
                ),
                selectedIcon: _CartIcon(
                  icon: item.activeIcon,
                  count: cart.itemCount,
                  isActive: true,
                ),
                label: item.label,
              );
            }

            return NavigationDestination(
              icon: Icon(item.icon, color: AppTheme.secondaryColor),
              selectedIcon: Icon(item.activeIcon, color: AppTheme.primaryColor),
              label: item.label,
            );
          }).toList(),
        );
      },
    );
  }
}

class _CartIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;

  const _CartIcon({
    required this.icon,
    required this.count,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: isActive ? AppTheme.primaryColor : AppTheme.secondaryColor),
        if (count > 0)
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
