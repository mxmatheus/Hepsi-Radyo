import 'package:flutter/material.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/models/radio_model.dart';
import '../../../shared/widgets/glass_container.dart';
import 'category_detail_screen.dart';

class CategoryConfig {
  final String id;
  final String name;
  final IconData icon;
  final String color;
  final List<String> keywords;

  const CategoryConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.keywords,
  });
}

const List<CategoryConfig> appCategories = [
  CategoryConfig(
    id: 'pop',
    name: 'Pop Müzik',
    icon: Icons.music_note_rounded,
    color: '#9333EA',
    keywords: ['pop', 'türkçe pop', 'hit', 'yabancı pop'],
  ),
  CategoryConfig(
    id: 'arabesk',
    name: 'Arabesk & Fantazi',
    icon: Icons.favorite_rounded,
    color: '#DC2626',
    keywords: ['arabesk', 'damar', 'fantazi', 'arabic'],
  ),
  CategoryConfig(
    id: 'halk',
    name: 'Halk Müziği & Türkü',
    icon: Icons.landscape_rounded,
    color: '#D97706',
    keywords: ['halk müziği', 'thm', 'türkü', 'anadolu', 'dersim', 'özgün müzik'],
  ),
  CategoryConfig(
    id: 'nostalji',
    name: 'Nostalji & 90\'lar',
    icon: Icons.radio_rounded,
    color: '#059669',
    keywords: ['nostalji', 'retro', '90s', '80s', '70s', '90lar', '70ler', '80ler', '45\'lik', 'nostalgic'],
  ),
  CategoryConfig(
    id: 'haber',
    name: 'Haber & Konuşma',
    icon: Icons.newspaper_rounded,
    color: '#1E3A8A',
    keywords: ['haber', 'sohbet', 'haberler', 'local haber'],
  ),
  CategoryConfig(
    id: 'dini',
    name: 'İslami & Dini',
    icon: Icons.mosque_rounded,
    color: '#0D9488',
    keywords: ['islami', 'dini', 'ilahi', 'kur’an', 'kuran', 'religion', 'islam'],
  ),
  CategoryConfig(
    id: 'rock',
    name: 'Rock & Metal',
    icon: Icons.electric_bolt_rounded,
    color: '#E11D48',
    keywords: ['rock', 'anadolu rock', 'pop rock', 'metal', 'hard rock', 'heavy metal', 'alternatif rock'],
  ),
  CategoryConfig(
    id: 'elektronik',
    name: 'Elektronik & Dans',
    icon: Icons.graphic_eq_rounded,
    color: '#7C3AED',
    keywords: ['elektronik', 'dans', 'house', 'deep house', 'edm', 'trance', 'techno', 'phonk', 'lounge', 'chillout', 'club'],
  ),
  CategoryConfig(
    id: 'caz',
    name: 'Caz & Klasik',
    icon: Icons.piano_rounded,
    color: '#4B5563',
    keywords: ['caz', 'jazz', 'klasik', 'klasik müzik', 'smoothjazz', 'ambient'],
  ),
  CategoryConfig(
    id: 'spor',
    name: 'Spor & Trafik',
    icon: Icons.sports_soccer_rounded,
    color: '#2563EB',
    keywords: ['spor', 'sports', 'traffic'],
  ),
  CategoryConfig(
    id: 'cocuk',
    name: 'Çocuk & Aile',
    icon: Icons.child_care_rounded,
    color: '#F59E0B',
    keywords: ['çocuk'],
  ),
  CategoryConfig(
    id: 'yerel',
    name: 'Yerel Radyolar',
    icon: Icons.location_on_rounded,
    color: '#0B3D2E',
    keywords: [],
  ),
];

class CategoriesScreen extends StatelessWidget {
  final ScrollController? scrollController;
  const CategoriesScreen({super.key, this.scrollController});

  int _countRadiosForCategory(CategoryConfig config, List<RadioModel> allRadios) {
    if (config.id == 'yerel') {
      return allRadios.where((r) =>
        r.city != null &&
        r.city != 'Genel' &&
        r.city != 'Türkiye' &&
        r.city != 'İstanbul' &&
        r.city != 'Ankara'
      ).length;
    }
    return allRadios.where((r) {
      return r.tags.any((t) =>
        config.keywords.any((kw) => t.toLowerCase().contains(kw.toLowerCase()))
      );
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final allRadios = HiveStorage.getCachedRadios();

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
        itemCount: appCategories.length,
        itemBuilder: (context, index) {
          final cat = appCategories[index];
          final colorVal = Color(int.parse(cat.color.replaceAll('#', '0xFF')));
          final radioCount = _countRadiosForCategory(cat, allRadios);

          return GlassContainer(
            padding: const EdgeInsets.all(AppTokens.padMd),
            borderRadius: AppTokens.radiusLg,
            color: colorVal.withOpacity(0.2),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryDetailScreen(categoryConfig: cat),
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
                  child: Icon(cat.icon, color: Colors.white, size: 22),
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
                      '$radioCount Radyo',
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
