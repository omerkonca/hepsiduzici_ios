import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'trip_planner_theme.dart';

class TripCategoryOption {
  const TripCategoryOption({
    required this.id,
    required this.label,
    this.recommended = false,
  });

  final String id;
  final String label;
  final bool recommended;
}

/// İlgi alanı seçimi — koyu tema, altın vurgu.
class TripPlannerCategoryHub extends StatefulWidget {
  const TripPlannerCategoryHub({
    super.key,
    required this.onContinue,
    required this.onEditorRoutes,
    required this.onSavedRoutes,
    this.onBack,
  });

  final void Function(Set<String> categoryIds) onContinue;
  final VoidCallback onEditorRoutes;
  final VoidCallback onSavedRoutes;
  final VoidCallback? onBack;

  static const categories = <TripCategoryOption>[
    TripCategoryOption(id: 'KALE', label: 'Kaleler'),
    TripCategoryOption(id: 'TARİHİ YER', label: 'Tarihi Yerler'),
    TripCategoryOption(id: 'LEZZET DURAĞI', label: 'Lezzet Durakları'),
    TripCategoryOption(id: 'KAMP ALANI', label: 'Kamp Alanları'),
    TripCategoryOption(id: 'MÜZE', label: 'Müzeler'),
    TripCategoryOption(id: 'YÜRÜYÜŞ ROTASI', label: 'Yürüyüş Rotaları'),
    TripCategoryOption(id: 'DOĞAL GÜZELLİK', label: 'Doğal Güzellikler'),
    TripCategoryOption(id: 'YAYLA', label: 'Yaylalar'),
    TripCategoryOption(id: 'PARK', label: 'Parklar'),
    TripCategoryOption(id: 'EDITOR', label: 'Editör Seçimi', recommended: true),
    TripCategoryOption(id: 'HEPSİ', label: 'Tümü'),
  ];

  @override
  State<TripPlannerCategoryHub> createState() => _TripPlannerCategoryHubState();
}

class _TripPlannerCategoryHubState extends State<TripPlannerCategoryHub> {
  final Set<String> _selected = {'DOĞAL GÜZELLİK'};

  void _toggle(String id) {
    setState(() {
      if (id == 'HEPSİ') {
        _selected
          ..clear()
          ..add('HEPSİ');
        return;
      }
      if (id == 'EDITOR') {
        widget.onEditorRoutes();
        return;
      }
      _selected.remove('HEPSİ');
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      if (_selected.isEmpty) _selected.add('DOĞAL GÜZELLİK');
    });
  }

  IconData _getCategoryIcon(String id) {
    switch (id) {
      case 'KALE':
        return Icons.fort_rounded;
      case 'TARİHİ YER':
        return Icons.history_edu_rounded;
      case 'LEZZET DURAĞI':
        return Icons.restaurant_rounded;
      case 'KAMP ALANI':
        return Icons.terrain_rounded;
      case 'MÜZE':
        return Icons.museum_rounded;
      case 'YÜRÜYÜŞ ROTASI':
        return Icons.directions_walk_rounded;
      case 'DOĞAL GÜZELLİK':
        return Icons.filter_hdr_rounded;
      case 'YAYLA':
        return Icons.landscape_rounded;
      case 'PARK':
        return Icons.park_rounded;
      case 'EDITOR':
        return Icons.auto_awesome_rounded;
      case 'HEPSİ':
        return Icons.explore_rounded;
      default:
        return Icons.map_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: TripPlannerTheme.theme(),
      child: Scaffold(
        backgroundColor: TripPlannerTheme.bg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          ),
          title: const Text('Gezi Planlayıcı'),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: TripPlannerTheme.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: TripPlannerTheme.gold.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.hiking_rounded, color: Color(0xFF1A1508), size: 42),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Merhaba, Osmaniye\'ye hoş geldiniz',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TripPlannerTheme.gold,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 8),
                      const Text(
                        'Gezi planınız için hangi tür yerleri keşfetmek istersiniz?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TripPlannerTheme.textSecondary,
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 120.ms),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: TripPlannerCategoryHub.categories.map((c) {
                          final selected = _selected.contains(c.id);
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () => _toggle(c.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: selected ? TripPlannerTheme.chipSelectedGradient : null,
                                    color: selected ? null : TripPlannerTheme.chipBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected
                                          ? TripPlannerTheme.gold.withValues(alpha: 0.55)
                                          : Colors.white.withValues(alpha: 0.06),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getCategoryIcon(c.id),
                                        size: 15,
                                        color: selected ? TripPlannerTheme.gold : TripPlannerTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        c.label,
                                        style: TextStyle(
                                          color: selected ? TripPlannerTheme.textPrimary : TripPlannerTheme.textSecondary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (c.recommended)
                                Positioned(
                                  top: -8,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE85D4C),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Önerilen',
                                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ).animate(delay: 180.ms).fadeIn(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onEditorRoutes,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: TripPlannerTheme.gold),
                        label: const Text('Editör Rotaları'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TripPlannerTheme.textPrimary,
                          backgroundColor: TripPlannerTheme.surface,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onSavedRoutes,
                        icon: const Icon(Icons.bookmark_rounded, size: 16, color: TripPlannerTheme.ctaBlue),
                        label: const Text('Kayıtlı Rotalarım'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TripPlannerTheme.textPrimary,
                          backgroundColor: TripPlannerTheme.surface,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: TripPlannerTheme.primaryCta(
                  label: 'Devam Et',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => widget.onContinue(Set<String>.from(_selected)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
