import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scentview/admin/admin_layout.dart';
import 'package:scentview/services/api_service.dart';
import 'package:scentview/services/orders_service.dart';
import 'package:scentview/services/auth_service.dart';
import 'package:scentview/models/product_model.dart';
import 'package:scentview/models/category.dart' as app_category;

import 'package:scentview/admin/product_list_screen.dart';
import 'package:scentview/admin/categories_screen.dart';
import 'package:scentview/admin/product_form_screen.dart';
import 'package:scentview/admin/add_edit_banner_screen.dart';
import 'package:scentview/admin/add_edit_category_screen.dart';
import 'package:scentview/admin/orders_dashboard.dart';
import 'package:scentview/admin/subscribers_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  static const String routeName = '/admin/dashboard';
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Product>> _productsFuture;
  late Future<List<app_category.Category>> _categoriesFuture;
  late Future<List<dynamic>> _subscribersFuture;

  static const Color _bg       = Color(0xFFF7F8FC);
  static const Color _white    = Colors.white;
  static const Color _primary  = Color(0xFFFF6B9D);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _textSub  = Color(0xFF9094A6);

  // ── Dummy Orders ─────────────────────
  final List<Map<String, dynamic>> _dummyOrders = [
    {'id': '#1001', 'user': 'Ahmed Khan',    'product': 'Rose Perfume',   'rate': 'Rs 4500', 'address': 'Lahore, Punjab',   'status': 'Pending'},
    {'id': '#1002', 'user': 'Sara Ali',      'product': 'Oud Musk',       'rate': 'Rs 7800', 'address': 'Karachi, Sindh',   'status': 'Completed'},
    {'id': '#1003', 'user': 'Bilal Raza',    'product': 'Jasmine Essence','rate': 'Rs 3200', 'address': 'Islamabad',        'status': 'Pending'},
    {'id': '#1004', 'user': 'Hina Shafiq',   'product': 'Amber Wood',     'rate': 'Rs 9500', 'address': 'Faisalabad',       'status': 'Cancelled'},
    {'id': '#1005', 'user': 'Usman Tariq',   'product': 'Blue Ocean',     'rate': 'Rs 5500', 'address': 'Multan, Punjab',   'status': 'Completed'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _productsFuture    = _apiService.fetchProducts();
      _categoriesFuture  = _apiService.fetchCategories();
      _subscribersFuture = _apiService.fetchSubscribers();
      Provider.of<OrdersService>(context, listen: false).fetchOrders();
    });
  }

  void _logoutAndVisitShop(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Switched to Shop View'), backgroundColor: Color(0xFFFF6B9D)),
      );
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Coming Soon'),
        content: Text('$feature jald aa raha hai!'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Color(0xFFFF6B9D))))],
      ),
    );
  }

  void _nav(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersService>(
      builder: (context, ordersService, _) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _white,
            elevation: 0,
            centerTitle: false,
            title: const Text('Admin Panel', style: TextStyle(color: Color(0xFF1A1D2E), fontWeight: FontWeight.w800, fontSize: 20)),
            actions: [
              TextButton.icon(
                onPressed: () => _logoutAndVisitShop(context),
                icon: const Icon(Icons.storefront_outlined, color: Color(0xFFFF6B9D), size: 18),
                label: const Text('Shop', style: TextStyle(color: Color(0xFFFF6B9D), fontWeight: FontWeight.w700)),
              ),
              IconButton(icon: const Icon(Icons.logout_rounded, color: Color(0xFF9094A6)), onPressed: () => _logoutAndVisitShop(context), tooltip: 'Logout'),
              const SizedBox(width: 6),
            ],
          ),
          body: AdminLayout(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: () async {
                _loadData();
              },
              child: FutureBuilder(
                future: Future.wait([_productsFuture, _categoriesFuture, _subscribersFuture]),
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _primary));
                  }
                  
                  final List<Product> products = snapshot.data?[0] ?? [];
                  final List<app_category.Category> categories = snapshot.data?[1] ?? [];
                  final List<dynamic> subscribers = snapshot.data?[2] ?? [];
                  
                  // Calculations
                  double totalInventoryValue = 0;
                  int lowStockItems = 0;
                  int manProducts = 0;
                  int womanProducts = 0;
                  int unisexProducts = 0;

                  for (var p in products) {
                    totalInventoryValue += (p.price * p.quantity);
                    if (p.quantity <= 5) lowStockItems++;
                    
                    String cat = (p.category ?? '').toLowerCase();
                    if (cat.contains('man') || cat.contains('male')) manProducts++;
                    else if (cat.contains('woman') || cat.contains('female')) womanProducts++;
                    else if (cat.contains('unisex')) unisexProducts++;
                  }

                  final stats = [
                    _StatItem(title: 'Total Products',   value: products.length.toString(), icon: Icons.shopping_bag_rounded,   iconBg: const Color(0xFFE8F0FE), iconColor: const Color(0xFF4A6CF7), onTap: () => _nav(context, const ProductListScreen())),
                    _StatItem(title: 'Inventory Value', value: 'Rs ${totalInventoryValue.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_rounded, iconBg: const Color(0xFFFFF3E0), iconColor: const Color(0xFFF39C12), onTap: () {}),
                    _StatItem(title: 'Low Stock',      value: lowStockItems.toString(), icon: Icons.warning_amber_rounded, iconBg: const Color(0xFFFDEDED), iconColor: const Color(0xFFE74C3C), onTap: () {}),
                    _StatItem(title: 'Categories',      value: categories.length.toString(), icon: Icons.category_rounded,        iconBg: const Color(0xFFE6F9F0), iconColor: const Color(0xFF27AE60), onTap: () => _nav(context, const CategoriesScreen())),
                    _StatItem(title: 'Newsletter',      value: subscribers.length.toString(), icon: Icons.mark_email_read_rounded, iconBg: const Color(0xFFF3E5F5), iconColor: Colors.purple, onTap: () => _nav(context, const SubscribersScreen())),
                    _StatItem(title: 'Total Orders',     value: ordersService.orders.isEmpty ? _dummyOrders.length.toString() : ordersService.orders.length.toString(), icon: Icons.receipt_long_rounded,    iconBg: const Color(0xFFE1F5FE), iconColor: Colors.lightBlue, onTap: () => Navigator.pushNamed(context, AdminOrdersDashboard.routeName)),
                  ];

                  return CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      // ── Stats Grid ───────────────────────────────────
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 1.0, // Ratio 1.0 means Square cards - more height
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _buildStatCard(stats[i]),
                            childCount: stats.length,
                          ),
                        ),
                      ),

                      // ── Product by Categories ──────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                          child: const Text('Products by Category', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1D2E))),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: _buildCategoryBreakdown(manProducts, womanProducts, unisexProducts),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // ── Recently Added Products ────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Recently Added', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1D2E))),
                              TextButton(
                                onPressed: () => _nav(context, const ProductListScreen()),
                                child: const Text('View All', style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: _buildRecentProductsList(products),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // ── Recent Orders ──────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                          child: const Text('Recent Orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1D2E))),
                        ),
                      ),

                      SliverToBoxAdapter(child: _buildOrdersTable()),

                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Header ────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hello Admin! 👋', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text('ScentView Overview', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Manage your inventory and orders easily.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.insights_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  // ─── Stat Card ────────────────────
  Widget _buildStatCard(_StatItem stat) {
    return GestureDetector(
      onTap: stat.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: stat.iconColor.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Stack(
          children: [
            // Decorative background circle
            Positioned(
              right: -10,
              top: -10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: stat.iconColor.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Content stays together in center
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stat.iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(stat.icon, color: stat.iconColor, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  stat.title.toUpperCase(),
                  style: TextStyle(
                    color: _textSub,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Value
                Text(
                  stat.value ?? '0',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Indicator Bar
                Container(
                  height: 3,
                  width: 30,
                  decoration: BoxDecoration(
                    color: stat.iconColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Category Breakdown ────────────────────
  Widget _buildCategoryBreakdown(int man, int woman, int unisex) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBreakdownItem('Men', man, const Color(0xFF4A6CF7)),
          _buildBreakdownItem('Women', woman, _primary),
          _buildBreakdownItem('Unisex', unisex, const Color(0xFF27AE60)),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: _textSub, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─── Recent Products ────────────────────
  Widget _buildRecentProductsList(List<Product> products) {
    final recent = products.reversed.take(4).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recent.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, i) {
          final p = recent[i];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(p.imageUrl, width: 45, height: 45, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _bg, child: const Icon(Icons.image_not_supported, size: 20))),
            ),
            title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(p.category ?? 'No Category', style: const TextStyle(fontSize: 11)),
            trailing: Text('Rs ${p.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: _primary)),
          );
        },
      ),
    );
  }

  // ─── Orders Table ───────────────────────
  Widget _buildOrdersTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF7F8FC)),
            headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9094A6)),
            dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1A1D2E)),
            columnSpacing: 20,
            horizontalMargin: 16,
            dividerThickness: 0.8,
            columns: const [
              DataColumn(label: Text('Order ID')),
              DataColumn(label: Text('User')),
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Rate')),
              DataColumn(label: Text('Address')),
              DataColumn(label: Text('Status')),
            ],
            rows: _dummyOrders.map((order) {
              final status = order['status'] as String;
              final statusColor = status == 'Completed'
                  ? const Color(0xFF27AE60)
                  : status == 'Pending'
                      ? const Color(0xFFF39C12)
                      : const Color(0xFFE74C3C);

              return DataRow(cells: [
                DataCell(Text(order['id'],      style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(order['user'])),
                DataCell(Text(order['product'])),
                DataCell(Text(order['rate'],    style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(order['address'])),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Data Models ──────────────────────────────────────────────────
class _StatItem {
  final String title;
  final String? value;
  final Future<List<dynamic>>? future;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  _StatItem({required this.title, this.value, this.future, required this.icon, required this.iconBg, required this.iconColor, required this.onTap});
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _ActionItem({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});
}
