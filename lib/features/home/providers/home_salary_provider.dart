import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/providers/gulf_country_provider.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';
import 'package:netgulf/features/salary_calculator/providers/uae_salary_provider.dart';
import 'package:netgulf/features/share/widgets/salary_share_card.dart';

/// لقطة الراتب على الشاشة الرئيسية — country-aware hero card data.
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
  bool get isSimpleGcc =>
      country == GulfCountry.oman ||
      country == GulfCountry.qatar ||
      country == GulfCountry.bahrain ||
      country == GulfCountry.kuwait;

  SalaryShareData toShareData() => SalaryShareData(
        netSalary: net,
        grossSalary: gross,
        gosiDeduction: deduction,
        date: DateTime.now(),
      );
}

/// الدولة النشطة على الشاشة الرئيسية.
final homeCountryProvider = Provider<GulfCountry>((ref) {
  return ref.watch(gulfCountryProvider);
});

/// تنسيق العملة حسب الدولة المختارة.
final homeCurrencyFormatProvider = Provider<NumberFormat>((ref) {
  final country = ref.watch(gulfCountryProvider);
  return NumberFormat.currency(
    locale: country.currencyLocale,
    symbol: country.currencySymbol,
    decimalDigits: 2,
  );
});

/// حالة الراتب البسيط (عمان، قطر، البحرين، الكويت) — بدون اقتطاع تأمين.
class SimpleCountrySalaryState {
  const SimpleCountrySalaryState({
    this.basicSalary = 0,
    this.housingAllowance = 0,
    this.otherAllowances = 0,
  });

  final double basicSalary;
  final double housingAllowance;
  final double otherAllowances;

  double get totalGross =>
      basicSalary + housingAllowance + otherAllowances;
}

class SimpleCountrySalaryNotifier
    extends StateNotifier<SimpleCountrySalaryState> {
  SimpleCountrySalaryNotifier() : super(const SimpleCountrySalaryState());

  void setBasic(double v) => state = SimpleCountrySalaryState(
        basicSalary: v,
        housingAllowance: state.housingAllowance,
        otherAllowances: state.otherAllowances,
      );

  void setHousing(double v) => state = SimpleCountrySalaryState(
        basicSalary: state.basicSalary,
        housingAllowance: v,
        otherAllowances: state.otherAllowances,
      );

  void setOther(double v) => state = SimpleCountrySalaryState(
        basicSalary: state.basicSalary,
        housingAllowance: state.housingAllowance,
        otherAllowances: v,
      );
}

final simpleCountrySalaryProvider = StateNotifierProvider<
    SimpleCountrySalaryNotifier, SimpleCountrySalaryState>(
  (ref) => SimpleCountrySalaryNotifier(),
);

/// لقطة موحّدة للراتب — ٦ دول خليجية.
final homeSalarySnapshotProvider = Provider<HomeSalarySnapshot>((ref) {
  final country = ref.watch(gulfCountryProvider);

  return switch (country) {
    GulfCountry.saudiArabia => _buildSaudiSnapshot(ref, country),
    GulfCountry.uae => _buildUaeSnapshot(ref, country),
    _ => _buildSimpleSnapshot(ref, country),
  };
});

HomeSalarySnapshot _buildSaudiSnapshot(Ref ref, GulfCountry country) {
  final salary = ref.watch(salaryNotifierProvider);
  final gosi = ref.watch(gosiModelProvider);
  return HomeSalarySnapshot(
    country: country,
    net: gosi?.netSalary ?? 0,
    gross: gosi?.totalGross ?? salary.allowances.totalGross,
    deduction: gosi?.employeeGosi ?? 0,
  );
}

HomeSalarySnapshot _buildUaeSnapshot(Ref ref, GulfCountry country) {
  final uae = ref.watch(uaeSalaryModelProvider);
  return HomeSalarySnapshot(
    country: country,
    net: uae.netSalary,
    gross: uae.totalGross,
    deduction: uae.totalMonthlyDeductions,
  );
}

HomeSalarySnapshot _buildSimpleSnapshot(Ref ref, GulfCountry country) {
  final simple = ref.watch(simpleCountrySalaryProvider);
  return HomeSalarySnapshot(
    country: country,
    net: simple.totalGross,
    gross: simple.totalGross,
    deduction: 0,
  );
}

/// هل الدولة الحالية السعودية — GOSI وتنبيهات فقط.
final homeIsSaudiProvider = Provider<bool>((ref) {
  return ref.watch(gulfCountryProvider) == GulfCountry.saudiArabia;
});
