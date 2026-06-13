import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';

class QiblaCompass extends StatefulWidget {
  const QiblaCompass({super.key});

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass> {
  // Varsayılan Düziçi Konumu (GPS izin verilmeme durumu için)
  static const double defaultLat = 37.2396;
  static const double defaultLng = 36.4544;
  
  double _currentLat = defaultLat;
  double _currentLng = defaultLng;
  bool _isUsingGPS = false;
  double _distanceToMakkah = 0.0;
  double _qiblaBearing = 0.0;
  
  StreamSubscription? _compassSubscription;
  double _lastAngle = 0.0;
  double _currentHeading = 0.0;
  bool _hasSensors = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  // Kıble Açısı ve Mesafe Hesaplama
  void _calculateQibla() {
    // Makkah koordinatları
    const double makkahLat = 21.4225;
    const double makkahLng = 39.8262;

    // Açı hesabı (Radyan)
    double phi1 = _currentLat * math.pi / 180.0;
    double phi2 = makkahLat * math.pi / 180.0;
    double lambda1 = _currentLng * math.pi / 180.0;
    double lambda2 = makkahLng * math.pi / 180.0;

    double y = math.sin(lambda2 - lambda1);
    double x = math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(lambda2 - lambda1);

    double bearing = math.atan2(y, x);
    _qiblaBearing = (bearing * 180.0 / math.pi + 360.0) % 360.0;

    // Mesafe hesabı (km)
    _distanceToMakkah = Geolocator.distanceBetween(
      _currentLat,
      _currentLng,
      makkahLat,
      makkahLng,
    ) / 1000.0; // metre to km
  }

  // Konum Servisi ve İzinler
  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useDefaultLocation();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useDefaultLocation();
        return;
      }

