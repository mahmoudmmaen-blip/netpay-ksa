import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/providers/gulf_country_provider.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/features/home/presentation/widgets/gulf_country_selector.dart';
import 'package:netgulf/features/home/presentation/widgets/home_net_salary_card.dart';
import 'package:netgulf/features/home/presentation/widgets/home_screen_header.dart';
import 'package:netgulf/features/home/presentation/widgets/saudi_home_section.dart';
import 'package:netgulf/features/home/presentation/widgets/uae_home_section.dart';
import 'package:netgulf/features/home/providers/home_salary_provider.dart';
import 'package:netgulf/features/salary_calculator/models/gosi_model.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';
import 'package:netgulf/core/widgets/premium_upgrade_button.dart';

/// محتوى الشاشة الرئيسية — محور الدولة + بطاقة الراتب + قسم الحاسبة.
/// Home scrollable body — country selector, hero card, country-specific calculator.
class HomeScreenBody extends ConsumerWidget {
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

  static const _sectionSpacing = 20.0;
  static const _switchDuration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final country = ref.watch(gulfCountryProvider);
    final snapshot = ref.watch(homeSalarySnapshotProvider);
    final currency = ref.watch(homeCurrencyFormatProvider);
    final isSaudi = snapshot.isSaudi;
    final salary = ref.watch(salaryNotifierProvider);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        GulfCountrySelector(
          selected: country,
          onSelected: (c) =>
              ref.read(gulfCountryProvider.notifier).setCountry(c),
        ),
        const SizedBox(height: _sectionSpacing),
        HomeScreenHeader(country: country),
        const SizedBox(height: _sectionSpacing),
        AnimatedSwitcher(
          duration: _switchDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: _fadeSlideTransition,
          child: HomeNetSalaryCard(
            key: ValueKey(country),
            country: country,
            net: snapshot.net,
            gross: snapshot.gross,
            deduction: snapshot.deduction,
            isDark: isDark,
            formatValue: currency.format,
          ),
        ),
        const SizedBox(height: 16),
        const PremiumUpgradeButton(),
        const SizedBox(height: 24),
        quickActions,
        const SizedBox(height: 28),
        if (isSaudi && salary.hasError)
          _HomeErrorBanner(message: salary.errorMessage!),
        ...gosiWarnings,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: _fadeSlideTransition,
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
    );
  }

  static Widget _fadeSlideTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
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
