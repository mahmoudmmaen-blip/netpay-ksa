import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/premium_constants.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/core/widgets/premium_gate_sheet.dart';

/// بطاقة ترقية Premium — emerald/gold + glassmorphism.
class PremiumUpgradeButton extends ConsumerWidget {
  const PremiumUpgradeButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) {
      return compact ? const SizedBox.shrink() : const _PremiumActiveBadge();
    }

    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showPremiumGate(
            context,
            feature: PremiumFeature.pdfExport,
          ),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.25),
                  AppColors.emerald.withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 18,
                  color: AppColors.goldBright,
                ),
                const SizedBox(width: 6),
                Text(
                  'Premium',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldBright,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GlassSurface(
      highlighted: true,
      borderRadius: 22,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showPremiumGate(
            context,
            feature: PremiumFeature.pdfExport,
          ),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF1A2332),
                  Color(0xFF064E3B),
                  Color(0xFF0F766E),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.22),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.goldBright,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ترقية إلى Premium',
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${PremiumConstants.premiumPriceFull} — بدون إعلانات + كل الميزات',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.goldBright.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumActiveBadge extends StatelessWidget {
  const _PremiumActiveBadge();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.goldBright, size: 22),
          const SizedBox(width: 8),
          Text(
            '✅ Premium مفعّل',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              color: AppColors.emeraldLight,
            ),
          ),
        ],
      ),
    );
  }
}
