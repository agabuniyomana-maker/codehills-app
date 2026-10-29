import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:code_hills_app/data/app_data.dart';
import 'package:code_hills_app/features/home/home_shell.dart';
import 'package:code_hills_app/features/auth/login_screen.dart';
import 'package:code_hills_app/features/plan_detail/plan_detail_screen.dart';
import 'package:code_hills_app/features/auth/signup_screen.dart';
import 'package:code_hills_app/services/auth_service.dart';
import 'package:code_hills_app/services/backend_config.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppData.instance.load();
  });

  testWidgets('seed data loaded: 7 plans, 6 resources', (tester) async {
    expect(AppData.instance.plans.length, 7);
    expect(AppData.instance.resources.length, 6);
  });

  testWidgets('register a new account and land in the catalog',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'testuser');
    await tester.enterText(fields.at(1), 'secret123');
    await tester.enterText(fields.at(2), 'secret123');
    await tester.tap(find.text('SIGN UP'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    // Catalog shows the real seeded plans (first card is on screen).
    expect(find.text('Kirinda Grain Guard'), findsOneWidget);
    expect(AuthService.instance.session?.username, 'testuser');
  });

  testWidgets('search filter narrows the catalog', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();

    expect(find.text('Kirinda Grain Guard'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'bwiza');
    await tester.pumpAndSettle();

    expect(find.text('Bwiza Jewels'), findsOneWidget);
    expect(find.text('Kirinda Grain Guard'), findsNothing);
  });

  testWidgets('open a plan and post a comment', (tester) async {
    // Sign in explicitly so this test is independent of the ones before it.
    final loginError =
        await AuthService.instance.login('admin', 'codehills1001');
    expect(loginError, isNull);

    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kirinda Grain Guard'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailScreen), findsOneWidget);
    expect(find.text('DOWNLOAD BUSINESS PLAN (PDF)'), findsOneWidget);
    expect(find.text('REQUEST PARTNERSHIP'), findsOneWidget);

    // The comment composer is the last text field (pushed route on top).
    // It lives below the fold in the 800x600 test viewport — scroll to it.
    final composer = find.byType(TextField).last;
    await tester.ensureVisible(composer);
    await tester.pumpAndSettle();
    await tester.enterText(composer, 'Beautiful venture!');
    await tester.ensureVisible(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Beautiful venture!'), findsOneWidget);
    final planId = AppData.instance.plans
        .firstWhere((p) => p.planName == 'Kirinda Grain Guard')
        .planId;
    expect(AppData.instance.commentsFor(planId), isNotEmpty);
  });

  testWidgets('admin login opens the admin portal', (tester) async {
    // Wide surface so the navigation rail (with the admin entry) shows.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await AuthService.instance.logout();
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'admin');
    await tester.enterText(fields.at(1), 'codehills1001');
    await tester.tap(find.text('ENTER PORTAL'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeShell), findsOneWidget);
    expect(AuthService.instance.session?.isAdmin, isTrue);

    await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('SIGNED IN AS ADMIN'), findsOneWidget);
    expect(find.text('CONTACT INQUIRIES'), findsOneWidget);
    expect(find.text('BUSINESS PLANS'), findsOneWidget);
  });

  testWidgets('partner request is recorded from the plan detail screen',
      (tester) async {
    final loginError =
        await AuthService.instance.login('admin', 'codehills1001');
    expect(loginError, isNull);

    await tester.pumpWidget(const MaterialApp(home: HomeShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kirinda Grain Guard'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailScreen), findsOneWidget);

    await tester.tap(find.text('REQUEST PARTNERSHIP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEND REQUEST'));
    await tester.pumpAndSettle();

    final request = AppData.instance.partnerRequests
        .where((r) => r['plan_name'] == 'Kirinda Grain Guard')
        .toList();
    expect(request, isNotEmpty);
    expect(request.last['username'], 'admin');
  });

  test('tests run without a backend configured (offline mode)', () {
    expect(BackendConfig.isConfigured, isFalse);
    expect(AuthService.instance.isSupabaseMode, isFalse);
  });

  testWidgets('wrong password is rejected', (tester) async {
    await AuthService.instance.logout();
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'nobody');
    await tester.enterText(fields.at(1), 'wrongpass');
    await tester.tap(find.text('ENTER PORTAL'));
    await tester.pump();
    await tester.pump();

    expect(AuthService.instance.session, isNull);
    expect(find.byType(HomeShell), findsNothing);
  });
}
