import 'package:flutter/material.dart';
import 'package:flutter_app_liftmove/core/theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Región del diagrama corporal: SVG superpuesto + músculos primarios en BD.
class MuscleRegion {
  const MuscleRegion({
    required this.id,
    required this.asset,
    required this.label,
    required this.primaryMuscles,
    required this.hitRect,
    this.hitPriority = 0,
  });

  final String id;
  final String asset;
  final String label;
  final List<String> primaryMuscles;
  /// Rectángulo normalizado (0–1) sobre el diagrama para detectar toques.
  final Rect hitRect;
  final int hitPriority;
}

/// Capas SVG apiladas sobre [bodyinactive.svg]; al tocar una zona se resalta el músculo.
class BodyMusclePicker extends StatelessWidget {
  const BodyMusclePicker({
    super.key,
    required this.selectedId,
    required this.onRegionSelected,
    this.height = 280,
  });

  final String? selectedId;
  final ValueChanged<MuscleRegion> onRegionSelected;
  final double height;

  static const String baseAsset = 'assets/body/bodyinactive.svg';

  static const List<MuscleRegion> regions = [
    MuscleRegion(
      id: 'forearms',
      asset: 'assets/body/forearms.svg',
      label: 'Antebrazos',
      primaryMuscles: ['antebrazos'],
      hitRect: Rect.fromLTWH(0.04, 0.40, 0.14, 0.22),
      hitPriority: 100,
    ),
    MuscleRegion(
      id: 'forearms_r',
      asset: 'assets/body/forearms.svg',
      label: 'Antebrazos',
      primaryMuscles: ['antebrazos'],
      hitRect: Rect.fromLTWH(0.82, 0.40, 0.14, 0.22),
      hitPriority: 100,
    ),
    MuscleRegion(
      id: 'biceps',
      asset: 'assets/body/biceps.svg',
      label: 'Bíceps',
      primaryMuscles: ['bíceps'],
      hitRect: Rect.fromLTWH(0.10, 0.24, 0.14, 0.18),
      hitPriority: 90,
    ),
    MuscleRegion(
      id: 'biceps_r',
      asset: 'assets/body/biceps.svg',
      label: 'Bíceps',
      primaryMuscles: ['bíceps'],
      hitRect: Rect.fromLTWH(0.76, 0.24, 0.14, 0.18),
      hitPriority: 90,
    ),
    MuscleRegion(
      id: 'triceps',
      asset: 'assets/body/triceps.svg',
      label: 'Tríceps',
      primaryMuscles: ['tríceps'],
      hitRect: Rect.fromLTWH(0.08, 0.30, 0.12, 0.14),
      hitPriority: 85,
    ),
    MuscleRegion(
      id: 'triceps_r',
      asset: 'assets/body/triceps.svg',
      label: 'Tríceps',
      primaryMuscles: ['tríceps'],
      hitRect: Rect.fromLTWH(0.80, 0.30, 0.12, 0.14),
      hitPriority: 85,
    ),
    MuscleRegion(
      id: 'shoulder',
      asset: 'assets/body/shoulder.svg',
      label: 'Hombros',
      primaryMuscles: ['hombros'],
      hitRect: Rect.fromLTWH(0.14, 0.16, 0.18, 0.12),
      hitPriority: 80,
    ),
    MuscleRegion(
      id: 'shoulder_r',
      asset: 'assets/body/shoulder.svg',
      label: 'Hombros',
      primaryMuscles: ['hombros'],
      hitRect: Rect.fromLTWH(0.68, 0.16, 0.18, 0.12),
      hitPriority: 80,
    ),
    MuscleRegion(
      id: 'chest',
      asset: 'assets/body/chest.svg',
      label: 'Pecho',
      primaryMuscles: ['pecho'],
      hitRect: Rect.fromLTWH(0.30, 0.22, 0.40, 0.14),
      hitPriority: 75,
    ),
    MuscleRegion(
      id: 'traps',
      asset: 'assets/body/traps.svg',
      label: 'Trapecios',
      primaryMuscles: ['trapecios'],
      hitRect: Rect.fromLTWH(0.34, 0.10, 0.32, 0.10),
      hitPriority: 70,
    ),
    MuscleRegion(
      id: 'oblique',
      asset: 'assets/body/oblique.svg',
      label: 'Oblicuos',
      primaryMuscles: ['abdominales'],
      hitRect: Rect.fromLTWH(0.22, 0.34, 0.14, 0.16),
      hitPriority: 65,
    ),
    MuscleRegion(
      id: 'oblique_r',
      asset: 'assets/body/oblique.svg',
      label: 'Oblicuos',
      primaryMuscles: ['abdominales'],
      hitRect: Rect.fromLTWH(0.64, 0.34, 0.14, 0.16),
      hitPriority: 65,
    ),
    MuscleRegion(
      id: 'abs',
      asset: 'assets/body/abs.svg',
      label: 'Abdominales',
      primaryMuscles: ['abdominales'],
      hitRect: Rect.fromLTWH(0.34, 0.36, 0.32, 0.14),
      hitPriority: 60,
    ),
    MuscleRegion(
      id: 'psoas',
      asset: 'assets/body/psoas.svg',
      label: 'Cadera',
      primaryMuscles: ['espalda baja', 'abductores'],
      hitRect: Rect.fromLTWH(0.36, 0.48, 0.28, 0.08),
      hitPriority: 55,
    ),
    MuscleRegion(
      id: 'glutes',
      asset: 'assets/body/glutes.svg',
      label: 'Glúteos',
      primaryMuscles: ['glúteos'],
      hitRect: Rect.fromLTWH(0.30, 0.50, 0.40, 0.10),
      hitPriority: 50,
    ),
    MuscleRegion(
      id: 'quads',
      asset: 'assets/body/quads.svg',
      label: 'Cuádriceps',
      primaryMuscles: ['cuadríceps'],
      hitRect: Rect.fromLTWH(0.28, 0.58, 0.44, 0.16),
      hitPriority: 45,
    ),
    MuscleRegion(
      id: 'hamstrings',
      asset: 'assets/body/hamstrings.svg',
      label: 'Isquiotibiales',
      primaryMuscles: ['isquiotibiales'],
      hitRect: Rect.fromLTWH(0.28, 0.62, 0.44, 0.12),
      hitPriority: 40,
    ),
    MuscleRegion(
      id: 'calves',
      asset: 'assets/body/calves.svg',
      label: 'Pantorrillas',
      primaryMuscles: ['pantorrillas'],
      hitRect: Rect.fromLTWH(0.30, 0.76, 0.40, 0.16),
      hitPriority: 35,
    ),
    MuscleRegion(
      id: 'backs',
      asset: 'assets/body/backs.svg',
      label: 'Espalda',
      primaryMuscles: [
        'espalda',
        'dorsales',
        'espalda media',
        'espalda baja',
        'trapecios',
      ],
      hitRect: Rect.fromLTWH(0.28, 0.18, 0.44, 0.32),
      hitPriority: 10,
    ),
  ];

