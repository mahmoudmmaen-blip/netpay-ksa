import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/providers/gulf_country_provider.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';
import 'package:netgulf/features/salary_calculator/providers/uae_salary_provider.dart';
import 'package:netgulf/features/share/widgets/salary_share_card.dart';

/// لقطة الراتب على الشاشة الرئيسية — country-aware hero card data.
/// Home salary snapshot — unified net/gross/deduction for the active country.
class HomeSalarySnapshot {
  const HomeSalarySnapshot({
    required this.country,
    required this.net,
    required this.gross,
    required this.deduction,
  });

  final GulfCountry country;
  final double net;
  final double gross;
  final double deduction;

  bool get hasData => net > 0;
  bool get isSaudi => country == GulfCountry.saudiArabia;
  bool get isUae => country == GulfCountry.uae;

  /// بيانات المشاركة — share payload from snapshot values.
  SalaryShareData toShareData() => SalaryShareData(
        netSalary: net,
        grossSalary: gross,
        gosiDeduction: deduction,
        date: DateTime.now(),
      );
}

/// تنسيق العملة حسب الدولة المختارة — currency formatter by selected country.
final homeCurrencyFormatProvider = Provider<NumberFormat>((ref) {
  final country = ref.watch(gulfCountryProvider);
  return NumberFormat.currency(
    locale: country.currencyLocale,
    symbol: country.currencySymbol,
    decimalDigits: 2,
  );
});

/// لقطة موحّدة للراتب — Saudi GOSI أو UAE GPSSA/DEWS.
/// Unified home salary snapshot — routes to the active country's calculator.
final homeSalarySnapshotProvider = Provider<HomeSalarySnapshot>((ref) {
  final country = ref.watch(gulfCountryProvider);

  if (country == GulfCountry.saudiArabia) {
    final salary = ref.watch(salaryNotifierProvider);
    final gosi = ref.watch(gosiModelProvider);
    return HomeSalarySnapshot(
      country: country,
      net: gosi?.netSalary ?? 0,
      gross: gosi?.totalGross ?? salary.allowances.totalGross,
      deduction: gosi?.employeeGosi ?? 0,
    );
  }

  final uae = ref.watch(uaeSalaryModelProvider);
  return HomeSalarySnapshot(
    country: country,
    net: uae.netSalary,
    gross: uae.totalGross,
    deduction: uae.totalMonthlyDeductions,
  );
});

/// هل الدولة الحالية السعودية — convenience for Saudi-only UI.
final homeIsSaudiProvider = Provider<bool>((ref) {
  return ref.watch(gulfCountryProvider) == GulfCountry.saudiArabia;
});
