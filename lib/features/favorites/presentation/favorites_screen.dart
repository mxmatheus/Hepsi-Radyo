import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/models/radio_model.dart';
import '../../../shared/widgets/radio_card.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  const FavoritesScreen({super.key, this.scrollController});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<RadioModel> favRadios = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    final favIds = HiveStorage.getFavoriteIds();
    final allRadios = HiveStorage.getCachedRadios();
    setState(() {
      favRadios = allRadios.where((r) => favIds.contains(r.id)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(AppTokens.padMd, AppTokens.padMd, AppTokens.padMd, 100),
              itemCount: favRadios.length,
              itemBuilder: (context, index) {
                return RadioCard(
                  radio: favRadios[index],
                  onTap: _loadFavorites,
                );
              },
            ),
    );
  }
}
