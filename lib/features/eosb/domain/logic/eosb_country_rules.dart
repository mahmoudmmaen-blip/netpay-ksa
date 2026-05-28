import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';

/// صيغ مشتركة لمكافآت نهاية الخدمة (أيام أجر × سنوات).
abstract final class EosbGratuityFormulas {
  /// 15 يوماً عن كل سنة (أول [firstTierYears]) ثم 30 يوماً — عُمان / البحرين.
  static double fifteenThenThirtyDays({
    required double monthlyWage,
    required double totalYears,
    double minimumYears = 1,
    int firstTierYears = 3,
  }) {
    if (monthlyWage <= 0 || totalYears < minimumYears) return 0;
    final daily = monthlyWage / 30;
    final inFirst = totalYears.clamp(0.0, firstTierYears.toDouble());
    final afterFirst =
        (totalYears - firstTierYears).clamp(0.0, 100.0);
    return inFirst * 15 * daily + afterFirst * 30 * daily;
  }

  /// 21 يوماً (أول 5 سنوات) ثم 30 يوماً — قطر.
  static double twentyOneThenThirtyDays({
    required double monthlyWage,
    required double totalYears,
    double minimumYears = 1,
    double? capMonths,
  }) {
    if (monthlyWage <= 0 || totalYears < minimumYears) return 0;
    final daily = monthlyWage / 30;
    final inFirst5 = totalYears.clamp(0.0, 5.0);
    final after5 = (totalYears - 5.0).clamp(0.0, 100.0);
    var amount = inFirst5 * 21 * daily + after5 * 30 * daily;
    if (capMonths != null) {
      final cap = monthlyWage * capMonths;
      if (amount > cap) amount = cap;
    }
    return amount;
  }

  /// 30 يوماً (شهر أجر) عن كل سنة — الكويت.
  static double thirtyDaysPerYear({
    required double monthlyWage,
    required double totalYears,
    double minimumYears = 1,
  }) {
    if (monthlyWage <= 0 || totalYears < minimumYears) return 0;
    return monthlyWage * totalYears;
  }
}

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

  /// إنهاء من صاحب العمل / تقاعد / انتهاء عقد — مكافأة كاملة مع تعديلات الفصل المشروع.
  static double employerTerminationAward({
    required EosbModel input,
    required double fullBase,
  }) {
    if (fullBase <= 0) return 0;
    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair => fullBase,
      EosbTerminationType.employerDismissalValidReason => fullBase * 0.5,
      EosbTerminationType.contractExpiry =>
        input.contractType == EosbContractType.fixed &&
                input.totalServiceYears < 1
            ? fullBase * 0.5
            : fullBase,
      EosbTerminationType.mutualAgreement =>
        fullBase * (input.mutualAgreementPercent / 100),
      EosbTerminationType.retirementOrDeath => fullBase,
      EosbTerminationType.employeeResignation => fullBase,
    };
  }

  static double routeByTermination({
    required EosbModel input,
    required double fullBase,
    required double Function(double years) resignationFactor,
  }) {
    if (fullBase <= 0) return 0;
    if (input.isResignation) {
      return fullBase * resignationFactor(input.totalServiceYears);
    }
    return employerTerminationAward(input: input, fullBase: fullBase);
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

/// عُمان — المواد 49 و 50: 15/30 يوم · استقالة ≠ إنهاء من جهة العمل.
class OmanEosbRules extends EosbCountryRules {
  const OmanEosbRules();

  @override
  double fullGratuity(EosbModel input) => EosbGratuityFormulas.fifteenThenThirtyDays(
        monthlyWage: input.basicSalary,
        totalYears: input.totalServiceYears,
        minimumYears: 1,
      );

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
  double? appliedPercent(EosbModel input) {
    if (input.isResignation && input.totalServiceYears < 3) return 0;
    return EosbCountryRules.standardAppliedPercent(input);
  }

  @override
  String eosSubtitle(EosbModel input, double amount) {
    if (input.isResignation) {
      if (input.totalServiceYears < 3) {
        return 'استقالة — أقل من 3 سنوات (لا مكافأة · م. 50)';
      }
      return 'استقالة بعد 3 سنوات — مكافأة كاملة (15/30 يوم)';
    }
    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair =>
        'إنهاء من صاحب العمل — 100% (15/30 يوم · م. 49)',
      EosbTerminationType.employerDismissalValidReason =>
        'فصل لسبب مشروع — 50%',
      EosbTerminationType.mutualAgreement =>
        'اتفاق بالتراضي — ${input.mutualAgreementPercent.round()}%',
      EosbTerminationType.retirementOrDeath =>
        'تقاعد/وفاة — مكافأة كاملة',
      _ => 'م. 49 — 15 يوم (أول 3 سنوات) · 30 يوم بعدها',
    };
  }

  @override
  List<EosbLegalReference> legalReferences(EosbModel input) {
    final refs = <EosbLegalReference>[
      const EosbLegalReference(
        article: 'المادة 49 — مكافأة نهاية الخدمة',
        summary:
            '15 يوم أجر أساسي عن كل سنة من أول 3 سنوات، و30 يوماً عن كل سنة بعدها.',
      ),
    ];
    if (input.isResignation) {
      refs.add(
        const EosbLegalReference(
          article: 'المادة 50 — الاستقالة',
          summary:
              'الاستقالة قبل 3 سنوات: لا مكافأة. بعد 3 سنوات: المكافأة كاملة عن مدة الخدمة.',
        ),
      );
    } else {
      refs.add(
        const EosbLegalReference(
          article: 'إنهاء العقد من صاحب العمل',
          summary:
              'عند الفصل أو الإنهاء (غير الاستقالة): المكافأة حسب المادة 49 مع تعديل الفصل لسبب مشروع.',
        ),
      );
    }
    refs.addAll(EosbCountryRules.commonLeaveAndTicketRefs(input));
    return refs;
  }
}

