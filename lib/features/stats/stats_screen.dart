import 'package:flutter/material.dart';

import '../../data/app_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/portal_widgets.dart';

/// Product statistics — port of ProductStatsPanel.java (JFreeChart -> Flutter).
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = AppData.instance.plans;
    final byResource = <String, int>{};
    for (final p in plans) {
      byResource[p.resourceName] = (byResource[p.resourceName] ?? 0) + 1;
    }
    final maxCount = byResource.values.fold<int>(1, (a, b) => a > b ? a : b);

    return PortalCard(
      radius: 22,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PortalHeading('Product Stats', size: 24),
                const SizedBox(height: 4),
                const ImigongoBand(height: 14),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _statCard('PLANS', '${plans.length}'),
                    const SizedBox(width: 12),
                    _statCard(
                      'PREMIUM',
                      '${plans.where((p) => p.isPremium).length}',
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      'FREE',
                      '${plans.where((p) => !p.isPremium).length}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const PortalHeading(
                  'Plans per natural resource',
                  size: 15,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 14),
                for (final entry in byResource.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key} — ${entry.value}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 700),
                          tween: Tween(
                            begin: 0,
                            end: entry.value / maxCount,
                          ),
                          builder: (context, value, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 14,
                              color: AppColors.gold,
                              backgroundColor: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) => Expanded(
        child: PortalCard(
          radius: 16,
          background: AppColors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.mutedBrown,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
