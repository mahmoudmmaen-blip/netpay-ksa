enum Article77TerminatedBy { employee, employer }

enum Article77ContractType { fixedTerm, openEnded }

class Article77Input {
  const Article77Input({
    required this.terminatedBy,
    required this.contractType,
    required this.basicSalary,
    this.remainingMonths = 0,
    this.yearsOfService = 0,
    this.hasPenaltyClause = false,
    this.penaltyAmount = 0,
  });

  final Article77TerminatedBy terminatedBy;
  final Article77ContractType contractType;
  final double basicSalary;
  final double remainingMonths;
  final double yearsOfService;
  final bool hasPenaltyClause;
  final double penaltyAmount;
}

class Article77BreakdownLine {
  const Article77BreakdownLine(this.label, this.amount);
  final String label;
  final double amount;
}

class Article77Result {
  const Article77Result({
    required this.totalAmount,
    required this.breakdown,
    required this.legalReference,
    required this.note,
    this.isPenaltyOnly = false,
  });

  final double totalAmount;
  final List<Article77BreakdownLine> breakdown;
  final String legalReference;
  final String note;
  final bool isPenaltyOnly;
}

/// حاسبة الفسخ التعسفي — المادة 77 (السعودية).
abstract final class Article77Calculator {
  Article77Calculator._();

  static double _eosbEstimate(double salary, double years) {
    if (years < 1) return 0;
    final firstFive = years.clamp(0.0, 5.0);
    final afterFive = (years - 5).clamp(0.0, double.infinity);
    return salary * 0.5 * firstFive + salary * afterFive;
  }

  static double _noticeCompensation(
    Article77ContractType type,
    double salary,
  ) {
    final days = type == Article77ContractType.fixedTerm ? 30 : 60;
    return salary * days / 30;
  }

  static Article77Result calculate(Article77Input input) {
    final salary = input.basicSalary;
    if (salary <= 0) {
      return const Article77Result(
        totalAmount: 0,
        breakdown: [],
        legalReference: 'المادة 77 — نظام العمل السعودي',
        note: 'أدخل الراتب الأساسي لحساب التقدير',
      );
    }

    if (input.terminatedBy == Article77TerminatedBy.employee) {
      return _employeeEnded(input, salary);
    }
    return _employerEnded(input, salary);
  }

  static Article77Result _employeeEnded(Article77Input input, double salary) {
    if (input.hasPenaltyClause) {
      return Article77Result(
        totalAmount: input.penaltyAmount,
        breakdown: [
          Article77BreakdownLine('الشرط الجزائي', input.penaltyAmount),
        ],
        legalReference: 'شرط جزائي في العقد (لا يتجاوز أجر شهرين — المادة 77)',
        note: 'هذا تقدير استرشادي — استشر محامياً',
        isPenaltyOnly: true,
      );
    }

    final compensation = input.contractType == Article77ContractType.fixedTerm
        ? input.remainingMonths * salary
        : salary * 2;

    return Article77Result(
      totalAmount: compensation,
      breakdown: [
        Article77BreakdownLine(
          input.contractType == Article77ContractType.fixedTerm
              ? 'تعويض المدة الباقية (${input.remainingMonths.round()} شهر)'
              : 'تعويض عقد غير محدد (شهران)',
          compensation,
        ),
      ],
      legalReference: 'المادة 77 — نظام العمل السعودي',
      note: 'هذا تقدير استرشادي — استشر محامياً',
    );
  }

  static Article77Result _employerEnded(Article77Input input, double salary) {
    final breakdown = <Article77BreakdownLine>[];

    double art77Comp;
    if (input.contractType == Article77ContractType.fixedTerm) {
      art77Comp = input.remainingMonths * salary;
      breakdown.add(
        Article77BreakdownLine(
          'تعويض الفسخ التعسفي (${input.remainingMonths.round()} شهر باقٍ)',
          art77Comp,
        ),
      );
    } else {
      final months =
          (input.yearsOfService * 12 * 0.5).clamp(0.0, 12.0);
      art77Comp = months * salary;
      breakdown.add(
        Article77BreakdownLine(
          'تعويض الفسخ التعسفي (${months.round()} شهر — حد أقصى 12)',
          art77Comp,
        ),
      );
    }

    final eosb = _eosbEstimate(salary, input.yearsOfService);
    if (eosb > 0) {
      breakdown.add(
        Article77BreakdownLine(
          'مكافأة نهاية الخدمة (تقدير)',
          eosb,
        ),
      );
    }

    final notice = _noticeCompensation(input.contractType, salary);
    breakdown.add(
      Article77BreakdownLine('تعويض عدم الإشعار (تقدير)', notice),
    );

    final total =
        breakdown.fold<double>(0, (sum, line) => sum + line.amount);

    return Article77Result(
      totalAmount: total,
      breakdown: breakdown,
      legalReference:
          'المادة 77 + 84-85 (نهاية الخدمة) + 75 (الإشعار) — نظام العمل السعودي',
      note: 'هذا تقدير استرشادي — استشر محامياً',
    );
  }
}
