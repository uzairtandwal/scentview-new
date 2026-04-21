import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../admin/admin_home_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'main_app_screen.dart';
import 'registration_screen.dart';
import 'widgets/app_logo.dart';
import 'widgets/feedback_dialog.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();

  bool _isLoading = false;
  bool _obscure   = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.signInWithEmailAndPassword(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      await showErrorDialog(
        context,
        title: 'Login Failed',
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
        leading: Navigator.canPop(context) 
          ? IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context))
          : null,
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
                  const AppLogo(size: 80),
                  const SizedBox(height: 32),
                  Text(
                    'WELCOME BACK',
                    style: AppTheme.headingSerif.copyWith(fontSize: 28, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SIGN IN TO CONTINUE',
                    style: AppTheme.bodySans.copyWith(fontSize: 12, letterSpacing: 1, color: Colors.black54),
                  ),
                  const SizedBox(height: 48),
                  
                  // EMAIL FIELD
                  TextFormField(
                    controller: _emailCtrl,
                    style: AppTheme.bodySans,
                    decoration: InputDecoration(
                      labelText: 'EMAIL ADDRESS',
                      labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      prefixIcon: const Icon(Iconsax.sms, size: 18, color: Colors.black),
                    ),
                    validator: (v) => v!.isEmpty ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 20),
                  
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
                    validator: (v) => v!.isEmpty ? 'Password is required' : null,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SIGN IN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // REGISTER LINK
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, RegistrationScreen.routeName),
                    child: RichText(
                      text: TextSpan(
                        style: AppTheme.bodySans.copyWith(color: Colors.black54, fontSize: 13),
                        children: const [
                          TextSpan(text: "DON'T HAVE AN ACCOUNT? "),
                          TextSpan(text: 'REGISTER', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
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
