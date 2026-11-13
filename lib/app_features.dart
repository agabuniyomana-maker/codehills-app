import 'package:flutter/material.dart';

import 'features/about/about_screen.dart';
import 'features/admin/admin_screen.dart';
import 'features/articles/articles_screen.dart';
import 'features/catalog/catalog_screen.dart';
import 'features/contact/contact_screen.dart';
import 'features/marketplace/marketplace_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/water_products/water_products_screen.dart';

/// One navigable feature of the app.
///
/// Adding a feature = create `lib/features/<id>/<id>_screen.dart`,
/// then append one [AppFeature] to [appFeatures] below. Navigation
/// (desktop rail + phone bottom bar) and the automatic feature test
/// pick the new entry up with no other changes — see AGENTS.md.
class AppFeature {
  /// Stable identifier, also the folder name under `lib/features/`.
  final String id;

  /// Full navigation label (shown uppercase in the desktop rail).
  final String label;

  /// Short label for the phone bottom bar (one word reads best).
  final String phoneLabel;

  /// Unique icon — must differ from every other feature's icon,
  /// because the feature test taps icons to switch screens.
  final IconData icon;

  /// Builds the screen. Screens must be self-contained widgets.
  final WidgetBuilder builder;

  /// A text substring that always appears on the screen when it is
  /// open. The registry test asserts it to prove the feature works.
  final String probeText;

  const AppFeature({
    required this.id,
    required this.label,
    required this.phoneLabel,
    required this.icon,
    required this.builder,
    required this.probeText,
  });
}

/// Order matters: the first five also appear in the phone bottom bar.
final List<AppFeature> appFeatures = [
  AppFeature(
    id: 'about',
    label: 'ABOUT US',
    phoneLabel: 'ABOUT',
    icon: Icons.info_outline,
    builder: (_) => const AboutScreen(),
    probeText: 'ready-to-use ventures',
  ),
  AppFeature(
    id: 'marketplace',
    label: 'MARKETPLACE',
    phoneLabel: 'SHOP',
    icon: Icons.storefront_outlined,
    builder: (_) => const MarketplaceScreen(),
    probeText: 'MARKETPLACE',
  ),
  AppFeature(
    id: 'catalog',
    label: 'NATURAL RESOURCES',
    phoneLabel: 'PLANS',
    icon: Icons.park_outlined,
    builder: (_) => const CatalogScreen(),
    probeText: 'RWANDAN LOCAL VENTURES',
  ),
  AppFeature(
    id: 'water_products',
    label: 'WATER PRODUCTS',
    phoneLabel: 'WATER',
    icon: Icons.water_drop_outlined,
    builder: (_) => const WaterProductsScreen(),
    probeText: 'Water-based value chains',
  ),
  AppFeature(
    id: 'stats',
    label: 'PRODUCT STATS',
    phoneLabel: 'STATS',
    icon: Icons.bar_chart,
    builder: (_) => const StatsScreen(),
    probeText: 'PLANS PER NATURAL RESOURCE',
  ),
  AppFeature(
    id: 'articles',
    label: 'PRODUCT ARTICLES',
    phoneLabel: 'ARTICLES',
    icon: Icons.article_outlined,
    builder: (_) => const ArticlesScreen(),
    probeText: 'Cascara: the coffee byproduct',
  ),
  AppFeature(
    id: 'contact',
    label: 'CONTACT US',
    phoneLabel: 'CONTACT',
    icon: Icons.mail_outline,
    builder: (_) => const ContactScreen(),
    probeText: 'YOUR INQUIRY',
  ),
  AppFeature(
    id: 'admin',
    label: 'ADMIN PORTAL',
    phoneLabel: 'ADMIN',
    icon: Icons.admin_panel_settings_outlined,
    builder: (_) => const AdminScreen(),
    probeText: 'ADMIN LOGIN',
  ),
];

/// Index of the feature the app opens on (the catalog, like the old portal).
/// Keep this in step with the list above: 'catalog' is index 2.
const int initialFeatureIndex = 2;
