import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/widgets/glass_container.dart';
import 'category_detail_screen.dart';

class CategoriesScreen extends StatelessWidget {
  final ScrollController? scrollController;
  const CategoriesScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final categories = [
      CategoryModel(id: '1', name: 'Haber & Konuşma', icon: 'newspaper', color: '#1E3A8A', radioCount: 18),
      CategoryModel(id: '2', name: 'Pop Müzik', icon: 'music_note', color: '#9333EA', radioCount: 45),
      CategoryModel(id: '3', name: 'Arabesk & Fantazi', icon: 'favorite', color: '#DC2626', radioCount: 32),
      CategoryModel(id: '4', name: 'Halk Müziği & Türkü', icon: 'landscape', color: '#D97706', radioCount: 28),
      CategoryModel(id: '5', name: 'Nostalji & 90\'lar', icon: 'radio', color: '#059669', radioCount: 20),
      CategoryModel(id: '6', name: 'Dini & İlahi', icon: 'mosque', color: '#0D9488', radioCount: 15),
      CategoryModel(id: '7', name: 'Spor', icon: 'sports_soccer', color: '#2563EB', radioCount: 12),
      CategoryModel(id: '8', name: 'Yabancı & Pop', icon: 'public', color: '#7C3AED', radioCount: 38),
      CategoryModel(id: '9', name: 'Caz & Klasik', icon: 'piano', color: '#4B5563', radioCount: 14),
      CategoryModel(id: '10', name: 'Yerel Radyolar', icon: 'location_on', color: '#0B3D2E', radioCount: 65),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategoriler & Türler', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: GridView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(AppTokens.padMd, AppTokens.padMd, AppTokens.padMd, 170),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final colorVal = Color(int.parse(cat.color.replaceAll('#', '0xFF')));

          return GlassContainer(
            padding: const EdgeInsets.all(AppTokens.padMd),
            borderRadius: AppTokens.radiusLg,
            color: colorVal.withOpacity(0.2),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryDetailScreen(categoryName: cat.name),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorVal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.radio_rounded, color: Colors.white, size: 22),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cat.radioCount} Radyo',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