  /// Regiones únicas por asset (para pintar capas SVG sin duplicar).
  static List<MuscleRegion> get uniqueLayers {
    final seen = <String>{};
    final layers = <MuscleRegion>[];
    for (final r in regions) {
      if (seen.add(r.asset)) layers.add(r);
    }
    return layers;
  }

  static MuscleRegion? regionById(String? id) {
    if (id == null) return null;
    for (final r in regions) {
      if (r.id == id) return r;
    }
    return null;
  }

  static MuscleRegion? hitTest(Offset local, Size size) {
    final nx = local.dx / size.width;
    final ny = local.dy / size.height;
    final sorted = List<MuscleRegion>.from(regions)
      ..sort((a, b) => b.hitPriority.compareTo(a.hitPriority));
    for (final r in sorted) {
      if (r.hitRect.contains(Offset(nx, ny))) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedRegion = regionById(selectedId);
    final visibleAsset = selectedRegion?.asset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          selectedRegion != null
              ? selectedRegion.label
              : 'Toca una zona del cuerpo',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selectedRegion != null
                ? AppColors.oceanBlue
                : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final region = hitTest(details.localPosition, Size(w, h));
                  if (region != null) onRegionSelected(region);
                },
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    SvgPicture.asset(
                      baseAsset,
                      fit: BoxFit.contain,
                    ),
                    for (final layer in uniqueLayers)
                      IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: visibleAsset == layer.asset ? 1 : 0,
                          child: SvgPicture.asset(
                            layer.asset,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
