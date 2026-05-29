import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/utils/feature_hive_store.dart';
import 'package:netgulf/features/salary_distribution/domain/salary_distribution_calculator.dart';

const _hiveBox = 'salary_distribution';

class SalaryDistributionState {
  const SalaryDistributionState({
    this.netSalary = 0,
    this.mode = DistributionMode.classic503020,
    this.needsPercent = 50,
    this.wantsPercent = 30,
    this.savingsPercent = 20,
    this.rent = 0,
    this.savingsYears = 5,
  });

  final double netSalary;
  final DistributionMode mode;
  final double needsPercent;
  final double wantsPercent;
  final double savingsPercent;
  final double rent;
  final int savingsYears;

  SalaryDistributionInput get input => SalaryDistributionInput(
        netSalary: netSalary,
        mode: mode,
        needsPercent: needsPercent,
        wantsPercent: wantsPercent,
        savingsPercent: savingsPercent,
        rent: rent,
        savingsYears: savingsYears,
      );

  SalaryDistributionState copyWith({
    double? netSalary,
    DistributionMode? mode,
    double? needsPercent,
    double? wantsPercent,
    double? savingsPercent,
    double? rent,
    int? savingsYears,
  }) {
    return SalaryDistributionState(
      netSalary: netSalary ?? this.netSalary,
      mode: mode ?? this.mode,
      needsPercent: needsPercent ?? this.needsPercent,
      wantsPercent: wantsPercent ?? this.wantsPercent,
      savingsPercent: savingsPercent ?? this.savingsPercent,
      rent: rent ?? this.rent,
      savingsYears: savingsYears ?? this.savingsYears,
    );
  }
}

class SalaryDistributionNotifier extends StateNotifier<SalaryDistributionState> {
  SalaryDistributionNotifier() : super(const SalaryDistributionState()) {
    _load();
  }

  Future<void> _load() async {
    final net = await FeatureHiveStore.get<double>(_hiveBox, 'net');
    if (net != null) state = state.copyWith(netSalary: net);
  }

  void setNet(double v) {
    state = state.copyWith(netSalary: v);
    FeatureHiveStore.put(_hiveBox, 'net', v);
  }

  void setMode(DistributionMode m) => state = state.copyWith(mode: m);

  void setNeeds(double p) => state = state.copyWith(needsPercent: p);

  void setWants(double p) => state = state.copyWith(wantsPercent: p);

  void setSavings(double p) => state = state.copyWith(savingsPercent: p);

  void setRent(double r) => state = state.copyWith(rent: r);

  void setYears(int y) => state = state.copyWith(savingsYears: y);
}

final salaryDistributionProvider =
    StateNotifierProvider<SalaryDistributionNotifier, SalaryDistributionState>(
  (ref) => SalaryDistributionNotifier(),
);

final salaryDistributionResultProvider =
    Provider<SalaryDistributionResult>((ref) {
  return SalaryDistributionCalculator.calculate(
    ref.watch(salaryDistributionProvider).input,
  );
});
