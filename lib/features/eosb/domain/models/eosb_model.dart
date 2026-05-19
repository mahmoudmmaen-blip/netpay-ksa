// نموذج مكافأة نهاية الخدمة والمستحقات — نظام العمل السعودي (المادتان 84 و 85).

/// نوع العقد — محدد المدة / غير محدد.
enum EosbContractType {
  /// عقد محدد المدة
  fixed,

  /// عقد غير محدد المدة
  unlimited,
}

/// تكرار تذكرة السفر في العقد.
enum FlightTicketFrequency {
  /// تذكرة واحدة سنوياً
  yearly,

  /// تذكرتان سنوياً
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
    this.ticketCost = 0,
    this.ticketFrequency = FlightTicketFrequency.yearly,
  });

  final int yearsOfService;
  final int monthsOfService;
  final double basicSalary;
  final double housingAllowance;
  final EosbContractType contractType;
  final double ticketCost;
  final FlightTicketFrequency ticketFrequency;

  /// إجمالي سنوات الخدمة (كسور السنة محسوبة).
  double get totalServiceYears =>
      yearsOfService + (monthsOfService.clamp(0, 11) / 12.0);

  /// الأجر الشهري لأغراض المكافأة (أساسي + سكن — وفق الممارسة الشائعة).
  double get monthlyWage => basicSalary + housingAllowance;

  /// أجر اليوم (30 يوماً في الشهر).
  double get dailyWage => monthlyWage > 0 ? monthlyWage / 30 : 0;

  /// أيام الإجازة السنوية: 21 قبل 5 سنوات، 30 من 5 سنوات فأكثر.
  int get annualVacationDays => totalServiceYears >= 5 ? 30 : 21;

  /// مكافأة نهاية الخدمة — المادة 84 (انتهاء عقد / إنهاء من صاحب العمل).
  ///
  /// أول 5 سنوات: نصف شهر عن كل سنة.
  /// ما بعد 5 سنوات: شهر كامل عن كل سنة.
  /// يُحتسب بالتناسب لكسور السنة.
  double get endOfServiceAmount {
    if (totalServiceYears <= 0 || monthlyWage <= 0) return 0;

    final years = totalServiceYears;
    final inFirstBracket = years.clamp(0.0, 5.0);
    final inSecondBracket = (years - 5).clamp(0.0, double.infinity);

    return (inFirstBracket * 0.5 * monthlyWage) +
        (inSecondBracket * 1.0 * monthlyWage);
  }

  /// بدل الإجازة — قيمة أيام الإجازة السنوية المستحقة (21 أو 30 يوماً).
  double get vacationAllowance => dailyWage * annualVacationDays;

  /// بدل تذكرة السفر — مُوزَّع على سنوات الخدمة حسب التكرار.
  double get flightTicketAllowance {
    if (ticketCost <= 0 || totalServiceYears <= 0) return 0;
    final multiplier = ticketFrequency == FlightTicketFrequency.biannual
        ? 2.0
        : 1.0;
    return ticketCost * multiplier * totalServiceYears;
  }

  /// إجمالي المستحقات.
  double get totalEntitlements =>
      endOfServiceAmount + vacationAllowance + flightTicketAllowance;

  EosbModel copyWith({
    int? yearsOfService,
    int? monthsOfService,
    double? basicSalary,
    double? housingAllowance,
    EosbContractType? contractType,
    double? ticketCost,
    FlightTicketFrequency? ticketFrequency,
  }) {
    return EosbModel(
      yearsOfService: yearsOfService ?? this.yearsOfService,
      monthsOfService: monthsOfService ?? this.monthsOfService,
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      contractType: contractType ?? this.contractType,
      ticketCost: ticketCost ?? this.ticketCost,
      ticketFrequency: ticketFrequency ?? this.ticketFrequency,
    );
  }

  /// تسمية نوع العقد بالعربية.
  static String contractTypeLabel(EosbContractType type) => switch (type) {
        EosbContractType.fixed => 'محدد المدة',
        EosbContractType.unlimited => 'غير محدد',
      };

  /// تسمية تكرار التذكرة.
  static String ticketFrequencyLabel(FlightTicketFrequency f) => switch (f) {
        FlightTicketFrequency.yearly => 'سنوي',
        FlightTicketFrequency.biannual => 'نصف سنوي (مرتين)',
      };
}