/// قطر — قانون 14/2004 م. 51: 21 يوم (أول 5) · 30 يوم بعدها.
class QatarEosbRules extends EosbCountryRules {
  const QatarEosbRules();

  @override
  double fullGratuity(EosbModel input) =>
      EosbGratuityFormulas.twentyOneThenThirtyDays(
        monthlyWage: input.basicSalary,
        totalYears: input.totalServiceYears,
        minimumYears: 1,
        capMonths: 24,
      );

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
      return 'استقالة — ${(f * 100).round()}% من مكافأة م. 51';
    }
    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair =>
        'إنهاء — 100% · 21 يوم (أول 5) + 30 يوم',
      EosbTerminationType.employerDismissalValidReason =>
        'فصل لسبب مشروع — 50%',
      _ => 'م. 51 — 21 يوم (أول 5 سنوات) · 30 يوم بعدها',
    };
  }

  @override
  List<EosbLegalReference> legalReferences(EosbModel input) {
    final refs = <EosbLegalReference>[
      const EosbLegalReference(
        article: 'قانون العمل رقم 14 لسنة 2004 — المادة 51',
        summary:
            'مكافأة نهاية الخدمة: 21 يوم أجر أساسي عن كل سنة من أول 5 سنوات، '
            'و30 يوماً عن كل سنة بعدها (حد أقصى أجر 24 شهراً).',
      ),
    ];
    if (input.isResignation) {
      refs.add(
        const EosbLegalReference(
          article: 'الاستقالة — تخفيض المكافأة',
          summary:
              'أقل من سنتين: لا مكافأة | 2–5 سنوات: ثلث | 5–10: ثلثان | 10+: كامل.',
        ),
      );
    }
    refs.addAll(EosbCountryRules.commonLeaveAndTicketRefs(input));
    return refs;
  }
}

/// البحرين — 15/30 يوم أجر (أول 3 سنوات / بعدها) مع شروط الاستقالة.
class BahrainEosbRules extends EosbCountryRules {
  const BahrainEosbRules();

