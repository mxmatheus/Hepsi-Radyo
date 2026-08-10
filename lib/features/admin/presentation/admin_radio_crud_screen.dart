import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/models/radio_model.dart';
import '../../../shared/widgets/glass_container.dart';

class AdminRadioCrudScreen extends StatefulWidget {
  final RadioModel? radioToEdit;

  const AdminRadioCrudScreen({super.key, this.radioToEdit});

  @override
  State<AdminRadioCrudScreen> createState() => _AdminRadioCrudScreenState();
}

class _AdminRadioCrudScreenState extends State<AdminRadioCrudScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _faviconController;
  late TextEditingController _cityController;
  late TextEditingController _tagsController;
  bool _isActive = true;
  bool _isMetadataSupported = true;

  @override
  void initState() {
    super.initState();
    final r = widget.radioToEdit;
    _nameController = TextEditingController(text: r?.name ?? '');
    _urlController = TextEditingController(text: r?.streamUrl ?? '');
    _faviconController = TextEditingController(text: r?.faviconUrl ?? '');
    _cityController = TextEditingController(text: r?.city ?? 'İstanbul');
    _tagsController = TextEditingController(text: r?.tags.join(', ') ?? 'Pop');
    _isActive = r?.isActive ?? true;
    _isMetadataSupported = r?.isMetadataSupported ?? true;
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final tagsList = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final radio = RadioModel(
        id: widget.radioToEdit?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        streamUrl: _urlController.text.trim(),
        faviconUrl: _faviconController.text.trim().isNotEmpty ? _faviconController.text.trim() : null,
        city: _cityController.text.trim(),
        tags: tagsList,
        isActive: _isActive,
        isMetadataSupported: _isMetadataSupported,
        source: 'admin-manual',
      );

      final current = HiveStorage.getCachedRadios();
      final updatedList = List<RadioModel>.from(current);
      if (widget.radioToEdit != null) {
        final idx = updatedList.indexWhere((element) => element.id == radio.id);
        if (idx != -1) updatedList[idx] = radio;
      } else {
        updatedList.insert(0, radio);
      }
      await HiveStorage.cacheRadios(updatedList);

      // Sync to Supabase Database
      if (SupabaseService.isInitialized && SupabaseService.client != null) {
        try {
          await SupabaseService.client!.from('radios').upsert(radio.toJson());
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Radyo başarıyla kaydedildi!'), backgroundColor: AppColors.racingGreenPrimary),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.radioToEdit == null ? 'Yeni Radyo Ekle' : 'Radyoyu Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.padMd),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(AppTokens.padMd),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Radyo İsmi *'),
                      validator: (v) => v == null || v.isEmpty ? 'İsim zorunludur' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(labelText: 'Stream URL * (http/https)'),
                      validator: (v) => v == null || v.isEmpty ? 'Yayın adresi zorunludur' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _faviconController,
                      decoration: const InputDecoration(labelText: 'Logo URL (Opsiyonel)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Şehir (ör. İstanbul)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(labelText: 'Etiketler (Virgülle ayırın: Pop, Haber, Spor)'),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Aktif Yayın'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    SwitchListTile(
                      title: const Text('ICY Metadata Destekliyor'),
                      value: _isMetadataSupported,
                      onChanged: (v) => setState(() => _isMetadataSupported = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wineRedAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kaydet ve Yayınla', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
