// نموذج مكافأة نهاية الخدمة والمستحقات — نظام العمل السعودي (المادتان 84 و 85).

/// سبب انتهاء العلاقة العمالية.
enum LeavingReason {
  /// فصل من صاحب العمل — مكافأة كاملة (راتب عن كل سنة)
  termination,

  /// استقالة — نسب مخفّضة حسب مدة الخدمة (م. 85)
  resignation,

  /// انتهاء عقد محدد المدة — مثل الفصل (مكافأة كاملة)
  contractEnd,
}

/// نوع العقد — محدد المدة / غير محدد.
enum EosbContractType {
  fixed,
  unlimited,
}

/// تكرار تذكرة السفر في العقد.
enum FlightTicketFrequency {
  yearly,
  biannual,
}

/// مدخلات وحسابات نهاية الخدمة والإجازة وتذكرة السفر.
class EosbModel {
  const EosbModel({
    this.yearsOfService = 0,
    this.monthsOfService = 0,
    this.basicSalary = 0,
    this.housingAllowance = 0,
    this.contractType = EosbContractType.unlimited,
    this.leavingReason = LeavingReason.termination,
    this.ticketCost = 0,
    this.ticketFrequency = FlightTicketFrequency.yearly,
  });

  final int yearsOfService;
  final int monthsOfService;
  final double basicSalary;
  final double housingAllowance;
  final EosbContractType contractType;
  final LeavingReason leavingReason;
  final double ticketCost;
  final FlightTicketFrequency ticketFrequency;

  double get totalServiceYears =>
      yearsOfService + (monthsOfService.clamp(0, 11) / 12.0);

  double get monthlyWage => basicSalary + housingAllowance;

  double get dailyWage => monthlyWage > 0 ? monthlyWage / 30 : 0;

  int get annualVacationDays => totalServiceYears >= 5 ? 30 : 21;

  /// مكافأة كاملة = راتب شهري × سنوات الخدمة (قبل تطبيق نسبة الاستقالة).
  double get fullEndOfServiceBase {
    if (totalServiceYears <= 0 || monthlyWage <= 0) return 0;
    return monthlyWage * totalServiceYears;
  }

  /// نسبة مكافأة الاستقالة (م. 85) — 1.0 = كامل.
  double get resignationAwardFactor {
    final y = totalServiceYears;
    if (y < 2) return 0;
    if (y < 5) return 1 / 3;
    if (y < 10) return 2 / 3;
    return 1;
  }

  /// مكافأة نهاية الخدمة حسب سبب المغادرة.
  double get endOfServiceAmount {
    if (totalServiceYears <= 0 || monthlyWage <= 0) return 0;

    return switch (leavingReason) {
      LeavingReason.termination || LeavingReason.contractEnd =>
        fullEndOfServiceBase,
      LeavingReason.resignation =>
        fullEndOfServiceBase * resignationAwardFactor,
    };
  }

  double get vacationAllowance => dailyWage * annualVacationDays;

  double get flightTicketAllowance {
    if (ticketCost <= 0 || totalServiceYears <= 0) return 0;
    final multiplier =
        ticketFrequency == FlightTicketFrequency.biannual ? 2.0 : 1.0;
    return ticketCost * multiplier * totalServiceYears;
  }

  double get totalEntitlements =>
      endOfServiceAmount + vacationAllowance + flightTicketAllowance;

  bool get isResignation => leavingReason == LeavingReason.resignation;

  EosbModel copyWith({
    int? yearsOfService,
    int? monthsOfService,
    double? basicSalary,
    double? housingAllowance,
    EosbContractType? contractType,
    LeavingReason? leavingReason,
    double? ticketCost,
    FlightTicketFrequency? ticketFrequency,
  }) {
    return EosbModel(
      yearsOfService: yearsOfService ?? this.yearsOfService,
      monthsOfService: monthsOfService ?? this.monthsOfService,
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      contractType: contractType ?? this.contractType,
      leavingReason: leavingReason ?? this.leavingReason,
      ticketCost: ticketCost ?? this.ticketCost,
      ticketFrequency: ticketFrequency ?? this.ticketFrequency,
    );
  }

  static String contractTypeLabel(EosbContractType type) => switch (type) {
        EosbContractType.fixed => 'محدد المدة',
        EosbContractType.unlimited => 'غير محدد',
      };

  static String leavingReasonLabel(LeavingReason reason) => switch (reason) {
        LeavingReason.termination => 'فصل',
        LeavingReason.resignation => 'استقالة',
        LeavingReason.contractEnd => 'انتهاء عقد',
      };

  static String ticketFrequencyLabel(FlightTicketFrequency f) => switch (f) {
        FlightTicketFrequency.yearly => 'سنوي',
        FlightTicketFrequency.biannual => 'نصف سنوي (مرتين)',
      };
}
