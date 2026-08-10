import 'package:flutter/material.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/models/radio_model.dart';
import '../../../shared/widgets/radio_card.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;

  const CategoryDetailScreen({super.key, required this.categoryName});

  List<RadioModel> _getCategoryRadios() {
    final allRadios = HiveStorage.getCachedRadios();
    return allRadios.where((r) {
      if (categoryName == 'Yerel Radyolar') {
        return r.city != null && r.city != 'Genel' && r.city != 'İstanbul' && r.city != 'Ankara';
      }
      return r.tags.any((t) => t.toLowerCase().contains(categoryName.toLowerCase().split(' ').first));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final radios = _getCategoryRadios();

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
