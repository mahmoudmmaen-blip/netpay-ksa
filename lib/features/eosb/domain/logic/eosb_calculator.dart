import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_country_rules.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';

/// بند مستحق في نتيجة الحساب.
class EosbComponentItem {
  const EosbComponentItem({
    required this.id,
    required this.titleAr,
    required this.amount,
    this.subtitleAr,
    this.isPrimary = false,
  });

  final String id;
  final String titleAr;
  final String? subtitleAr;
  final double amount;
  final bool isPrimary;
}

/// نتيجة حاسبة نهاية الخدمة — دول مجلس التعاون الخليجي الست.
class EosbCalculationResult {
  const EosbCalculationResult({
    required this.input,
    required this.endOfServiceAmount,
    required this.vacationAllowance,
    required this.cashLeaveAllowance,
    required this.flightTicketAllowance,
    required this.totalEntitlements,
    required this.components,
    required this.legalReferences,
    required this.resignationFactorApplied,
    this.appliedAwardPercent,
  });

  final EosbModel input;
  final double endOfServiceAmount;
  final double vacationAllowance;
  final double cashLeaveAllowance;
  final double flightTicketAllowance;
  final double totalEntitlements;
  final List<EosbComponentItem> components;
  final List<EosbLegalReference> legalReferences;

  /// نسبة الاستقالة المطبّقة (null = غير مستخدمة).
  final double? resignationFactorApplied;

  /// نسبة مخصّصة على المكافأة (اتفاق بالتراضي / فصل لسبب مشروع).
  final double? appliedAwardPercent;

  String get countryLabel =>
      '${input.country.flag} ${input.country.nameAr}';

  List<EosbBreakdownRow> get breakdownRows => input.breakdownRows;
}

/// محرك الحساب — offline وفق أنظمة العمل في دول الخليج الست.
class EosbCalculator {
  const EosbCalculator();

  /// تقدير تكلفة تذكرة سنوية حسب الدولة (ريال / درهم).
  static double defaultYearlyTicketEstimate(GulfCountry country) =>
      switch (country) {
        GulfCountry.saudiArabia => 1500,
        GulfCountry.uae => 1200,
        GulfCountry.oman => 180,
        GulfCountry.qatar => 2000,
        GulfCountry.bahrain => 400,
        GulfCountry.kuwait => 350,
      };

  /// حساب كامل لنهاية الخدمة من مدخلات المعالج.
  ///
  /// يُستخدم في المعاينة المباشرة وشاشة النتائج عبر [eosbCalculatorProvider].
  EosbCalculationResult calculateEndOfService(EosbModel input) {
    final endOfServiceAward = calculateEndOfServiceAward(input);
    final remainingLeavePay = computeCashLeaveAllowance(input);
    final vacationEntitlementPay = computeVacationAllowance(input);
    final flightTicketValue = computeFlightTicketAllowance(input);
    final totalEntitlements = endOfServiceAward +
        remainingLeavePay +
        vacationEntitlementPay +
        flightTicketValue;

    return _buildResult(
      input: input,
      endOfServiceAward: endOfServiceAward,
      remainingLeavePay: remainingLeavePay,
      vacationEntitlementPay: vacationEntitlementPay,
      flightTicketValue: flightTicketValue,
      totalEntitlements: totalEntitlements,
    );
  }

  // ─── مكافأة نهاية الخدمة (نقطة الدخول الموحّدة) ─────────────────────

  /// حساب مكافأة نهاية الخدمة — توجيه حسب الدولة (استراتيجية + السعودية/الإمارات).
  static double calculateEndOfServiceAward(EosbModel input) {
    if (input.totalServiceYears <= 0 || input.basicSalary <= 0) return 0;

    return switch (input.country) {
      GulfCountry.saudiArabia => _saudiEndOfServiceByTermination(input),
      GulfCountry.uae => _uaeEndOfServiceByTermination(input),
      GulfCountry.oman => const OmanEosbRules().gratuityByTermination(input),
      GulfCountry.qatar => const QatarEosbRules().gratuityByTermination(input),
      GulfCountry.bahrain =>
        const BahrainEosbRules().gratuityByTermination(input),
      GulfCountry.kuwait => const KuwaitEosbRules().gratuityByTermination(input),
    };
  }

