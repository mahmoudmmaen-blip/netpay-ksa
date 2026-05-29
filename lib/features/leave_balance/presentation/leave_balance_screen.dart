import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';
import 'package:netgulf/features/leave_balance/domain/leave_balance_calculator.dart';
import 'package:netgulf/features/leave_balance/domain/leave_balance_model.dart';
import 'package:netgulf/features/leave_balance/providers/leave_balance_provider.dart';

/// حاسبة رصيد الإجازة السنوية — ٦ دول خليجية.
class LeaveBalanceScreen extends ConsumerWidget {
  const LeaveBalanceScreen({
    super.key,
    this.embeddedInHub = false,
  });

  final bool embeddedInHub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(leaveBalanceProvider);
    final notifier = ref.read(leaveBalanceProvider.notifier);
    final currency = NumberFormat.currency(
      locale: model.country.currencyLocale,
      symbol: model.country.currencySymbol,
      decimalDigits: 2,
    );

    final body = _LeaveBalanceBody(
      model: model,
      notifier: notifier,
      currency: currency,
    );

    if (embeddedInHub) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(top: false, child: body),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.home),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رصيد الإجازة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              'الاستحقاق السنوي + القيمة النقدية للأيام المتبقية',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(child: body),
      ),
    );
  }
}

class _LeaveBalanceBody extends StatelessWidget {
  const _LeaveBalanceBody({
    required this.model,
    required this.notifier,
    required this.currency,
  });

  final LeaveBalanceModel model;
  final LeaveBalanceNotifier notifier;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'اختر دولة العمل',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 10),
        _LeaveCountryGrid(
          selected: model.country,
          onSelected: (c) {
            HapticFeedback.selectionClick();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifier.setCountry(c);
            });
          },
        ),
        const SizedBox(height: 12),
        GlassSurface(
          borderRadius: 14,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.gavel_rounded, color: AppColors.emerald, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      model.legalReference,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LeaveBalanceCalculator.rulesSummary(model.country),
                      style: GoogleFonts.cairo(fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'مدة الخدمة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _ServiceDurationRow(
          key: ValueKey('leave-service-${model.country.name}'),
          years: model.serviceYears,
          months: model.serviceMonths,
          onYearsChanged: notifier.setServiceYears,
          onMonthsChanged: notifier.setServiceMonths,
        ),
        const SizedBox(height: 16),
        HomeSalaryField(
          key: ValueKey('leave-basic-${model.country.name}'),
          label: 'الراتب الأساسي الشهري',
          value: model.basicSalary,
          currencySymbol: currency.currencySymbol,
          countryFlag: model.country.flag,
          onChanged: notifier.setBasicSalary,
        ),
        if (model.showsHousingAllowance) ...[
          HomeSalaryField(
            key: ValueKey('leave-housing-${model.country.name}'),
            label: 'بدل السكن الشهري',
            value: model.housingAllowance,
            currencySymbol: currency.currencySymbol,
            countryFlag: model.country.flag,
            onChanged: notifier.setHousingAllowance,
          ),
        ],
        const SizedBox(height: 8),
        _LeaveDaysRow(
          key: ValueKey('leave-days-${model.country.name}'),
          usedDays: model.usedLeaveDays,
          pendingDays: model.pendingLeaveDays,
          onUsedChanged: notifier.setUsedLeaveDays,
          onPendingChanged: notifier.setPendingLeaveDays,
        ),
        const SizedBox(height: 20),
        _ResultCard(model: model, currency: currency),
      ],
    );
  }
}

class _LeaveCountryGrid extends StatelessWidget {
  const _LeaveCountryGrid({
    required this.selected,
    required this.onSelected,
  });

  final GulfCountry selected;
  final ValueChanged<GulfCountry> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: GulfCountry.values.length,
      itemBuilder: (context, index) {
        final country = GulfCountry.values[index];
        final isSelected = country == selected;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(country),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.emerald
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? AppColors.emerald.withValues(alpha: 0.12)
                    : Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(country.flag, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 4),
                  Text(
                    country.nameAr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.emerald : null,
                    ),
                  ),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.emerald,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ServiceDurationRow extends StatefulWidget {
  const _ServiceDurationRow({
    super.key,
    required this.years,
    required this.months,
    required this.onYearsChanged,
    required this.onMonthsChanged,
  });

  final int years;
  final int months;
  final ValueChanged<int> onYearsChanged;
  final ValueChanged<int> onMonthsChanged;

  @override
  State<_ServiceDurationRow> createState() => _ServiceDurationRowState();
}

class _ServiceDurationRowState extends State<_ServiceDurationRow> {
  late final TextEditingController _yearsCtrl;
  late final TextEditingController _monthsCtrl;

