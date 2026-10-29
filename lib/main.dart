import 'package:flutter/material.dart';

import 'data/app_data.dart';
import 'features/home/home_shell.dart';
import 'features/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'services/backend_config.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connects Supabase when keys were passed via --dart-define;
  // no-op otherwise (fully offline mode).
  await BackendConfig.init();
  await AppData.instance.load();
  await AuthService.instance.init();
  runApp(const CodeHillsApp());
}

class CodeHillsApp extends StatelessWidget {
  const CodeHillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Hills 1001',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AuthService.instance.isSignedIn
          ? const HomeShell()
          : const LoginScreen(),
    );
  }
}
