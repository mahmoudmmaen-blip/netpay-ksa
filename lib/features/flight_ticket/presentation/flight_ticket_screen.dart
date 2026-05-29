import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/eosb/presentation/widgets/eosb_country_grid.dart';
import 'package:netgulf/features/flight_ticket/data/flight_ticket_rules.dart';
import 'package:netgulf/features/flight_ticket/providers/flight_ticket_provider.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';

class FlightTicketScreen extends ConsumerWidget {
  const FlightTicketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flightTicketProvider);
    final notifier = ref.read(flightTicketProvider.notifier);
    final rule = flightTicketRuleFor(state.country);
    final currency = NumberFormat.currency(
      locale: state.country.currencyLocale,
      symbol: state.country.currencySymbol,
      decimalDigits: 0,
    );

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
        title: Text('تذكرة السفر',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              EosbCountryGrid(
                selected: state.country,
                onSelected: notifier.setCountry,
              ),
              const SizedBox(height: 12),
              GlassSurface(
                borderRadius: 12,
                padding: const EdgeInsets.all(12),
                child: Text(rule.noteAr,
                    style: GoogleFonts.cairo(fontSize: 12, height: 1.4)),
              ),
              const SizedBox(height: 12),
              Text('تكرار الاستحقاق',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              SegmentedButton<FlightTicketFrequency>(
                segments: const [
                  ButtonSegment(
                    value: FlightTicketFrequency.annual,
                    label: Text('سنوي'),
                  ),
                  ButtonSegment(
                    value: FlightTicketFrequency.biennial,
                    label: Text('كل سنتين'),
                  ),
                ],
                selected: {state.frequency},
                onSelectionChanged: (s) => notifier.setFrequency(s.first),
              ),
              const SizedBox(height: 12),
              Text('أفراد العائلة (1–4)',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              Slider(
                value: state.familyMembers.toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                label: '${state.familyMembers}',
                onChanged: (v) => notifier.setFamily(v.round()),
              ),
              Text('وجهة السفر',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FlightDestinationRegion.values.map((r) {
                  final selected = state.region == r;
                  return FilterChip(
                    label: Text(flightRegionLabelAr(r),
                        style: GoogleFonts.cairo(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => notifier.setRegion(r),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              HomeSalaryField(
                label: 'تكلفة التذكرة (للفرد)',
                value: state.ticketCost,
                currencySymbol: state.country.currencySymbol,
                onChanged: notifier.setTicketCost,
              ),
              HomeSalaryField(
                label: 'راتبك الشهري (اختياري)',
                value: state.monthlySalary,
                currencySymbol: state.country.currencySymbol,
                onChanged: notifier.setMonthlySalary,
              ),
              const SizedBox(height: 20),
              GlassSurface(
                highlighted: true,
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('قيمة التذكرة السنوية',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                    Text(
                      currency.format(state.annualValue),
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.emerald,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يعادل ${currency.format(state.monthlyEquivalent)} شهرياً من راتبك',
                      style: GoogleFonts.cairo(fontSize: 13),
                    ),
                    if (state.monthlySalary > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'الحزمة السنوية مع التذكرة: ${currency.format(state.monthlySalary * 12 + state.annualValue)}',
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                    ],
                    const Divider(height: 20),
                    Text(
                      'قيمة التذكرة لا تدخل في احتساب GOSI أو نهاية الخدمة',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
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
