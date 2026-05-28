import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';

/// قواعد حساب مكافأة نهاية الخدمة — عُمان، قطر، البحرين، الكويت.
abstract class EosbCountryRules {
  const EosbCountryRules();

  static EosbCountryRules? forCountry(GulfCountry country) => switch (country) {
        GulfCountry.oman => const OmanEosbRules(),
        GulfCountry.qatar => const QatarEosbRules(),
        GulfCountry.bahrain => const BahrainEosbRules(),
        GulfCountry.kuwait => const KuwaitEosbRules(),
        _ => null,
      };

  double fullGratuity(EosbModel input);
  double gratuityByTermination(EosbModel input);
  double resignationFactor(double years);
  double? appliedPercent(EosbModel input);
  List<EosbLegalReference> legalReferences(EosbModel input);
  String eosSubtitle(EosbModel input, double amount);

  bool shouldShowResignationZeroBanner(EosbModel input, double award) =>
      input.isResignation &&
      award <= 0 &&
      resignationFactor(input.totalServiceYears) <= 0;

  static double routeByTermination({
    required EosbModel input,
    required double fullBase,
    required double Function(double years) resignationFactor,
  }) {
    if (fullBase <= 0) return 0;
    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair => fullBase,
      EosbTerminationType.employerDismissalValidReason => fullBase * 0.5,
      EosbTerminationType.employeeResignation =>
        fullBase * resignationFactor(input.totalServiceYears),
      EosbTerminationType.contractExpiry =>
        input.contractType == EosbContractType.fixed &&
                input.totalServiceYears < 1
            ? fullBase * 0.5
            : fullBase,
      EosbTerminationType.mutualAgreement =>
        fullBase * (input.mutualAgreementPercent / 100),
      EosbTerminationType.retirementOrDeath => fullBase,
    };
  }

  static double? standardAppliedPercent(EosbModel input) =>
      switch (input.terminationType) {
        EosbTerminationType.employerDismissalUnfair => 100.0,
        EosbTerminationType.employerDismissalValidReason => 50.0,
        EosbTerminationType.mutualAgreement => input.mutualAgreementPercent,
        EosbTerminationType.contractExpiry when
              input.contractType == EosbContractType.fixed &&
                  input.totalServiceYears < 1 =>
          50.0,
        _ => null,
      };

  static List<EosbLegalReference> commonLeaveAndTicketRefs(EosbModel input) {
    final refs = <EosbLegalReference>[];
    if (input.accruedLeaveDays > 0) {
      refs.add(
        const EosbLegalReference(
          article: 'الإجازة السنوية المتبقية',
          summary:
              '(الأجر اليومي) × أيام الإجازة غير المستخدمة عند إنهاء الخدمة.',
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
          article: 'مدة الإشعار',
          summary:
              'عدم الالتزام بمدة الإشعار قد يترتب عليه تعويض إضافي — راجع العقد.',
        ),
      );
    }
    return refs;
  }
}

/// عُمان — المواد 49 و 50.
class OmanEosbRules extends EosbCountryRules {
  const OmanEosbRules();

  @override
  double fullGratuity(EosbModel input) {
    if (input.basicSalary <= 0 || input.totalServiceYears < 1) return 0;
    final daily = input.basicSalary / 30;
    final first3 = input.totalServiceYears.clamp(0, 3) * 15 * daily;
    final after3 = (input.totalServiceYears - 3).clamp(0, 100) * 30 * daily;
    return first3 + after3;
  }

  @override
  double gratuityByTermination(EosbModel input) =>
      EosbCountryRules.routeByTermination(
        input: input,
        fullBase: fullGratuity(input),
        resignationFactor: resignationFactor,
      );

  @override
  double resignationFactor(double years) => years < 3 ? 0 : 1;

  @override
  double? appliedPercent(EosbModel input) =>
      EosbCountryRules.standardAppliedPercent(input);

