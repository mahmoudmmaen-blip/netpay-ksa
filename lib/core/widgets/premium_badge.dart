import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/premium_constants.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// شارة Premium — AppBar (تظهر فقط عند اشتراك ساري).
class PremiumBadge extends ConsumerWidget {
  const PremiumBadge({super.key, this.compact = true, this.size = 32});

  final bool compact;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isPremiumProvider)) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return _CompactBadge(size: size);
    }
    return _FullBadge();
  }
}

class _CompactBadge extends StatelessWidget {
  const _CompactBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.35,
        vertical: size * 0.18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            PremiumConstants.premiumGradientStart,
            PremiumConstants.premiumGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(size),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: PremiumConstants.premiumColor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: size * 0.55,
          ),
          SizedBox(width: size * 0.15),
          Text(
            PremiumConstants.premiumBadgeText,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: size * 0.12),
          Icon(Icons.check_circle_rounded, color: Colors.white, size: size * 0.4),
        ],
      ),
    );
  }
}

class _FullBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            PremiumConstants.premiumGradientStart,
            PremiumConstants.premiumGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            PremiumConstants.statusActive,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
