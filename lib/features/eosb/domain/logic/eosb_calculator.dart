import 'package:netgulf/core/domain/gulf_country.dart';
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

/// نتيجة حاسبة نهاية الخدمة — السعودية (84/85) والإمارات (132/51).
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

/// محرك الحساب — offline وفق نظام العمل السعودي والإماراتي.
class EosbCalculator {
  const EosbCalculator();

  /// تقدير تكلفة تذكرة سنوية حسب الدولة (ريال / درهم).
  static double defaultYearlyTicketEstimate(GulfCountry country) =>
      switch (country) {
        GulfCountry.saudiArabia => 1500,
        GulfCountry.uae => 1200,
      };

  /// حساب كامل لنهاية الخدمة من مدخلات المعالج.
  EosbCalculationResult calculateEndOfService(EosbModel input) {
    final endOfServiceAward = computeEndOfServiceAward(input);
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

  /// @deprecated استخدم [calculateEndOfService]
  EosbCalculationResult calculate(EosbModel input) =>
      calculateEndOfService(input);

  // ─── مكافأة نهاية الخدمة ───────────────────────────────────────────

  static double computeEndOfServiceAward(EosbModel input) {
    if (input.totalServiceYears <= 0) return 0;

    if (input.country == GulfCountry.uae) {
      return _computeUaeGratuity(input);
    }
    return _computeSaudiEndOfService(input);
  }

  // ─── السعودية ───────────────────────────────────────────────────────

  /// فصل تعسفي — مكافأة كاملة: الراتب الأساسي × سنوات الخدمة.
  static double saudiUnfairDismissalAward(EosbModel input) {
    if (input.basicSalary <= 0) return 0;
    return input.basicSalary * input.totalServiceYears;
  }

  /// م. 84 — نصف الراتب الأساسي لأول 5 سنوات + راتب كامل لكل سنة بعدها.
  static double saudiArticle84OnBasic(EosbModel input) {
    if (input.basicSalary <= 0) return 0;
    final y = input.totalServiceYears;
    final first5 = y.clamp(0.0, 5.0);
    final after5 = (y - 5).clamp(0.0, 100.0);
    return (input.basicSalary * 0.5 * first5) + (input.basicSalary * after5);
  }

  static double _computeSaudiEndOfService(EosbModel input) {
    if (input.basicSalary <= 0) return 0;

    final unfairFull = saudiUnfairDismissalAward(input);
    final art84 = saudiArticle84OnBasic(input);

    return switch (input.terminationType) {
      // 100% — راتب أساسي × سنوات
      EosbTerminationType.employerDismissalUnfair => unfairFull,
      // 50% من المكافأة الكاملة
      EosbTerminationType.employerDismissalValidReason => unfairFull * 0.5,
      // م. 84: 50% أول 5 سنوات + 100% بعدها
      EosbTerminationType.employeeResignation => art84,
      EosbTerminationType.contractExpiry =>
        _saudiContractExpiryAward(input, art84),
      EosbTerminationType.mutualAgreement =>
        art84 * (input.mutualAgreementPercent / 100),
      EosbTerminationType.retirementOrDeath => art84,
    };
  }

  /// انتهاء عقد: أقل من سنة في عقد محدد → نصف م. 84؛ وإلا كامل.
  static double _saudiContractExpiryAward(EosbModel input, double art84) {
    if (input.contractType == EosbContractType.fixed &&
        input.totalServiceYears < 1) {
      return art84 * 0.5;
    }
    return art84;
  }

  /// م. 85 — نسب الاستقالة على أساس م. 84.
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

  // ─── الإمارات — م. 132 / 51 ───────────────────────────────────────

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

  static double _computeUaeGratuity(EosbModel input) {
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
    if (input.country == GulfCountry.uae) {
      return _uaeAppliedPercent(input);
    }
    return _saudiAppliedPercent(input);
  }

  // ─── بدلات إضافية ───────────────────────────────────────────────────

  /// بدل الإجازات المتبقية — (الراتب ÷ 30) × أيام متبقية.
  static double computeCashLeaveAllowance(EosbModel input) {
    if (input.accruedLeaveDays <= 0 || input.basicSalary <= 0) return 0;
    return (input.basicSalary / 30) * input.accruedLeaveDays;
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
    if (input.country == GulfCountry.uae) {
      return _uaeLegalReferences(input);
    }
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
              'نصف الراتب الأساسي عن كل سنة من أول 5 سنوات، وراتب أساسي كامل عن كل سنة بعد السنة الخامسة.',
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
              '${input.accruedLeaveDays} يوم · (${input.basicSalary.round()} ÷ 30) × ${input.accruedLeaveDays}',
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
    ];

    double? resignationFactor;
    if (input.isResignation && input.country == GulfCountry.uae) {
      resignationFactor = uaeResignationFactor(input.totalServiceYears);
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
        'استقالة — م. 84 (50% أول 5 سنوات + 100% بعدها)',
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
