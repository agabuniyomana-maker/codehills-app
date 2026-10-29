import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:code_hills_app/app_features.dart';
import 'package:code_hills_app/features/home/home_shell.dart';
import 'package:code_hills_app/services/auth_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Signed out so the admin feature shows its login gate (its probe state).
    await AuthService.instance.logout();
  });

  testWidgets('every registered feature opens from navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);

    for (final feature in appFeatures) {
      await tester.tap(find.byIcon(feature.icon));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(feature.probeText),
        findsWidgets,
        reason:
            'Feature "${feature.id}" did not show its probe text '
            '"${feature.probeText}". If the screen text changed on purpose, '
            'update probeText in lib/app_features.dart.',
      );
    }
  });

  testWidgets('registry entries are unique and phone-safe', (_) async {
    final ids = appFeatures.map((f) => f.id).toSet();
    final icons = appFeatures.map((f) => f.icon).toSet();

    expect(ids.length, appFeatures.length,
        reason: 'feature ids must be unique (they name the folders)');
    expect(icons.length, appFeatures.length,
        reason: 'icons must be unique — the feature test taps by icon');
    expect(appFeatures.length, greaterThanOrEqualTo(5),
        reason: 'the phone bottom bar shows the first five features');
    for (final f in appFeatures) {
      expect(f.phoneLabel.split(' ').length, 1,
          reason: 'bottom-bar label for "${f.id}" should be one word');
    }
  });
}