  static EosbCountryRules? _rulesFor(EosbModel input) =>
      EosbCountryRules.forCountry(input.country);

  // ─── السعودية — نظام العمل ─────────────────────────────────────────

  /// **فصل تعسفي (م.85 عملياً / مكافأة كاملة)**
  ///
  /// 100% من الراتب الأساسي × سنوات الخدمة:
  /// `الراتب الأساسي × إجمالي سنوات الخدمة`
  static double saudiUnfairDismissalAward(EosbModel input) {
    if (input.basicSalary <= 0 || input.totalServiceYears <= 0) return 0;
    return input.basicSalary * input.totalServiceYears;
  }

  /// **المادة 84 — أساس حساب المكافأة العادية**
  ///
  /// وعاء الأجر = أساسي + بدل سكن.
  /// - أول 5 سنوات: **50%** من وعاء الأجر عن كل سنة
  /// - بعد 5 سنوات: **100%** من وعاء الأجر عن كل سنة
  ///
  /// مثال: 10,000 أساسي + 2,500 سكن، 7 سنوات:
  /// `(12,500×0.5×5) + (12,500×2) = 56,250`
  static double saudiArticle84OnBasic(EosbModel input) {
    final wage = input.eosWageBase; // أساسي + سكن
    if (wage <= 0 || input.totalServiceYears <= 0) return 0;

    final years = input.totalServiceYears;
    final first5Years = years.clamp(0.0, 5.0);
    final yearsAfter5 = (years - 5.0).clamp(0.0, 100.0);

    final first5Component = wage * 0.5 * first5Years;
    final after5Component = wage * 1.0 * yearsAfter5;

    return first5Component + after5Component;
  }

  /// اسم بديل لـ [saudiArticle84OnBasic] — نفس صيغة المادة 84.
  static double saudiArticle84Award(EosbModel input) =>
      saudiArticle84OnBasic(input);

  /// توجيه مكافأة السعودية حسب [EosbTerminationType].
  static double _saudiEndOfServiceByTermination(EosbModel input) {
    final unfairFull = saudiUnfairDismissalAward(input);
    final article84 = saudiArticle84OnBasic(input);

    return switch (input.terminationType) {
      // فصل تعسفي — 100% (راتب أساسي × سنوات)
      EosbTerminationType.employerDismissalUnfair => unfairFull,

      // فصل لسبب مشروع (م.80) — نصف المكافأة التعسفية المحتسبة
      EosbTerminationType.employerDismissalValidReason => unfairFull * 0.5,

      // استقالة — المادة 84 كاملة (قد تُخفّض بم.85 في أنظمة أخرى؛ هنا صيغة 84)
      EosbTerminationType.employeeResignation => article84,

      // انتهاء عقد — م.84 مع قواعد العقد المحدد
      EosbTerminationType.contractExpiry =>
        _saudiContractExpiryAward(input, article84),

      // اتفاق بالتراضي — نسبة يحددها المستخدم على أساس م.84
      EosbTerminationType.mutualAgreement =>
        article84 * (input.mutualAgreementPercent / 100.0),

      // تقاعد / وفاة — م.84 كاملة
      EosbTerminationType.retirementOrDeath => article84,
    };
  }

  /// **انتهاء عقد (م.74 محدد / م.75 غير محدد)**
  ///
  /// عقد محدد المدة وأقل من سنة خدمة → نصف مكافأة المادة 84.
  static double _saudiContractExpiryAward(EosbModel input, double art84) {
    if (input.contractType == EosbContractType.fixed &&
        input.totalServiceYears < 1) {
      return art84 * 0.5;
    }
    return art84;
  }

  /// **المادة 85 — نسب الاستقالة** (للمرجع؛ UAE تستخدمها في الحساب).
  static double saudiResignationFactor(double years) {
    if (years < 2) return 0;
    if (years < 5) return 1 / 3;
    if (years < 10) return 2 / 3;
    return 1;
  }

