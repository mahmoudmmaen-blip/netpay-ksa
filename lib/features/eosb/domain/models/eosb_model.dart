import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';

/// سبب إنهاء علاقة العمل — السعودية والإمارات.
enum EosbTerminationType {
  /// فصل تعسفي — مكافأة كاملة (أساسي × سنوات)
  employerDismissalUnfair,

  /// فصل لسبب مشروع — نصف المكافأة
  employerDismissalValidReason,

  /// استقالة — م. 84 + م. 85
  employeeResignation,

  /// انتهاء مدة عقد
  contractExpiry,

  /// اتفاق بالتراضي — نسبة قابلة للتخصيص
  mutualAgreement,

  /// تقاعد أو وفاة
  retirementOrDeath,
}

/// نوع العقد.
enum EosbContractType {
  fixed,
  unlimited,
}

/// تكرار تذكرة السفر في العقد.
enum FlightTicketFrequency {
  yearly,
  biannual,
}

/// صف في جدول النتائج.
class EosbBreakdownRow {
  const EosbBreakdownRow({
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  final String label;
  final double amount;
  final bool highlight;
}

/// مرجع قانوني للعرض في النتائج.
class EosbLegalReference {
  const EosbLegalReference({
    required this.article,
    required this.summary,
  });

  final String article;
  final String summary;
}

/// مدخلات وحسابات نهاية الخدمة — offline.
class EosbModel {
  const EosbModel({
    this.country = GulfCountry.saudiArabia,
    this.yearsOfService = 0,
    this.monthsOfService = 0,
    this.daysOfService = 0,
    this.basicSalary = 0,
    this.housingAllowance = 0,
    this.otherAllowances = 0,
    this.contractType = EosbContractType.unlimited,
    this.terminationType = EosbTerminationType.employerDismissalUnfair,
    this.ticketCost = 0,
    this.includeFlightTicket = false,
    this.ticketFrequency = FlightTicketFrequency.yearly,
    this.accruedLeaveDays = 0,
    this.noticeProvided = true,
    this.mutualAgreementPercent = 100,
  });

  static const _calc = EosbCalculator();

  final GulfCountry country;
  final int yearsOfService;
  final int monthsOfService;
  final int daysOfService;
  final double basicSalary;
  final double housingAllowance;
  final double otherAllowances;
  final int accruedLeaveDays;
  final EosbContractType contractType;
  final EosbTerminationType terminationType;
  final double ticketCost;
  final bool includeFlightTicket;
  final FlightTicketFrequency ticketFrequency;
  final bool noticeProvided;

  /// نسبة الاتفاق بالتراضي (0–100) على أساس م. 84 / م. 51.
  final double mutualAgreementPercent;

  double get totalServiceYears =>
      yearsOfService +
      (monthsOfService.clamp(0, 11) / 12.0) +
      (daysOfService.clamp(0, 364) / 365.0);

  double get eosWageBase => country == GulfCountry.uae
      ? basicSalary
      : basicSalary + housingAllowance;

  double get monthlyWage =>
      basicSalary + housingAllowance + otherAllowances;

  double get dailyWage => monthlyWage > 0 ? monthlyWage / 30 : 0;

  /// تكلفة التذكرة المستخدمة في الحساب (تقدير تلقائي إن لزم).
  double get effectiveTicketCost =>
      EosbCalculator.resolveTicketUnitCost(this);

  int get annualVacationDays => totalServiceYears >= 5 ? 30 : 21;

  bool get isResignation =>
      terminationType == EosbTerminationType.employeeResignation;

  bool get isValidEmployerDismissal =>
      terminationType == EosbTerminationType.employerDismissalValidReason;

  bool get isMutualAgreement =>
      terminationType == EosbTerminationType.mutualAgreement;

  /// المكافأة النظرية قبل خصومات الاستقالة (للعرض).
  double get fullEndOfServiceBase {
    if (totalServiceYears <= 0) return 0;
    if (country == GulfCountry.uae) {
      return basicSalary > 0 ? EosbCalculator.uaeFullGratuity(this) : 0;
    }
    return switch (terminationType) {
      EosbTerminationType.employerDismissalUnfair =>
        EosbCalculator.saudiUnfairDismissalAward(this),
      EosbTerminationType.employerDismissalValidReason =>
        EosbCalculator.saudiUnfairDismissalAward(this) * 0.5,
      _ => EosbCalculator.saudiArticle84OnBasic(this),
    };
  }

  double get resignationAwardFactor => country == GulfCountry.uae
      ? EosbCalculator.uaeResignationFactor(totalServiceYears)
      : EosbCalculator.saudiResignationFactor(totalServiceYears);

  double get endOfServiceAmount =>
      EosbCalculator.calculateEndOfServiceAward(this);

  double get vacationAllowance =>
      EosbCalculator.computeVacationAllowance(this);

  double get flightTicketAllowance =>
      EosbCalculator.computeFlightTicketAllowance(this);

  double get cashLeaveAllowance =>
      EosbCalculator.computeCashLeaveAllowance(this);

  double get totalEntitlements =>
      endOfServiceAmount +
      vacationAllowance +
      flightTicketAllowance +
      cashLeaveAllowance;

  List<EosbBreakdownRow> get breakdownRows {
    final rows = <EosbBreakdownRow>[
      EosbBreakdownRow(
        label: 'مكافأة نهاية الخدمة',
        amount: endOfServiceAmount,
        highlight: true,
      ),
      if (cashLeaveAllowance > 0)
        EosbBreakdownRow(
          label: 'بدل الإجازات المتبقية ($accruedLeaveDays يوم)',
          amount: cashLeaveAllowance,
        ),
      if (vacationAllowance > 0)
        EosbBreakdownRow(
          label: 'بدل إجازة سنوية تقديري ($annualVacationDays يوم)',
          amount: vacationAllowance,
        ),
      if (includeFlightTicket && flightTicketAllowance > 0)
        EosbBreakdownRow(
          label: 'تذكرة طيران (تقدير)',
          amount: flightTicketAllowance,
        ),
      EosbBreakdownRow(
        label: 'الإجمالي المستحق',
        amount: totalEntitlements,
        highlight: true,
      ),
    ];
    return rows;
  }

  List<EosbLegalReference> get legalReferences =>
      EosbCalculator.buildLegalReferences(this);

  String get terminationSummary => switch (terminationType) {
        EosbTerminationType.employerDismissalUnfair =>
          'فصل من صاحب العمل (تعسفي / بدون سبب مشروع)',
        EosbTerminationType.employerDismissalValidReason =>
          'فصل لسبب مشروع',
        EosbTerminationType.employeeResignation => 'استقالة الموظف',
        EosbTerminationType.contractExpiry => 'انتهاء مدة العقد',
        EosbTerminationType.mutualAgreement => 'اتفاق بالتراضي',
        EosbTerminationType.retirementOrDeath => 'تقاعد / وفاة',
      };

  EosbModel copyWith({
    GulfCountry? country,
    int? yearsOfService,
    int? monthsOfService,
    int? daysOfService,
    double? basicSalary,
    double? housingAllowance,
    double? otherAllowances,
    EosbContractType? contractType,
    EosbTerminationType? terminationType,
    double? ticketCost,
    bool? includeFlightTicket,
    FlightTicketFrequency? ticketFrequency,
    int? accruedLeaveDays,
    bool? noticeProvided,
    double? mutualAgreementPercent,
  }) {
    return EosbModel(
      country: country ?? this.country,
      yearsOfService: yearsOfService ?? this.yearsOfService,
      monthsOfService: monthsOfService ?? this.monthsOfService,
      daysOfService: daysOfService ?? this.daysOfService,
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      otherAllowances: otherAllowances ?? this.otherAllowances,
      contractType: contractType ?? this.contractType,
      terminationType: terminationType ?? this.terminationType,
      ticketCost: ticketCost ?? this.ticketCost,
      includeFlightTicket: includeFlightTicket ?? this.includeFlightTicket,
      ticketFrequency: ticketFrequency ?? this.ticketFrequency,
      accruedLeaveDays: accruedLeaveDays ?? this.accruedLeaveDays,
      noticeProvided: noticeProvided ?? this.noticeProvided,
      mutualAgreementPercent:
          mutualAgreementPercent ?? this.mutualAgreementPercent,
    );
  }

  static String contractTypeLabel(EosbContractType type) => switch (type) {
        EosbContractType.fixed => 'محدد المدة',
        EosbContractType.unlimited => 'غير محدد المدة',
      };

  static String terminationTypeLabel(EosbTerminationType type) =>
      EosbModel(terminationType: type).terminationSummary;

  static String ticketFrequencyLabel(FlightTicketFrequency f) => switch (f) {
        FlightTicketFrequency.yearly => 'سنوي',
        FlightTicketFrequency.biannual => 'نصف سنوي (مرتين)',
      };

  EosbCalculationResult calculate() => _calc.calculateEndOfService(this);
}
