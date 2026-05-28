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

/// نتيجة حاسبة نهاية الخدمة — السعودية (84/85) والإمارات.
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

  EosbCalculationResult calculate(EosbModel input) {
    final eos = input.endOfServiceAmount;
    final vacation = input.vacationAllowance;
    final leave = input.cashLeaveAllowance;
    final ticket = input.flightTicketAllowance;
    final total = input.totalEntitlements;

    final components = <EosbComponentItem>[
      EosbComponentItem(
        id: 'eos',
        titleAr: 'مكافأة نهاية الخدمة',
        subtitleAr: _eosSubtitle(input),
        amount: eos,
        isPrimary: true,
      ),
      if (leave > 0)
        EosbComponentItem(
          id: 'leave',
          titleAr: 'بدل الإجازات المتبقية',
          subtitleAr:
              '${input.accruedLeaveDays} يوم · أجر يومي ${(input.basicSalary / 30).toStringAsFixed(0)}',
          amount: leave,
        ),
      EosbComponentItem(
        id: 'vacation',
        titleAr: 'بدل إجازة سنوية (تقديري)',
        subtitleAr:
            '${input.annualVacationDays} يوم · ${input.totalServiceYears.toStringAsFixed(1)} سنة خدمة',
        amount: vacation,
      ),
      if (input.includeFlightTicket)
        EosbComponentItem(
          id: 'ticket',
          titleAr: 'تذكرة طيران سنوية (تقدير)',
          subtitleAr: _ticketSubtitle(input, ticket),
          amount: ticket,
        ),
    ];

    double? factor;
    if (input.isResignation && input.fullEndOfServiceBase > 0) {
      factor = input.resignationAwardFactor;
    }

    return EosbCalculationResult(
      input: input,
      endOfServiceAmount: eos,
      vacationAllowance: vacation,
      cashLeaveAllowance: leave,
      flightTicketAllowance: ticket,
      totalEntitlements: total,
      components: components,
      legalReferences: input.legalReferences,
      resignationFactorApplied: factor,
    );
  }

  String _ticketSubtitle(EosbModel input, double amount) {
    if (amount <= 0) {
      return 'تقدير غير متاح — تحقق من مدة الخدمة والراتب';
    }
    final freq = EosbModel.ticketFrequencyLabel(input.ticketFrequency);
    final cost = input.ticketCost.round();
    final years = input.totalServiceYears.toStringAsFixed(1);
    return '$freq · $cost ${input.country.currencySymbol} × $years سنة';
  }

  String _eosSubtitle(EosbModel input) {
    if (input.isValidEmployerDismissal) {
      return 'فصل لسبب مشروع — قد لا يستحق (م. 80)';
    }
    if (input.isResignation) {
      final f = input.resignationAwardFactor;
      if (f == 0) return 'استقالة — أقل من الحد الأدنى للمدة';
      if (f < 1) {
        return 'استقالة — نسبة ${(f * 100).round()}% من المكافأة';
      }
    }
    if (input.country == GulfCountry.uae) {
      return '21/30 يوم أجر أساسي · حد أقصى سنتان';
    }
    return 'م. 84 — وعاء: أساسي + سكن';
  }
}
