import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_player_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

class SleepTimerDialog extends ConsumerWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = [15, 30, 45, 60, 90];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusLg)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.padLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime_rounded, color: AppColors.wineRedAccent, size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Uyku Zamanlayıcı',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (playerState.sleepTimerMinutesRemaining != null) ...[
              Text(
                'Kalan Süre: ${playerState.sleepTimerMinutesRemaining} dakika',
                style: const TextStyle(
                  color: AppColors.wineRedAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(playerProvider.notifier).cancelSleepTimer();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.cancel_rounded),
                label: const Text('Zamanlayıcıyı İptal Et'),
              ),
            ] else ...[
              const Text(
                'Süre dolduğunda radyo yayını otomatik olarak duracaktır.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((min) {
                  return ChoiceChip(
                    label: Text('$min dk'),
                    selected: false,
                    selectedColor: AppColors.wineRedAccent,
                    onSelected: (_) {
                      ref.read(playerProvider.notifier).startSleepTimer(min);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Uyku zamanlayıcı $min dakikaya ayarlandı.'),
                          backgroundColor: AppColors.racingGreenPrimary,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    );
  }
}
