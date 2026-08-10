import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/glass_container.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(gamificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalListenMinutes = HiveStorage.getListenMinutes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rozetler & Başarımlar', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppTokens.padMd, AppTokens.padMd, AppTokens.padMd, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Header
            GlassContainer(
              padding: const EdgeInsets.all(AppTokens.padLg),
              color: AppColors.racingGreenPrimary,
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 48, color: AppColors.goldHighlight),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam Dinleme: ${totalListenMinutes ~/ 60} saat ${totalListenMinutes % 60} dk',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kazanılan Rozet: ${badges.where((b) => b.isUnlocked).length} / ${badges.length}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Tüm Rozetler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];

                return GlassContainer(
                  padding: const EdgeInsets.all(12),
                  borderRadius: AppTokens.radiusLg,
                  color: badge.isUnlocked
                      ? (isDark ? AppColors.darkCard : AppColors.lightCard)
                      : Colors.black.withOpacity(0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badge.isUnlocked ? AppColors.wineRedAccent : Colors.grey.shade400,
                          boxShadow: badge.isUnlocked ? AppTokens.glowShadowGold : null,
                        ),
                        child: Icon(
                          badge.isUnlocked ? Icons.stars_rounded : Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        badge.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: badge.isUnlocked ? null : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badge.description,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
