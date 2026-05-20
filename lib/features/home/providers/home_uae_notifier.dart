import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/features/uae/domain/models/uae_model.dart';

/// مدخلات حاسبة الإمارات على الشاشة الرئيسية.
class HomeUaeState extends Equatable {
  const HomeUaeState({
    this.basicSalary = 10000,
    this.housingAllowance = 3000,
    this.yearsOfService = 2,
    this.nationality = UAENationalityType.expat,
  });

  final double basicSalary;
  final double housingAllowance;
  final int yearsOfService;
  final UAENationalityType nationality;

  UaeModel get model => UaeModel(
        basicSalary: basicSalary,
        housingAllowance: housingAllowance,
        yearsOfService: yearsOfService,
        nationality: nationality,
      );

  HomeUaeState copyWith({
    double? basicSalary,
    double? housingAllowance,
    int? yearsOfService,
    UAENationalityType? nationality,
  }) {
    return HomeUaeState(
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      yearsOfService: yearsOfService ?? this.yearsOfService,
      nationality: nationality ?? this.nationality,
    );
  }

  @override
  List<Object?> get props =>
      [basicSalary, housingAllowance, yearsOfService, nationality];
}

class HomeUaeNotifier extends Notifier<HomeUaeState> {
  @override
  HomeUaeState build() => const HomeUaeState();

  void setBasic(double v) => state = state.copyWith(basicSalary: v);
  void setHousing(double v) => state = state.copyWith(housingAllowance: v);
  void setYears(int v) => state = state.copyWith(yearsOfService: v);
  void setNationality(UAENationalityType v) =>
      state = state.copyWith(nationality: v);
}

final homeUaeProvider =
    NotifierProvider<HomeUaeNotifier, HomeUaeState>(HomeUaeNotifier.new);

final homeUaeModelProvider = Provider<UaeModel>((ref) {
  return ref.watch(homeUaeProvider).model;
});
