import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/notice_period/domain/notice_period_model.dart';

final noticePeriodProvider =
    StateNotifierProvider<NoticePeriodNotifier, NoticePeriodModel>(
  (ref) => NoticePeriodNotifier(),
);

class NoticePeriodNotifier extends StateNotifier<NoticePeriodModel> {
  NoticePeriodNotifier()
      : super(
          const NoticePeriodModel(
            country: GulfCountry.saudiArabia,
            monthlyBasicSalary: 0,
            totalServiceYears: 0,
          ),
        );

  void setCountry(GulfCountry c) => state = state.copyWith(country: c);

  void setSalary(double v) =>
      state = state.copyWith(monthlyBasicSalary: v < 0 ? 0 : v);

  void setYears(double v) =>
      state = state.copyWith(totalServiceYears: v < 0 ? 0 : v);

  void setContractType(EosbContractType t) =>
      state = state.copyWith(contractType: t);

  void setNoticeGiven(bool v) => state = state.copyWith(
        noticeWasGiven: v,
        daysNoticeGiven: v ? state.daysNoticeGiven : 0,
      );

  void setDaysGiven(int v) =>
      state = state.copyWith(daysNoticeGiven: v < 0 ? 0 : v);
}
