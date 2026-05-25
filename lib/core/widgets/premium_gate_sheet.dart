import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/premium_constants.dart';
import 'package:netgulf/core/models/premium_status.dart';
import 'package:netgulf/core/providers/gulf_country_provider.dart';
import 'package:netgulf/core/services/premium_access.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';

const _benefitIcons = [
  Icons.block_rounded,
  Icons.history_rounded,
  Icons.picture_as_pdf_rounded,
  Icons.compare_arrows_rounded,
  Icons.smart_toy_outlined,
  Icons.auto_awesome_rounded,
];

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
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _PremiumGateSheet(feature: feature),
  );
  return result ?? false;
}

/// يتحقق من Premium — يعرض البوابة إن لزم.
Future<bool> requirePremium(
  BuildContext context,
  WidgetRef ref, {
  required PremiumFeature feature,
}) =>
    PremiumAccess.requirePremium(context, ref, feature: feature);

class _PremiumGateSheet extends ConsumerStatefulWidget {
  const _PremiumGateSheet({required this.feature});

  final PremiumFeature feature;

  @override
  ConsumerState<_PremiumGateSheet> createState() => _PremiumGateSheetState();
}

class _PremiumGateSheetState extends ConsumerState<_PremiumGateSheet>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _restoring = false;
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _purchase() async {
    setState(() => _loading = true);
    try {
      final ok =
          await ref.read(premiumNotifierProvider.notifier).upgradeToPremium();
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
    final subState = ref.watch(premiumSubscriptionStateProvider);
    final country = ref.watch(gulfCountryProvider);
    final benefits = PremiumConstants.benefitItemsFor(country);
    final ctaLabel = subState == PremiumSubscriptionState.expired
        ? PremiumConstants.renewCta
        : PremiumConstants.upgradeButtonText;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            clipBehavior: Clip.antiAlias,
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
                    : [
                        Colors.white,
                        AppColors.emeraldMuted.withValues(alpha: 0.35),
                        const Color(0xFFF0FDF9),
                      ],
              ),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, -6),
                ),
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -30,
                  child: _GlowOrb(
                    color: AppColors.emerald.withValues(alpha: 0.18),
                    size: 140,
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: -20,
                  child: _GlowOrb(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    size: 100,
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gold.withValues(alpha: 0.4),
                              AppColors.emerald.withValues(alpha: 0.35),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.65),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.25),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 48,
                          color: AppColors.goldBright,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (b) =>
                            AppColors.goldGradient.createShader(b),
                        child: Text(
                          PremiumConstants.premiumUpgradeTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        PremiumConstants.premiumUpgradeSubtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          height: 1.45,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.feature.labelAr} — ميزة Premium',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(height: 22),
                      GlassSurface(
                        highlighted: true,
                        borderRadius: 18,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        child: Column(
                          children: [
                            Text(
                              PremiumConstants.premiumPriceFullFor(country),
                              style: GoogleFonts.cairo(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.emeraldLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              PremiumConstants.premiumBenefitsTitle,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      ...benefits.asMap().entries.map(
                        (entry) {
                          final benefit = entry.value;
                          final icon = _benefitIcons[
                              entry.key % _benefitIcons.length];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassSurface(
                              borderRadius: 14,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 20,
                                      color: AppColors.emeraldLight,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      benefit,
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.emerald,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 26),
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
                                color: AppColors.gold.withValues(alpha: 0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: busy ? null : _purchase,
                            icon: _loading
                                ? const SizedBox.shrink()
                                : const Icon(
                                    Icons.rocket_launch_rounded,
                                    color: AppColors.navy,
                                  ),
                            label: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    ctaLabel,
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: busy ? null : _restore,
                        child: _restoring
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
