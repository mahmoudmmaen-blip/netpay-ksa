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

  /// حساب كامل لنهاية الخدمة من مدخلات المعالج.
  ///
  /// يشمل: مكافأة نهاية الخدمة، بدل الإجازات المتبقية، بدل إجازة سنوية،
  /// تذكرة طيران (تقدير)، والإجمالي + المراجع القانونية.
  EosbCalculationResult calculateEndOfService(EosbModel input) {
    // 1) مكافأة نهاية الخدمة
    //    السعودية: فصل تعسفي = (أساسي÷2)×أول5 + أساسي كامل بعدها
    //              استقالة/انتهاء عقد = م.84 (نصف وعاء أول5) + م.85 للاستقالة
    //    الإمارات: م.132/51 — 21/30 يوم على الأساسي بحد سنتين أجر
    final endOfServiceAward = input.endOfServiceAmount;

    // 2) بدل الإجازات المتبقية — (راتب أساسي ÷ 30) × أيام متبقية
    final remainingLeavePay = input.cashLeaveAllowance;

    // 3) بدل إجازة سنوية تقديري — 21 أو 30 يوم حسب مدة الخدمة
    final vacationEntitlementPay = input.vacationAllowance;

    // 4) تذكرة طيران — تقدير سنوي × سنوات الخدمة (إن وُجد المفتاح)
    final flightTicketValue = input.flightTicketAllowance;

    // 5) إجمالي المستحقات
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

  EosbCalculationResult _buildResult({
    required EosbModel input,
    required double endOfServiceAward,
    required double remainingLeavePay,
    required double vacationEntitlementPay,
    required double flightTicketValue,
    required double totalEntitlements,
  }) {
    final eos = endOfServiceAward;
    final vacation = vacationEntitlementPay;
    final leave = remainingLeavePay;
    final ticket = flightTicketValue;
    final total = totalEntitlements;

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
      return 'م. 132/51 — 21/30 يوم أجر أساسي · حد أقصى سنتان';
    }
    if (input.terminationType == EosbTerminationType.employerDismissalUnfair) {
      return 'فصل تعسفي — (أساسي÷2)×أول 5 سنوات، أساسي كامل بعدها';
    }
    if (input.terminationType == EosbTerminationType.contractExpiry) {
      return 'انتهاء عقد — م. 84 (أساسي + سكن)';
    }
    return 'م. 84 — وعاء: أساسي + سكن';
  }
}
