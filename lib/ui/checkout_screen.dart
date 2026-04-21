import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/cart_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(); // ADDED: Email Controller
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  
  bool _isLoading = false;
  static const double _deliveryFee = 200.0; 

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email; // Pre-fill email if logged in
      _phoneController.text = user.phoneNumber ?? '';
      _addressController.text = user.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose(); // Dispose email controller
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _openWhatsAppOrder(CartService cart) async {
    const phoneNumber = "+923079417399"; 
    
    final StringBuffer buffer = StringBuffer();
    buffer.writeln("✨ *NEW ORDER FROM SCENTVIEW* ✨");
    buffer.writeln("--------------------------------");
    buffer.writeln("*Customer Details:*");
    buffer.writeln("Name: ${_nameController.text}");
    buffer.writeln("Email: ${_emailController.text}"); // Added to WhatsApp
    buffer.writeln("Phone: ${_phoneController.text}");
    buffer.writeln("Address: ${_addressController.text}, ${_cityController.text}");
    buffer.writeln("");
    buffer.writeln("*Items:*");
    
    final uniqueProducts = cart.uniqueItems;
    for (var product in uniqueProducts) {
      final qty = cart.getQuantity(product);
      final price = (product.salePrice != null && product.salePrice! > 0) ? product.salePrice! : product.price;
      buffer.writeln("- ${product.name} (x$qty) : Rs ${(price * qty).toStringAsFixed(0)}");
    }

    buffer.writeln("");
    buffer.writeln("*Total Amount:* Rs ${(cart.totalPrice + _deliveryFee).toStringAsFixed(0)}");
    buffer.writeln("--------------------------------");
    buffer.writeln("Please confirm my order.");

    final url = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(buffer.toString())}';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final cart = Provider.of<CartService>(context, listen: false);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    // Correctly group items with their real quantities
    final uniqueProducts = cart.uniqueItems;
    final orderItems = uniqueProducts.map((product) {
      final qty = cart.getQuantity(product);
      return {
        'id': product.id,
        'name': product.name,
        'quantity': qty,
        'price': (product.salePrice != null && product.salePrice! > 0) ? product.salePrice : product.price,
      };
    }).toList();

    final orderData = {
      'user_id': user?.id,
      'customer_name': _nameController.text,
      'customer_email': _emailController.text, 
      'email': _emailController.text,          // Standard key for many mailers
      'customer_phone': _phoneController.text,
      'shipping_address': '${_addressController.text}, ${_cityController.text}',
      'total_amount': cart.totalPrice + _deliveryFee,
      'payment_method': 'COD',
      'items': orderItems,
    };

    try {
      // Re-enabled system order so email can be sent by backend
      await _api.placeOrder(orderData);
    } catch (e) {
      debugPrint("System Order Error (Ignored for WhatsApp): $e");
    }

    // Always Open WhatsApp
    _openWhatsAppOrder(cart);

    if (mounted) {
      setState(() => _isLoading = false);
      cart.clear();
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('ORDER PLACED!', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Your order has been sent. A confirmation will be sent to your email and WhatsApp.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamedAndRemoveUntil('/main-app', (route) => false);
            },
            child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('CHECKOUT'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('SHIPPING INFORMATION'),
                  const SizedBox(height: 20),
                  _buildTextField('Full Name', _nameController, Iconsax.user),
                  const SizedBox(height: 16),
                  // EMAIL FIELD
                  _buildTextField('Email Address', _emailController, Iconsax.sms, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildTextField('Phone Number', _phoneController, Iconsax.call, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField('Shipping Address', _addressController, Iconsax.location, maxLines: 2),
                  const SizedBox(height: 16),
                  _buildTextField('City', _cityController, Iconsax.building_31),
                  
                  const SizedBox(height: 40),
                  _buildSectionTitle('ORDER SUMMARY'),
                  const SizedBox(height: 20),
                  _buildOrderSummary(cart),
                  
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: Text('PLACE ORDER - Rs ${(cart.totalPrice + _deliveryFee).toStringAsFixed(0)}'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.bodySans.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTheme.bodySans,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'This field is required';
        if (label.contains('Email') && !value.contains('@')) return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _buildOrderSummary(CartService cart) {
    final Map<dynamic, int> productCounts = {};
    for (var p in cart.items) {
      productCounts[p.id] = (productCounts[p.id] ?? 0) + 1;
    }
    
    final Set<dynamic> seenIds = {};
    final uniqueProducts = cart.items.where((p) {
      if (seenIds.contains(p.id)) return false;
      seenIds.add(p.id);
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          ...uniqueProducts.map((product) {
            final qty = productCounts[product.id] ?? 1;
            final price = (product.salePrice != null && product.salePrice! > 0) ? product.salePrice! : product.price;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${qty}x ${product.name}', style: AppTheme.bodySans)),
                  Text('Rs ${(price * qty).toStringAsFixed(0)}', style: AppTheme.bodySans),
                ],
              ),
            );
          }).toList(),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Rs ${cart.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Rs ${(cart.totalPrice + _deliveryFee).toStringAsFixed(0)}', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.accentColor)),
            ],
          ),
        ],
      ),
    );
  }
}
