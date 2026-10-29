import 'package:flutter/material.dart';

import '../../data/app_data.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/portal_widgets.dart';

/// Admin portal — port of AdminPortalPanel.java (phase 1: stats overview,
/// plan management list and received inquiries).
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AuthService.instance.session;
    if (session == null || !session.isAdmin) {
      return const _AdminLoginGate();
    }

    final plans = AppData.instance.plans;
    final inquiries = AppData.instance.inquiries;

    return PortalCard(
      radius: 22,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PortalHeading('Admin Portal', size: 24),
                const SizedBox(height: 4),
                const ImigongoBand(height: 14),
                const SizedBox(height: 18),
                PortalHeading(
                  'Signed in as ${session.username}',
                  size: 13,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 22),
                const PortalHeading('Business plans', size: 16),
                const SizedBox(height: 10),
                for (final plan in plans)
                  PortalCard(
                    radius: 14,
                    background: AppColors.white,
                    child: ListTile(
                      leading: const Icon(
                        Icons.description_outlined,
                        color: AppColors.gold,
                      ),
                      title: Text(
                        plan.planName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${plan.resourceName} · ${plan.planType} · '
                        '${plan.priceRange}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        'Downloads: ${plan.downloadCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedBrown,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 22),
                const PortalHeading('Contact inquiries', size: 16),
                const SizedBox(height: 10),
                if (inquiries.isEmpty)
                  const PortalHeading(
                    'No inquiries yet',
                    size: 13,
                    color: AppColors.mutedBrown,
                  )
                else
                  for (final inquiry in inquiries)
                    PortalCard(
                      radius: 14,
                      background: AppColors.white,
                      child: ListTile(
                        leading: const Icon(
                          Icons.mail_outline,
                          color: AppColors.gold,
                        ),
                        title: Text(
                          inquiry['name']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(inquiry['inquiry']?.toString() ?? ''),
                        trailing: Text(
                          inquiry['email']?.toString() ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                const SizedBox(height: 22),
                PortalButton(
                  label: 'ADD NEW BUSINESS PLAN (needs backend)',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Plan uploads arrive when the Supabase backend '
                          'is connected (phase 2).',
                        ),
                        backgroundColor: AppColors.darkBrown,
                      ),
                    );
                  },
                  filled: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gate shown to non-admins: username/password check against the seeded admin.
class _AdminLoginGate extends StatefulWidget {
  const _AdminLoginGate();

  @override
  State<_AdminLoginGate> createState() => _AdminLoginGateState();
}

class _AdminLoginGateState extends State<_AdminLoginGate> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final error = await AuthService.instance
        .login(_userController.text, _passwordController.text);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.darkBrown),
      );
      return;
    }
    if (AuthService.instance.session?.isAdmin != true) {
      await AuthService.instance.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That account is not an administrator.'),
          backgroundColor: AppColors.darkBrown,
        ),
      );
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PortalCard(
      radius: 22,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PortalHeading('Admin Login', size: 22),
                const SizedBox(height: 4),
                const ImigongoBand(height: 14),
                const SizedBox(height: 20),
                TextField(
                  controller: _userController,
                  decoration:
                      const InputDecoration(labelText: 'ADMIN USERNAME'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'PASSWORD'),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 20),
                PortalButton(label: 'ENTER ADMIN PORTAL', onPressed: _login),
                const SizedBox(height: 14),
                const Text(
                  'Demo admin: admin / codehills1001',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.mutedBrown),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
