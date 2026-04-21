import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:scentview/services/auth_service.dart';
import 'package:scentview/theme/app_theme.dart';
import 'package:scentview/admin/admin_home_screen.dart';
import 'package:scentview/ui/login_screen.dart';
import 'package:scentview/ui/wishlist_screen.dart' show WishlistScreen;
import 'package:scentview/ui/order_history_screen.dart'
    show OrderHistoryScreen;
import 'package:scentview/ui/addresses_screen.dart' show AddressesScreen;
import 'package:scentview/ui/payment_methods_screen.dart'
    show PaymentMethodsScreen;

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  bool _emailNotifications = true;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterLocalNotificationsPlugin _notifPlugin =
      FlutterLocalNotificationsPlugin();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const String _privacyPolicyText = '''
PRIVACY POLICY – ScentView
Last Updated: February 2026

1. INFORMATION WE COLLECT
We collect information you provide directly to us, such as when you create an account, make a purchase, or contact us for support. This includes:
• Name and email address
• Shipping and billing addresses
• Payment information (processed securely via third-party providers)
• Purchase history and wishlist items
• Profile photos you upload

2. HOW WE USE YOUR INFORMATION
We use the information we collect to:
• Process transactions and send related information
• Send promotional communications (only if you opt in)
• Respond to comments and questions
• Monitor and analyze trends and usage
• Detect and prevent fraudulent transactions

3. INFORMATION SHARING
We do not sell, trade, or rent your personal information to third parties. We may share your information with:
• Service providers who assist in our operations
• Law enforcement when required by law

4. DATA SECURITY
We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

5. COOKIES
We use cookies to enhance your experience. You can disable cookies through your browser settings.

6. YOUR RIGHTS
You have the right to:
• Access your personal data
• Correct inaccurate data
• Request deletion of your data
• Opt out of marketing communications

7. CONTACT US
Email: privacy@scentview.com
Phone: +92 300 1234567
''';

  static const String _termsText = '''
TERMS & CONDITIONS – ScentView
Last Updated: February 2026

1. ACCEPTANCE OF TERMS
By accessing and using the ScentView application, you accept and agree to be bound by these Terms and Conditions.

2. USE OF SERVICE
You agree to use ScentView only for lawful purposes and in a manner that does not infringe the rights of others.

3. ACCOUNT RESPONSIBILITY
You are responsible for:
• Maintaining the confidentiality of your account credentials
• All activities that occur under your account
• Notifying us immediately of any unauthorized use

4. PRODUCTS AND PRICING
• All prices are listed in Pakistani Rupees (PKR)
• Prices are subject to change without notice
• We reserve the right to limit quantities

5. ORDERS AND PAYMENT
• Orders are confirmed only after payment is received
• Accepted payment methods: Cash on Delivery, JazzCash, EasyPaisa, Bank Transfer

6. SHIPPING AND DELIVERY
• Delivery within Karachi: 1-2 business days
• Nationwide delivery: 3-5 business days

7. RETURNS AND REFUNDS
• Unused products may be returned within 7 days
• Refunds processed within 5-7 business days

8. CONTACT
Email: legal@scentview.com
Phone: +92 300 1234567
''';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notifPlugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notifPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? granted =
          await androidPlugin?.requestNotificationsPermission();
      if (granted == false) {
        _showSnackBar('Notification permission denied.', Colors.red,
            Iconsax.notification_bing);
        return;
      }
      await _notifPlugin.show(
        0,
        'ScentView 🌸',
        'Notifications are now enabled!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'scentview_channel', 'ScentView Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      _showSnackBar('Push notifications enabled!', Colors.green,
          Iconsax.notification_status5);
    } else {
      _showSnackBar(
          'Notifications disabled.', Colors.orange, Iconsax.notification_bing);
    }
    setState(() => _notificationsEnabled = value);
  }

  void _toggleDarkMode(bool value) {
    setState(() => _darkModeEnabled = value);
    _showSnackBar(
      value ? 'Dark mode enabled' : 'Light mode enabled',
      Colors.indigo,
      value ? Iconsax.moon5 : Iconsax.sun_15,
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool supported = await _localAuth.isDeviceSupported();
      if (!canCheck || !supported) {
        _showSnackBar('Biometrics not available on this device.',
            Colors.red, Iconsax.finger_scan);
        return;
      }
      final List<BiometricType> available =
          await _localAuth.getAvailableBiometrics();
      if (available.isEmpty) {
        _showSnackBar(
          'No biometrics enrolled. Setup in device settings.',
          Colors.orange,
          Iconsax.finger_scan,
        );
        return;
      }
      try {
        final bool auth = await _localAuth.authenticate(
          localizedReason:
              'Scan your fingerprint or face to enable biometric login',
          options: const AuthenticationOptions(
              biometricOnly: true, stickyAuth: true),
        );
        if (auth) {
          setState(() => _biometricEnabled = true);
          _showSnackBar('Biometric login enabled!', Colors.green,
              Iconsax.finger_scan5);
        } else {
          _showSnackBar('Authentication failed.', Colors.red,
              Iconsax.finger_scan);
        }
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red, Iconsax.finger_scan);
      }
    } else {
      try {
        final bool auth = await _localAuth.authenticate(
          localizedReason: 'Authenticate to disable biometric login',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (auth) {
          setState(() => _biometricEnabled = false);
          _showSnackBar('Biometric login disabled.', Colors.orange,
              Iconsax.finger_scan);
        }
      } catch (_) {
        setState(() => _biometricEnabled = false);
      }
    }
  }

  void _toggleEmailNotifications(bool value) {
    setState(() => _emailNotifications = value);
    _showSnackBar(
      value
          ? 'Email notifications enabled.'
          : 'Email notifications disabled.',
      value ? Colors.green : Colors.orange,
      value ? Iconsax.sms_notification5 : Iconsax.sms,
    );
  }

  void _showSnackBar(String msg, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _darkModeEnabled ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          final bool isLoggedIn = authService.isAuthenticated;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildProfileCard(context, user, isLoggedIn),
                        const SizedBox(height: 24),

                        if (!isLoggedIn) ...[
                          _buildLoginCard(context),
                          const SizedBox(height: 24),
                        ],

                        if (isLoggedIn) ...[
                          _buildSectionHeader(
                              'Purchase History', Iconsax.bag_timer),
                          const SizedBox(height: 12),
                          _buildPurchaseHistory(),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                              'Account Settings', Iconsax.setting_2),
                          const SizedBox(height: 12),
                          _buildAccountSection(context, authService),
                          const SizedBox(height: 24),
                        ],

                        _buildSectionHeader(
                            'Preferences', Iconsax.setting_3),
                        const SizedBox(height: 12),
                        _buildPreferencesSection(),
                        const SizedBox(height: 24),

                        _buildSectionHeader(
                            'Support & Info', Iconsax.info_circle),
                        const SizedBox(height: 12),
                        _buildSupportSection(),
                        const SizedBox(height: 32),

                        _buildAppVersion(),
                        const SizedBox(height: 20),

                        if (isLoggedIn)
                          _buildLogoutButton(context, authService),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Profile Card ─────────────────────────────────────────────
  Widget _buildProfileCard(
      BuildContext context, AuthUser? user, bool isLoggedIn) {
    return Container(
      decoration: BoxDecoration(
        color: _darkModeEnabled ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _darkModeEnabled
                ? Colors.black.withOpacity(0.3)
                : Colors.blue.withOpacity(0.15),
            blurRadius: 30, spreadRadius: 3,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _darkModeEnabled
                        ? [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)]
                        : [
                            const Color(0xFF3B82F6),
                            const Color(0xFF8B5CF6),
                            const Color(0xFFEC4899),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 25,
                        spreadRadius: 5)
                  ],
                ),
              ),
              Container(
                width: 108, height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _darkModeEnabled
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    width: 5,
                  ),
                  color: _darkModeEnabled
                      ? const Color(0xFF334155)
                      : Colors.grey.shade100,
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover)
                      : user?.photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(user!.photoUrl!),
                              fit: BoxFit.cover)
                          : null,
                ),
                child: _selectedImage == null && user?.photoUrl == null
                    ? Icon(
                        Iconsax.user, size: 45,
                        color: _darkModeEnabled
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                      )
                    : null,
              ),
              if (isLoggedIn)
                Positioned(
                  bottom: 2, right: 2,
                  child: GestureDetector(
                    onTap: () => _showImagePicker(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2)
                        ],
                      ),
                      child: const Icon(Iconsax.camera5,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
              if (isLoggedIn)
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _darkModeEnabled
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(Icons.check,
                        size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            isLoggedIn ? (user?.name ?? 'User') : 'Guest User',
            style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800,
              color: _darkModeEnabled
                  ? Colors.white
                  : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _darkModeEnabled
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.sms, size: 14,
                    color: _darkModeEnabled
                        ? Colors.blue.shade300
                        : Colors.blue),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isLoggedIn
                        ? (user?.email ?? '')
                        : 'Login to access all features',
                    style: TextStyle(
                      fontSize: 13,
                      color: _darkModeEnabled
                          ? Colors.blue.shade300
                          : Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis, // ← overflow fix
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (isLoggedIn)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _darkModeEnabled
                    ? const Color(0xFF334155)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(Iconsax.shopping_bag, '12', 'Orders'),
                  _buildDivider(),
                  _buildStatItem(Iconsax.heart5, '8', 'Wishlist'),
                  _buildDivider(),
                  _buildStatItem(Iconsax.star5, '4.8', 'Rating'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(
      width: 1, height: 40,
      color: _darkModeEnabled
          ? Colors.grey.shade700
          : Colors.grey.shade300);

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: _darkModeEnabled
                ? Colors.white
                : const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _darkModeEnabled
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Purchase History  (overflow fixed) ───────────────────────
  Widget _buildPurchaseHistory() {
    final purchases = [
      {
        'name': 'Dior Sauvage EDT',
        'date': 'Feb 10, 2026',
        'price': 'PKR 8,500',
        'quantity': '100ml',
        'status': 'Delivered',
        'icon': Iconsax.box_15,
      },
      {
        'name': 'Chanel No. 5 EDP',
        'date': 'Jan 28, 2026',
        'price': 'PKR 12,000',
        'quantity': '50ml',
        'status': 'Delivered',
        'icon': Iconsax.box_15,
      },
      {
        'name': 'Tom Ford Black Orchid',
        'date': 'Jan 15, 2026',
        'price': 'PKR 15,500',
        'quantity': '100ml',
        'status': 'Delivered',
        'icon': Iconsax.box_15,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: _darkModeEnabled ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _darkModeEnabled
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 20, spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.shopping_cart5,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                // ── OVERFLOW FIX: wrap in Expanded ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Purchases',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _darkModeEnabled
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${purchases.length} perfumes bought',
                        style: TextStyle(
                          fontSize: 12,
                          color: _darkModeEnabled
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showFullPurchaseHistory(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: purchases.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: _darkModeEnabled
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
            ),
            itemBuilder: (_, i) => _buildPurchaseItem(purchases[i]),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildPurchaseItem(Map<String, dynamic> purchase) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _darkModeEnabled
                  ? Colors.green.withOpacity(0.2)
                  : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(purchase['icon'], color: Colors.green, size: 22),
          ),
          const SizedBox(width: 12),
          // ── OVERFLOW FIX: Expanded + ellipsis ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase['name'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _darkModeEnabled
                        ? Colors.white
                        : const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // ← overflow fix
                ),
                const SizedBox(height: 4),
                // ── OVERFLOW FIX: Wrap row items ──
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.calendar_1,
                            size: 11,
                            color: _darkModeEnabled
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Text(
                          purchase['date'],
                          style: TextStyle(
                            fontSize: 11,
                            color: _darkModeEnabled
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.drop,
                            size: 11,
                            color: _darkModeEnabled
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Text(
                          purchase['quantity'],
                          style: TextStyle(
                            fontSize: 11,
                            color: _darkModeEnabled
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── OVERFLOW FIX: constrained width ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                purchase['price'],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _darkModeEnabled
                      ? Colors.white
                      : const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  purchase['status'],
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Login Card ───────────────────────────────────────────────
  Widget _buildLoginCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _darkModeEnabled
              ? [const Color(0xFF1E40AF), const Color(0xFF7C3AED)]
              : [
                  const Color(0xFF3B82F6),
                  const Color(0xFF8B5CF6),
                  const Color(0xFFEC4899),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 25,
              spreadRadius: 3)
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.lock_15,
                size: 50, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Unlock Premium Features',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Login to manage orders, wishlist,\npurchase history & more',
            style:
                TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, LoginScreen.routeName),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF3B82F6),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.login, size: 20),
                SizedBox(width: 10),
                Text('Login / Register',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: _darkModeEnabled
                  ? Colors.white
                  : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Account Section (with real navigation) ───────────────────
  Widget _buildAccountSection(
      BuildContext context, AuthService authService) {
    return Container(
      decoration: BoxDecoration(
        color: _darkModeEnabled ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _darkModeEnabled
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 20, spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          if (authService.currentUser?.role == 'admin')
            _buildAccountTile(
              icon: Iconsax.setting_25,
              title: 'Admin Dashboard',
              subtitle: 'Manage store & orders',
              color: Colors.purple,
              onTap: () =>
                  Navigator.pushNamed(context, AdminHomeScreen.routeName),
            ),
          // ── MY ORDERS → OrdersScreen ──
          _buildAccountTile(
            icon: Iconsax.bag_25,
            title: 'My Orders',
            subtitle: 'Track and view all orders',
            color: Colors.blue,
            onTap: () =>
                Navigator.pushNamed(context, OrderHistoryScreen.routeName),
          ),
          // ── WISHLIST → WishlistScreen ──
          _buildAccountTile(
            icon: Iconsax.heart5,
            title: 'Wishlist',
            subtitle: 'Your saved perfumes',
            color: Colors.red,
            onTap: () =>
                Navigator.pushNamed(context, WishlistScreen.routeName),
          ),
          // ── ADDRESSES → AddressesScreen ──
          _buildAccountTile(
            icon: Iconsax.location5,
            title: 'Addresses',
            subtitle: 'Manage shipping addresses',
            color: Colors.orange,
            onTap: () =>
                Navigator.pushNamed(context, AddressesScreen.routeName),
          ),
          // ── PAYMENT METHODS → PaymentMethodsScreen ──
          _buildAccountTile(
            icon: Iconsax.wallet_35,
            title: 'Payment Methods',
            subtitle: 'Manage & allow payment options',
            color: Colors.green,
            onTap: () => Navigator.pushNamed(
                context, PaymentMethodsScreen.routeName),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: _darkModeEnabled
                            ? Colors.white
                            : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: _darkModeEnabled
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3, size: 20,
                color: _darkModeEnabled
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Preferences Section ──────────────────────────────────────
  Widget _buildPreferencesSection() {
    return Container(
      decoration: BoxDecoration(
        color: _darkModeEnabled ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _darkModeEnabled
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 20, spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPreferenceTile(
            icon: Iconsax.notification5,
            title: 'Push Notifications',
            subtitle: _notificationsEnabled
                ? 'Enabled – receiving order alerts'
                : 'Disabled – tap to enable',
            color: Colors.blue,
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          _buildPreferenceTile(
            icon: Iconsax.moon5,
            title: 'Dark Mode',
            subtitle: _darkModeEnabled
                ? 'Dark theme active'
                : 'Light theme active',
            color: Colors.indigo,
            value: _darkModeEnabled,
            onChanged: _toggleDarkMode,
          ),
          _buildPreferenceTile(
            icon: Iconsax.finger_scan5,
            title: 'Biometric Login',
            subtitle: _biometricEnabled
                ? 'Fingerprint / Face ID enabled'
                : 'Tap to set up biometric login',
            color: Colors.purple,
            value: _biometricEnabled,
            onChanged: _toggleBiometric,
          ),
          _buildPreferenceTile(
            icon: Iconsax.sms_notification5,
            title: 'Email Notifications',
            subtitle: _emailNotifications
                ? 'Receiving order confirmation emails'
                : 'Email notifications off',
            color: Colors.orange,
            value: _emailNotifications,
            onChanged: _toggleEmailNotifications,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: _darkModeEnabled
                        ? Colors.white
                        : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: _darkModeEnabled
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: color,
              activeTrackColor: color.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Support Section ──────────────────────────────────────────
  Widget _buildSupportSection() {
    return Container(
      decoration: BoxDecoration(
        color: _darkModeEnabled ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _darkModeEnabled
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 20, spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSupportTile(
            icon: Iconsax.message_question5,
            title: 'Help Center',
            subtitle: 'Get help with your account',
            color: Colors.green,
            onTap: () => _showHelpCenter(context),
          ),
          _buildSupportTile(
            icon: Iconsax.shield_tick5,
            title: 'Privacy Policy',
            subtitle: 'How we protect your data',
            color: Colors.blue,
            onTap: () => _showPolicyDialog(
              context,
              title: 'Privacy Policy',
              icon: Iconsax.shield_tick5,
              iconColor: Colors.blue,
              content: _privacyPolicyText,
            ),
          ),
          _buildSupportTile(
            icon: Iconsax.document_text_15,
            title: 'Terms & Conditions',
            subtitle: 'User agreement',
            color: Colors.orange,
            onTap: () => _showPolicyDialog(
              context,
              title: 'Terms & Conditions',
              icon: Iconsax.document_text_15,
              iconColor: Colors.orange,
              content: _termsText,
            ),
          ),
          _buildSupportTile(
            icon: Iconsax.star_15,
            title: 'Rate App',
            subtitle: 'Share your feedback',
            color: Colors.amber,
            onTap: () => _showRateAppDialog(context),
          ),
          _buildSupportTile(
            icon: Iconsax.info_circle5,
            title: 'About ScentView',
            subtitle: 'Version 1.0.0',
            color: Colors.purple,
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: _darkModeEnabled
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        )),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: _darkModeEnabled
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        )),
                  ],
                ),
              ),
              Icon(Iconsax.arrow_right_3, size: 20,
                  color: _darkModeEnabled
                      ? Colors.grey.shade600
                      : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // ─── App Version ──────────────────────────────────────────────
  Widget _buildAppVersion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _darkModeEnabled
            ? const Color(0xFF1E293B).withOpacity(0.5)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _darkModeEnabled
              ? Colors.grey.shade800
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.code_circle, size: 20,
              color: _darkModeEnabled
                  ? Colors.grey.shade400
                  : Colors.grey.shade600),
          const SizedBox(width: 10),
          Text(
            'ScentView v1.0.0 • Made with ❤️',
            style: TextStyle(
              fontSize: 13,
              color: _darkModeEnabled
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Logout Button ────────────────────────────────────────────
  Widget _buildLogoutButton(
      BuildContext context, AuthService authService) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 15, spreadRadius: 2)
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutConfirmation(context, authService),
        icon: const Icon(Iconsax.logout_15, size: 22),
        label: const Text('Logout',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkModeEnabled
              ? Colors.red.shade900
              : Colors.red.shade50,
          foregroundColor: Colors.red,
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
                color: Colors.red.withOpacity(0.3), width: 2),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ─── Image Picker ─────────────────────────────────────────────
  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color:
              _darkModeEnabled ? const Color(0xFF1E293B) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50, height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Update Profile Picture',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800,
                color: _darkModeEnabled
                    ? Colors.white
                    : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildImageOption(
                    icon: Iconsax.camera5,
                    label: 'Camera',
                    color: Colors.blue,
                    onTap: () => _pickImage(ImageSource.camera, ctx),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageOption(
                    icon: Iconsax.gallery5,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () => _pickImage(ImageSource.gallery, ctx),
                  ),
                ),
              ],
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _selectedImage = null);
                    Navigator.pop(ctx);
                    _showSnackBar('Photo removed.', Colors.red,
                        Iconsax.trash);
                  },
                  icon: const Icon(Iconsax.trash),
                  label: const Text('Remove Current Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, BuildContext ctx) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024, maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
        Navigator.pop(ctx);
        _showSnackBar('Profile picture updated! ✨', Colors.green,
            Iconsax.tick_circle5);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red, Iconsax.close_circle);
    }
  }

  // ─── Edit Profile Dialog ──────────────────────────────────────
  void _showEditProfileDialog(BuildContext context, AuthUser? user) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _darkModeEnabled
            ? const Color(0xFF1E293B)
            : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.edit_25,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Edit Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _darkModeEnabled
                      ? Colors.white
                      : const Color(0xFF1F2937),
                )),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                  controller: nameCtrl,
                  label: 'Full Name',
                  icon: Iconsax.user),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: emailCtrl,
                  label: 'Email',
                  icon: Iconsax.sms,
                  readOnly: true),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: phoneCtrl,
                  label: 'Phone Number',
                  icon: Iconsax.call),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Profile updated!', Colors.green,
                  Iconsax.tick_circle5);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(
        color: _darkModeEnabled
            ? Colors.white
            : const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _darkModeEnabled
              ? Colors.grey.shade400
              : Colors.grey.shade600,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
        filled: true,
        fillColor: _darkModeEnabled
            ? const Color(0xFF334155)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _darkModeEnabled
                ? Colors.grey.shade700
                : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
      ),
    );
  }

  // ─── Full Purchase History ────────────────────────────────────
  void _showFullPurchaseHistory(BuildContext context) {
    final all = [
      {
        'month': 'February 2026',
        'items': [
          {
            'name': 'Dior Sauvage EDT',
            'date': 'Feb 10, 2026',
            'price': 'PKR 8,500',
            'quantity': '100ml',
            'status': 'Delivered',
            'icon': Iconsax.box_15,
          },
        ]
      },
      {
        'month': 'January 2026',
        'items': [
          {
            'name': 'Chanel No. 5 EDP',
            'date': 'Jan 28, 2026',
            'price': 'PKR 12,000',
            'quantity': '50ml',
            'status': 'Delivered',
            'icon': Iconsax.box_15,
          },
          {
            'name': 'Tom Ford Black Orchid',
            'date': 'Jan 15, 2026',
            'price': 'PKR 15,500',
            'quantity': '100ml',
            'status': 'Delivered',
            'icon': Iconsax.box_15,
          },
        ]
      },
      {
        'month': 'December 2025',
        'items': [
          {
            'name': 'Versace Eros',
            'date': 'Dec 20, 2025',
            'price': 'PKR 7,200',
            'quantity': '100ml',
            'status': 'Delivered',
            'icon': Iconsax.box_15,
          },
        ]
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: _darkModeEnabled
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _darkModeEnabled
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.bag_timer5,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Purchase History',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _darkModeEnabled
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              )),
                          Text('All your perfume purchases',
                              style: TextStyle(
                                fontSize: 12,
                                color: _darkModeEnabled
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              )),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Iconsax.close_circle),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  itemCount: all.length,
                  itemBuilder: (_, i) {
                    final group = all[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (i > 0) const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF3B82F6),
                                Color(0xFF8B5CF6)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            group['month'] as String,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...(group['items']
                                as List<Map<String, dynamic>>)
                            .map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildPurchaseItem(p),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Policy Dialog ────────────────────────────────────────────
  void _showPolicyDialog(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: _darkModeEnabled
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50, height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _darkModeEnabled
                                ? Colors.white
                                : const Color(0xFF1F2937),
                          )),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Iconsax.close_circle,
                          color: _darkModeEnabled
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: _darkModeEnabled
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14, height: 1.7,
                      color: _darkModeEnabled
                          ? Colors.grey.shade300
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('I Understand',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Rate App ─────────────────────────────────────────────────
  void _showRateAppDialog(BuildContext context) {
    int stars = 5;
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _darkModeEnabled
              ? const Color(0xFF1E293B)
              : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Iconsax.star5,
                    color: Colors.amber, size: 40),
              ),
              const SizedBox(height: 12),
              Text('Rate ScentView',
                  style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: _darkModeEnabled
                        ? Colors.white
                        : const Color(0xFF1F2937),
                  )),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setS(() => stars = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < stars ? Iconsax.star5 : Iconsax.star1,
                        color: Colors.amber, size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your feedback...',
                  filled: true,
                  fillColor: _darkModeEnabled
                      ? const Color(0xFF334155)
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showSnackBar('Thanks for your $stars-star rating! 🌟',
                    Colors.amber, Iconsax.star5);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Help Center ──────────────────────────────────────────────
  void _showHelpCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _darkModeEnabled
            ? const Color(0xFF1E293B)
            : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.message_question5,
                  color: Colors.green, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Help Center',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _darkModeEnabled
                      ? Colors.white
                      : const Color(0xFF1F2937),
                )),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHelpItem(
                icon: Iconsax.call5,
                title: 'Call Support',
                subtitle: '+92 300 1234567'),
            const SizedBox(height: 12),
            _buildHelpItem(
                icon: Iconsax.sms5,
                title: 'Email Support',
                subtitle: 'support@scentview.com'),
            const SizedBox(height: 12),
            _buildHelpItem(
                icon: Iconsax.message5,
                title: 'Live Chat',
                subtitle: 'Chat with our team'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkModeEnabled
            ? const Color(0xFF334155)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _darkModeEnabled
                          ? Colors.white
                          : const Color(0xFF1F2937),
                    )),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _darkModeEnabled
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── About ────────────────────────────────────────────────────
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _darkModeEnabled
            ? const Color(0xFF1E293B)
            : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.shopping_bag,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text('ScentView',
                style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  color: _darkModeEnabled
                      ? Colors.white
                      : const Color(0xFF1F2937),
                )),
            const SizedBox(height: 8),
            Text('Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: _darkModeEnabled
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                )),
          ],
        ),
        content: Text(
          'Your premium destination for authentic perfumes. Discover, explore, and purchase the finest fragrances from around the world.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14, height: 1.5,
            color: _darkModeEnabled
                ? Colors.grey.shade300
                : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  // ─── Logout ───────────────────────────────────────────────────
  void _showLogoutConfirmation(
      BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _darkModeEnabled
            ? const Color(0xFF1E293B)
            : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.logout_15,
                  color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _darkModeEnabled
                      ? Colors.white
                      : const Color(0xFF1F2937),
                )),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: _darkModeEnabled
                ? Colors.grey.shade300
                : Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              authService.signOut();
              Navigator.pop(ctx);
              _showSnackBar('Logged out successfully', Colors.red,
                  Iconsax.logout_15);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
