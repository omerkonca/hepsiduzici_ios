import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/premium_city_theme.dart';

class AdminPushPanel extends ConsumerStatefulWidget {
  const AdminPushPanel({super.key, required this.adminToken});

  final String adminToken;

  @override
  ConsumerState<AdminPushPanel> createState() => _AdminPushPanelState();
}

class _AdminPushPanelState extends ConsumerState<AdminPushPanel> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;
  String? _status;
  int? _registeredDevices;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final count = await Supabase.instance.client.rpc('push_device_count');
      if (mounted) {
        setState(() => _registeredDevices = (count as num?)?.toInt());
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve mesaj girin.')),
      );
      return;
    }

    setState(() {
      _sending = true;
      _status = 'Gönderiliyor...';
    });

    try {
      final dio = ref.read(dioProvider);
      Response<dynamic> res;

      // Önce Supabase Edge Function (Render güncellemesi gerektirmez)
      try {
        res = await dio.post(
          '${AppConfig.supabaseUrl}/functions/v1/send-push',
          data: {'title': title, 'body': body},
          options: Options(
            headers: {
              'x-admin-token': widget.adminToken,
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
              'apikey': AppConfig.supabaseAnonKey,
            },
            validateStatus: (s) => true,
          ),
        );
        if (res.statusCode == 404 || res.statusCode == 503) {
          throw Exception('edge fallback');
        }
      } catch (_) {
        res = await dio.post(
          '${AppConfig.backendBaseUrl}/api/push/send',
          data: {'title': title, 'body': body},
          options: Options(
            headers: {'x-admin-token': widget.adminToken},
            validateStatus: (s) => true,
          ),
        );
      }

      final data = res.data;
      if (res.statusCode == 200 && data is Map && data['ok'] == true) {
        setState(() {
          _status =
              'Gönderildi: ${data['sent'] ?? 0} başarılı, ${data['failed'] ?? 0} başarısız';
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_status!)),
        );
        _titleController.clear();
        _bodyController.clear();
        await _loadStatus();
      } else {
        final msg = data is Map ? (data['message'] as String? ?? 'Gönderilemedi') : 'Gönderilemedi';
        setState(() => _status = msg);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      setState(() => _status = 'Hata: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _applyTemplate(String title, String body) {
    _titleController.text = title;
    _bodyController.text = body;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Toplu Bildirim Gönder',
          style: TextStyle(
            color: PremiumCityTheme.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _registeredDevices != null
              ? 'Kayıtlı cihaz: $_registeredDevices'
              : 'Uygulama yüklü kullanıcılara anlık push gönderin.',
          style: const TextStyle(color: PremiumCityTheme.muted, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: const Text(
            'Kurulum: Firebase dosyaları + Supabase secret\'ları gerekli. '
            'Detay: docs/PUSH_KURULUM_ADIM_ADIM.md\n'
            'Gönderim çalışmıyorsa PUSH_ADMIN_TOKEN ve '
            'FIREBASE_SERVICE_ACCOUNT_JSON secret\'larını kontrol edin.',
            style: TextStyle(fontSize: 11.5, height: 1.35, color: Color(0xFF1565C0)),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('Günaydın'),
              onPressed: () => _applyTemplate(
                'Günaydın Düziçi!',
                'Hepsi Düziçi ile güne başlayın. Bugünün haberlerine göz atın.',
              ),
            ),
            ActionChip(
              label: const Text('Yeni özellik'),
              onPressed: () => _applyTemplate(
                'Yeni özellik eklendi',
                'Uygulamayı güncelleyin ve yeni özellikleri keşfedin.',
              ),
            ),
            ActionChip(
              label: const Text('Duyuru'),
              onPressed: () => _applyTemplate(
                'Önemli duyuru',
                'Belediye ve şehir duyuruları için uygulamayı açın.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Başlık',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Mesaj',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (_status != null) ...[
          const SizedBox(height: 10),
          Text(
            _status!,
            style: TextStyle(
              color: _status!.startsWith('Gönderildi')
                  ? Colors.green.shade700
                  : PremiumCityTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumCityTheme.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_sending ? 'Gönderiliyor...' : 'Tüm kullanıcılara gönder'),
          ),
        ),
      ],
    );
  }
}
