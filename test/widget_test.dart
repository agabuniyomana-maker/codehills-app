import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:code_hills_app/features/auth/login_screen.dart';
import 'package:code_hills_app/widgets/portal_widgets.dart';

void main() {
  testWidgets('login portal renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );
    expect(find.byType(PortalCard), findsWidgets);
    expect(find.text('LOGIN PORTAL'), findsOneWidget);
    expect(find.text('ENTER PORTAL'), findsOneWidget);
  });
}
