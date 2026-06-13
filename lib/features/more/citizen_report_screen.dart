import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/premium_city_theme.dart';
import '../../data/services/citizen_report_service.dart';

/// Vatandaş bildirimi: sorun, öneri, tavsiye + fotoğraf.
class CitizenReportScreen extends ConsumerStatefulWidget {
  const CitizenReportScreen({super.key});

  @override
  ConsumerState<CitizenReportScreen> createState() => _CitizenReportScreenState();
}

class _CitizenReportScreenState extends ConsumerState<CitizenReportScreen> {
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _picker = ImagePicker();

  CitizenReportCategory _category = CitizenReportCategory.problem;
  final List<File> _photos = [];
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= 3) {
      _snack('En fazla 3 fotoğraf ekleyebilirsiniz.');
      return;
    }
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1920,
    );
    if (file == null || !mounted) return;
    setState(() => _photos.add(File(file.path)));
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.length < 10) {
      _snack('Lütfen en az 10 karakterlik bir açıklama yazın.');
      return;
    }

    setState(() => _sending = true);
    try {
      final service = CitizenReportService(ref.read(dioProvider));
      final result = await service.submit(
        category: _category,
        message: message,
        contactName: _nameController.text,
        contactEmail: _emailController.text,
        photos: _photos,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Teşekkürler'),
          content: Text(result),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _snack('Gönderilemedi: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumCityTheme.canvas,
      appBar: AppBar(
        title: const Text('İhbar ve Öneri'),
        backgroundColor: PremiumCityTheme.canvas,
        foregroundColor: PremiumCityTheme.ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _HeroCard(),
          const SizedBox(height: 20),
          const _SectionLabel('Bildirim Türü'),
          const SizedBox(height: 10),
          ...CitizenReportCategory.values.map(_categoryTile),
          const SizedBox(height: 20),
          const _SectionLabel('Açıklama'),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 6,
            maxLength: 2000,
            decoration: InputDecoration(
              hintText:
                  'Sorunu, önerinizi veya tavsiyenizi detaylı yazın...\n'
                  'Örn: Sokak lambası arızalı, uygulamaya X özelliği eklensin.',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Fotoğraflar (isteğe bağlı, en fazla 3)'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._photos.asMap().entries.map((e) => _PhotoThumb(
                    file: e.value,
                    onRemove: () => setState(() => _photos.removeAt(e.key)),
                  )),
              if (_photos.length < 3) _AddPhotoButton(onPick: _pickPhoto),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('İletişim (isteğe bağlı)'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: _fieldDecoration('Adınız'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _fieldDecoration('E-posta (geri dönüş için)'),
          ),
          const SizedBox(height: 8),
          Text(
            'Yanıt almak istemezseniz boş bırakabilirsiniz. '
            'Genel iletişim: ${AppConfig.contactEmail}',
            style: const TextStyle(
              color: PremiumCityTheme.muted,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _sending ? 'Gönderiliyor...' : 'Bildirimi Gönder',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: PremiumCityTheme.navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _categoryTile(CitizenReportCategory cat) {
    final selected = _category == cat;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? PremiumCityTheme.navy.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _category = cat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? PremiumCityTheme.navy
                    : PremiumCityTheme.mist,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? PremiumCityTheme.navy : PremiumCityTheme.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: selected
                              ? PremiumCityTheme.navy
                              : PremiumCityTheme.ink,
                        ),
                      ),
                      Text(
                        cat.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: PremiumCityTheme.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: PremiumCityTheme.navyGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign_rounded, color: Colors.white, size: 32),
          SizedBox(height: 12),
          Text(
            'İhbar ve Öneri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Şehirde gördüğünüz sorunları, uygulama önerilerinizi veya '
            'faydalı tavsiyelerinizi fotoğrafla birlikte paylaşın.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: PremiumCityTheme.ink,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.file, required this.onRemove});

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            file,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(28, 28),
              padding: EdgeInsets.zero,
            ),
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 16),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onPick});

  final Future<void> Function(ImageSource source) onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showSourceSheet(context),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PremiumCityTheme.mist, width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: PremiumCityTheme.navy),
            SizedBox(height: 4),
            Text(
              'Fotoğraf',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: PremiumCityTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeriden seç'),
              onTap: () {
                Navigator.pop(ctx);
                onPick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Kamera ile çek'),
              onTap: () {
                Navigator.pop(ctx);
                onPick(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}
