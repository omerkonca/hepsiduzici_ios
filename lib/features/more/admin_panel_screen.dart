import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../app/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/premium_city_theme.dart';

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final _tokenController = TextEditingController();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _statusMessage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkSavedToken();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('hd_admin_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      _tokenController.text = savedToken;
      _verifyToken(savedToken, isAutoLogin: true);
    }
  }

  Future<void> _verifyToken(String token, {bool isAutoLogin = false}) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Doğrulanıyor...';
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '${AppConfig.backendBaseUrl}/api/admin/check',
        options: Options(
          headers: {'x-admin-token': token},
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('hd_admin_token', token);
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
          _statusMessage = null;
        });
        if (!isAutoLogin && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yayıncı girişi başarılı!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
          _statusMessage = 'Geçersiz admin şifresi!';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Bağlantı hatası: ${e.toString()}';
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hd_admin_token');
    _tokenController.clear();
    setState(() {
      _isAuthenticated = false;
      _statusMessage = null;
    });
  }

  Future<void> _pickAndUploadImage(String fieldName) async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
        _statusMessage = 'Görsel sunucuya yükleniyor...';
      });

      // 1. Upload the image to /api/upload
      final dio = ref.read(dioProvider);
      final file = File(image.path);
      final filename = file.path.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: filename,
        ),
      });

      final uploadResponse = await dio.post(
        '${AppConfig.backendBaseUrl}/api/upload',
        data: formData,
        options: Options(
          headers: {'x-admin-token': token},
        ),
      );

      if (uploadResponse.statusCode != 200 || uploadResponse.data['ok'] != true) {
        throw Exception(uploadResponse.data['message'] ?? 'Yükleme başarısız.');
      }

      final uploadedUrl = uploadResponse.data['fileUrl'] as String;
      final fullUrl = uploadedUrl.startsWith('http')
          ? uploadedUrl
          : '${AppConfig.backendBaseUrl}$uploadedUrl';

      setState(() {
        _statusMessage = 'Uygulama görsel ayarları güncelleniyor...';
      });

      // 2. Update the background image in city content branding
      final updateResponse = await dio.post(
        '${AppConfig.backendBaseUrl}/api/city-content/update-branding',
        data: {fieldName: fullUrl},
        options: Options(
          headers: {'x-admin-token': token},
        ),
      );

      if (updateResponse.statusCode != 200 || updateResponse.data['ok'] != true) {
        throw Exception(updateResponse.data['message'] ?? 'Güncelleme başarısız.');
      }

      // Refresh the city content provider to update the app immediately
      ref.invalidate(cityContentProvider);

      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görsel başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hata'),
            content: Text('Görsel güncellenirken hata oluştu: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cityContent = ref.watch(cityContentProvider).asData?.value;
    final heroCardBg = cityContent?.branding?.heroCardBg;
    final exploreHeaderBg = cityContent?.branding?.exploreHeaderBg;

    return Scaffold(
      backgroundColor: PremiumCityTheme.canvas,
      appBar: AppBar(
        title: const Text('Yayıncı Paneli'),
        backgroundColor: PremiumCityTheme.canvas,
        foregroundColor: PremiumCityTheme.ink,
        elevation: 0,
        actions: _isAuthenticated
            ? [
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Çıkış Yap',
                  onPressed: _logout,
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage ?? 'Lütfen bekleyin...',
                    style: const TextStyle(
                      color: PremiumCityTheme.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: _isAuthenticated
                  ? _buildAdminDashboard(heroCardBg, exploreHeaderBg)
                  : _buildLoginScreen(),
            ),
    );
  }

  Widget _buildLoginScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Icon(
            Icons.admin_panel_settings_rounded,
            size: 80,
            color: PremiumCityTheme.gold,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Yayıncı Girişi',
          style: TextStyle(
            color: PremiumCityTheme.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Görsel güncellemeleri ve yönetimsel işlemler için lütfen yayıncı parolanızı girin.',
          style: TextStyle(
            color: PremiumCityTheme.muted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _tokenController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Parola / Token',
            labelStyle: const TextStyle(color: PremiumCityTheme.muted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: PremiumCityTheme.gold, width: 2),
            ),
            prefixIcon: const Icon(Icons.lock_rounded, color: PremiumCityTheme.gold),
          ),
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _statusMessage!,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumCityTheme.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            onPressed: () {
              final token = _tokenController.text.trim();
              if (token.isNotEmpty) {
                _verifyToken(token);
              }
            },
            child: const Text(
              'Giriş Yap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminDashboard(String? heroBg, String? exploreBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ana Sayfa Bölümü
        _buildImageCardSection(
          title: 'Ana Sayfa Başlık Görseli',
          description: 'Ana sayfadaki başlık kartının arka plan görselidir.',
          currentUrl: heroBg,
          fieldName: 'heroCardBg',
        ),

        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 20),

        // Keşfet Bölümü
        _buildImageCardSection(
          title: 'Keşfet Ekranı Görseli',
          description: 'Keşfet ekranındaki başlık kartının arka plan görselidir.',
          currentUrl: exploreBg,
          fieldName: 'exploreHeaderBg',
        ),

        const SizedBox(height: 40),
        const Divider(),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Hepsi Düziçi Yönetim Sistemi v1.0',
            style: TextStyle(
              color: PremiumCityTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCardSection({
    required String title,
    required String description,
    required String? currentUrl,
    required String fieldName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: PremiumCityTheme.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(
            color: PremiumCityTheme.muted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPreviewImage(currentUrl),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Mevcut Arka Plan',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUrl ?? 'Varsayılan Kale Resmi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumCityTheme.gold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            onPressed: () => _pickAndUploadImage(fieldName),
            icon: const Icon(Icons.photo_library_rounded, size: 20),
            label: const Text(
              'Görsel Seç & Değiştir',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewImage(String? bg) {
    if (bg == null || bg.trim().isEmpty) {
      return Image.asset(
        'assets/images/duzici_castle_header.png',
        fit: BoxFit.cover,
      );
    }

    if (bg.startsWith('http://') || bg.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: bg,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => Image.asset(
          'assets/images/duzici_castle_header.png',
          fit: BoxFit.cover,
        ),
      );
    }

    final assetPath = bg.startsWith('asset:') ? bg.substring(6) : bg;
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
    );
  }
}
