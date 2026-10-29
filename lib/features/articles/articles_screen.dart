import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/portal_widgets.dart';

/// Product Articles portal — port of ProductArticlesPanel.java.
class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  static const _articles = [
    (
      title: 'From Umuravumba to shelf: grain storage that lasts',
      summary: 'How Kirinda Grain Guard turns a local clay tradition into '
          'affordable post-harvest protection for smallholder farmers.',
      body: 'Smallholder farmers lose a large share of harvested grain to '
          'pests and damp. Umuravumba is a plant already trusted in many '
          'households for protecting stored grain. Kirinda Grain Guard '
          'packages it into a low-cost product sold in small sachets, so '
          'farmers can protect a harvest without expensive chemicals. '
          'Start-up cost is below 500,000 RWF.',
    ),
    (
      title: 'Sisal beyond rope: composite panels and agri inputs',
      summary: 'Terra Twine and Fibra Panel show how one plant can feed two '
          'very different markets.',
      body: 'Sisal fibre can become twine for farms (Terra Twine) or the '
          'reinforcement in lightweight composite panels for building '
          '(Fibra Panel). The same raw material serves a low-cost '
          'agricultural market and a higher-value construction market, '
          'letting a grower choose the venture that fits their budget.',
    ),
    (
      title: 'Cascara: the coffee byproduct nobody sells yet',
      summary: 'Cascara Circle is turning coffee cherry skins into tea-grade '
          'exports and new income for washing stations.',
      body: 'Washing stations produce large piles of coffee cherry skins '
          'that are usually thrown away. Dried and sorted, they become '
          'cascara, a tea-style drink with growing export demand. '
          'Cascara Circle collects the skins, dries them and sells them '
          'in bulk, giving stations extra income from waste.',
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
                const PortalHeading('Product Articles', size: 24),
                const SizedBox(height: 4),
                const ImigongoBand(height: 14),
                const SizedBox(height: 18),
                for (final article in _articles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: PortalCard(
                      radius: 16,
                      background: AppColors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              article.summary,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: AppColors.mutedBrown,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              article.body,
                              style: const TextStyle(fontSize: 14, height: 1.5),
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
