import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'trip_planner_theme.dart';

class TripCategoryOption {
  const TripCategoryOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.recommended = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
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
    TripCategoryOption(id: 'DOĞAL GÜZELLİK', label: 'Doğal Güzellik', icon: Icons.filter_hdr_rounded, color: Color(0xFF2196F3)),
    TripCategoryOption(id: 'TARİHİ YER',     label: 'Tarihi Yer',     icon: Icons.history_edu_rounded, color: Color(0xFFFF9800)),
    TripCategoryOption(id: 'KALE',            label: 'Kale',            icon: Icons.fort_rounded,        color: Color(0xFF795548)),
    TripCategoryOption(id: 'YAYLA',           label: 'Yayla',           icon: Icons.landscape_rounded,   color: Color(0xFF00BCD4)),
    TripCategoryOption(id: 'KAMP ALANI',      label: 'Kamp Alanı',     icon: Icons.terrain_rounded,     color: Color(0xFF4CAF50)),
    TripCategoryOption(id: 'YÜRÜYÜŞ ROTASI', label: 'Yürüyüş',        icon: Icons.directions_walk_rounded, color: Color(0xFF009688)),
    TripCategoryOption(id: 'MÜZE',            label: 'Müze',            icon: Icons.museum_rounded,      color: Color(0xFF9C27B0)),
    TripCategoryOption(id: 'LEZZET DURAĞI',  label: 'Lezzet Durağı',  icon: Icons.restaurant_rounded,  color: Color(0xFFF44336)),
    TripCategoryOption(id: 'PARK',            label: 'Park',            icon: Icons.park_rounded,        color: Color(0xFF8BC34A)),
    TripCategoryOption(id: 'EDITOR',          label: 'Editör Seçimi',  icon: Icons.auto_awesome_rounded, color: Color(0xFFD4AF37), recommended: true),
    TripCategoryOption(id: 'HEPSİ',          label: 'Tümünü Göster',  icon: Icons.explore_rounded,     color: Color(0xFF5C6BC0)),
  ];

  @override
  State<TripPlannerCategoryHub> createState() => _TripPlannerCategoryHubState();
}

class _TripPlannerCategoryHubState extends State<TripPlannerCategoryHub>
    with SingleTickerProviderStateMixin {
  final Set<String> _selected = {'DOĞAL GÜZELLİK'};
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (id == 'HEPSİ') {
        _selected..clear()..add('HEPSİ');
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
          title: const Text('Gezi Rehberi'),
          backgroundColor: TripPlannerTheme.bg,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      // ── Animated Hero Illustration ──
                      _HubIllustration(controller: _bgCtrl),
                      const SizedBox(height: 20),

                      // ── Heading ──
                      const Text(
                        'Düziçi\'ye Hoş Geldiniz',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TripPlannerTheme.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 8),
                      const Text(
                        'Hangi tür yerleri keşfetmek istersiniz?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TripPlannerTheme.textSecondary,
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 24),

                      // ── Category Grid ──
                      _CategoryGrid(
                        categories: TripPlannerCategoryHub.categories,
                        selected: _selected,
                        onToggle: _toggle,
                      ).animate(delay: 150.ms).fadeIn(),

                      const SizedBox(height: 24),

                      // ── Quick Action Tiles ──
                      _QuickActionRow(
                        onEditorRoutes: widget.onEditorRoutes,
                        onSavedRoutes: widget.onSavedRoutes,
                      ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ),

              // ── CTA ──
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

// ── Animated illustration ──────────────────────────────────────────────
class _HubIllustration extends StatelessWidget {
  final AnimationController controller;
  const _HubIllustration({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return SizedBox(
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 140 + 6 * math.sin(t * math.pi),
                height: 140 + 6 * math.sin(t * math.pi),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      TripPlannerTheme.gold.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Inner circle
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TripPlannerTheme.surface,
                  border: Border.all(
                    color: TripPlannerTheme.gold.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  size: 50,
                  color: TripPlannerTheme.gold,
                ),
              ),
              // Orbiting category icons
              ..._buildOrbitIcons(t),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildOrbitIcons(double t) {
    final icons = [
      (Icons.fort_rounded, const Color(0xFF795548)),
      (Icons.filter_hdr_rounded, const Color(0xFF2196F3)),
      (Icons.restaurant_rounded, const Color(0xFFF44336)),
      (Icons.landscape_rounded, const Color(0xFF00BCD4)),
      (Icons.museum_rounded, const Color(0xFF9C27B0)),
      (Icons.terrain_rounded, const Color(0xFF4CAF50)),
    ];

    return List.generate(icons.length, (i) {
      final angle = (i / icons.length) * 2 * math.pi + t * math.pi * 0.4;
      const r = 68.0;
      final x = math.cos(angle) * r;
      final y = math.sin(angle) * r;
      return Positioned(
        left: 80 + x - 14,
        top: 80 + y - 14,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: icons[i].$2.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: icons[i].$2.withValues(alpha: 0.4), width: 1),
          ),
          child: Icon(icons[i].$1, size: 14, color: icons[i].$2),
        ),
      );
    });
  }
}

// ── 2-column grid of category chips ──────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  final List<TripCategoryOption> categories;
  final Set<String> selected;
  final void Function(String id) onToggle;

  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = selected.contains(cat.id);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => onToggle(cat.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            cat.color.withValues(alpha: 0.85),
                            cat.color.withValues(alpha: 0.55),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : TripPlannerTheme.chipBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? cat.color
                        : Colors.white.withValues(alpha: 0.07),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cat.color.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : cat.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat.icon,
                          size: 16,
                          color: isSelected ? Colors.white : cat.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cat.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : TripPlannerTheme.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            if (cat.recommended)
              Positioned(
                top: -7,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85D4C),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Önerilen',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Quick action row ─────────────────────────────────────────────────
class _QuickActionRow extends StatelessWidget {
  final VoidCallback onEditorRoutes;
  final VoidCallback onSavedRoutes;

  const _QuickActionRow({
    required this.onEditorRoutes,
    required this.onSavedRoutes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickTile(
            icon: Icons.auto_awesome_rounded,
            label: 'Editör\nRotaları',
            iconColor: TripPlannerTheme.gold,
            onTap: onEditorRoutes,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickTile(
            icon: Icons.bookmark_rounded,
            label: 'Kayıtlı\nRotalarım',
            iconColor: TripPlannerTheme.ctaBlue,
            onTap: onSavedRoutes,
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: TripPlannerTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: TripPlannerTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: TripPlannerTheme.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
