import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/supabase_client.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/storage/hive_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive Local Cache
  await HiveStorage.init();

  // Initialize Supabase Client
  await SupabaseService.init();

  // Initialize Push Notifications
  await PushNotificationService.init();

  runApp(const ProviderScope(child: HepsiRadyoApp()));
}

class HepsiRadyoApp extends StatelessWidget {
  const HepsiRadyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModeStr = HiveStorage.getThemeMode();

    ThemeMode mode;
    if (themeModeStr == 'dark') {
      mode = ThemeMode.dark;
    } else if (themeModeStr == 'light') {
      mode = ThemeMode.light;
    } else {
      mode = ThemeMode.system;
    }

    return MaterialApp(
      title: 'HepsiRadyo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      home: const SplashScreen(),
    );
  }
}