  @override
  String eosSubtitle(EosbModel input, double amount) {
    if (amount <= 0 && input.isResignation && input.totalServiceYears < 3) {
      return 'استقالة — أقل من 3 سنوات (لا مكافأة)';
    }
    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair =>
        'فصل تعسفي — 100% (15/30 يوم أجر)',
      EosbTerminationType.employerDismissalValidReason =>
        'فصل لسبب مشروع — 50%',
      EosbTerminationType.employeeResignation => 'استقالة — م. 49/50',
      EosbTerminationType.mutualAgreement =>
        'اتفاق بالتراضي — ${input.mutualAgreementPercent.round()}%',
      _ => 'م. 49 — 15 يوم (أول 3 سنوات) · 30 يوم بعدها',
    };
  }

  @override
  List<EosbLegalReference> legalReferences(EosbModel input) {
    final refs = <EosbLegalReference>[
      const EosbLegalReference(
        article: 'المادة 49 — مكافأة نهاية الخدمة',
        summary:
            '15 يوماً من الأجر الأساسي عن كل سنة من أول 3 سنوات، و30 يوماً عن كل سنة بعدها.',
      ),
    ];
    if (input.isResignation) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 50 — الاستقالة',
          summary: 'الاستقالة قبل 3 سنوات: لا تستحق مكافأة نهاية الخدمة.',
        ),
      );
    }
    refs.addAll(EosbCountryRules.commonLeaveAndTicketRefs(input));
    return refs;
  }
}

/// قطر — قانون 14/2004 م. 51.
class QatarEosbRules extends EosbCountryRules {
  const QatarEosbRules();

  @override
  double fullGratuity(EosbModel input) {
    if (input.basicSalary <= 0 || input.totalServiceYears < 1) return 0;
    final daily = input.basicSalary / 30;
    final first5 = input.totalServiceYears.clamp(0, 5) * 21 * daily;
    final after5 = (input.totalServiceYears - 5).clamp(0, 100) * 30 * daily;
    final amount = first5 + after5;
    final cap = input.basicSalary * 24;
    return amount > cap ? cap : amount;
  }

  @override
  double gratuityByTermination(EosbModel input) =>
      EosbCountryRules.routeByTermination(
        input: input,
        fullBase: fullGratuity(input),
        resignationFactor: resignationFactor,
      );

  @override
  double resignationFactor(double years) {
    if (years < 2) return 0;
    if (years < 5) return 1 / 3;
    if (years < 10) return 2 / 3;
    return 1;
  }

  @override
  double? appliedPercent(EosbModel input) =>
      EosbCountryRules.standardAppliedPercent(input);

  @override
  String eosSubtitle(EosbModel input, double amount) {
    if (amount <= 0 && input.isResignation && input.totalServiceYears < 2) {
      return 'استقالة — أقل من سنتين (لا مكافأة)';
    }
    final f = resignationFactor(input.totalServiceYears);
    if (input.isResignation && f > 0 && f < 1) {
      return 'استقالة — ${(f * 100).round()}% من المكافأة';
    }
    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair => 'فصل تعسفي — 100% م. 51',
      EosbTerminationType.employerDismissalValidReason =>
        'فصل لسبب مشروع — 50%',
      _ => 'م. 51 — 21/30 يوم · حد سنتان أجر',
    };
  }

  @override
  List<EosbLegalReference> legalReferences(EosbModel input) {
    final refs = <EosbLegalReference>[
      const EosbLegalReference(
        article: 'قانون العمل رقم 14 لسنة 2004 — المادة 51',
        summary:
            '21 يوم أجر أساسي عن كل سنة (أول 5 سنوات) و30 يوماً بعدها — بحد أقصى أجر سنتين.',
      ),
    ];
    if (input.isResignation) {
      refs.add(
        const EosbLegalReference(
          article: 'الاستقالة — تخفيض المكافأة',
          summary:
              'أقل من سنتين (0) | 2–5 سنوات (ثلث) | 5–10 (ثلثان) | 10+ (كامل).',
        ),
      );
    }
    refs.addAll(EosbCountryRules.commonLeaveAndTicketRefs(input));
    return refs;
  }
}

/// البحرين — مكافأة نهاية الخدمة (قطاع خاص).
class BahrainEosbRules extends EosbCountryRules {
  const BahrainEosbRules();

  @override
  double fullGratuity(EosbModel input) {
    final wage = input.eosWageBase;
    if (wage <= 0 || input.totalServiceYears < 1) return 0;
    final first3 = input.totalServiceYears.clamp(0, 3) * 0.5 * wage;
    final after3 = (input.totalServiceYears - 3).clamp(0, 100) * wage;
    return first3 + after3;
  }

