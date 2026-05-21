import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/premium_constants.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// شارة Premium — AppBar (تظهر فقط عند اشتراك ساري).
class PremiumBadge extends ConsumerWidget {
  const PremiumBadge({
    super.key,
    this.compact = false,
    this.size,
  });

  /// وضع مضغوط للـ AppBar.
  final bool compact;

  /// حجم الشارة؛ الافتراضي 24 في compact و 32 في الوضع الكامل.
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isPremiumProvider)) {
      return const SizedBox.shrink();
    }

    final badgeSize = size ?? (compact ? 24.0 : 32.0);

    if (compact) {
      return _CompactBadge(size: badgeSize);
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
        horizontal: size * 0.3,
        vertical: size * 0.14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            PremiumConstants.premiumGradientStart,
            PremiumConstants.premiumGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.9),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: PremiumConstants.premiumColor.withValues(alpha: 0.3),
            blurRadius: 6,
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
            size: size * 0.5,
          ),
          SizedBox(width: size * 0.12),
          Text(
            PremiumConstants.premiumBadgeText,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: size * 0.34,
              fontWeight: FontWeight.w800,
            ),
          ),
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
