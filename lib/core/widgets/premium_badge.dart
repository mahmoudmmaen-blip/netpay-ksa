import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/premium_constants.dart';
import 'package:netgulf/core/models/premium_status.dart';
import 'package:netgulf/core/services/premium_access.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// شارة Premium — تاج + خلفية emerald + نبض خفيف (AppBar / الإعدادات).
class PremiumBadge extends ConsumerWidget {
  const PremiumBadge({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumSubscriptionStateProvider);
    if (state != PremiumSubscriptionState.active) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return const _CompactBadge();
    }

    return const _FullBadge();
  }
}

class _CompactBadge extends StatefulWidget {
  const _CompactBadge();

  @override
  State<_CompactBadge> createState() => _CompactBadgeState();
}

class _CompactBadgeState extends State<_CompactBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _glow;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.22, end: 0.48).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.emerald, AppColors.emeraldDark],
            ),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.45 + _glow.value * 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: _glow.value),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 15,
            color: AppColors.goldBright,
          ),
          const SizedBox(width: 5),
          Text(
            'Premium',
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: const BoxDecoration(
              color: AppColors.goldBright,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 9,
              color: AppColors.emeraldDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullBadge extends StatelessWidget {
  const _FullBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.emerald, AppColors.emeraldDark, Color(0xFF064E3B)],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.goldBright.withValues(alpha: 0.6),
              ),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.goldBright,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      PremiumConstants.statusActive,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.goldBright,
                    ),
                  ],
                ),
                Text(
                  PremiumConstants.statusActiveSubtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
