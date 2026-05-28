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
    if (mounted) setState(() => _loading = true);
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

  Future<void> _openDetails(EosbHistoryEntry entry) async {
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
    await context.push('${AppRoutes.eosb}?historyId=${entry.id}');
    if (mounted) await _load();
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
        actions: [
          if (_entries.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '${_entries.length}',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
                              height: MediaQuery.sizeOf(context).height * 0.18,
                            ),
                            const _EosbHistoryEmptyState(),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          itemCount: _entries.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _EosbHistoryCardAnimated(
                              index: index,
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
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.emerald.withValues(alpha: 0.22),
                  AppColors.emeraldDark.withValues(alpha: 0.06),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.history_rounded,
              size: 60,
              color: AppColors.emerald.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'لا توجد حسابات محفوظة بعد',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'بعد إنهاء حاسبة نهاية الخدمة، اضغط «حفظ الحساب» '
            'من شاشة النتائج لتظهر حساباتك هنا.',
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
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.eosb),
            icon: const Icon(Icons.calculate_rounded),
            label: Text(
              'فتح حاسبة نهاية الخدمة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة مع دخول متدرّج.
class _EosbHistoryCardAnimated extends StatefulWidget {
  const _EosbHistoryCardAnimated({
    required this.index,
    required this.entry,
    required this.isDark,
    required this.onView,
    required this.onDelete,
  });

  final int index;
  final EosbHistoryEntry entry;
  final bool isDark;
  final VoidCallback onView;
  final VoidCallback onDelete;

  @override
  State<_EosbHistoryCardAnimated> createState() => _EosbHistoryCardAnimatedState();
}

class _EosbHistoryCardAnimatedState extends State<_EosbHistoryCardAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 380 + (widget.index * 40).clamp(0, 200)),
    );
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fade = curve;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curve);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _EosbHistoryCard(
          entry: widget.entry,
          isDark: widget.isDark,
          onView: widget.onView,
          onDelete: widget.onDelete,
        ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(16),
        child: GlassSurface(
          highlighted: true,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppColors.emerald.withValues(alpha: isDark ? 0.3 : 0.16),
                      AppColors.emeraldDark.withValues(alpha: isDark ? 0.14 : 0.06),
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(flag, style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 10),
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
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.terminationSummary,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.emerald,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'إجمالي المستحقات',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currency.format(entry.totalEntitlements),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: AppColors.emerald,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateFmt.format(entry.savedAt),
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  children: [
                    _MiniStat(
                      label: 'مكافأة نهاية الخدمة',
                      value: currency.format(entry.endOfServiceAmount),
                    ),
                    const SizedBox(width: 8),
                    _MiniStat(
                      label: 'مدة الخدمة',
                      value: '${entry.serviceYears.toStringAsFixed(1)} سنة',
                    ),
                  ],
                ),
              ),
              const Divider(height: 20, indent: 12, endIndent: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
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
        ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
