import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/services/premium_access.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/premium_badge.dart';
import 'package:netgulf/core/widgets/premium_gate_sheet.dart';
import 'package:netgulf/features/pdf_export/pdf_service.dart';
import 'package:netgulf/features/salary_calculator/models/salary_record.dart';
import 'package:netgulf/features/salary_calculator/providers/history_notifier.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyNotifierProvider);
    final isPremium = PremiumAccess.watchIsPremium(ref);
    final recordCount = historyAsync.valueOrNull?.length ?? 0;
    final limit = isPremium ? null : AppConstants.freeHistoryLimit;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سجل الرواتب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!isPremium)
            IconButton(
              tooltip: 'ترقية Premium',
              icon: const Icon(Icons.workspace_premium_rounded),
              color: AppColors.goldBright,
              onPressed: () => showPremiumGate(
                context,
                feature: PremiumFeature.unlimitedHistory,
              ),
            ),
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 12),
            child: Center(
              child: PremiumBadge(compact: true, size: 24),
            ),
          ),
          historyAsync.whenOrNull(
                data: (list) => list.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح الكل',
                        icon: const Icon(Icons.delete_sweep_rounded),
                        onPressed: () => _confirmClearAll(context, ref),
                      ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('حدث خطأ: $e', style: GoogleFonts.cairo()),
        ),
        data: (records) => Column(
          children: [
            if (!isPremium && limit != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _LimitBanner(used: recordCount, limit: limit),
              ),
            Expanded(
              child: records.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: records.length,
                      itemBuilder: (_, i) => _RecordCard(
                        record: records[i],
                        onDelete: () => ref
                            .read(historyNotifierProvider.notifier)
                            .delete(records[i].id),
                        onRestore: () => _restore(ref, records[i]),
                        onExportPdf: () =>
                            _exportPdf(context, ref, records[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _trySave(context, ref),
        icon: const Icon(Icons.save_rounded),
        label: Text('حفظ الراتب الحالي', style: GoogleFonts.cairo()),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  void _restore(WidgetRef ref, SalaryRecord r) {
    final n = ref.read(salaryNotifierProvider.notifier);
    n.setBasic(r.basicSalary);
    n.setHousing(r.housingAllowance);
    n.setOther(r.otherAllowances);
    n.setIncludeOtherInGosi(r.includeOtherInGosiBase);
    n.setNationality(r.nationality);
    n.setRegime(r.regime);
  }

  Future<void> _trySave(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(historyNotifierProvider.notifier);
    if (!await notifier.canSaveMore()) {
      if (!context.mounted) return;
      await PremiumAccess.requirePremium(
        context,
        ref,
        feature: PremiumFeature.unlimitedHistory,
      );
      return;
    }
    if (!context.mounted) return;
    await _showSaveDialog(context, ref);
  }

  Future<void> _showSaveDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'حفظ الراتب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'اسم السجل (اختياري)',
            hintStyle: GoogleFonts.cairo(),
          ),
          style: GoogleFonts.cairo(),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
            child: Text('حفظ', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final saved = await ref
          .read(historyNotifierProvider.notifier)
          .saveCurrentSalary(controller.text);
      if (!context.mounted) return;
      if (saved) {
        await PremiumAccess.showInterstitialIfFree(ref);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الراتب', style: GoogleFonts.cairo()),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    WidgetRef ref,
    SalaryRecord record,
  ) async {
    if (PremiumAccess.isFeatureLocked(ref)) {
      final upgraded = await PremiumAccess.requirePremium(
        context,
        ref,
        feature: PremiumFeature.pdfExport,
      );
      await PremiumAccess.showInterstitialIfFree(ref);
      if (!upgraded || !context.mounted) return;
    }

    try {
      await PdfService.exportAndShare(record);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذّر تصدير PDF. حاول مرة أخرى.',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    }
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'مسح الكل',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'هل أنت متأكد من مسح جميع السجلات؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('مسح', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyNotifierProvider.notifier).clearAll();
    }
  }
}

class _LimitBanner extends StatelessWidget {
  const _LimitBanner({required this.used, required this.limit});

  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'النسخة المجانية: $used / $limit سجلات — Premium للسجل الكامل',
              style: GoogleFonts.cairo(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد سجلات محفوظة',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على "حفظ الراتب الحالي" للبدء',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onDelete,
    required this.onRestore,
    required this.onExportPdf,
  });

  final SalaryRecord record;
  final VoidCallback onDelete;
  final VoidCallback onRestore;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.emerald.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.label,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  dateFormat.format(record.savedAt),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoChip(
                  label: 'صافي',
                  value: currency.format(record.netSalary),
                  highlight: true,
                ),
                _InfoChip(
                  label: 'إجمالي',
                  value: currency.format(record.totalGross),
                ),
                _InfoChip(
                  label: 'GOSI',
                  value: currency.format(record.employeeGosi),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onExportPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: Text('PDF', style: GoogleFonts.cairo(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                ),
                TextButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: Text('استعادة', style: GoogleFonts.cairo(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.emerald),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text('حذف', style: GoogleFonts.cairo(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.emerald : null,
          ),
        ),
      ],
    );
  }
}
