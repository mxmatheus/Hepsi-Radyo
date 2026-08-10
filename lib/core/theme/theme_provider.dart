import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/hive_storage.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_initialThemeMode());

  static ThemeMode _initialThemeMode() {
    final str = HiveStorage.getThemeMode();
    if (str == 'light') return ThemeMode.light;
    if (str == 'system') return ThemeMode.system;
    return ThemeMode.dark;
  }

  Future<void> setThemeMode(String val) async {
    await HiveStorage.setThemeMode(val);
    if (val == 'light') {
      state = ThemeMode.light;
    } else if (val == 'system') {
      state = ThemeMode.system;
    } else {
      state = ThemeMode.dark;
    }
  }
}

final appThemeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
