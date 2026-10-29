import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/portal_widgets.dart';

/// Water Products portal — port of WaterProductsPanel.java.
class WaterProductsScreen extends StatelessWidget {
  const WaterProductsScreen({super.key});

  static const _ventures = [
    (
      icon: Icons.water_drop,
      title: 'Packaged spring water',
      summary: 'Source, filter and bottle safe drinking water for local '
          'shops, schools and events.',
      steps: [
        'Secure a protected spring and a water-quality test (RSB standards).',
        'Start with a small filtration and bottling line.',
        'Sell first to nearby shops, then to offices and events.',
      ],
      investment: '2,000,000 – 5,000,000 RWF',
    ),
    (
      icon: Icons.grass,
      title: 'Irrigation services',
      summary: 'Rent out drip and pump irrigation to smallholder farmers '
          'so they can grow through the dry season.',
      steps: [
        'Buy a pump and drip-kit sets that can move between farms.',
        'Sign seasonal contracts with farmer cooperatives.',
        'Add maintenance plans for a steady monthly income.',
      ],
      investment: 'Below 500,000 – 2,000,000 RWF',
    ),
    (
      icon: Icons.set_meal_outlined,
      title: 'Small-scale aquaculture',
      summary: 'Raise tilapia in ponds or tanks and supply local markets '
          'and restaurants with fresh fish.',
      steps: [
        'Build one or two ponds near a reliable water source.',
        'Buy certified fingerlings and a starter feed supply.',
        'Harvest in 6–8 months and sell fresh or smoked.',
      ],
      investment: '500,000 – 5,000,000 RWF',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                const PortalHeading('Water Products', size: 24),
                const SizedBox(height: 4),
                const ImigongoBand(height: 14),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/resource_water.jpg',
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: AppColors.gold,
                      child: const Icon(
                        Icons.water_drop,
                        size: 64,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Water-based value chains: packaging spring water, '
                  'irrigation services and aquaculture ventures. '
                  'Tap a venture to see how to start.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 18),
                for (final v in _ventures)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PortalCard(
                      radius: 16,
                      background: AppColors.white,
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: Icon(v.icon, color: AppColors.gold),
                          title: Text(
                            v.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(v.summary),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          expandedCrossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < v.steps.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text('${i + 1}. ${v.steps[i]}',
                                    style: const TextStyle(
                                        fontSize: 14, height: 1.4)),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              'Typical investment: ${v.investment}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mutedBrown,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
