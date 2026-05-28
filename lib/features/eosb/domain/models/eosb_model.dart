import 'package:netgulf/core/domain/gulf_country.dart';

/// سبب إنهاء علاقة العمل — السعودية والإمارات.
enum EosbTerminationType {
  /// فصل تعسفي / بدون سبب مشروع — مكافأة كاملة (م. 84)
  employerDismissalUnfair,

  /// فصل لسبب مشروع (م. 80) — غالباً لا مكافأة
  employerDismissalValidReason,

  /// استقالة — نسب مخفّضة (م. 85 / قانون الإمارات)
  employeeResignation,

  /// انتهاء مدة عقد محدد
  contractExpiry,

  /// اتفاق بالتراضي
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
  });

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

  double get totalServiceYears =>
      yearsOfService +
      (monthsOfService.clamp(0, 11) / 12.0) +
      (daysOfService.clamp(0, 364) / 365.0);

  /// وعاء المكافأة — السعودية: أساسي + سكن | الإمارات: الأساسي غالباً.
  double get eosWageBase => country == GulfCountry.uae
      ? basicSalary
      : basicSalary + housingAllowance;

  double get monthlyWage =>
      basicSalary + housingAllowance + otherAllowances;

  double get dailyWage => monthlyWage > 0 ? monthlyWage / 30 : 0;

  int get annualVacationDays => totalServiceYears >= 5 ? 30 : 21;

  bool get isResignation =>
      terminationType == EosbTerminationType.employeeResignation;

  bool get isValidEmployerDismissal =>
      terminationType == EosbTerminationType.employerDismissalValidReason;

  /// مكافأة كاملة نظرية قبل نسب الاستقالة.
  double get fullEndOfServiceBase {
    if (totalServiceYears <= 0 || eosWageBase <= 0) return 0;
    if (country == GulfCountry.uae) return _uaeFullGratuity;
    return _saudiFullGratuity;
  }

  /// السعودية — م. 84: نصف شهر عن كل سنة (أول 5) وشهر كامل بعدها.
  double get _saudiFullGratuity {
    final y = totalServiceYears;
    final first5 = y.clamp(0.0, 5.0);
    final after5 = (y - 5).clamp(0.0, 100.0);
    return (eosWageBase * 0.5 * first5) + (eosWageBase * after5);
  }

  double get _uaeFullGratuity {
    if (totalServiceYears < 1) return 0;
    final daily = basicSalary / 30;
    final first5Years = totalServiceYears.clamp(0, 5);
    final after5 = (totalServiceYears - 5).clamp(0, 100);
    final amount = (first5Years * 21 * daily) + (after5 * 30 * daily);
    final cap = basicSalary * 24;
    return amount > cap ? cap : amount;
  }

  double get resignationAwardFactor {
    final y = totalServiceYears;
    if (country == GulfCountry.uae) {
      if (y < 1) return 0;
      if (y < 3) return 0;
      if (y < 5) return 1 / 3;
      return 1;
    }
    if (y < 2) return 0;
    if (y < 5) return 1 / 3;
    if (y < 10) return 2 / 3;
    return 1;
  }

  double get endOfServiceAmount {
    if (totalServiceYears <= 0 || eosWageBase <= 0) return 0;

    if (isValidEmployerDismissal) return 0;

    final base = fullEndOfServiceBase;
    if (isResignation) return base * resignationAwardFactor;

    return switch (terminationType) {
      EosbTerminationType.employerDismissalUnfair ||
      EosbTerminationType.contractExpiry ||
      EosbTerminationType.mutualAgreement ||
      EosbTerminationType.retirementOrDeath =>
        base,
      EosbTerminationType.employerDismissalValidReason => 0,
      EosbTerminationType.employeeResignation =>
        base * resignationAwardFactor,
    };
  }

  double get vacationAllowance => dailyWage * annualVacationDays;

  double get flightTicketAllowance {
    if (!includeFlightTicket || ticketCost <= 0 || totalServiceYears <= 0) {
      return 0;
    }
    final multiplier =
        ticketFrequency == FlightTicketFrequency.biannual ? 2.0 : 1.0;
    return ticketCost * multiplier * totalServiceYears;
  }

  double get cashLeaveAllowance {
    if (basicSalary <= 0 || accruedLeaveDays <= 0) return 0;
    return (basicSalary / 30) * accruedLeaveDays;
  }

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
      EosbBreakdownRow(
        label: 'بدل إجازة سنوية تقديري ($annualVacationDays يوم)',
        amount: vacationAllowance,
      ),
      if (includeFlightTicket)
        EosbBreakdownRow(
          label: 'تذكرة طيران سنوية (تقدير)',
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

  List<EosbLegalReference> get legalReferences {
    if (country == GulfCountry.uae) {
      return _uaeLegalRefs;
    }
    return _saudiLegalRefs;
  }

  List<EosbLegalReference> get _saudiLegalRefs {
    final refs = <EosbLegalReference>[
      const EosbLegalReference(
        article: 'المادة 84',
        summary:
            'مكافأة نهاية الخدمة — نصف شهر أجر (أساسي + سكن) عن كل سنة من أول 5 سنوات، وشهر كامل عن كل سنة بعدها.',
      ),
      const EosbLegalReference(
        article: 'المادة 85',
        summary: 'نسب مكافأة الاستقالة: أقل من سنتين (0)، 2–5 (ثلث)، 5–10 (ثلثان)، 10+ (كامل).',
      ),
    ];
    if (isValidEmployerDismissal) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 80',
          summary: 'الفصل لسبب مشروع قد يستبعد المكافأة — راجع سبب الإنهاء مع الموارد البشرية أو محامٍ.',
        ),
      );
    }
    if (!noticeProvided) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 75',
          summary: 'إشعار الإنهاء: عدم الالتزام قد يؤثر على التعويضات — تحقق من مدة الإشعار حسب نوع العقد.',
        ),
      );
    }
    return refs;
  }

  List<EosbLegalReference> get _uaeLegalRefs {
    return [
      const EosbLegalReference(
        article: 'المادة 51 — قانون العمل الإماراتي',
        summary: '21 يوم أجر أساسي عن كل سنة (أول 5 سنوات) و30 يوماً لكل سنة بعدها — بحد أقصى سنتان أجر.',
      ),
      const EosbLegalReference(
        article: 'المرسوم الاتحادي 33 لسنة 2021',
        summary: 'استحقاق المكافأة بعد سنة خدمة؛ الاستقالة قبل 3 سنوات قد تُسقط المكافأة أو تخفّضها.',
      ),
      if (isResignation)
        const EosbLegalReference(
          article: 'استقالة الموظف',
          summary: '3–5 سنوات: ثلث المكافأة | 5+ سنوات: كامل (حسب مدة الخدمة الفعلية).',
        ),
    ];
  }

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
}
