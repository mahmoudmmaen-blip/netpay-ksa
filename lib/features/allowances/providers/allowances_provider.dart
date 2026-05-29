import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/utils/feature_hive_store.dart';
import 'package:netgulf/features/allowances/domain/allowances_calculator.dart';

const _hiveBox = 'allowances';

class AllowancesState {
  const AllowancesState({
    this.country = GulfCountry.saudiArabia,
    this.basicSalary = 0,
    this.housingEnabled = true,
    this.housingAmount = 0,
    this.transportEnabled = true,
    this.transportAmount = 0,
    this.phoneEnabled = false,
    this.phoneAmount = 0,
    this.foodEnabled = false,
    this.foodAmount = 0,
    this.otherEnabled = false,
    this.otherAmount = 0,
  });

  final GulfCountry country;
  final double basicSalary;
  final bool housingEnabled;
  final double housingAmount;
  final bool transportEnabled;
  final double transportAmount;
  final bool phoneEnabled;
  final double phoneAmount;
  final bool foodEnabled;
  final double foodAmount;
  final bool otherEnabled;
  final double otherAmount;

  AllowancesInput get input => AllowancesInput(
        country: country,
        basicSalary: basicSalary,
        housingEnabled: housingEnabled,
        housingAmount: housingAmount,
        transportEnabled: transportEnabled,
        transportAmount: transportAmount,
        phoneEnabled: phoneEnabled,
        phoneAmount: phoneAmount,
        foodEnabled: foodEnabled,
        foodAmount: foodAmount,
        otherEnabled: otherEnabled,
        otherAmount: otherAmount,
      );

  AllowancesState copyWith({
    GulfCountry? country,
    double? basicSalary,
    bool? housingEnabled,
    double? housingAmount,
    bool? transportEnabled,
    double? transportAmount,
    bool? phoneEnabled,
    double? phoneAmount,
    bool? foodEnabled,
    double? foodAmount,
    bool? otherEnabled,
    double? otherAmount,
  }) {
    return AllowancesState(
      country: country ?? this.country,
      basicSalary: basicSalary ?? this.basicSalary,
      housingEnabled: housingEnabled ?? this.housingEnabled,
      housingAmount: housingAmount ?? this.housingAmount,
      transportEnabled: transportEnabled ?? this.transportEnabled,
      transportAmount: transportAmount ?? this.transportAmount,
      phoneEnabled: phoneEnabled ?? this.phoneEnabled,
      phoneAmount: phoneAmount ?? this.phoneAmount,
      foodEnabled: foodEnabled ?? this.foodEnabled,
      foodAmount: foodAmount ?? this.foodAmount,
      otherEnabled: otherEnabled ?? this.otherEnabled,
      otherAmount: otherAmount ?? this.otherAmount,
    );
  }
}

class AllowancesNotifier extends StateNotifier<AllowancesState> {
  AllowancesNotifier() : super(const AllowancesState()) {
    _load();
  }

  Future<void> _load() async {
    final basic = await FeatureHiveStore.get<double>(_hiveBox, 'basic');
    final countryName = await FeatureHiveStore.get<String>(_hiveBox, 'country');
    GulfCountry? country;
    if (countryName != null) {
      for (final c in GulfCountry.values) {
        if (c.name == countryName) {
          country = c;
          break;
        }
      }
    }
    state = state.copyWith(
      basicSalary: basic ?? state.basicSalary,
      country: country ?? state.country,
    );
  }

  Future<void> _persist() async {
    await FeatureHiveStore.put(_hiveBox, 'basic', state.basicSalary);
    await FeatureHiveStore.put(_hiveBox, 'country', state.country.name);
  }

  void setCountry(GulfCountry c) {
    state = state.copyWith(country: c);
    _persist();
  }

  void setBasic(double v) {
    state = state.copyWith(basicSalary: v);
    _persist();
  }

  void setHousing({bool? enabled, double? amount}) {
    state = state.copyWith(
      housingEnabled: enabled ?? state.housingEnabled,
      housingAmount: amount ?? state.housingAmount,
    );
  }

  void setTransport({bool? enabled, double? amount}) {
    state = state.copyWith(
      transportEnabled: enabled ?? state.transportEnabled,
      transportAmount: amount ?? state.transportAmount,
    );
  }

  void setPhone({bool? enabled, double? amount}) {
    state = state.copyWith(
      phoneEnabled: enabled ?? state.phoneEnabled,
      phoneAmount: amount ?? state.phoneAmount,
    );
  }

  void setFood({bool? enabled, double? amount}) {
    state = state.copyWith(
      foodEnabled: enabled ?? state.foodEnabled,
      foodAmount: amount ?? state.foodAmount,
    );
  }

  void setOther({bool? enabled, double? amount}) {
    state = state.copyWith(
      otherEnabled: enabled ?? state.otherEnabled,
      otherAmount: amount ?? state.otherAmount,
    );
  }
}

final allowancesProvider =
    StateNotifierProvider<AllowancesNotifier, AllowancesState>(
  (ref) => AllowancesNotifier(),
);

final allowancesResultProvider = Provider<AllowancesResult>((ref) {
  final s = ref.watch(allowancesProvider);
  return AllowancesCalculator.calculate(s.input);
});