  static double? _saudiAppliedPercent(EosbModel input) {
    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair => 100.0,
      EosbTerminationType.employerDismissalValidReason => 50.0,
      EosbTerminationType.mutualAgreement => input.mutualAgreementPercent,
      EosbTerminationType.contractExpiry when
            input.contractType == EosbContractType.fixed &&
                input.totalServiceYears < 1 =>
        50.0,
      _ => null,
    };
  }

  // ─── الإمارات — قانون العمل الاتحادي ───────────────────────────────

  /// **المادة 51 — مكافأة أساسية (21/30 يوم أجر × سنوات، حد سنتين)**
  static double uaeFullGratuity(EosbModel input) {
    if (input.basicSalary <= 0 || input.totalServiceYears < 1) return 0;
    final daily = input.basicSalary / 30;
    final first5Years = input.totalServiceYears.clamp(0, 5);
    final after5 = (input.totalServiceYears - 5).clamp(0, 100);
    final amount = (first5Years * 21 * daily) + (after5 * 30 * daily);
    final cap = input.basicSalary * 24;
    return amount > cap ? cap : amount;
  }

  static double uaeResignationFactor(double years) {
    if (years < 1) return 0;
    if (years < 3) return 0;
    if (years < 5) return 1 / 3;
    return 1;
  }

  /// توجيه مكافأة الإمارات حسب نوع الإنهاء (م.132 + م.51).
  static double _uaeEndOfServiceByTermination(EosbModel input) {
    if (input.basicSalary <= 0) return 0;
    final base = uaeFullGratuity(input);
    if (base <= 0) return 0;

    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair => base,
      EosbTerminationType.employerDismissalValidReason => base * 0.5,
      EosbTerminationType.employeeResignation =>
        base * uaeResignationFactor(input.totalServiceYears),
      EosbTerminationType.contractExpiry =>
        input.contractType == EosbContractType.fixed &&
                input.totalServiceYears < 1
            ? base * 0.5
            : base,
      EosbTerminationType.mutualAgreement =>
        base * (input.mutualAgreementPercent / 100),
      EosbTerminationType.retirementOrDeath => base,
    };
  }

  static double? _uaeAppliedPercent(EosbModel input) {
    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair => 100.0,
      EosbTerminationType.employerDismissalValidReason => 50.0,
      EosbTerminationType.mutualAgreement => input.mutualAgreementPercent,
      EosbTerminationType.contractExpiry when
            input.contractType == EosbContractType.fixed &&
                input.totalServiceYears < 1 =>
        50.0,
      _ => null,
    };
  }

  static double? appliedAwardPercent(EosbModel input) {
    final rules = _rulesFor(input);
    if (rules != null) return rules.appliedPercent(input);
    if (input.country == GulfCountry.uae) return _uaeAppliedPercent(input);
    return _saudiAppliedPercent(input);
  }

  // ─── بدلات إضافية ───────────────────────────────────────────────────

  /// بدل الإجازات المتبقية — (الأجر الشهري ÷ 30) × أيام متبقية.
  static double computeCashLeaveAllowance(EosbModel input) {
    if (input.accruedLeaveDays <= 0) return 0;
    final daily = input.country.eosLeaveDailyFromBasicOnly
        ? (input.basicSalary > 0 ? input.basicSalary / 30 : 0)
        : (input.eosWageBase > 0 ? input.eosWageBase / 30 : 0);
    if (daily <= 0) return 0;
    return daily * input.accruedLeaveDays.toDouble();
  }

  /// أجر اليوم لعرض بدل الإجازات في النتائج.
  static double leaveDailyWage(EosbModel input) {
    if (input.accruedLeaveDays <= 0) return 0;
    return input.country.eosLeaveDailyFromBasicOnly
        ? (input.basicSalary > 0 ? input.basicSalary / 30 : 0)
        : (input.eosWageBase > 0 ? input.eosWageBase / 30 : 0);
  }

  /// بدل إجازة سنوية تقديري — 21 أو 30 يوم حسب مدة الخدمة.
  static double computeVacationAllowance(EosbModel input) {
    if (input.dailyWage <= 0) return 0;
    return input.dailyWage * input.annualVacationDays;
  }

  /// تكلفة التذكرة الفعلية (تقدير تلقائي إن لم يُدخل المستخدم مبلغاً).
  static double resolveTicketUnitCost(EosbModel input) {
    if (!input.includeFlightTicket) return 0;
    if (input.ticketCost > 0) return input.ticketCost;
    return defaultYearlyTicketEstimate(input.country);
  }

  /// تذكرة طيران — تقدير سنوي × سنوات الخدمة.
  static double computeFlightTicketAllowance(EosbModel input) {
    if (!input.includeFlightTicket || input.totalServiceYears <= 0) {
      return 0;
    }
    final unit = resolveTicketUnitCost(input);
    final multiplier =
        input.ticketFrequency == FlightTicketFrequency.biannual ? 2.0 : 1.0;
    return unit * multiplier * input.totalServiceYears;
  }

  // ─── مراجع قانونية ──────────────────────────────────────────────────

  static List<EosbLegalReference> buildLegalReferences(EosbModel input) {
    final rules = _rulesFor(input);
    if (rules != null) return rules.legalReferences(input);
    if (input.country == GulfCountry.uae) return _uaeLegalReferences(input);
    return _saudiLegalReferences(input);
  }

  static List<EosbLegalReference> _saudiLegalReferences(EosbModel input) {
    final refs = <EosbLegalReference>[];

    if (input.terminationType == EosbTerminationType.employerDismissalUnfair) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 85 — فصل تعسفي',
          summary:
              'مكافأة كاملة: الراتب الأساسي × عدد سنوات الخدمة (دون خصم نسب الاستقالة).',
        ),
      );
    } else {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 84 — حساب المكافأة',
          summary:
              'نصف أجر (أساسي + بدل سكن) عن كل سنة من أول 5 سنوات، وأجر كامل عن كل سنة بعد السنة الخامسة.',
        ),
      );
    }

    if (input.isResignation) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 84 — الاستقالة',
          summary:
              'نصف الراتب الأساسي عن كل سنة من أول 5 سنوات، وراتب أساسي كامل عن كل سنة بعد السنة الخامسة.',
        ),
      );
    }

    if (input.terminationType == EosbTerminationType.retirementOrDeath) {
      refs.add(
        const EosbLegalReference(
          article: 'التقاعد / الوفاة',
          summary: 'مكافأة نهاية الخدمة كاملة وفق المادة 84.',
        ),
      );
    }

    if (input.terminationType == EosbTerminationType.employerDismissalValidReason) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 80 — فصل لسبب مشروع',
          summary:
              'نصف المكافأة المستحقة (50% من الراتب الأساسي × سنوات الخدمة) — راجع سبب الفصل مع الموارد البشرية.',
        ),
      );
    }

    if (input.terminationType == EosbTerminationType.mutualAgreement) {
      refs.add(
        EosbLegalReference(
          article: 'اتفاق بالتراضي',
          summary:
              'نسبة متفق عليها: ${input.mutualAgreementPercent.round()}% من مكافأة المادة 84 — يمكن تعديلها حسب الاتفاق.',
        ),
      );
    }

    if (input.terminationType == EosbTerminationType.contractExpiry) {
      refs.add(
        EosbLegalReference(
          article: input.contractType == EosbContractType.fixed
              ? 'انتهاء عقد محدد المدة — المادة 74'
              : 'انتهاء عقد غير محدد — المادة 75',
          summary: input.contractType == EosbContractType.fixed &&
                  input.totalServiceYears < 1
              ? 'خدمة أقل من سنة: غالباً نصف مكافأة المادة 84.'
              : 'انتهاء المدة أو الإنهاء: مكافأة كاملة وفق المادة 84.',
        ),
      );
    }

    if (input.accruedLeaveDays > 0) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 109 — الإجازة السنوية',
          summary:
              '(الراتب ÷ 30) × أيام الإجازة المتبقية عند انتهاء الخدمة.',
        ),
      );
    }

    if (input.includeFlightTicket) {
      refs.add(
        const EosbLegalReference(
          article: 'تذكرة السفر — العقد / اللائحة',
          summary:
              'تقدير تلقائي حسب الدولة ومدة الخدمة عند عدم إدخال تكلفة يدوياً.',
        ),
      );
    }

    if (!input.noticeProvided) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 75 — إشعار الإنهاء',
          summary:
              'عدم الالتزام بمدة الإشعار قد يترتب عليه تعويض إضافي — تحقق من نوع العقد.',
        ),
      );
    }

    return refs;
  }

  static List<EosbLegalReference> _uaeLegalReferences(EosbModel input) {
    final refs = <EosbLegalReference>[
      const EosbLegalReference(
        article: 'المادة 132 — قانون العمل الاتحادي',
        summary:
            'يستحق العامل مكافأة نهاية الخدمة عند إنهاء العقد أو انتهائه.',
      ),
      const EosbLegalReference(
        article: 'المادة 51 — قيمة المكافأة',
        summary:
            '21 يوم أجر أساسي (أول 5 سنوات) و30 يوماً (بعدها) — بحد أقصى أجر سنتين.',
      ),
    ];

    if (input.terminationType == EosbTerminationType.employerDismissalValidReason) {
      refs.add(
        const EosbLegalReference(
          article: 'إنهاء لسبب مشروع',
          summary: 'نصف مكافأة نهاية الخدمة المستحقة وفق المادة 51.',
        ),
      );
    }

    if (input.isResignation) {
      refs.add(
        const EosbLegalReference(
          article: 'المرسوم الاتحادي رقم 33 لسنة 2021',
          summary:
              'الاستقالة: أقل من 3 سنوات (0) | 3–5 (ثلث) | 5+ (كامل).',
        ),
      );
    }

    if (input.terminationType == EosbTerminationType.mutualAgreement) {
      refs.add(
        EosbLegalReference(
          article: 'اتفاق بالتراضي',
          summary:
              'نسبة ${input.mutualAgreementPercent.round()}% من المكافأة حسب الاتفاق.',
        ),
      );
    }

    if (input.accruedLeaveDays > 0) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 75 — الإجازة السنوية',
          summary: '(الراتب ÷ 30) × أيام الإجازة المتبقية.',
        ),
      );
    }

    if (input.includeFlightTicket) {
      final est = defaultYearlyTicketEstimate(GulfCountry.uae).round();
      refs.add(
        EosbLegalReference(
          article: 'تذكرة السفر',
          summary:
              'تقدير تلقائي: $est ${input.country.currencySymbol}/سنة عند عدم إدخال تكلفة.',
        ),
      );
    }

    return refs;
  }

  EosbCalculationResult _buildResult({
    required EosbModel input,
    required double endOfServiceAward,
    required double remainingLeavePay,
    required double vacationEntitlementPay,
    required double flightTicketValue,
    required double totalEntitlements,
  }) {
    final ticketUnit = resolveTicketUnitCost(input);

    final components = <EosbComponentItem>[
      EosbComponentItem(
        id: 'eos',
        titleAr: 'مكافأة نهاية الخدمة',
        subtitleAr: _eosSubtitle(input, endOfServiceAward),
        amount: endOfServiceAward,
        isPrimary: true,
      ),
      if (remainingLeavePay > 0)
        EosbComponentItem(
          id: 'leave',
          titleAr: 'بدل الإجازات المتبقية',
          subtitleAr:
              '${input.accruedLeaveDays} يوم · أجر يومي ${leaveDailyWage(input).round()}',
          amount: remainingLeavePay,
        ),
      if (vacationEntitlementPay > 0)
        EosbComponentItem(
          id: 'vacation',
          titleAr: 'بدل إجازة سنوية (تقديري)',
          subtitleAr:
              '${input.annualVacationDays} يوم · ${input.totalServiceYears.toStringAsFixed(1)} سنة',
          amount: vacationEntitlementPay,
        ),
      if (input.includeFlightTicket)
        EosbComponentItem(
          id: 'ticket',
          titleAr: 'تذكرة طيران (تقدير)',
          subtitleAr: _ticketSubtitle(input, flightTicketValue, ticketUnit),
          amount: flightTicketValue,
        ),
      EosbComponentItem(
        id: 'total',
        titleAr: 'الإجمالي المستحق',
        subtitleAr: 'مكافأة + إجازات + تذكرة (إن وُجدت)',
        amount: totalEntitlements,
      ),
    ];

    double? resignationFactor;
    if (input.isResignation) {
      final rules = _rulesFor(input);
      if (rules != null) {
        resignationFactor = rules.resignationFactor(input.totalServiceYears);
      } else if (input.country == GulfCountry.uae) {
        resignationFactor = uaeResignationFactor(input.totalServiceYears);
      }
      if (resignationFactor == 0) resignationFactor = null;
    }

    return EosbCalculationResult(
      input: input,
      endOfServiceAmount: endOfServiceAward,
      vacationAllowance: vacationEntitlementPay,
      cashLeaveAllowance: remainingLeavePay,
      flightTicketAllowance: flightTicketValue,
      totalEntitlements: totalEntitlements,
      components: components,
      legalReferences: buildLegalReferences(input),
      resignationFactorApplied: resignationFactor,
      appliedAwardPercent: appliedAwardPercent(input),
    );
  }

  String _ticketSubtitle(
    EosbModel input,
    double amount,
    double unitCost,
  ) {
    if (amount <= 0) {
      return 'تقدير غير متاح — فعّل التذكرة وأدخل مدة الخدمة';
    }
    final freq = EosbModel.ticketFrequencyLabel(input.ticketFrequency);
    final estimated = input.ticketCost <= 0;
    final cost = unitCost.round();
    final years = input.totalServiceYears.toStringAsFixed(1);
    final prefix = estimated ? 'تقدير تلقائي' : 'يدوي';
    return '$prefix · $freq · $cost ${input.country.currencySymbol} × $years سنة';
  }

  String _eosSubtitle(EosbModel input, double amount) {
    final rules = _rulesFor(input);
    if (rules != null) return rules.eosSubtitle(input, amount);

    if (input.country == GulfCountry.uae) {
      return switch (input.terminationType) {
        EosbTerminationType.employerDismissalUnfair =>
          'فصل تعسفي — 100% م. 51',
        EosbTerminationType.employerDismissalValidReason =>
          'فصل لسبب مشروع — 50% م. 51',
        EosbTerminationType.employeeResignation => () {
          final f = uaeResignationFactor(input.totalServiceYears);
          if (f == 0) return 'استقالة — أقل من 3 سنوات';
          if (f < 1) return 'استقالة — ${(f * 100).round()}% من المكافأة';
          return 'استقالة — مكافأة كاملة';
        }(),
        EosbTerminationType.mutualAgreement =>
          'اتفاق بالتراضي — ${input.mutualAgreementPercent.round()}%',
        _ => 'م. 51/132 — 21/30 يوم · حد سنتان',
      };
    }

    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair =>
        'فصل تعسفي — 100% (أساسي × ${input.totalServiceYears.toStringAsFixed(1)} سنة)',
      EosbTerminationType.employerDismissalValidReason =>
        'فصل لسبب مشروع — 50% من المكافأة',
      EosbTerminationType.employeeResignation =>
        'استقالة — م. 84 (أساسي + سكن · 50% أول 5 سنوات + 100% بعدها)',
      EosbTerminationType.contractExpiry => () {
        final half = input.contractType == EosbContractType.fixed &&
            input.totalServiceYears < 1;
        return half
            ? 'انتهاء عقد — نصف م. 84 (أقل من سنة)'
            : 'انتهاء عقد — م. 84 كاملة';
      }(),
      EosbTerminationType.mutualAgreement =>
        'اتفاق بالتراضي — ${input.mutualAgreementPercent.round()}% من م. 84',
      EosbTerminationType.retirementOrDeath => 'تقاعد/وفاة — م. 84 كاملة',
    };
  }
}
