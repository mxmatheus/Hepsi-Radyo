import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/models/banner_model.dart';
import '../../../shared/widgets/glass_container.dart';

class AdminBannerCrudScreen extends StatefulWidget {
  const AdminBannerCrudScreen({super.key});

  @override
  State<AdminBannerCrudScreen> createState() => _AdminBannerCrudScreenState();
}

class _AdminBannerCrudScreenState extends State<AdminBannerCrudScreen> {
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _targetValueController = TextEditingController();
  String _actionType = 'radio';

  final List<BannerModel> _bannersList = [
    BannerModel(
      id: 'b1',
      title: 'Kral FM Canlı Dinle',
      imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=800&q=80',
      actionType: 'radio',
      targetValue: 'seed-kral-fm',
    ),
    BannerModel(
      id: 'b2',
      title: '90\'lar Pop Nostalji Fırtınası',
      imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=800&q=80',
      actionType: 'category',
      targetValue: 'Nostalji & 90\'lar',
    ),
  ];

  void _addBanner() {
    if (_titleController.text.isNotEmpty && _imageUrlController.text.isNotEmpty) {
      final banner = BannerModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        imageUrl: _imageUrlController.text,
        actionType: _actionType,
        targetValue: _targetValueController.text,
      );
      setState(() {
        _bannersList.add(banner);
        _titleController.clear();
        _imageUrlController.clear();
        _targetValueController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni Banner Eklendi!'), backgroundColor: AppColors.racingGreenPrimary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banner & Sponsor Yönetimi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.padMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Banner Form
            GlassContainer(
              padding: const EdgeInsets.all(AppTokens.padMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Yeni Banner Ekle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Banner Başlığı'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(labelText: 'Görsel URL (http/https)'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _actionType,
                    decoration: const InputDecoration(labelText: 'Eylem Tipi'),
                    items: const [
                      DropdownMenuItem(value: 'radio', child: Text('Özel Radyoyu Aç')),
                      DropdownMenuItem(value: 'category', child: Text('Kategoriye Git')),
                      DropdownMenuItem(value: 'url', child: Text('Harici Web Bağlantısı')),
                    ],
                    onChanged: (v) => setState(() => _actionType = v!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _targetValueController,
                    decoration: const InputDecoration(labelText: 'Hedef Değer (Radyo ID / Kategori Adı / URL)'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addBanner,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.wineRedAccent, foregroundColor: Colors.white),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Banner Yayınla'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Aktif Bannerlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bannersList.length,
              itemBuilder: (context, index) {
                final b = _bannersList[index];
                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(b.imageUrl, width: 60, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Eylem: ${b.actionType} (${b.targetValue ?? ''})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _bannersList.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
