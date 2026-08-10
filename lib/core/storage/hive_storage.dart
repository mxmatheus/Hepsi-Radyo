import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/radio_model.dart';

class HiveStorage {
  static const String boxFavorites = 'favorites_box';
  static const String boxRecent = 'recently_played_box';
  static const String boxSettings = 'settings_box';
  static const String boxRadioCache = 'radio_cache_box';
  static const String boxBadges = 'badges_box';
  static const String boxClickStats = 'click_stats_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxFavorites);
    await Hive.openBox(boxRecent);
    await Hive.openBox(boxSettings);
    await Hive.openBox(boxRadioCache);
    await Hive.openBox(boxBadges);
    await Hive.openBox(boxClickStats);

    // Sync default radio list if cache is empty or has old duplicate count (811)
    if (Hive.isBoxOpen(boxRadioCache)) {
      final cacheBox = Hive.box(boxRadioCache);
      if (cacheBox.isEmpty || cacheBox.length != 659) {
        await loadDefaultAssetRadios();
      }
    }
  }

  static Future<void> loadDefaultAssetRadios() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/default_radios.json');
      final List<dynamic> list = json.decode(jsonString);
      if (Hive.isBoxOpen(boxRadioCache)) {
        final cacheBox = Hive.box(boxRadioCache);
        await cacheBox.clear(); // Clear old 811 cache
        for (var item in list) {
          final radio = RadioModel.fromJson(item);
          await cacheBox.put(radio.id, radio.toJson());
        }
      }
    } catch (_) {}
  }

  // Radios Cache
  static List<RadioModel> getCachedRadios() {
    if (!Hive.isBoxOpen(boxRadioCache)) return [];
    final box = Hive.box(boxRadioCache);
    final List<RadioModel> list = [];
    for (var key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        list.add(RadioModel.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    return list;
  }

  static Future<void> cacheRadios(List<RadioModel> radios) async {
    if (!Hive.isBoxOpen(boxRadioCache)) return;
    final box = Hive.box(boxRadioCache);
    await box.clear();
    for (var r in radios) {
      await box.put(r.id, r.toJson());
    }
  }

  // Favorites
  static List<String> getFavoriteIds() {
    if (!Hive.isBoxOpen(boxFavorites)) return [];
    final box = Hive.box(boxFavorites);
    return box.keys.map((e) => e.toString()).toList();
  }

  static Future<void> toggleFavorite(String radioId) async {
    if (!Hive.isBoxOpen(boxFavorites)) return;
    final box = Hive.box(boxFavorites);
    if (box.containsKey(radioId)) {
      await box.delete(radioId);
    } else {
      await box.put(radioId, DateTime.now().toIso8601String());
    }
  }

  static bool isFavorite(String radioId) {
    if (!Hive.isBoxOpen(boxFavorites)) return false;
    return Hive.box(boxFavorites).containsKey(radioId);
  }

  // Recently Played
  static List<RadioModel> getRecentlyPlayed() {
    if (!Hive.isBoxOpen(boxRecent)) return [];
    final box = Hive.box(boxRecent);
    final List<RadioModel> list = [];
    for (var key in box.keys.toList().reversed) {
      final data = box.get(key);
      if (data != null) {
        list.add(RadioModel.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    return list;
  }

  static Future<void> addRecentlyPlayed(RadioModel radio) async {
    if (!Hive.isBoxOpen(boxRecent)) return;
    final box = Hive.box(boxRecent);
    await box.delete(radio.id);
    await box.put(radio.id, radio.toJson());
    if (box.length > 20) {
      await box.delete(box.keys.first);
    }
  }

  // Click Count Tracker for Top 50
  static Future<void> incrementClickCount(String radioId) async {
    if (!Hive.isBoxOpen(boxClickStats)) return;
    final box = Hive.box(boxClickStats);
    final current = box.get(radioId, defaultValue: 0) as int;
    await box.put(radioId, current + 1);
  }

  static int getClickCount(String radioId) {
    if (!Hive.isBoxOpen(boxClickStats)) return 0;
    return Hive.box(boxClickStats).get(radioId, defaultValue: 0) as int;
  }

  static List<RadioModel> getTopRadios() {
    final radios = getCachedRadios();
    radios.sort((a, b) {
      final countA = getClickCount(a.id);
      final countB = getClickCount(b.id);
      if (countA != countB) {
        return countB.compareTo(countA);
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return radios.take(50).toList();
  }

  // Settings
  static String getThemeMode() {
    if (!Hive.isBoxOpen(boxSettings)) return 'system';
    return Hive.box(boxSettings).get('theme_mode', defaultValue: 'system');
  }

  static Future<void> setThemeMode(String mode) async {
    if (!Hive.isBoxOpen(boxSettings)) return;
    await Hive.box(boxSettings).put('theme_mode', mode);
  }

  static int getSleepTimerDefault() {
    if (!Hive.isBoxOpen(boxSettings)) return 30;
    return Hive.box(boxSettings).get('sleep_timer_default', defaultValue: 30);
  }

  static Future<void> setSleepTimerDefault(int minutes) async {
    if (!Hive.isBoxOpen(boxSettings)) return;
    await Hive.box(boxSettings).put('sleep_timer_default', minutes);
  }

  // Gamification Metrics
  static int getListenMinutes() {
    if (!Hive.isBoxOpen(boxBadges)) return 0;
    return Hive.box(boxBadges).get('listen_minutes', defaultValue: 0);
  }

  static Future<void> addListenMinutes(int minutes) async {
    if (!Hive.isBoxOpen(boxBadges)) return;
    final current = getListenMinutes();
    await Hive.box(boxBadges).put('listen_minutes', current + minutes);
  }

  static List<String> getUnlockedBadges() {
    if (!Hive.isBoxOpen(boxBadges)) return [];
    final List<dynamic> list = Hive.box(boxBadges).get('unlocked_badges', defaultValue: []);
    return list.map((e) => e.toString()).toList();
  }

  static Future<void> unlockBadge(String badgeId) async {
    if (!Hive.isBoxOpen(boxBadges)) return;
    final current = getUnlockedBadges();
    if (!current.contains(badgeId)) {
      current.add(badgeId);
      await Hive.box(boxBadges).put('unlocked_badges', current);
    }
  }
}
