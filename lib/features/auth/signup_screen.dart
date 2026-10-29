import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/portal_widgets.dart';
import '../../services/auth_service.dart';
import '../home/home_shell.dart';

/// Sign-up portal — port of createSignupPage from Main.java.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppColors.darkBrown,
        ),
      );
      return;
    }
    final error = await AuthService.instance
        .register(_emailController.text, _passwordController.text);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.darkBrown),
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
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
                        'Create Account',
                        size: 22,
                        color: AppColors.mutedBrown,
                      ),
                      const SizedBox(height: 24),
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
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _confirmController,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          labelText: 'CONFIRM PASSWORD',
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                        ),
                        onSubmitted: (_) => _createAccount(),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: PortalButton(
                          label: 'SIGN UP',
                          onPressed: _createAccount,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Back to login',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
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
