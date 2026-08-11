import 'package:flutter/material.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/models/radio_model.dart';
import '../../../shared/widgets/radio_card.dart';
import 'categories_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final CategoryConfig? categoryConfig;
  final String? categoryName;

  const CategoryDetailScreen({
    super.key,
    this.categoryConfig,
    this.categoryName,
  });

  List<RadioModel> _getCategoryRadios() {
    final allRadios = HiveStorage.getCachedRadios();
    final name = categoryConfig?.name ?? categoryName ?? '';

    if (categoryConfig != null) {
      if (categoryConfig!.id == 'yerel') {
        return allRadios.where((r) =>
          r.city != null &&
          r.city != 'Genel' &&
          r.city != 'Türkiye' &&
          r.city != 'İstanbul' &&
          r.city != 'Ankara'
        ).toList();
      }
      return allRadios.where((r) {
        return r.tags.any((t) =>
          categoryConfig!.keywords.any((kw) => t.toLowerCase().contains(kw.toLowerCase()))
        );
      }).toList();
    }

    return allRadios.where((r) {
      if (name == 'Yerel Radyolar') {
        return r.city != null && r.city != 'Genel' && r.city != 'Türkiye' && r.city != 'İstanbul' && r.city != 'Ankara';
      }
      return r.tags.any((t) => t.toLowerCase().contains(name.toLowerCase().split(' ').first));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final radios = _getCategoryRadios();
    final title = categoryConfig?.name ?? categoryName ?? 'Kategori';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: radios.isEmpty
          ? const Center(child: Text('Bu kategoride radyo bulunamadı.'))
          : ListView.builder(
              padding: const EdgeInsets.all(AppTokens.padMd),
              itemCount: radios.length,
              itemBuilder: (context, index) {
                return RadioCard(radio: radios[index]);
              },
            ),
    );
  }
}
