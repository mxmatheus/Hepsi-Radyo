import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/hive_storage.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super(HiveStorage.getFavoriteIds().toSet());

  Future<void> toggleFavorite(String radioId) async {
    await HiveStorage.toggleFavorite(radioId);
    state = HiveStorage.getFavoriteIds().toSet();
  }

  bool isFavorite(String radioId) {
    return state.contains(radioId);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});
