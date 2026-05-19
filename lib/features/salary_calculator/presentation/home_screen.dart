import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/providers/app_state_provider.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/features/gosi/domain/enums/gosi_regime.dart';
import 'package:netgulf/features/gosi/domain/enums/nationality_type.dart';
import 'package:netgulf/features/salary_calculator/models/gosi_model.dart';
import 'package:netgulf/features/admob/widgets/home_banner_ad.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';
import 'package:netgulf/features/notifications/providers/notifications_provider.dart';

/// الشاشة الرئيسية — حاسبة الراتب الصافي (Phase 1).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salary = ref.watch(salaryNotifierProvider);
    final gosi = ref.watch(gosiModelProvider);
    final showGosiBadge = ref.watch(gosiAlertWithin30DaysProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
      decimalDigits: 2,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'حاسبة الراتب الصافي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'التنبيهات',
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: showGosiBadge,
              backgroundColor: AppColors.emerald,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'تبديل الوضع',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () =>
                ref.read(appStateProvider.notifier).toggleDarkLight(),
          ),
          IconButton(
            tooltip: 'السجل',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push(AppRoutes.history),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.homeGradient(
                  Theme.of(context).brightness,
                ),
              ),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
              if (salary.hasError) _ErrorBanner(message: salary.errorMessage!),
              if (gosi != null) ..._warningBanners(gosi),
              _NetSalaryCard(
                net: gosi?.netSalary ?? 0,
                gross: gosi?.totalGross ?? salary.allowances.totalGross,
                employeeGosi: gosi?.employeeGosi ?? 0,
                currency: currency,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'تفاصيل الراتب', icon: Icons.payments_outlined),
              _SalaryField(
                key: const ValueKey('salary-basic'),
                label: 'الراتب الأساسي',
                value: salary.basicSalary,
                onChanged: (v) =>
                    ref.read(salaryNotifierProvider.notifier).setBasic(v),
              ),
              _SalaryField(
                key: const ValueKey('salary-housing'),
                label: 'بدل السكن',
                value: salary.housingAllowance,
                onChanged: (v) =>
                    ref.read(salaryNotifierProvider.notifier).setHousing(v),
              ),
              _SalaryField(
                key: const ValueKey('salary-other'),
                label: 'بدلات أخرى',
                value: salary.otherAllowances,
                onChanged: (v) =>
                    ref.read(salaryNotifierProvider.notifier).setOther(v),
              ),
              _GosiBaseSwitch(
                value: salary.includeOtherInGosiBase,
                onChanged: (v) => ref
                    .read(salaryNotifierProvider.notifier)
                    .setIncludeOtherInGosi(v),
              ),
              const SizedBox(height: 20),
              _SectionTitle(
                title: 'التأمينات الاجتماعية (GOSI)',
                icon: Icons.shield_outlined,
              ),
              Text(
                'الجنسية',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<NationalityType>(
                style: _segmentStyle(context),
                segments: const [
                  ButtonSegment(
                    value: NationalityType.saudi,
                    label: Text('سعودي'),
                    icon: Icon(Icons.flag_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: NationalityType.nonSaudi,
                    label: Text('غير سعودي'),
                    icon: Icon(Icons.public_rounded, size: 18),
                  ),
                ],
                selected: {salary.nationality},
                onSelectionChanged: (s) => ref
                    .read(salaryNotifierProvider.notifier)
                    .setNationality(s.first),
              ),
              const SizedBox(height: 14),
              Text(
                'نظام الاشتراك',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<GosiRegime>(
                style: _segmentStyle(context),
                segments: const [
                  ButtonSegment(
                    value: GosiRegime.legacy,
                    label: Text('قديم 9.75%'),
                  ),
                  ButtonSegment(
                    value: GosiRegime.newLawPhased,
                    label: Text('جديد 2026'),
                  ),
                ],
                selected: {salary.regime},
                onSelectionChanged: (s) => ref
                    .read(salaryNotifierProvider.notifier)
                    .setRegime(s.first),
              ),
              if (gosi != null) ...[
                const SizedBox(height: 20),
                _GosiBreakdownCard(gosi: gosi, currency: currency),
              ],
              const SizedBox(height: 20),
              _FeatureNavCard(
                title: 'نهاية الخدمة والمستحقات',
                subtitle: 'مكافأة · إجازة · تذكرة سفر (م. 84/85)',
                icon: Icons.card_giftcard_outlined,
                onTap: () => context.push(AppRoutes.eosb),
              ),
              const SizedBox(height: 12),
              _FeatureNavCard(
                title: 'مقارنة العروض',
                subtitle: 'قارن صافي راتبين بعد GOSI',
                icon: Icons.compare_arrows_rounded,
                onTap: () => context.push(AppRoutes.comparison),
              ),
              const SizedBox(height: 12),
              _FeatureNavCard(
                title: 'حاسبة الزيادة',
                subtitle: 'أثر الزيادة على الصافي و GOSI',
                icon: Icons.trending_up_rounded,
                onTap: () => context.push(AppRoutes.increase),
              ),
              const SizedBox(height: 12),
              _FeatureNavCard(
                title: '🇦🇪 الإمارات — GPSSA / DEWS',
                subtitle: 'حاسبة الراتب الإماراتية',
                icon: Icons.flag_circle_outlined,
                onTap: () => context.push(AppRoutes.uae),
              ),
                  ],
                ),
              ),
            ),
          ),
          const HomeBannerAd(),
        ],
      ),
    );
  }

  ButtonStyle _segmentStyle(BuildContext context) {
    return ButtonStyle(
      visualDensity: VisualDensity.compact,
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  List<Widget> _warningBanners(GosiModel gosi) {
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

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.emerald),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetSalaryCard extends StatelessWidget {
  const _NetSalaryCard({
    required this.net,
    required this.gross,
    required this.employeeGosi,
    required this.currency,
    required this.isDark,
  });

  final double net;
  final double gross;
  final double employeeGosi;
  final NumberFormat currency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow(isDark: isDark),
      ),
      child: Column(
        children: [
          Text(
            'صافي الراتب',
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currency.format(net),
            style: GoogleFonts.cairo(
              color: AppColors.goldBright,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(label: 'الإجمالي', value: currency.format(gross)),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                _StatChip(label: 'خصم GOSI', value: currency.format(employeeGosi)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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

class _FeatureNavCard extends StatelessWidget {
  const _FeatureNavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.emerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.emerald,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GosiBaseSwitch extends StatelessWidget {
  const _GosiBaseSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(
          'إدراج البدلات الأخرى في أجر الاشتراك',
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        subtitle: Text(
          'يؤثر على قاعدة حساب GOSI فقط',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        activeThumbColor: AppColors.emerald,
        onChanged: onChanged,
      ),
    );
  }
}

class _SalaryField extends StatefulWidget {
  const _SalaryField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_SalaryField> createState() => _SalaryFieldState();
}

class _SalaryFieldState extends State<_SalaryField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _SalaryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;

    // لا تُعاد كتابة الحقل أثناء الكتابة — يمنع فقدان التركيز والقيمة.
    if (_focusNode.hasFocus) return;

    final formatted = _format(widget.value);
    if (_controller.text != formatted) {
      _controller.text = formatted;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _format(double v) => v > 0 ? v.toStringAsFixed(0) : '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: GoogleFonts.cairo(),
          suffixText: 'ر.س',
          prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
          filled: true,
        ),
        onChanged: (t) => widget.onChanged(double.tryParse(t) ?? 0),
      ),
    );
  }
}

class _GosiBreakdownCard extends StatelessWidget {
  const _GosiBreakdownCard({required this.gosi, required this.currency});
  final GosiModel gosi;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final phaseLabel = gosi.activePhaseYear != null
        ? 'مرحلة يوليو ${gosi.activePhaseYear}'
        : 'النظام القديم (9.75%)';

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.emerald.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 20, color: AppColors.emerald),
                const SizedBox(width: 8),
                Text(
                  'تفصيل GOSI',
                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    phaseLabel,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('خصم الموظف (${gosi.employeeRatePercent}%)',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _BreakdownRow('تقاعد', currency.format(gosi.employeePension)),
            _BreakdownRow('ساند (SANED)', currency.format(gosi.employeeSaned)),
            _BreakdownRow('إجمالي خصم الموظف', currency.format(gosi.employeeGosi), bold: true),
            const Divider(height: 24),
            Text('اشتراك صاحب العمل (${gosi.employerRatePercent}%)',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _BreakdownRow('تقاعد', currency.format(gosi.employerPension)),
            _BreakdownRow('أخطار مهنية', currency.format(gosi.employerHazard)),
            _BreakdownRow('ساند', currency.format(gosi.employerSaned)),
            _BreakdownRow('إجمالي صاحب العمل', currency.format(gosi.employerGosi), bold: true),
            const Divider(height: 24),
            _BreakdownRow('أجر الاشتراك', currency.format(gosi.subscriptionWage)),
            _BreakdownRow(
              'بعد السقف (${GosiModel.wageCeiling.toInt()} ر.س)',
              currency.format(gosi.contributableWage),
              bold: true,
            ),
            if (gosi.wageCeilingApplied)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'تم تطبيق سقف 45,000 ر.س على أجر الاشتراك',
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}