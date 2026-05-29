import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/features/contract_analysis/presentation/contract_analysis_screen.dart';
import 'package:netgulf/features/eosb/presentation/eosb_wizard_screen.dart';
import 'package:netgulf/features/leave_balance/presentation/leave_balance_screen.dart';
import 'package:netgulf/features/notice_period/presentation/notice_period_screen.dart';

/// مسار `/eosb` — أربعة تبويبات: نهاية الخدمة · إشعار · إجازة · تحليل العقد.
class EosbScreen extends StatelessWidget {
  const EosbScreen({super.key, this.historyEntryId});

  final String? historyEntryId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.home),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المساعد القانوني',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              Text(
                'نهاية الخدمة · إشعار · إجازة · عقد',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.emerald,
            labelColor: AppColors.emeraldLight,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(
                icon: Icon(Icons.card_giftcard_rounded),
                text: 'نهاية الخدمة',
              ),
              Tab(
                icon: Icon(Icons.access_time_rounded),
                text: 'إشعار الإنهاء',
              ),
              Tab(
                icon: Icon(Icons.beach_access_rounded),
                text: 'رصيد الإجازة',
              ),
              Tab(
                icon: Icon(Icons.document_scanner_rounded),
                text: 'تحليل العقد',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            EosbWizardScreen(
              dedicatedEosbBranding: true,
              historyEntryId: historyEntryId,
              embeddedInHub: true,
            ),
            const NoticePeriodScreen(embeddedInHub: true),
            const LeaveBalanceScreen(embeddedInHub: true),
            const ContractAnalysisScreen(embeddedInHub: true),
          ],
        ),
      ),
    );
  }
}
