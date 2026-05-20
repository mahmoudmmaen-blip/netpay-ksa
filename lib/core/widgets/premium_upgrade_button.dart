import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/premium_constants.dart';
import 'package:netgulf/core/models/premium_status.dart';
import 'package:netgulf/core/services/premium_access.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/core/widgets/premium_badge.dart';
import 'package:netgulf/core/widgets/premium_gate_sheet.dart';

/// بطاقة ترقية Premium — emerald/gold + glassmorphism.
class PremiumUpgradeButton extends ConsumerWidget {
  const PremiumUpgradeButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(premiumSubscriptionStateProvider);

    if (subState == PremiumSubscriptionState.active) {
      return compact ? const PremiumBadge() : const PremiumBadge(compact: false);
    }

    if (compact) {
      return _CompactUpgradeChip(
        label: subState == PremiumSubscriptionState.expired
            ? 'جدّد'
            : 'Premium',
      );
    }

    if (subState == PremiumSubscriptionState.expired) {
      return _ExpiredBanner();
    }

    return const _FullUpgradeBanner();
  }
}

class _CompactUpgradeChip extends StatelessWidget {
  const _CompactUpgradeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
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
                label,
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
}

class _FullUpgradeBanner extends StatelessWidget {
  const _FullUpgradeBanner();

  @override
  Widget build(BuildContext context) {
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
                        PremiumConstants.upgradeTitle,
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${PremiumConstants.premiumPriceFull} — ${PremiumConstants.statusNotSubscribedSubtitle}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

class _ExpiredBanner extends StatelessWidget {
  const _ExpiredBanner();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.history_toggle_off_rounded, color: AppColors.warning, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PremiumConstants.statusExpired,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
                Text(
                  PremiumConstants.statusExpiredSubtitle,
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => showPremiumGate(
              context,
              feature: PremiumFeature.pdfExport,
            ),
            child: Text(
              PremiumConstants.renewCta,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                color: AppColors.emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
