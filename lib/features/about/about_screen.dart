import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/portal_widgets.dart';

/// About Us page — port of AboutUsPanel.java.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PortalCard(
      radius: 22,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PortalHeading('About Us', size: 24),
                SizedBox(height: 4),
                ImigongoBand(height: 14),
                SizedBox(height: 20),
                Text(
                  'Code Hills 1001 is a catalog of Rwandan natural-resource '
                  'business plans. We turn local resources — umuravumba, '
                  'umwenya (bamboo), sisal, coffee, tea, pyrethrum and more — '
                  'into ready-to-use ventures with downloadable plans for '
                  'entrepreneurs and partners.',
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
                SizedBox(height: 16),
                Text(
                  'Each plan includes the concept, the resource it uses, '
                  'an investment range, and the city of operation, so you can '
                  'start a business that grows from the land around you.',
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
                SizedBox(height: 26),
                PortalCard(
                  radius: 16,
                  background: AppColors.white,
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Column(
                      children: [
                        PortalHeading('Our Vision',
                            size: 16, color: AppColors.gold),
                        SizedBox(height: 8),
                        Text(
                          'A generation of young Rwandan entrepreneurs building '
                          'value chains from the resources in their own hills.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
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
