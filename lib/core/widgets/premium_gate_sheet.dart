import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/premium_constants.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';

/// سبب ظهور بوابة Premium.
enum PremiumFeature {
  pdfExport('تصدير PDF'),
  unlimitedHistory('سجل غير محدود'),
  fullComparison('مقارنة العروض الكاملة'),
  legalPriority('أولوية المساعد القانوني');

  const PremiumFeature(this.labelAr);
  final String labelAr;
}

/// يعرض bottom sheet Premium — يرجع true إذا أصبح المستخدم Premium.
Future<bool> showPremiumGate(
  BuildContext context, {
  required PremiumFeature feature,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PremiumGateSheet(feature: feature),
  );
  return result ?? false;
}

/// يتحقق من Premium — يعرض البوابة إن لزم.
Future<bool> requirePremium(
  BuildContext context,
  WidgetRef ref, {
  required PremiumFeature feature,
}) async {
  if (ref.read(premiumNotifierProvider.notifier).isPremium()) return true;
  final upgraded = await showPremiumGate(context, feature: feature);
  return upgraded ||
      ref.read(premiumNotifierProvider.notifier).isPremium();
}

class _PremiumGateSheet extends ConsumerStatefulWidget {
  const _PremiumGateSheet({required this.feature});

  final PremiumFeature feature;

  @override
  ConsumerState<_PremiumGateSheet> createState() => _PremiumGateSheetState();
}

class _PremiumGateSheetState extends ConsumerState<_PremiumGateSheet> {
  bool _loading = false;
  bool _restoring = false;

  Future<void> _purchase() async {
    setState(() => _loading = true);
    try {
      final ok =
          await ref.read(premiumNotifierProvider.notifier).purchasePremium();
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تفعيل Premium بنجاح! 🎉',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.emerald,
          ),
        );
      } else {
        _showError('تعذّر الشراء. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      final ok =
          await ref.read(premiumNotifierProvider.notifier).restorePurchases();
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم استعادة Premium بنجاح',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.emerald,
          ),
        );
      } else {
        _showError('لم يُعثر على اشتراك سابق.');
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.cairo())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final busy = _loading || _restoring;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark
                ? [
                    AppColors.navyMid,
                    AppColors.navyDeepGreen,
                    const Color(0xFF0F172A),
                  ]
                : [Colors.white, AppColors.emeraldMuted.withValues(alpha: 0.4)],
          ),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.35),
                      AppColors.emerald.withValues(alpha: 0.35),
                    ],
                  ),
                  border:
                      Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 44,
                  color: AppColors.goldBright,
                ),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                child: Text(
                  'NetGulf Premium',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.feature.labelAr} — ميزة Premium',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GlassSurface(
                borderRadius: 18,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  PremiumConstants.premiumPriceFull,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emeraldLight,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...PremiumConstants.benefits.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            Icon(b.$1, size: 20, color: AppColors.emeraldLight),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          b.$2,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.emerald,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.goldBright,
                        AppColors.gold,
                        AppColors.emerald,
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: busy ? null : _purchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'فعّل Premium',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: busy ? null : _restore,
                child: _restoring
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'استعادة المشتريات',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          color: AppColors.emerald,
                        ),
                      ),
              ),
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(context, false),
                child: Text(
                  'لاحقاً',
                  style: GoogleFonts.cairo(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
