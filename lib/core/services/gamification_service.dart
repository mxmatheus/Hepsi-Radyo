import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/badge_model.dart';
import '../storage/hive_storage.dart';

final defaultBadgesList = [
  BadgeModel(
    id: 'first_listen',
    title: 'İlk Frekans',
    description: 'İlk radyo yayınını dinledin!',
    icon: 'play_arrow',
    requiredMetric: 'radio_count',
    requiredValue: 1,
  ),
  BadgeModel(
    id: 'explorer_5',
    title: 'Radyo Kaşifi',
    description: '5 farklı radyo frekansı keşfettin.',
    icon: 'explore',
    requiredMetric: 'radio_count',
    requiredValue: 5,
  ),
  BadgeModel(
    id: 'explorer_20',
    title: 'Frekans Avcısı',
    description: '20 farklı radyo dinledin.',
    icon: 'auto_awesome',
    requiredMetric: 'radio_count',
    requiredValue: 20,
  ),
  BadgeModel(
    id: 'music_lover_1h',
    title: 'Müzik Sever',
    description: 'Toplam 1 saat radyo dinledin.',
    icon: 'headset',
    requiredMetric: 'listen_minutes',
    requiredValue: 60,
  ),
  BadgeModel(
    id: 'music_lover_10h',
    title: 'Frekans Tutkunu',
    description: 'Toplam 10 saat radyo dinledin.',
    icon: 'workspace_premium',
    requiredMetric: 'listen_minutes',
    requiredValue: 600,
  ),
];

class GamificationNotifier extends StateNotifier<List<BadgeModel>> {
  GamificationNotifier() : super([]) {
    loadBadges();
  }

  void loadBadges() {
    final unlockedIds = HiveStorage.getUnlockedBadges();
    state = defaultBadgesList.map((b) {
      return b.copyWith(isUnlocked: unlockedIds.contains(b.id));
    }).toList();
  }

  Future<void> checkRadioListenCount(int uniqueRadiosCount) async {
    for (var b in state) {
      if (!b.isUnlocked && b.requiredMetric == 'radio_count' && uniqueRadiosCount >= b.requiredValue) {
        await HiveStorage.unlockBadge(b.id);
      }
    }
    loadBadges();
  }

  Future<void> addListenMinutes(int minutes) async {
    await HiveStorage.addListenMinutes(minutes);
    final totalMin = HiveStorage.getListenMinutes();

    for (var b in state) {
      if (!b.isUnlocked && b.requiredMetric == 'listen_minutes' && totalMin >= b.requiredValue) {
        await HiveStorage.unlockBadge(b.id);
      }
    }
    loadBadges();
  }
}

final gamificationProvider = StateNotifierProvider<GamificationNotifier, List<BadgeModel>>((ref) {
  return GamificationNotifier();
});
