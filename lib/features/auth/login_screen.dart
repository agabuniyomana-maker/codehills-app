import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/portal_widgets.dart';
import '../../services/auth_service.dart';
import '../home/home_shell.dart';
import 'signup_screen.dart';

/// Login portal — port of createLoginPage / handleLogin from Main.java.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enterPortal() async {
    setState(() => _busy = true);
    final error = await AuthService.instance
        .login(_emailController.text, _passwordController.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.darkBrown,
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: PortalCard(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PortalHeading('Code Hills 1001', size: 26),
                      const SizedBox(height: 4),
                      const ImigongoBand(height: 14),
                      const SizedBox(height: 18),
                      const PortalHeading(
                        'Login Portal',
                        size: 22,
                        color: AppColors.mutedBrown,
                      ),
                      const PortalHeading(
                        'User Access',
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(height: 26),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'EMAIL ADDRESS',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'PASSWORD',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        onSubmitted: (_) => _enterPortal(),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: PortalButton(
                          label: _busy ? 'CHECKING...' : 'ENTER PORTAL',
                          onPressed: _busy ? null : _enterPortal,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'New here?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'SIGN UP',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Admin? Use ADMIN LOGIN from the navigation menu.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
