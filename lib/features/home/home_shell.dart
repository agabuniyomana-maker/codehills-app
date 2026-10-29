import 'package:flutter/material.dart';

import '../../app_features.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/portal_widgets.dart';
import '../auth/login_screen.dart';

/// Top-level shell: navigation + page switching + the branded header.
///
/// All destinations and pages come from [appFeatures] — this widget
/// never lists screens itself, so new features appear automatically.
/// Uses a NavigationRail on wide screens (desktop/tablet) and a
/// bottom NavigationBar on phones.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = initialFeatureIndex;

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final user = AuthService.instance.session;

    final content = IndexedStack(
      index: _index,
      children: [for (final f in appFeatures) f.builder(context)],
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: wide
                ? Row(
                    children: [
                      NavigationRail(
                        backgroundColor: AppColors.cream,
                        selectedIndex: _index,
                        onDestinationSelected: (i) =>
                            setState(() => _index = i),
                        labelType: width >= 1200
                            ? NavigationRailLabelType.all
                            : NavigationRailLabelType.none,
                        indicatorColor: AppColors.yellow,
                        selectedIconTheme: const IconThemeData(
                          color: AppColors.darkBrown,
                        ),
                        unselectedIconTheme: const IconThemeData(
                          color: AppColors.mutedBrown,
                        ),
                        selectedLabelTextStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: AppColors.darkBrown,
                        ),
                        unselectedLabelTextStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: AppColors.mutedBrown,
                        ),
                        destinations: [
                          for (final f in appFeatures)
                            NavigationRailDestination(
                              icon: Icon(f.icon),
                              selectedIcon: Icon(f.icon),
                              label: Text(f.label),
                            ),
                        ],
                        trailing: Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ImigongoAvatar(
                                    seed: user?.username ?? 'guest',
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    user?.username ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.mutedBrown,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  IconButton(
                                    tooltip: 'Log out',
                                    onPressed: _logout,
                                    icon: const Icon(Icons.logout, size: 20),
                                    color: AppColors.darkBrown,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, color: AppColors.gold),
                      Expanded(child: content),
                    ],
                  )
                : content,
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              backgroundColor: AppColors.cream,
              indicatorColor: AppColors.yellow,
              height: 64,
              selectedIndex: _index.clamp(0, appFeatures.length - 1),
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final f in appFeatures.take(5))
                  NavigationDestination(
                    icon: Icon(f.icon),
                    label: f.phoneLabel,
                  ),
              ],
            ),
    );
  }
}

/// Branded header with the banner image and Imigongo band.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 92,
          width: double.infinity,
          color: AppColors.darkBrown,
          child: Image.asset(
            'assets/images/header_banner.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: PortalHeading(
                'CODE HILLS 1001',
                size: 26,
                color: AppColors.yellow,
              ),
            ),
          ),
        ),
        const ImigongoBand(height: 16),
      ],
    );
  }
}