  @override
  double gratuityByTermination(EosbModel input) =>
      EosbCountryRules.routeByTermination(
        input: input,
        fullBase: fullGratuity(input),
        resignationFactor: resignationFactor,
      );

  @override
  double resignationFactor(double years) {
    if (years < 3) return 0;
    if (years < 5) return 0.5;
    return 1;
  }

  @override
  double? appliedPercent(EosbModel input) =>
      EosbCountryRules.standardAppliedPercent(input);

  @override
  String eosSubtitle(EosbModel input, double amount) {
    if (amount <= 0 && input.isResignation && input.totalServiceYears < 3) {
      return 'استقالة — أقل من 3 سنوات';
    }
    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair =>
        'فصل تعسفي — مكافأة كاملة',
      EosbTerminationType.employerDismissalValidReason =>
        'فصل لسبب مشروع — 50%',
      EosbTerminationType.employeeResignation =>
        'استقالة — نصف/كامل حسب المدة',
      _ => 'نصف شهر (أول 3 سنوات) + شهر كامل بعدها',
    };
  }

  @override
  List<EosbLegalReference> legalReferences(EosbModel input) {
    final refs = <EosbLegalReference>[
      const EosbLegalReference(
        article: 'قانون العمل البحريني — مكافأة نهاية الخدمة',
        summary:
            'نصف أجر شهري عن كل سنة من أول 3 سنوات، وأجر شهري كامل عن كل سنة بعدها.',
      ),
    ];
    if (input.isResignation) {
      refs.add(
        const EosbLegalReference(
          article: 'الاستقالة',
          summary: 'أقل من 3 سنوات (0) | 3–5 (نصف) | 5+ (كامل).',
        ),
      );
    }
    refs.addAll(EosbCountryRules.commonLeaveAndTicketRefs(input));
    return refs;
  }
}

/// الكويت — قانون 6/2010 م. 51.
class KuwaitEosbRules extends EosbCountryRules {
  const KuwaitEosbRules();

  @override
  double fullGratuity(EosbModel input) {
    final wage = input.eosWageBase;
    if (wage <= 0 || input.totalServiceYears < 1) return 0;
    final first5 = input.totalServiceYears.clamp(0, 5) * (wage / 2);
    final after5 = (input.totalServiceYears - 5).clamp(0, 100) * wage;
    return first5 + after5;
  }

  @override
  double gratuityByTermination(EosbModel input) =>
      EosbCountryRules.routeByTermination(
        input: input,
        fullBase: fullGratuity(input),
        resignationFactor: resignationFactor,
      );

  @override
  double resignationFactor(double years) {
    if (years < 3) return 0;
    if (years < 5) return 0.5;
    if (years < 10) return 2 / 3;
    return 1;
  }

  @override
  double? appliedPercent(EosbModel input) =>
      EosbCountryRules.standardAppliedPercent(input);

  @override
  String eosSubtitle(EosbModel input, double amount) {
    if (amount <= 0 && input.isResignation && input.totalServiceYears < 3) {
      return 'استقالة — أقل من 3 سنوات';
    }
    final f = resignationFactor(input.totalServiceYears);
    if (input.isResignation && f > 0 && f < 1) {
      return 'استقالة — ${(f * 100).round()}% من المكافأة';
    }
    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair => 'فصل تعسفي — 100% م. 51',
      EosbTerminationType.employerDismissalValidReason =>
        'فصل لسبب مشروع — 50%',
      _ => 'م. 51 — 15 يوم/سنة (أول 5) · شهر/سنة بعدها',
    };
  }

  @override
  List<EosbLegalReference> legalReferences(EosbModel input) {
    final refs = <EosbLegalReference>[
      const EosbLegalReference(
        article: 'قانون العمل رقم 6 لسنة 2010 — المادة 51',
        summary:
            '15 يوم أجر عن كل سنة من أول 5 سنوات، وأجر شهر كامل عن كل سنة بعدها.',
      ),
    ];
    if (input.isResignation) {
      refs.add(
        const EosbLegalReference(
          article: 'الاستقالة — المادة 53',
          summary:
              'أقل من 3 (0) | 3–5 (نصف) | 5–10 (ثلثان) | 10+ (كامل).',
        ),
      );
    }
    refs.addAll(EosbCountryRules.commonLeaveAndTicketRefs(input));
    return refs;
  }
}
