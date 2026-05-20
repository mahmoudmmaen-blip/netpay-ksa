import 'package:flutter/material.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// خلفية فاخرة — تدرج كحلي + بقع زمردية/ذهبية.
class PremiumMeshBackground extends StatelessWidget {
  const PremiumMeshBackground({
    super.key,
    required this.child,
    this.isDark = true,
  });

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dark = isDark || Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: dark
                ? AppColors.luxuryDarkMesh
                : AppColors.luxuryLightMesh,
          ),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: _GlowOrb(
            size: 220,
            color: AppColors.emerald.withValues(alpha: dark ? 0.22 : 0.14),
          ),
        ),
        Positioned(
          top: 120,
          left: -90,
          child: _GlowOrb(
            size: 180,
            color: AppColors.gold.withValues(alpha: dark ? 0.12 : 0.08),
          ),
        ),
        if (dark)
          Positioned(
            bottom: 80,
            right: -40,
            child: _GlowOrb(
              size: 140,
              color: AppColors.emeraldLight.withValues(alpha: 0.1),
            ),
          ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
