import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/eosb/services/eosb_history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<EosbHistoryEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _entries = EosbHistoryService.loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy · HH:mm', 'ar');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'سجل الحسابات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
      ),
      body: _entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 72,
                      color: AppColors.emerald.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'لا توجد حسابات محفوظة بعد',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'احفظ حساب نهاية الخدمة من شاشة النتائج بزر «حفظ الحساب»',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: _entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final e = _entries[index];
                final currency = NumberFormat.currency(
                  locale: 'ar',
                  symbol: '${e.currencySymbol} ',
                  decimalDigits: 0,
                );
                return GlassSurface(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نهاية خدمة — ${e.countryNameAr}',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              e.terminationSummary,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              dateFmt.format(e.savedAt),
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currency.format(e.totalEntitlements),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
