import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/premium_constants.dart';
import 'package:netgulf/core/models/premium_status.dart';
import 'package:netgulf/core/services/premium_access.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// شارة Premium — AppBar أو بطاقات مختصرة.
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppColors.emerald.withValues(alpha: 0.28),
              AppColors.gold.withValues(alpha: 0.18),
            ],
          ),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 16, color: AppColors.goldBright),
            const SizedBox(width: 4),
            Text(
              'Premium',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.goldBright,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.emerald.withValues(alpha: 0.2),
            AppColors.gold.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.goldBright, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '✅ ${PremiumConstants.statusActive} — ${PremiumConstants.statusActiveSubtitle}',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.emeraldLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
