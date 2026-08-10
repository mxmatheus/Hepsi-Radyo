import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/radio_card.dart';

class FavoritesScreen extends ConsumerWidget {
  final ScrollController? scrollController;
  const FavoritesScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritesProvider);
    final allRadios = HiveStorage.getCachedRadios();
    final favRadios = allRadios.where((r) => favIds.contains(r.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favori Radyolarım', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: favRadios.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 72, color: AppColors.wineRedAccent.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz favori radyo eklemediniz',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Radyo kartlarındaki kalp ikonuna basarak favorilerinize ekleyebilirsiniz.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(AppTokens.padMd, AppTokens.padMd, AppTokens.padMd, 100),
              itemCount: favRadios.length,
              itemBuilder: (context, index) {
                return RadioCard(
                  radio: favRadios[index],
                );
              },
            ),
    );
  }
}
