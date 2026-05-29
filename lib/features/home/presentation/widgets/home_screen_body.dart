import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/providers/gulf_country_provider.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/premium_gate_sheet.dart';
import 'package:netgulf/core/widgets/premium_upgrade_button.dart';
import 'package:netgulf/features/home/presentation/widgets/gulf_country_selector.dart';
import 'package:netgulf/features/home/presentation/widgets/home_net_salary_card.dart';
import 'package:netgulf/features/home/presentation/widgets/home_page_transitions.dart';
import 'package:netgulf/features/home/presentation/widgets/home_screen_header.dart';
import 'package:netgulf/features/home/presentation/widgets/saudi_home_section.dart';
import 'package:netgulf/features/home/presentation/widgets/simple_country_section.dart';
import 'package:netgulf/features/home/presentation/widgets/uae_home_section.dart';
import 'package:netgulf/features/home/providers/home_salary_provider.dart';
import 'package:netgulf/features/salary_calculator/models/gosi_model.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';

/// محتوى الشاشة الرئيسية — محور الدولة + بطاقة الراتب + قسم الحاسبة.
/// Home scrollable body — country selector, hero card, country-specific calculator.
class HomeScreenBody extends ConsumerStatefulWidget {
  const HomeScreenBody({
    super.key,
    required this.scrollController,
    required this.isDark,
    required this.quickActions,
    this.gosiWarnings = const [],
  });

  final ScrollController scrollController;
  final bool isDark;
  final Widget quickActions;
  final List<Widget> gosiWarnings;

  static const _horizontalPadding = 20.0;
  static const _bottomPadding = 32.0;
  static const _sectionSpacing = 20.0;

  @override
  ConsumerState<HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends ConsumerState<HomeScreenBody> {
  @override
  Widget build(BuildContext context) {
    ref.listen<GulfCountry>(gulfCountryProvider, (previous, next) {
      if (previous != null && previous != next && widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });

    final country = ref.watch(gulfCountryProvider);
    final snapshot = ref.watch(homeSalarySnapshotProvider);
    final currency = ref.watch(homeCurrencyFormatProvider);
    final isSaudi = snapshot.isSaudi;
    final isPremium = ref.watch(isPremiumProvider);
    final salary = ref.watch(salaryNotifierProvider);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
        HomeScreenBody._horizontalPadding,
        4,
        HomeScreenBody._horizontalPadding,
        HomeScreenBody._bottomPadding,
      ),
      children: [
        // ── 1. Country selector (top) ──
        GulfCountrySelector(
          selected: country,
          onSelected: (c) =>
              ref.read(gulfCountryProvider.notifier).setCountry(c),
        ),
        const SizedBox(height: HomeScreenBody._sectionSpacing),

        // ── 2. Header (title + currency) ──
        HomeScreenHeader(country: country),
        const SizedBox(height: HomeScreenBody._sectionSpacing),

        // ── 3. Hero salary card ──
        AnimatedSwitcher(
          duration: HomePageTransitions.switchDuration,
          switchInCurve: HomePageTransitions.switchCurve,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: HomePageTransitions.fadeSlide,
          child: HomeNetSalaryCard(
            key: ValueKey('hero-${country.nameEn}'),
            country: country,
            net: snapshot.net,
            gross: snapshot.gross,
            deduction: snapshot.deduction,
            isDark: widget.isDark,
            formatValue: currency.format,
          ),
        ),

        if (!isPremium) ...[
          const SizedBox(height: 16),
          PremiumUpgradeButton(
            onPressed: () => showPremiumGate(
              context,
              feature: PremiumFeature.pdfExport,
            ),
          ),
        ],
        const SizedBox(height: 24),

        // ── 4. Quick actions ──
        AnimatedSwitcher(
          duration: HomePageTransitions.switchDuration,
          switchInCurve: HomePageTransitions.switchCurve,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: HomePageTransitions.fadeSlide,
          child: KeyedSubtree(
            key: ValueKey('actions-${country.nameEn}'),
            child: widget.quickActions,
          ),
        ),
        const SizedBox(height: 28),

        if (isSaudi && salary.hasError)
          _HomeErrorBanner(message: salary.errorMessage!),
        ...widget.gosiWarnings,

        // ── 5. Calculator section ──
        _HomeSectionLabel(
          titleAr: country.calculatorTitleAr,
          titleEn: country.schemeShort,
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: HomePageTransitions.switchDuration,
          switchInCurve: HomePageTransitions.switchCurve,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: HomePageTransitions.fadeSlideHorizontal,
          child: switch (country) {
            GulfCountry.saudiArabia => SaudiHomeSection(
                key: ValueKey(GulfCountry.saudiArabia),
                country: country,
                currency: currency,
              ),
            GulfCountry.uae => UaeHomeSection(
                key: ValueKey(GulfCountry.uae),
                country: country,
                currency: currency,
              ),
            _ => SimpleCountrySection(
                key: ValueKey(country),
                country: country,
                currency: currency,
              ),
          },
        ),
      ],
    );
  }
}

/// عنوان قسم — visual hierarchy divider.
class _HomeSectionLabel extends StatelessWidget {
  const _HomeSectionLabel({
    required this.titleAr,
    required this.titleEn,
  });

  final String titleAr;
  final String titleEn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: AppColors.emerald.withValues(alpha: 0.25),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.calculate_outlined,
                size: 18,
                color: AppColors.emerald.withValues(alpha: 0.8),
              ),
            ),
            Expanded(
              child: Divider(
                color: AppColors.emerald.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          titleAr,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          titleEn,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HomeErrorBanner extends StatelessWidget {
  const _HomeErrorBanner({required this.message});

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

/// تنبيه GOSI — Saudi-only warning banner.
class HomeGosiWarningBanner extends StatelessWidget {
  const HomeGosiWarningBanner({super.key, required this.gosi});

  final GosiModel gosi;

  @override
  Widget build(BuildContext context) {
    if (!gosi.hasUpcomingWarning) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HomeWarningBanner(message: gosi.upcomingWarning!.messageAr),
        if (gosi.upcomingWarnings.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '+${gosi.upcomingWarnings.length - 1} زيادات مرحلية قادمة حتى 2028',
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.warning),
            ),
          ),
      ],
    );
  }
}

class _HomeWarningBanner extends StatelessWidget {
  const _HomeWarningBanner({required this.message});

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
