import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netpay_ksa/features/gosi/domain/enums/gosi_regime.dart';
import 'package:netpay_ksa/features/gosi/domain/enums/nationality_type.dart';
import 'package:netpay_ksa/features/gosi/providers/gosi_calculator_provider.dart';
import 'package:netpay_ksa/features/salary_calculator/models/gosi_model.dart';

/// حالة نموذج الراتب — الحقول المدخلة + نتيجة GOSI المحسوبة.
class SalaryState extends Equatable {
  const SalaryState({
    this.basicSalary = 10000,
    this.housingAllowance = 2500,
    this.otherAllowances = 0,
    this.includeOtherInGosiBase = false,
    this.nationality = NationalityType.saudi,
    this.regime = GosiRegime.newLawPhased,
    this.calculationDate,
    this.gosi,
    this.errorMessage,
  });

  final double basicSalary;
  final double housingAllowance;
  final double otherAllowances;
  final bool includeOtherInGosiBase;
  final NationalityType nationality;
  final GosiRegime regime;
  final DateTime? calculationDate;

  /// النتيجة المالية — المصدر الوحيد للأرقام في الواجهة.
  final GosiModel? gosi;
  final String? errorMessage;

  SalaryAllowances get allowances => SalaryAllowances(
        basicSalary: basicSalary,
        housingAllowance: housingAllowance,
        otherAllowances: otherAllowances,
        includeOtherInGosiBase: includeOtherInGosiBase,
      );

  DateTime get effectiveDate => calculationDate ?? DateTime.now();

  bool get hasError => errorMessage != null;
  bool get hasGosi => gosi != null && !hasError;

  SalaryState copyWith({
    double? basicSalary,
    double? housingAllowance,
    double? otherAllowances,
    bool? includeOtherInGosiBase,
    NationalityType? nationality,
    GosiRegime? regime,
    DateTime? calculationDate,
    GosiModel? gosi,
    String? errorMessage,
    bool clearGosi = false,
    bool clearError = false,
  }) {
    return SalaryState(
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      otherAllowances: otherAllowances ?? this.otherAllowances,
      includeOtherInGosiBase:
          includeOtherInGosiBase ?? this.includeOtherInGosiBase,
      nationality: nationality ?? this.nationality,
      regime: regime ?? this.regime,
      calculationDate: calculationDate ?? this.calculationDate,
      gosi: clearGosi ? null : (gosi ?? this.gosi),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        basicSalary,
        housingAllowance,
        otherAllowances,
        includeOtherInGosiBase,
        nationality,
        regime,
        calculationDate,
        gosi,
        errorMessage,
      ];
}

/// يدير مدخلات الراتب ويعيد حساب GOSI عند أي تغيير.
class SalaryNotifier extends Notifier<SalaryState> {
  @override
  SalaryState build() => recalculate(const SalaryState());

  GosiModel? get currentGosi => state.gosi;

  void setBasic(double v) => _update(basicSalary: v);
  void setHousing(double v) => _update(housingAllowance: v);
  void setOther(double v) => _update(otherAllowances: v);
  void setIncludeOtherInGosi(bool v) => _update(includeOtherInGosiBase: v);
  void setNationality(NationalityType v) => _update(nationality: v);
  void setRegime(GosiRegime v) => _update(regime: v);
  void setCalculationDate(DateTime v) => _update(calculationDate: v);

  void _update({
    double? basicSalary,
    double? housingAllowance,
    double? otherAllowances,
    bool? includeOtherInGosiBase,
    NationalityType? nationality,
    GosiRegime? regime,
    DateTime? calculationDate,
  }) {
    state = recalculate(
      state.copyWith(
        basicSalary: basicSalary,
        housingAllowance: housingAllowance,
        otherAllowances: otherAllowances,
        includeOtherInGosiBase: includeOtherInGosiBase,
        nationality: nationality,
        regime: regime,
        calculationDate: calculationDate,
        clearError: true,
      ),
    );
  }

  /// يعيد حساب [GosiModel] من المدخلات الحالية عبر المحرك المحقون.
  void recalculateFromCurrent() {
    state = recalculate(state);
  }

  /// يبني [GosiModel.fromSalaryForm] — يُرجع حالة محدّثة (نمط خالٍ من الأثر الجانبي).
  SalaryState recalculate(SalaryState input) {
    final allowances = input.allowances;

    if (!allowances.isValid) {
      return input.copyWith(
        clearGosi: true,
        errorMessage: 'الرواتب والبدلات يجب أن تكون صفراً أو أكثر',
      );
    }

    try {
      final model = GosiModel.fromSalaryForm(
        allowances: allowances,
        nationality: input.nationality,
        regime: input.regime,
        calculationDate: input.effectiveDate,
        calculator: ref.read(gosiCalculatorProvider),
      );
      return input.copyWith(gosi: model, clearError: true);
    } on ArgumentError catch (e) {
      return input.copyWith(
        clearGosi: true,
        errorMessage: e.message?.toString() ?? 'مدخلات غير صالحة',
      );
    } catch (_) {
      return input.copyWith(
        clearGosi: true,
        errorMessage: 'تعذّر حساب التأمينات',
      );
    }
  }
}

final salaryNotifierProvider =
    NotifierProvider<SalaryNotifier, SalaryState>(SalaryNotifier.new);

/// [GosiModel] الحالي — للواجهة والتصدير.
final gosiModelProvider = Provider<GosiModel?>((ref) {
  return ref.watch(salaryNotifierProvider).gosi;
});

@Deprecated('Use SalaryState')
typedef SalaryFormState = SalaryState;

@Deprecated('Use gosiModelProvider')
final currentGosiModelProvider = gosiModelProvider;
