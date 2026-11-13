import 'package:flutter/material.dart';

import '../../app_features.dart';
import '../../services/auth_service.dart';
import '../../services/imigongo_identity.dart';
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
          if (user != null)
            _IdentityBar(session: user, onLogout: _logout),
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
                                    seed: user?.accountId ?? 'guest',
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

/// The account's permanent Imigongo identity, shown after login.
///
/// Everything here comes from the stable account id — never the display name
/// — so the artwork survives logout/login, reinstalls and other devices. On
/// phones this bar is also the sign-out control, since the navigation rail
/// (and its logout button) is hidden there.
class _IdentityBar extends StatelessWidget {
  const _IdentityBar({required this.session, required this.onLogout});

  final Session session;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final identity = ImigongoIdentity.forAccount(session.accountId);
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          ImigongoIdentityBadge(identity: identity, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'YOUR IMIGONGO IDENTITY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.mutedBrown,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.username} · ${identity.code}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                  ),
                ),
              ],
            ),
          ),
          if (session.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.darkBrown,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.yellow,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Log out',
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 20),
            color: AppColors.darkBrown,
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