  @override
  double fullGratuity(EosbModel input) =>
      EosbGratuityFormulas.fifteenThenThirtyDays(
        monthlyWage: input.eosWageBase,
        totalYears: input.totalServiceYears,
        minimumYears: 1,
      );

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
      return 'استقالة — أقل من 3 سنوات (شرط الاستحقاق)';
    }
    if (input.isResignation && input.totalServiceYears >= 3 &&
        input.totalServiceYears < 5) {
      return 'استقالة 3–5 سنوات — 50% من المكافأة';
    }
    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair =>
        'إنهاء — 100% · 15/30 يوم أجر',
      EosbTerminationType.employerDismissalValidReason =>
        'فصل لسبب مشروع — 50%',
      _ => '15 يوم/سنة (أول 3) · 30 يوم/سنة بعدها',
    };
  }

  @override
  List<EosbLegalReference> legalReferences(EosbModel input) {
    final refs = <EosbLegalReference>[
      const EosbLegalReference(
        article: 'قانون العمل البحريني — مكافأة نهاية الخدمة',
        summary:
            '15 يوم أجر عن كل سنة من أول 3 سنوات خدمة، و30 يوماً عن كل سنة بعدها '
            '(على أساس آخر أجر مستحق شامل البدلات المعتادة).',
      ),
      const EosbLegalReference(
        article: 'شروط الاستحقاق',
        summary: 'الحد الأدنى سنة خدمة واحدة مكتملة لاستحقاق المكافأة.',
      ),
    ];
    if (input.isResignation) {
      refs.add(
        const EosbLegalReference(
          article: 'الاستقالة — شروط مخفّضة',
          summary:
              'أقل من 3 سنوات: لا مكافأة | من 3 إلى 5: نصف المكافأة | 5 سنوات فأكثر: كامل.',
        ),
      );
    }
    refs.addAll(EosbCountryRules.commonLeaveAndTicketRefs(input));
    return refs;
  }
}

/// الكويت — 30 يوم أجر عن كل سنة (حد أدنى سنة خدمة).
class KuwaitEosbRules extends EosbCountryRules {
  const KuwaitEosbRules();

  static const double minimumServiceYears = 1;

  @override
  double fullGratuity(EosbModel input) =>
      EosbGratuityFormulas.thirtyDaysPerYear(
        monthlyWage: input.eosWageBase,
        totalYears: input.totalServiceYears,
        minimumYears: minimumServiceYears,
      );

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
    if (input.totalServiceYears < minimumServiceYears) {
      return 'أقل من سنة خدمة — لا مكافأة (م. 51)';
    }
    if (amount <= 0 && input.isResignation && input.totalServiceYears < 3) {
      return 'استقالة — أقل من 3 سنوات';
    }
    final f = resignationFactor(input.totalServiceYears);
    if (input.isResignation && f > 0 && f < 1) {
      return 'استقالة — ${(f * 100).round()}% · 30 يوم/سنة';
    }
    return switch (input.terminationType) {
      EosbTerminationType.employerDismissalUnfair =>
        'إنهاء — 100% · 30 يوم أجر عن كل سنة',
      EosbTerminationType.employerDismissalValidReason =>
        'فصل لسبب مشروع — 50%',
      _ => 'م. 51 — شهر أجر (30 يوم) عن كل سنة خدمة',
    };
  }

  @override
  List<EosbLegalReference> legalReferences(EosbModel input) {
    final refs = <EosbLegalReference>[
      const EosbLegalReference(
        article: 'قانون العمل رقم 6 لسنة 2010 — المادة 51',
        summary:
            'مكافأة نهاية الخدمة: 30 يوماً (شهر أجر) عن كل سنة خدمة، '
            'بشرط إتمام سنة خدمة واحدة على الأقل.',
      ),
    ];
    if (input.isResignation) {
      refs.add(
        const EosbLegalReference(
          article: 'الاستقالة — المادة 53',
          summary:
              'أقل من 3 سنوات: لا مكافأة | 3–5: نصف | 5–10: ثلثان | 10+: كامل.',
        ),
      );
    }
    if (input.totalServiceYears < minimumServiceYears) {
      refs.add(
        const EosbLegalReference(
          article: 'الحد الأدنى للخدمة',
          summary: 'لا تستحق مكافأة إذا كانت مدة الخدمة أقل من سنة واحدة.',
        ),
      );
    }
    refs.addAll(EosbCountryRules.commonLeaveAndTicketRefs(input));
    return refs;
  }
}
