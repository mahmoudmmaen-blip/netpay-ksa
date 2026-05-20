import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/providers/theme_provider.dart';
import 'package:netgulf/core/providers/gulf_country_provider.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/core/services/premium_access.dart';
import 'package:netgulf/core/widgets/premium_badge.dart';
import 'package:netgulf/core/widgets/premium_gate_sheet.dart';
import 'package:netgulf/core/widgets/premium_upgrade_button.dart';
import 'package:netgulf/core/widgets/premium_mesh_background.dart';
import 'package:netgulf/features/admob/widgets/home_banner_ad.dart';
import 'package:netgulf/features/pdf_export/pdf_export_helper.dart';
import 'package:netgulf/features/pdf_export/pdf_service.dart';
import 'package:netgulf/features/brain_rot/presentation/widgets/brain_rot_score_card.dart';
import 'package:netgulf/features/home/presentation/widgets/home_net_salary_card.dart';
import 'package:netgulf/features/home/presentation/widgets/home_quick_actions_row.dart';
import 'package:netgulf/features/home/presentation/widgets/gulf_country_selector.dart';
import 'package:netgulf/features/home/presentation/widgets/home_screen_header.dart';
import 'package:netgulf/features/home/presentation/widgets/saudi_home_section.dart';
import 'package:netgulf/features/home/presentation/widgets/uae_home_section.dart';
import 'package:netgulf/features/home/providers/home_uae_notifier.dart';
import 'package:netgulf/core/providers/notification_provider.dart';
import 'package:netgulf/features/salary_calculator/models/gosi_model.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';
import 'package:netgulf/features/share/providers/share_provider.dart';
import 'package:netgulf/features/share/share_service.dart';
import 'package:netgulf/features/share/widgets/salary_share_card.dart';

