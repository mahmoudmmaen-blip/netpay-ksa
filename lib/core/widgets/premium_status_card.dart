import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/constants/premium_constants.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/core/widgets/premium_gate_sheet.dart';

/// بطاقة حالة Premium — أعلى شاشة الإعدادات.
class PremiumStatusCard extends ConsumerWidget {
  const PremiumStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(premiumStatusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (status.isValid) {
      return _ActiveCard(expiresAt: status.expiresAt, isDark: isDark);
    }

    return _UpgradeCard(isDark: isDark);
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.expiresAt, required this.isDark});

  final DateTime? expiresAt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final expiryText = expiresAt != null
        ? DateFormat('dd MMMM yyyy', 'ar').format(expiresAt!)
        : '—';

    return GlassSurface(
      highlighted: true,
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.emerald.withValues(alpha: 0.35),
                  AppColors.gold.withValues(alpha: 0.25),
                ],
              ),
              border: Border.all(color: AppColors.emerald.withValues(alpha: 0.6)),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppColors.emeraldLight,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '✅ Premium مفعّل',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emeraldLight,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ينتهي في: $expiryText',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.72),
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

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.3),
                      AppColors.emerald.withValues(alpha: 0.25),
                    ],
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
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      PremiumConstants.premiumPriceFull,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...PremiumConstants.benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(b.$1, size: 18, color: AppColors.emeraldLight),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b.$2,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [AppColors.goldBright, AppColors.emerald],
                ),
              ),
              child: ElevatedButton(
                onPressed: () => showPremiumGate(
                  context,
                  feature: PremiumFeature.pdfExport,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'فعّل Premium',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
