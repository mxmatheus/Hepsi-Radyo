import 'package:flutter/material.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/glass_container.dart';
import 'admin_banner_crud_screen.dart';
import 'admin_radio_crud_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int totalRadios = 0;

  @override
  void initState() {
    super.initState();
    _refreshMetrics();
  }

  void _refreshMetrics() {
    final list = HiveStorage.getCachedRadios();
    setState(() {
      totalRadios = list.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Kontrol Paneli', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.padMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Metric Cards
            Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(AppTokens.padMd),
                    color: AppColors.racingGreenPrimary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.radio_rounded, color: Colors.white, size: 28),
                        const SizedBox(height: 10),
                        Text(
                          '$totalRadios',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                        ),
                        const Text('Toplam Radyo', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(AppTokens.padMd),
                    color: AppColors.wineRedAccent,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.view_carousel_rounded, color: Colors.white, size: 28),
                        SizedBox(height: 10),
                        Text(
                          '3',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                        ),
                        Text('Aktif Banner', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Hızlı Yönetim Eylemleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Action Tile: Add Radio
            GlassContainer(
              padding: const EdgeInsets.all(16),
              onTap: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminRadioCrudScreen()),
                );
                if (res == true) _refreshMetrics();
              },
              child: const Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: AppColors.wineRedAccent, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yeni Canlı Radyo Ekle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Yayın adresi, logosu ve etiketlerini tanımlayın', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action Tile: Banner Carousel Manager
            GlassContainer(
              padding: const EdgeInsets.all(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminBannerCrudScreen()),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.style_outlined, color: AppColors.racingGreenPrimary, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sponsor Banner Yönetimi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Ana sayfa carousel görsellerini ve bağlantıları düzenleyin', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
