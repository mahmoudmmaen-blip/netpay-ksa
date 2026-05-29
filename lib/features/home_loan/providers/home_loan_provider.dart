import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/utils/feature_hive_store.dart';
import 'package:netgulf/features/home_loan/domain/home_loan_calculator.dart';

const _hiveBox = 'home_loan';

class HomeLoanState {
  const HomeLoanState({
    this.country = GulfCountry.saudiArabia,
    this.propertyPrice = 0,
    this.downPaymentPercent = 20,
    this.annualInterestRate = 5.5,
    this.loanYears = 20,
    this.monthlySalary = 0,
    this.showSchedule = false,
  });

  final GulfCountry country;
  final double propertyPrice;
  final double downPaymentPercent;
  final double annualInterestRate;
  final int loanYears;
  final double monthlySalary;
  final bool showSchedule;

  HomeLoanInput get input => HomeLoanInput(
        country: country,
        propertyPrice: propertyPrice,
        downPaymentPercent: downPaymentPercent,
        annualInterestRate: annualInterestRate,
        loanYears: loanYears,
        monthlySalary: monthlySalary,
      );

  HomeLoanState copyWith({
    GulfCountry? country,
    double? propertyPrice,
    double? downPaymentPercent,
    double? annualInterestRate,
    int? loanYears,
    double? monthlySalary,
    bool? showSchedule,
  }) {
    return HomeLoanState(
      country: country ?? this.country,
      propertyPrice: propertyPrice ?? this.propertyPrice,
      downPaymentPercent: downPaymentPercent ?? this.downPaymentPercent,
      annualInterestRate: annualInterestRate ?? this.annualInterestRate,
      loanYears: loanYears ?? this.loanYears,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      showSchedule: showSchedule ?? this.showSchedule,
    );
  }
}

class HomeLoanNotifier extends StateNotifier<HomeLoanState> {
  HomeLoanNotifier() : super(const HomeLoanState()) {
    _load();
  }

  Future<void> _load() async {
    final price = await FeatureHiveStore.get<double>(_hiveBox, 'price');
    if (price != null) state = state.copyWith(propertyPrice: price);
  }

  void setCountry(GulfCountry c) {
    state = state.copyWith(
      country: c,
      annualInterestRate: HomeLoanCalculator.defaultRate(c),
    );
  }

  void setPropertyPrice(double v) {
    state = state.copyWith(propertyPrice: v);
    FeatureHiveStore.put(_hiveBox, 'price', v);
  }

  void setDownPayment(double p) =>
      state = state.copyWith(downPaymentPercent: p);

  void setRate(double r) => state = state.copyWith(annualInterestRate: r);

  void setYears(int y) => state = state.copyWith(loanYears: y);

  void setSalary(double s) => state = state.copyWith(monthlySalary: s);

  void toggleSchedule() =>
      state = state.copyWith(showSchedule: !state.showSchedule);
}

final homeLoanProvider =
    StateNotifierProvider<HomeLoanNotifier, HomeLoanState>(
  (ref) => HomeLoanNotifier(),
);

final homeLoanResultProvider = Provider<HomeLoanResult>((ref) {
  return HomeLoanCalculator.calculate(ref.watch(homeLoanProvider).input);
});
