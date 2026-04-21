import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../admin/admin_home_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'main_app_screen.dart';
import 'login_screen.dart';
import 'widgets/app_logo.dart';
import 'widgets/feedback_dialog.dart';

class RegistrationScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.createUserWithEmailAndPassword(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      await showErrorDialog(
        context,
        title: 'Registration Failed',
        message: error,
        actionText: 'Try Again',
      );
    } else {
      if (!mounted) return;
      final isAdmin = await authService.isAdmin();
      if (isAdmin) {
        Navigator.of(context).pushNamedAndRemoveUntil(AdminHomeScreen.routeName, (route) => false);
      } else {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed(MainAppScreen.routeName);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(size: 70),
                  const SizedBox(height: 24),
                  Text(
                    'CREATE ACCOUNT',
                    style: AppTheme.headingSerif.copyWith(fontSize: 24, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JOIN SCENTVIEW LUXURY',
                    style: AppTheme.bodySans.copyWith(fontSize: 10, letterSpacing: 1, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  
                  // NAME FIELD
                  TextFormField(
                    controller: _nameCtrl,
                    style: AppTheme.bodySans,
                    decoration: const InputDecoration(
                      labelText: 'FULL NAME',
                      labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      prefixIcon: Icon(Iconsax.user, size: 18, color: Colors.black),
                    ),
                    validator: (v) => v!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // EMAIL FIELD
                  TextFormField(
                    controller: _emailCtrl,
                    style: AppTheme.bodySans,
                    decoration: const InputDecoration(
                      labelText: 'EMAIL ADDRESS',
                      labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      prefixIcon: Icon(Iconsax.sms, size: 18, color: Colors.black),
                    ),
                    validator: (v) => v!.isEmpty ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // PASSWORD FIELD
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    style: AppTheme.bodySans,
                    decoration: InputDecoration(
                      labelText: 'PASSWORD',
                      labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      prefixIcon: const Icon(Iconsax.lock, size: 18, color: Colors.black),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Iconsax.eye : Iconsax.eye_slash, size: 18, color: Colors.black),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // CONFIRM PASSWORD FIELD
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscure,
                    style: AppTheme.bodySans,
                    decoration: const InputDecoration(
                      labelText: 'CONFIRM PASSWORD',
                      labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      prefixIcon: Icon(Iconsax.lock, size: 18, color: Colors.black),
                    ),
                    validator: (v) => v != _passwordCtrl.text ? 'Passwords do not match' : null,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // REGISTER BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // LOGIN LINK
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        style: AppTheme.bodySans.copyWith(color: Colors.black54, fontSize: 13),
                        children: const [
                          TextSpan(text: "ALREADY HAVE AN ACCOUNT? "),
                          TextSpan(text: 'LOGIN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
