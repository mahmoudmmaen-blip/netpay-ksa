import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/providers/theme_provider.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/core/services/premium_access.dart';
import 'package:netgulf/core/widgets/premium_badge.dart';
import 'package:netgulf/core/widgets/premium_gate_sheet.dart';
import 'package:netgulf/core/widgets/premium_mesh_background.dart';
import 'package:netgulf/features/admob/widgets/home_banner_ad.dart';
import 'package:netgulf/features/pdf_export/pdf_export_helper.dart';
import 'package:netgulf/features/pdf_export/pdf_service.dart';
import 'package:netgulf/features/home/presentation/widgets/home_quick_actions_row.dart';
import 'package:netgulf/features/home/presentation/widgets/home_screen_body.dart';
import 'package:netgulf/features/home/providers/home_salary_provider.dart';
import 'package:netgulf/core/providers/notification_provider.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';
import 'package:netgulf/features/share/providers/share_provider.dart';
import 'package:netgulf/features/share/share_service.dart';

/// الشاشة الرئيسية — حاسبة متعددة الدول (السعودية + الإمارات).
/// Home screen — multi-country salary calculator (Saudi + UAE).
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSaudi = ref.watch(homeIsSaudiProvider);
    final snapshot = ref.watch(homeSalarySnapshotProvider);
    final gosi = ref.watch(gosiModelProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final country = snapshot.country;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _HomeAppBarTitle(isDark: isDark),
        actions: [
          _GlassIconButton(
            tooltip: 'مشاركة النتيجة',
            icon: Icons.share_rounded,
            onPressed: () => _shareResult(context, ref, snapshot),
          ),
          if (isSaudi)
            _GlassIconButton(
              tooltip: 'التنبيهات',
              icon: Icons.notifications_none_rounded,
              badge: ref.watch(gosiAlertWithin30DaysProvider),
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
                child: HomeScreenBody(
                  scrollController: _scrollController,
                  isDark: isDark,
                  quickActions: HomeQuickActionsRow(
                    country: country,
                    items: _quickActionItems(context, ref, country, isPremium),
                  ),
                  gosiWarnings: isSaudi && gosi != null
                      ? [HomeGosiWarningBanner(gosi: gosi)]
                      : const [],
                ),
              ),
            ),
          ),
          if (ref.watch(showAdsProvider)) const HomeBannerAd(),
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
    WidgetRef ref,
    HomeSalarySnapshot snapshot,
  ) async {
    if (!snapshot.hasData) {
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

    try {
      await ref.read(shareServiceProvider).shareSalaryResult(
            context: context,
            data: snapshot.toShareData(),
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
}

/// عنوان AppBar — ذهبي في الداكن، زمردي في الفاتح.
class _HomeAppBarTitle extends StatelessWidget {
  const _HomeAppBarTitle({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.cairo(
      fontWeight: FontWeight.w800,
      fontSize: 20,
      color: isDark ? Colors.white : AppColors.emeraldDark,
    );

    if (!isDark) {
      return Text('NetGulf', style: style);
    }

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (b) => AppColors.goldGradient.createShader(b),
      child: Text('NetGulf', style: style.copyWith(color: Colors.white)),
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
