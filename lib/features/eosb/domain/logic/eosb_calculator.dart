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
    if (input.isValidEmployerDismissal) return 0;

    if (input.country == GulfCountry.uae) {
      return _computeUaeGratuity(input);
    }
    return _computeSaudiEndOfService(input);
  }

  /// السعودية — م. 84: نصف شهر (أساسي + سكن) لأول 5 سنوات، شهر كامل بعدها.
  static double saudiArticle84Base(EosbModel input) {
    final wage = input.eosWageBase;
    if (wage <= 0) return 0;
    final y = input.totalServiceYears;
    final first5 = y.clamp(0.0, 5.0);
    final after5 = (y - 5).clamp(0.0, 100.0);
    return (wage * 0.5 * first5) + (wage * after5);
  }

  static double _computeSaudiEndOfService(EosbModel input) {
    final base = saudiArticle84Base(input);
    if (base <= 0) return 0;

    return switch (input.terminationType) {
      // فصل تعسفي: مكافأة كاملة بلا خصم نسب الاستقالة (م. 84 — لا تُطبَّق م. 85)
      EosbTerminationType.employerDismissalUnfair => base,
      EosbTerminationType.employerDismissalValidReason => 0,
      EosbTerminationType.employeeResignation =>
        base * saudiResignationFactor(input.totalServiceYears),
      EosbTerminationType.contractExpiry =>
        _saudiContractExpiryAward(input, base),
      EosbTerminationType.mutualAgreement => base,
      EosbTerminationType.retirementOrDeath => base,
    };
  }

  /// انتهاء عقد: محدد المدة = م. 84 عند انتهاء المدة؛ غير محدد = م. 84 كاملة.
  static double _saudiContractExpiryAward(EosbModel input, double base) {
    if (input.contractType == EosbContractType.fixed &&
        input.totalServiceYears < 1) {
      return 0;
    }
    return base;
  }

  /// م. 85 — نسب الاستقالة.
  static double saudiResignationFactor(double years) {
    if (years < 2) return 0;
    if (years < 5) return 1 / 3;
    if (years < 10) return 2 / 3;
    return 1;
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
      EosbTerminationType.employerDismissalValidReason => 0,
      EosbTerminationType.employeeResignation =>
        base * uaeResignationFactor(input.totalServiceYears),
      EosbTerminationType.contractExpiry => base,
      EosbTerminationType.mutualAgreement => base,
      EosbTerminationType.retirementOrDeath => base,
      _ => base,
    };
  }

  // ─── بدلات إضافية ───────────────────────────────────────────────────

  /// بدل الإجازات المتبقية — (الراتب الشهري ÷ 30) × أيام متبقية.
  static double computeCashLeaveAllowance(EosbModel input) {
    if (input.accruedLeaveDays <= 0) return 0;
    final daily = input.leaveDailyWage;
    if (daily <= 0) return 0;
    return daily * input.accruedLeaveDays;
  }

  /// بدل إجازة سنوية تقديري — 21 أو 30 يوم حسب مدة الخدمة.
  static double computeVacationAllowance(EosbModel input) {
    if (input.dailyWage <= 0) return 0;
    return input.dailyWage * input.annualVacationDays;
  }

  /// تذكرة طيران — تقدير سنوي × سنوات الخدمة.
  static double computeFlightTicketAllowance(EosbModel input) {
    if (!input.includeFlightTicket ||
        input.ticketCost <= 0 ||
        input.totalServiceYears <= 0) {
      return 0;
    }
    final multiplier =
        input.ticketFrequency == FlightTicketFrequency.biannual ? 2.0 : 1.0;
    return input.ticketCost * multiplier * input.totalServiceYears;
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
          article: 'المادة 84 — فصل تعسفي',
          summary:
              'يستحق العامل مكافأة نهاية الخدمة كاملة دون تطبيق نسب الاستقالة: نصف شهر أجر (أساسي + سكن) عن كل سنة من أول 5 سنوات، وشهر أجر كامل عن كل سنة بعدها.',
        ),
      );
    } else {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 84 — حساب المكافأة',
          summary:
              'نصف شهر أجر (أساسي + بدل سكن) عن كل سنة من أول 5 سنوات، وشهر أجر كامل عن كل سنة بعدها.',
        ),
      );
    }

    if (input.isResignation) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 85 — الاستقالة',
          summary:
              'أقل من سنتين: لا مكافأة | من 2 إلى 5: ثلث المكافأة | من 5 إلى 10: ثلثان | 10 سنوات فأكثر: المكافأة كاملة.',
        ),
      );
    }

    if (input.terminationType == EosbTerminationType.contractExpiry) {
      refs.add(
        EosbLegalReference(
          article: input.contractType == EosbContractType.fixed
              ? 'انتهاء عقد محدد المدة — المادة 74'
              : 'انتهاء عقد غير محدد — المادة 75',
          summary: input.contractType == EosbContractType.fixed
              ? 'عند انتهاء مدة العقد المحدد دون تجديد، تُحسب المكافأة وفق المادة 84 إذا استوفى العامل مدة الخدمة.'
              : 'إنهاء عقد غير محدد المدة يستوجب احتساب المكافأة وفق المادة 84 مع مراعاة إشعار الإنهاء.',
        ),
      );
    }

    if (input.accruedLeaveDays > 0) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 109 — الإجازة السنوية',
          summary:
              'يستحق العامل أجر أيام إجازة لم يُستخدمها عند انتهاء الخدمة: (الراتب الشهري ÷ 30) × الأيام المتبقية.',
        ),
      );
    }

    if (input.includeFlightTicket) {
      refs.add(
        const EosbLegalReference(
          article: 'تذكرة السفر — العقد / اللائحة',
          summary:
              'إن نص العقد أو اللائحة على تذكرة سنوية للعامل وعائلته، يُحتسب بدل تقديري حسب تكلفة الوجهة ومدة الخدمة.',
        ),
      );
    }

    if (input.isValidEmployerDismissal) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 80 — فصل لسبب مشروع',
          summary:
              'قد يُسقط الفصل لسبب مشروع حق المكافأة — راجع سبب الإنهاء مع الموارد البشرية أو مستشار قانوني.',
        ),
      );
    }

    if (!input.noticeProvided) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 75 — إشعار الإنهاء',
          summary:
              'عدم الالتزام بمدة الإشعار قد يترتب عليه تعويض إضافي — تحقق من نوع العقد ومدة الإشعار.',
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
            'يستحق العامل مكافأة نهاية الخدمة عند إنهاء العقد أو انتهائه، وفق أحكام المادة 51.',
      ),
      const EosbLegalReference(
        article: 'المادة 51 — قيمة المكافأة',
        summary:
            '21 يوم أجر أساسي عن كل سنة من أول 5 سنوات، و30 يوماً عن كل سنة بعدها — بحد أقصى أجر سنتين.',
      ),
    ];

    if (input.isResignation) {
      refs.add(
        const EosbLegalReference(
          article: 'المرسوم الاتحادي رقم 33 لسنة 2021',
          summary:
              'الاستقالة: أقل من سنة (0) | 1–3 سنوات (0) | 3–5 سنوات (ثلث) | 5+ (كامل).',
        ),
      );
    }

    if (input.accruedLeaveDays > 0) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 75 — الإجازة السنوية',
          summary:
              'يُصرف للعامل أجر أيام الإجازة المتبقية عند انتهاء الخدمة.',
        ),
      );
    }

    if (input.includeFlightTicket) {
      refs.add(
        const EosbLegalReference(
          article: 'تذكرة السفر — العقد',
          summary:
              'تقدير تذكرة العودة للوطن حسب ما ينص عليه عقد العمل أو عُرف المهنة في القطاع.',
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
              '${input.accruedLeaveDays} يوم · أجر يومي ${input.leaveDailyWage.toStringAsFixed(0)}',
          amount: remainingLeavePay,
        ),
      if (vacationEntitlementPay > 0)
        EosbComponentItem(
          id: 'vacation',
          titleAr: 'بدل إجازة سنوية (تقديري)',
          subtitleAr:
              '${input.annualVacationDays} يوم · ${input.totalServiceYears.toStringAsFixed(1)} سنة خدمة',
          amount: vacationEntitlementPay,
        ),
      if (input.includeFlightTicket)
        EosbComponentItem(
          id: 'ticket',
          titleAr: 'تذكرة طيران (تقدير)',
          subtitleAr: _ticketSubtitle(input, flightTicketValue),
          amount: flightTicketValue,
        ),
    ];

    double? factor;
    if (input.isResignation && endOfServiceAward > 0) {
      factor = input.country == GulfCountry.uae
          ? uaeResignationFactor(input.totalServiceYears)
          : saudiResignationFactor(input.totalServiceYears);
      if (factor == 0) factor = null;
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
      resignationFactorApplied: factor,
    );
  }

  String _ticketSubtitle(EosbModel input, double amount) {
    if (amount <= 0) {
      return 'تقدير غير متاح — تحقق من مدة الخدمة والتكلفة';
    }
    final freq = EosbModel.ticketFrequencyLabel(input.ticketFrequency);
    final cost = input.ticketCost.round();
    final years = input.totalServiceYears.toStringAsFixed(1);
    return '$freq · $cost ${input.country.currencySymbol} × $years سنة';
  }

  String _eosSubtitle(EosbModel input, double amount) {
    if (amount <= 0 && input.isValidEmployerDismissal) {
      return 'فصل لسبب مشروع — قد لا يستحق (م. 80)';
    }
    if (input.isResignation) {
      final f = input.country == GulfCountry.uae
          ? uaeResignationFactor(input.totalServiceYears)
          : saudiResignationFactor(input.totalServiceYears);
      if (f == 0) return 'استقالة — أقل من الحد الأدنى للمدة';
      if (f < 1) {
        return 'استقالة — ${(f * 100).round()}% من مكافأة المادة 84';
      }
      return 'استقالة — مكافأة كاملة (م. 84 + 85)';
    }
    if (input.country == GulfCountry.uae) {
      return 'م. 51/132 — 21/30 يوم أجر أساسي · حد أقصى سنتان';
    }
    if (input.terminationType == EosbTerminationType.employerDismissalUnfair) {
      return 'فصل تعسفي — مكافأة كاملة (م. 84) دون خصم الاستقالة';
    }
    if (input.terminationType == EosbTerminationType.contractExpiry) {
      final type = EosbModel.contractTypeLabel(input.contractType);
      return 'انتهاء عقد ($type) — المادة 84';
    }
    return 'م. 84 — وعاء: أساسي + سكن';
  }
}
