import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/eosb/services/eosb_history_service.dart';

/// سجل حسابات نهاية الخدمة المحفوظة.
class EosbHistoryScreen extends StatefulWidget {
  const EosbHistoryScreen({super.key});

  @override
  State<EosbHistoryScreen> createState() => _EosbHistoryScreenState();
}

class _EosbHistoryScreenState extends State<EosbHistoryScreen> {
  List<EosbHistoryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    setState(() {
      _entries = EosbHistoryService.loadAll();
      _loading = false;
    });
  }

  Future<void> _confirmDelete(EosbHistoryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'حذف الحساب؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'سيتم حذف حساب «${entry.terminationSummary}» '
          '(${entry.countryNameAr}) من السجل نهائياً.',
          style: GoogleFonts.cairo(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await EosbHistoryService.delete(entry.id);
    if (!mounted) return;

    if (ok) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حذف الحساب من السجل',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    }
  }

  void _openDetails(EosbHistoryEntry entry) {
    if (!entry.canOpenDetails) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'هذا السجل قديم — احفظ حساباً جديداً لعرض التفاصيل الكاملة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.push('${AppRoutes.eosb}?historyId=${entry.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'سجل نهاية الخدمة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.emerald),
                )
              : RefreshIndicator(
                  color: AppColors.emerald,
                  onRefresh: _load,
                  child: _entries.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.2,
                            ),
                            const _EosbHistoryEmptyState(),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: _entries.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _EosbHistoryCard(
                              entry: _entries[index],
                              isDark: isDark,
                              onView: () => _openDetails(_entries[index]),
                              onDelete: () => _confirmDelete(_entries[index]),
                            );
                          },
                        ),
                ),
        ),
      ),
    );
  }
}

class _EosbHistoryEmptyState extends StatelessWidget {
  const _EosbHistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.emerald.withValues(alpha: 0.2),
                  AppColors.emeraldDark.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 56,
              color: AppColors.emerald.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد حسابات محفوظة',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'بعد إنهاء حاسبة نهاية الخدمة، اضغط «حفظ الحساب» '
            'لتجد حساباتك هنا مع إمكانية عرض التفاصيل أو التصدير.',
            style: GoogleFonts.cairo(
              fontSize: 14,
              height: 1.55,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.eosb),
            icon: const Icon(Icons.calculate_rounded),
            label: Text(
              'فتح حاسبة نهاية الخدمة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EosbHistoryCard extends StatelessWidget {
  const _EosbHistoryCard({
    required this.entry,
    required this.isDark,
    required this.onView,
    required this.onDelete,
  });

  final EosbHistoryEntry entry;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEEE، d MMMM yyyy · HH:mm', 'ar');
    final currency = NumberFormat.currency(
      locale: 'ar',
      symbol: '${entry.currencySymbol} ',
      decimalDigits: 0,
    );
    final flag = entry.countryCode == 'uae' ? '🇦🇪' : '🇸🇦';

    return GlassSurface(
      highlighted: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.emerald.withValues(alpha: isDark ? 0.28 : 0.14),
                  AppColors.emeraldDark.withValues(alpha: isDark ? 0.12 : 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(flag, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.countryNameAr,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.terminationSummary,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.emerald,
                        ),
                      ),
                      Text(
                        dateFmt.format(entry.savedAt),
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'الإجمالي',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    Text(
                      currency.format(entry.totalEntitlements),
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                _MiniStat(
                  label: 'مكافأة',
                  value: currency.format(entry.endOfServiceAmount),
                ),
                const SizedBox(width: 8),
                _MiniStat(
                  label: 'الخدمة',
                  value: '${entry.serviceYears.toStringAsFixed(1)} سنة',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(
                      'حذف',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: Text(
                      'عرض التفاصيل',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.emerald.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
