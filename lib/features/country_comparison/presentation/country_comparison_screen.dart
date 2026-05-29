import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/country_comparison/data/country_comparison_data.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';

class CountryComparisonScreen extends ConsumerStatefulWidget {
  const CountryComparisonScreen({super.key});

  @override
  ConsumerState<CountryComparisonScreen> createState() =>
      _CountryComparisonScreenState();
}

class _CountryComparisonScreenState
    extends ConsumerState<CountryComparisonScreen> {
  GulfCountry _a = GulfCountry.saudiArabia;
  GulfCountry _b = GulfCountry.uae;
  double _salary = 10000;
  List<ComparisonRow>? _rows;

  void _compare() {
    if (_a == _b) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('اختر دولتين مختلفتين', style: GoogleFonts.cairo()),
        ),
      );
      return;
    }
    setState(() {
      _rows = CountryComparisonEngine.compare(
        a: _a,
        b: _b,
        salary: _salary,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('مقارنة الدول',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _CountryPicker(
                            label: 'الدولة أ',
                            value: _a,
                            exclude: _b,
                            onChanged: (c) => setState(() => _a = c),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CountryPicker(
                            label: 'الدولة ب',
                            value: _b,
                            exclude: _a,
                            onChanged: (c) => setState(() => _b = c),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    HomeSalaryField(
                      label: 'الراتب للمقارنة',
                      value: _salary,
                      currencySymbol: _a.currencySymbol,
                      onChanged: (v) => setState(() => _salary = v),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _compare,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                        ),
                        child: Text('قارن',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    if (_rows != null) ...[
                      const SizedBox(height: 20),
                      _ComparisonTable(
                        countryA: _a,
                        countryB: _b,
                        rows: _rows!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryPicker extends StatelessWidget {
  const _CountryPicker({
    required this.label,
    required this.value,
    required this.exclude,
    required this.onChanged,
  });

  final String label;
  final GulfCountry value;
  final GulfCountry exclude;
  final ValueChanged<GulfCountry> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<GulfCountry>(
          isExpanded: true,
          value: value,
          items: GulfCountry.values
              .where((c) => c != exclude)
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text('${c.flag} ${c.nameAr}',
                      style: GoogleFonts.cairo(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (c) {
            if (c != null) onChanged(c);
          },
        ),
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({
    required this.countryA,
    required this.countryB,
    required this.rows,
  });

  final GulfCountry countryA;
  final GulfCountry countryB;
  final List<ComparisonRow> rows;

  double? _parseNum(String s) {
    final m = RegExp(r'[\d.]+').firstMatch(s.replaceAll(',', ''));
    return m != null ? double.tryParse(m.group(0)!) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text('${countryA.flag} ${countryA.nameAr}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: Text('${countryB.flag} ${countryB.nameAr}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...rows.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          final na = _parseNum(row.valueA);
          final nb = _parseNum(row.valueB);
          Widget? dotA;
          Widget? dotB;
          if (na != null && nb != null && na != nb) {
            final aBetter = row.higherIsBetter ? na > nb : na < nb;
            dotA = Icon(
              aBetter ? Icons.circle : Icons.circle_outlined,
              size: 10,
              color: aBetter ? Colors.green : Colors.red.withValues(alpha: 0.5),
            );
            dotB = Icon(
              !aBetter ? Icons.circle : Icons.circle_outlined,
              size: 10,
              color: !aBetter ? Colors.green : Colors.red.withValues(alpha: 0.5),
            );
          }
          return Container(
            color: i.isEven
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(row.label,
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ?dotA,
                    Expanded(
                      child: Text(row.valueA,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(fontSize: 12)),
                    ),
                    Expanded(
                      child: Text(row.valueB,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(fontSize: 12)),
                    ),
                    ?dotB,
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