/// الشاشة الرئيسية — حاسبة متعددة الدول (السعودية + الإمارات).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final country = ref.watch(gulfCountryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSaudi = country == GulfCountry.saudiArabia;
    final currency = NumberFormat.currency(
      locale: country.currencyLocale,
      symbol: country.currencySymbol,
      decimalDigits: 2,
    );

    final salary = ref.watch(salaryNotifierProvider);
    final gosi = ref.watch(gosiModelProvider);
    final uaeModel = ref.watch(homeUaeModelProvider);
    final showGosiBadge =
        isSaudi && ref.watch(gosiAlertWithin30DaysProvider);

    final net = isSaudi ? (gosi?.netSalary ?? 0) : uaeModel.netSalary;
    final gross =
        isSaudi ? (gosi?.totalGross ?? salary.allowances.totalGross) : uaeModel.totalGross;
    final deduction =
        isSaudi ? (gosi?.employeeGosi ?? 0) : uaeModel.monthlyContribution;

    final showAds = ref.watch(showAdsProvider);
    final isPremium = PremiumAccess.watchIsPremium(ref);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppColors.goldGradient.createShader(b),
              child: Text(
                'NetGulf',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          _GlassIconButton(
            tooltip: 'مشاركة النتيجة',
            icon: Icons.share_rounded,
            onPressed: () => _shareResult(
              context,
              ref,
              country: country,
              gosi: gosi,
              uaeNet: uaeModel.netSalary,
              uaeGross: uaeModel.totalGross,
              uaeDeduction: uaeModel.monthlyContribution,
            ),
          ),
          if (isSaudi)
            _GlassIconButton(
              tooltip: 'التنبيهات',
              icon: Icons.notifications_none_rounded,
              badge: showGosiBadge,
              onPressed: () => context.push(AppRoutes.notifications),
            ),
          _GlassIconButton(
            tooltip: 'تبديل الوضع',
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggleDarkLight(),
          ),
          _GlassIconButton(
            tooltip: 'السجل',
            icon: Icons.history_rounded,
            onPressed: () => context.push(AppRoutes.history),
          ),
          if (!isPremium)
            _GlassIconButton(
              tooltip: 'ترقية Premium',
              icon: Icons.workspace_premium_rounded,
              onPressed: () => showPremiumGate(
                context,
                feature: PremiumFeature.pdfExport,
              ),
            ),
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 4),
            child: Center(child: PremiumBadge(compact: true)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PremiumMeshBackground(
              isDark: isDark,
              child: SafeArea(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    GulfCountrySelector(
                      selected: country,
                      onSelected: (c) => ref
                          .read(gulfCountryProvider.notifier)
                          .setCountry(c),
                    ),
                    const SizedBox(height: 24),
                    HomeScreenHeader(country: country),
                    const SizedBox(height: 16),
                    const PremiumUpgradeButton(),
                    const SizedBox(height: 16),
                    const BrainRotScoreCard(),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: HomeNetSalaryCard(
                        key: ValueKey(country),
                        country: country,
                        net: net,
                        gross: gross,
                        deduction: deduction,
                        isDark: isDark,
                        formatValue: currency.format,
                      ),
                    ),
                    const SizedBox(height: 24),
                    HomeQuickActionsRow(
                      country: country,
                      items: _quickActionItems(context, ref, country, isPremium),
                    ),
                    const SizedBox(height: 28),
                    if (isSaudi && salary.hasError)
                      _ErrorBanner(message: salary.errorMessage!),
                    if (isSaudi && gosi != null) ..._gosiWarnings(gosi),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: isSaudi
                          ? SaudiHomeSection(
                              key: const ValueKey('saudi-body'),
                              country: country,
                              currency: currency,
                            )
                          : UaeHomeSection(
                              key: const ValueKey('uae-body'),
                              country: country,
                              currency: currency,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showAds) const HomeBannerAd(),
        ],
      ),
    );
  }

  List<HomeQuickActionItem> _quickActionItems(
    BuildContext context,
    WidgetRef ref,
    GulfCountry country,
    bool isPremium,
  ) {
    final isSaudi = country == GulfCountry.saudiArabia;

    final items = <HomeQuickActionItem>[
      HomeQuickActionItem(
        title: 'نهاية الخدمة',
        icon: Icons.card_giftcard_outlined,
        onTap: () => context.push(AppRoutes.eosb),
      ),
      HomeQuickActionItem(
        title: 'المساعد القانوني',
        icon: Icons.smart_toy_rounded,
        highlighted: true,
        onTap: () => context.push(AppRoutes.legal),
      ),
      HomeQuickActionItem(
        title: 'مقارنة العروض',
        icon: Icons.compare_arrows_rounded,
        locked: !isPremium,
        onTap: () => _openComparison(context, ref, isPremium),
      ),
      HomeQuickActionItem(
        title: 'تصدير PDF',
        icon: Icons.picture_as_pdf_outlined,
        locked: !isPremium,
        onTap: () => _exportPdfFromHome(context, ref, isPremium),
      ),
    ];

    if (isSaudi) {
      items.add(
        HomeQuickActionItem(
          title: 'حاسبة الزيادة',
          icon: Icons.trending_up_rounded,
          onTap: () => context.push(AppRoutes.increase),
        ),
      );
    } else {
      items.add(
        HomeQuickActionItem(
          title: 'GPSSA / DEWS',
          icon: Icons.account_balance_rounded,
          onTap: () => context.push(AppRoutes.uae),
        ),
      );
    }

    return items;
  }

  Future<void> _openComparison(
    BuildContext context,
    WidgetRef ref,
    bool isPremium,
  ) async {
    if (isPremium) {
      context.push(AppRoutes.comparison);
      return;
    }
    await PremiumAccess.requirePremium(
      context,
      ref,
      feature: PremiumFeature.fullComparison,
    );
  }

  Future<void> _exportPdfFromHome(
    BuildContext context,
    WidgetRef ref,
    bool isPremium,
  ) async {
    if (!isPremium) {
      await PremiumAccess.requirePremium(
        context,
        ref,
        feature: PremiumFeature.pdfExport,
      );
      await PremiumAccess.showInterstitialIfFree(ref);
      if (!context.mounted) return;
      if (PremiumAccess.isPremium(ref)) {
        await _exportPdfFromHome(context, ref, true);
      }
      return;
    }

    final record = buildCurrentSalaryRecord(ref);
    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أدخل بيانات الراتب أولاً',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }

    try {
      await PdfService.exportAndShare(record);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذّر تصدير PDF',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    }
  }

  static Future<void> _shareResult(
    BuildContext context,
    WidgetRef ref, {
    required GulfCountry country,
    required GosiModel? gosi,
    required double uaeNet,
    required double uaeGross,
    required double uaeDeduction,
  }) async {
    final isSaudi = country == GulfCountry.saudiArabia;
    final hasData = isSaudi
        ? gosi != null && gosi.netSalary > 0
        : uaeNet > 0;

    if (!hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أدخل بيانات الراتب أولاً لمشاركة النتيجة',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }

    final data = isSaudi
        ? SalaryShareData(
            netSalary: gosi!.netSalary,
            grossSalary: gosi.totalGross,
            gosiDeduction: gosi.employeeGosi,
            date: DateTime.now(),
          )
        : SalaryShareData(
            netSalary: uaeNet,
            grossSalary: uaeGross,
            gosiDeduction: uaeDeduction,
            date: DateTime.now(),
          );

    try {
      await ref.read(shareServiceProvider).shareSalaryResult(
            context: context,
            data: data,
          );
    } on ShareException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message, style: GoogleFonts.cairo())),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذرت المشاركة. حاول مرة أخرى.',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    }
  }

  List<Widget> _gosiWarnings(GosiModel gosi) {
    if (!gosi.hasUpcomingWarning) return const [];
    return [
      _WarningBanner(message: gosi.upcomingWarning!.messageAr),
      if (gosi.upcomingWarnings.length > 1)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '+${gosi.upcomingWarnings.length - 1} زيادات مرحلية قادمة حتى 2028',
            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.warning),
          ),
        ),
    ];
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: GoogleFonts.cairo(fontSize: 13))),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.badge = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Tooltip(
        message: tooltip,
        child: GlassSurface(
          borderRadius: 14,
          blur: 8,
          onTap: onPressed,
          padding: const EdgeInsets.all(10),
          child: Badge(
            isLabelVisible: badge,
            backgroundColor: AppColors.gold,
            smallSize: 8,
            child: Icon(icon, size: 22),
          ),
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.cairo(fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
