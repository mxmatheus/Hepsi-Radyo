import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/supabase_client.dart';
import 'core/services/push_notification_service.dart';
import 'core/storage/hive_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
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

class HepsiRadyoApp extends ConsumerWidget {
  const HepsiRadyoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeProvider);

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
