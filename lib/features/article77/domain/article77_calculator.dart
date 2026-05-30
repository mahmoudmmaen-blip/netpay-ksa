import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/notice_period/domain/notice_period_model.dart';

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
  const Article77BreakdownLine(this.label, this.amount, {this.isTotal = false});

  final String label;
  final double amount;
  final bool isTotal;
}

class Article77Result {
  const Article77Result({
    required this.totalAmount,
    required this.breakdown,
    required this.legalReference,
    required this.note,
    this.isPenaltyOnly = false,
    this.showEmployerBreakdown = false,
  });

  final double totalAmount;
  final List<Article77BreakdownLine> breakdown;
  final String legalReference;
  final String note;
  final bool isPenaltyOnly;
  final bool showEmployerBreakdown;
}

/// حاسبة الفسخ التعسفي — المادة 77 (السعودية).
abstract final class Article77Calculator {
  Article77Calculator._();

  static const _eosbCalc = EosbCalculator();

  static EosbModel _eosbModelFor(Article77Input input) {
    final years = input.yearsOfService.floor();
    final months =
        ((input.yearsOfService - years) * 12).round().clamp(0, 11);
    return EosbModel(
      country: GulfCountry.saudiArabia,
      yearsOfService: years,
      monthsOfService: months,
      basicSalary: input.basicSalary,
      contractType: input.contractType == Article77ContractType.fixedTerm
          ? EosbContractType.fixed
          : EosbContractType.unlimited,
      terminationType: EosbTerminationType.employerDismissalUnfair,
      noticeProvided: false,
    );
  }

  static double _noticeCompensation(Article77Input input) {
    final years = input.yearsOfService.floor();
    final months =
        ((input.yearsOfService - years) * 12).round().clamp(0, 11);
    final noticeModel = NoticePeriodModel(
      country: GulfCountry.saudiArabia,
      monthlyBasicSalary: input.basicSalary,
      serviceYears: years,
      serviceMonths: months,
      contractType: input.contractType == Article77ContractType.fixedTerm
          ? EosbContractType.fixed
          : EosbContractType.unlimited,
      noticeWasGiven: false,
      daysNoticeGiven: 0,
    );
    return noticeModel.compensationAmount;
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
    double art77Comp;
    if (input.contractType == Article77ContractType.fixedTerm) {
      art77Comp = input.remainingMonths * salary;
    } else {
      final months = (input.yearsOfService * 12 * 0.5).clamp(0.0, 12.0);
      art77Comp = months * salary;
    }

    final eosbResult =
        _eosbCalc.calculateEndOfService(_eosbModelFor(input));
    final eosbAmount = eosbResult.endOfServiceAmount;
    final noticeAmount = _noticeCompensation(input);
    final total = art77Comp + eosbAmount + noticeAmount;

    return Article77Result(
      totalAmount: total,
      showEmployerBreakdown: true,
      breakdown: [
        Article77BreakdownLine('مكافأة نهاية الخدمة', eosbAmount),
        Article77BreakdownLine('تعويض الفسخ التعسفي', art77Comp),
        Article77BreakdownLine('بدل الإشعار', noticeAmount),
        Article77BreakdownLine('الإجمالي المستحق', total, isTotal: true),
      ],
      legalReference:
          'المادة 77 + 84-85 (نهاية الخدمة) + 75 (الإشعار) — نظام العمل السعودي',
      note: 'هذا تقدير استرشادي — استشر محامياً',
    );
  }
}