  @override
  void initState() {
    super.initState();
    _yearsCtrl = TextEditingController(text: '${widget.years}');
    _monthsCtrl = TextEditingController(text: '${widget.months}');
  }

  @override
  void didUpdateWidget(covariant _ServiceDurationRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.years != widget.years &&
        _yearsCtrl.text != '${widget.years}') {
      _yearsCtrl.text = '${widget.years}';
    }
    if (oldWidget.months != widget.months &&
        _monthsCtrl.text != '${widget.months}') {
      _monthsCtrl.text = '${widget.months}';
    }
  }

  @override
  void dispose() {
    _yearsCtrl.dispose();
    _monthsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _IntField(
            controller: _yearsCtrl,
            label: 'سنوات (0–40)',
            onChanged: widget.onYearsChanged,
            max: 40,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _IntField(
            controller: _monthsCtrl,
            label: 'شهور (0–11)',
            onChanged: widget.onMonthsChanged,
            max: 11,
          ),
        ),
      ],
    );
  }
}

class _LeaveDaysRow extends StatefulWidget {
  const _LeaveDaysRow({
    super.key,
    required this.usedDays,
    required this.pendingDays,
    required this.onUsedChanged,
    required this.onPendingChanged,
  });

  final int usedDays;
  final int pendingDays;
  final ValueChanged<int> onUsedChanged;
  final ValueChanged<int> onPendingChanged;

  @override
  State<_LeaveDaysRow> createState() => _LeaveDaysRowState();
}

class _LeaveDaysRowState extends State<_LeaveDaysRow> {
  late final TextEditingController _usedCtrl;
  late final TextEditingController _pendingCtrl;

  @override
  void initState() {
    super.initState();
    _usedCtrl = TextEditingController(text: '${widget.usedDays}');
    _pendingCtrl = TextEditingController(text: '${widget.pendingDays}');
  }

  @override
  void didUpdateWidget(covariant _LeaveDaysRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.usedDays != widget.usedDays &&
        _usedCtrl.text != '${widget.usedDays}') {
      _usedCtrl.text = '${widget.usedDays}';
    }
    if (oldWidget.pendingDays != widget.pendingDays &&
        _pendingCtrl.text != '${widget.pendingDays}') {
      _pendingCtrl.text = '${widget.pendingDays}';
    }
  }

  @override
  void dispose() {
    _usedCtrl.dispose();
    _pendingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'أيام الإجازة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _IntField(
                controller: _usedCtrl,
                label: 'مستخدمة هذه السنة',
                onChanged: widget.onUsedChanged,
                max: 365,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _IntField(
                controller: _pendingCtrl,
                label: 'متبقية (غير مستخدمة)',
                onChanged: widget.onPendingChanged,
                max: 365,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IntField extends StatelessWidget {
  const _IntField({
    required this.controller,
    required this.label,
    required this.onChanged,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<int> onChanged;
  final int max;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        onChanged: (t) => onChanged((int.tryParse(t) ?? 0).clamp(0, max)),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.model,
    required this.currency,
  });

  final LeaveBalanceModel model;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final hasWage = model.dailyWage > 0;

    return GlassSurface(
      highlighted: true,
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.beach_access_rounded,
                color: AppColors.emerald,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'رصيد الإجازة — ${model.country.nameAr}',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ResultRow(
            label: 'الاستحقاق السنوي',
            value: '${model.annualEntitlementDays} يوم',
            highlight: true,
          ),
          _ResultRow(
            label: 'مستخدمة هذه السنة',
            value: '${model.usedLeaveDays} يوم',
          ),
          _ResultRow(
            label: 'متبقية (غير مستخدمة)',
            value: '${model.pendingLeaveDays} يوم',
          ),
          if (model.serviceMonths > 0)
            _ResultRow(
              label: 'مستحق من السنة الحالية (تقريبي)',
              value: model.accruedThisYear.toStringAsFixed(1),
            ),
          const Divider(height: 24),
          _ResultRow(
            label: 'الأجر اليومي',
            value: hasWage ? currency.format(model.dailyWage) : '—',
          ),
          Text(
            LeaveBalanceCalculator.wageBaseLabel(model.country),
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _ResultRow(
            label: 'قيمة الأيام المتبقية نقداً',
            value: hasWage && model.pendingLeaveDays > 0
                ? currency.format(model.cashValue)
                : (hasWage ? currency.format(0) : '—'),
            bold: true,
            highlight: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              model.legalReference,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 11,
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

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.cairo(fontSize: 13)),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.emerald : null,
            ),
          ),
        ],
      ),
    );
  }
}
