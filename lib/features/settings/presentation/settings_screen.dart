import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../admin/presentation/admin_login_screen.dart';
import '../../badges/presentation/badges_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  const SettingsScreen({super.key, this.scrollController});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late String currentTheme;
  late int sleepTimerDefault;

  @override
  void initState() {
    super.initState();
    currentTheme = HiveStorage.getThemeMode();
    sleepTimerDefault = HiveStorage.getSleepTimerDefault();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar & Tercihler', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(AppTokens.padMd, AppTokens.padMd, AppTokens.padMd, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gamification Banner Tile
            GlassContainer(
              padding: const EdgeInsets.all(AppTokens.padMd),
              color: AppColors.wineRedAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BadgesScreen()),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: AppColors.goldHighlight, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rozetler ve Başarımlar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Dinleme istatistiklerinizi ve kazandığınız rozetleri görün',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Görünüm & Ses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Theme Setting
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_outlined, color: AppColors.racingGreenPrimary),
                      SizedBox(width: 12),
                      Text('Uygulama Teması', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  DropdownButton<String>(
                    value: currentTheme,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('Sistem Teması')),
                      DropdownMenuItem(value: 'dark', child: Text('Koyu Mod')),
                      DropdownMenuItem(value: 'light', child: Text('Açık Mod')),
                    ],
                    onChanged: (val) async {
                      if (val != null) {
                        await HiveStorage.setThemeMode(val);
                        setState(() {
                          currentTheme = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Sleep Timer Default
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bedtime_outlined, color: AppColors.wineRedAccent),
                      SizedBox(width: 12),
                      Text('Varsayılan Uyku Süresi', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  DropdownButton<int>(
                    value: sleepTimerDefault,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15 dakika')),
                      DropdownMenuItem(value: 30, child: Text('30 dakika')),
                      DropdownMenuItem(value: 45, child: Text('45 dakika')),
                      DropdownMenuItem(value: 60, child: Text('60 dakika')),
                    ],
                    onChanged: (val) async {
                      if (val != null) {
                        await HiveStorage.setSleepTimerDefault(val);
                        setState(() {
                          sleepTimerDefault = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Yönetim & Sistem',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Admin Panel Entry Point
            GlassContainer(
              padding: const EdgeInsets.all(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: AppColors.racingGreenPrimary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Yönetici Paneli (Admin Mode)', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // App Version Info
            const Center(
              child: Column(
                children: [
                  Text(
                    'HepsiRadyo v1.0.0',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Radio-Browser & Supabase Altyapısı ile Güçlendirilmiştir.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
