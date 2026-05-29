import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/leave_balance/domain/leave_balance_model.dart';

final leaveBalanceProvider =
    StateNotifierProvider<LeaveBalanceNotifier, LeaveBalanceModel>(
  (ref) => LeaveBalanceNotifier(),
);

class LeaveBalanceNotifier extends StateNotifier<LeaveBalanceModel> {
  LeaveBalanceNotifier()
      : super(
          const LeaveBalanceModel(
            country: GulfCountry.saudiArabia,
          ),
        );

  void setCountry(GulfCountry c) => state = state.copyWith(country: c);

  void setServiceYears(int v) =>
      state = state.copyWith(serviceYears: v.clamp(0, 40));

  void setServiceMonths(int v) =>
      state = state.copyWith(serviceMonths: v.clamp(0, 11));

  void setBasicSalary(double v) =>
      state = state.copyWith(basicSalary: v < 0 ? 0 : v);

  void setHousingAllowance(double v) =>
      state = state.copyWith(housingAllowance: v < 0 ? 0 : v);

  void setUsedLeaveDays(int v) =>
      state = state.copyWith(usedLeaveDays: v < 0 ? 0 : v);

  void setPendingLeaveDays(int v) =>
      state = state.copyWith(pendingLeaveDays: v < 0 ? 0 : v);
}