      // Güncel Konumu Al
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      if (mounted) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
          _isUsingGPS = true;
          _calculateQibla();
        });
      }
    } catch (_) {
      _useDefaultLocation();
    }
  }

  void _useDefaultLocation() {
    if (mounted) {
      setState(() {
        _currentLat = defaultLat;
        _currentLng = defaultLng;
        _isUsingGPS = false;
        _calculateQibla();
      });
    }
  }

  // Pusula Sensörü Başlatma
  void _initCompass() {
    final events = FlutterCompass.events;
    if (events == null) {
      if (mounted) {
        setState(() => _hasSensors = false);
      }
      return;
    }

    _compassSubscription = events.listen((event) {
      if (!mounted) return;
      
      final heading = event.heading;
      if (heading == null) {
        setState(() {
          _hasSensors = false;
        });
        return;
      }

      setState(() {
        _hasSensors = true;
        _currentHeading = heading;
      });
    }, onError: (err) {
      setState(() {
        _hasSensors = false;
      });
    });
  }

  // Kısa Yol Açı Yumuşatma (360 -> 0 sınırında tam dönüşü engellemek için)
  double _getSmoothAngle(double targetAngleInDegrees) {
    double targetRad = targetAngleInDegrees * math.pi / 180.0;
    double delta = targetRad - _lastAngle;
    
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    
    _lastAngle += delta;
    return _lastAngle;
  }

  @override
  Widget build(BuildContext context) {
    // Kıble ile olan açı farkı
    double diff = (_currentHeading - _qiblaBearing).abs();
    // 360 derece döngüsü için farkı normalize edelim
    if (diff > 180) {
      diff = 360 - diff;
    }
    final bool isAligned = diff < 3.0; // 3 dereceden az sapma varsa hizalanmıştır

    // Hizalandığında hafif titreşim
    if (isAligned && _hasSensors) {
      HapticFeedback.lightImpact();
    }

    final theme = Theme.of(context);
    final darkColor = theme.brightness == Brightness.dark ? AppColors.darkSurface : Colors.white;

    if (!_hasSensors) {
      return _buildNoSensorFallback();
    }

    final compassHeight = math.min(
      MediaQuery.sizeOf(context).height * 0.42,
      360.0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
      children: [
        // Kalibrasyon uyarısı ve GPS durumu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: _isUsingGPS 
                ? const Color(0xFF00796B).withValues(alpha: 0.1)
                : Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isUsingGPS ? const Color(0xFF00796B).withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isUsingGPS ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                color: _isUsingGPS ? const Color(0xFF00796B) : Colors.amber[800],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isUsingGPS 
                      ? 'Konumunuz GPS üzerinden alındı.' 
                      : 'GPS izni verilmedi. Düziçi varsayılan konumu kullanılıyor.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isUsingGPS ? const Color(0xFF00796B) : Colors.amber[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),

        // Pusula Alanı
        SizedBox(
          height: compassHeight,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Arka Plan Işıması (Hizalandığında parlar)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isAligned 
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.25)
                            : Colors.transparent,
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),

                // Dış Kadran / Sabit Referans Halkası
                Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: darkColor,
                    border: Border.all(
                      color: isAligned 
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.8)
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: isAligned ? 4.0 : 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),

                // Dönen Pusula Kartı (N, S, E, W yönleri dahil)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: _getSmoothAngle(-_currentHeading)),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  builder: (context, angle, child) {
                    return Transform.rotate(
                      angle: angle,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Yön Dereceleri & Çizgileri
                          SizedBox(
                            width: 240,
                            height: 240,
                            child: CustomPaint(
                              painter: CompassDialPainter(
                                textStyle: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                          
                          // Ana Yön Harfleri (K, G, D, B)
                          const Positioned(
                            top: 14,
                            child: Text(
                              'N', 
                              style: TextStyle(
                                color: Colors.red, 
                                fontWeight: FontWeight.w900, 
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const Positioned(
                            bottom: 14,
                            child: Text(
                              'S', 
                              style: TextStyle(
                                color: Colors.blue, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Positioned(
                            right: 14,
                            child: Text(
                              'E', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 14,
                            child: Text(
                              'W', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 16,
                              ),
                            ),
                          ),

                          // Kıbleyi Gösteren Sabit Kadran Üstü Kıble İbresi (Yeşil/Altın)
                          Transform.rotate(
                            angle: _qiblaBearing * math.pi / 180.0,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Kıble oku hattı
                                Positioned(
                                  top: 35,
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.mosque_rounded,
                                        color: AppColors.primary,
                                        size: 36,
                                      ),
                                      Container(
                                        width: 4,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [AppColors.primary, Colors.transparent],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Tepe Referans Çizgisi (Kullanıcının baktığı yönü gösterir)
                Positioned(
                  top: 0,
                  child: Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isAligned ? const Color(0xFF4CAF50) : theme.colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                    ),
                  ),
                ),
                
                // Merkez Göbek
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAligned ? const Color(0xFF4CAF50) : AppColors.primary,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Durum Bilgileri
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: darkColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isAligned 
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.3) 
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: isAligned ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                isAligned ? 'KIBLEYE HİZALANDINIZ!' : 'TELEFONU KIBLE YÖNÜNE ÇEVİRİN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isAligned ? const Color(0xFF4CAF50) : theme.textTheme.titleMedium?.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatTile(
                    theme,
                    'Kıble Açısı',
                    '${_qiblaBearing.toStringAsFixed(1)}°',
                    Icons.explore_outlined,
                  ),
                  Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                  _buildStatTile(
                    theme,
                    'Kabe Mesafesi',
                    '${_distanceToMakkah.toStringAsFixed(0)} km',
                    Icons.straighten_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Cihaz Kalibrasyon İpucu
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Text(
            'İpucu: Pusulayı kalibre etmek için telefonunuzu havada 8 çizecek şekilde hareket ettirebilirsiniz. Telefonunuzu yere paralel tutun.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildStatTile(ThemeData theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildNoSensorFallback() {
    final theme = Theme.of(context);
    final darkColor = theme.brightness == Brightness.dark ? AppColors.darkSurface : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sensors_off_rounded,
              color: Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sensör Bulunamadı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cihazınızda yön tayini için gerekli magnetometre (pusula) sensörü bulunmamaktadır.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Düziçi İçin Kıble Yönü:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Güneye göre sol (Doğu) yönüne doğru 11.5 derece (Kuzeyden saat yönünde 168.5°).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pusula Kadranı Çizici
class CompassDialPainter extends CustomPainter {
  final TextStyle textStyle;

  CompassDialPainter({required this.textStyle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = textStyle.color ?? Colors.grey
      ..style = PaintingStyle.stroke;

    // Kadran çizgileri
    for (int i = 0; i < 360; i += 15) {
      final double angle = i * math.pi / 180.0;
      final double startDist = radius - (i % 30 == 0 ? 12 : 6);
      
      final start = Offset(
        center.dx + startDist * math.cos(angle),
        center.dy + startDist * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      paint.strokeWidth = i % 30 == 0 ? 1.5 : 0.8;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
