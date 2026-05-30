import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/api_keys.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/contract_analysis/presentation/contract_result_screen.dart';
import 'package:netgulf/features/contract_analysis/providers/contract_analysis_provider.dart';
import 'package:netgulf/features/eosb/presentation/widgets/eosb_country_grid.dart';

/// شاشة رفع وتحليل عقد العمل PDF.
class ContractAnalysisScreen extends ConsumerStatefulWidget {
  const ContractAnalysisScreen({
    super.key,
    this.embeddedInHub = false,
  });

  final bool embeddedInHub;

  @override
  ConsumerState<ContractAnalysisScreen> createState() =>
      _ContractAnalysisScreenState();
}

class _ContractAnalysisScreenState
    extends ConsumerState<ContractAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(contractAnalysisBootstrapProvider);
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر قراءة الملف', style: GoogleFonts.cairo()),
          ),
        );
        return;
      }
      HapticFeedback.selectionClick();
      ref.read(contractAnalysisControllerProvider).setPdf(bytes, file.name);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل اختيار الملف', style: GoogleFonts.cairo()),
        ),
      );
    }
  }

  Future<void> _analyze() async {
    if (!ApiKeys.canUseLiveAnthropic &&
        ApiKeys.effectiveClaudeApiKey.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('مفتاح API', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
          content: Text(
            'أضف مفتاح Claude API في الإعدادات\n\n'
            'flutter run --dart-define=CLAUDE_API_KEY=your_key',
            style: GoogleFonts.cairo(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('حسناً', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      );
      return;
    }

    await ref.read(contractAnalysisControllerProvider).analyze();
    if (!mounted) return;

    final error = ref.read(contractAnalysisErrorProvider);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.cairo()),
          action: SnackBarAction(
            label: 'إعادة',
            onPressed: _analyze,
          ),
        ),
      );
      return;
    }

    final result = ref.read(contractAnalysisResultProvider);
    if (result != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ContractResultScreen(
            result: result,
            embeddedInHub: widget.embeddedInHub,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(contractAnalysisBootstrapProvider);

    final country = ref.watch(contractAnalysisCountryProvider);
    final fileName = ref.watch(contractAnalysisFileNameProvider);
    final pdf = ref.watch(contractAnalysisPdfProvider);
    final loading = ref.watch(contractAnalysisLoadingProvider);
    final progress = ref.watch(contractAnalysisProgressProvider);

    final isPremium = ref.watch(isPremiumProvider);
    final canAnalyze = isPremium && pdf != null && !loading;

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'ارفع عقد العمل (PDF)',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 10),
        GlassSurface(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: loading ? null : _pickPdf,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emerald,
                  side: const BorderSide(color: AppColors.emerald, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(
                  fileName != null ? 'تغيير الملف' : 'رفع PDF',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
              ),
              if (fileName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded,
                        color: AppColors.emerald, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'دولة العمل',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 10),
        EosbCountryGrid(
          selected: country,
          onSelected: (c) {
            HapticFeedback.selectionClick();
            ref.read(contractAnalysisCountryProvider.notifier).state = c;
          },
        ),
        const SizedBox(height: 24),
        if (isPremium && loading) ...[
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0.05, 1.0)),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, _) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    color: AppColors.emerald,
                    backgroundColor:
                        AppColors.emerald.withValues(alpha: 0.15),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (!isPremium)
          const _ContractAnalysisPaywallCard()
        else
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: canAnalyze ? _analyze : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                disabledBackgroundColor:
                    AppColors.emerald.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.document_scanner_rounded),
              label: Text(
                'تحليل العقد',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        GlassSurface(
          borderRadius: 12,
          padding: const EdgeInsets.all(12),
          child: Text(
            'تحليل تقديري بالذكاء الاصطناعي — راجع محامياً للتأكيد.',
            style: GoogleFonts.cairo(
              fontSize: 11,
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );

    if (widget.embeddedInHub) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(top: false, child: body),
      );
    }

    return Scaffold(
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
              'تحليل العقد',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              'PDF',
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
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(child: body),
      ),
    );
  }
}

class _ContractAnalysisPaywallCard extends StatelessWidget {
  const _ContractAnalysisPaywallCard();

  static const _benefits = [
    '✓ تحليل PDF بالذكاء الاصطناعي',
    '✓ كشف المخاطر القانونية',
    '✓ مقارنة بقانون دولتك',
    '✓ تقييم العقد من 10',
  ];

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.gold, size: 40),
          const SizedBox(height: 12),
          Text(
            'تحليل العقد — حصري للمشتركين',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 16),
          ..._benefits.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => context.push('/premium'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF1A1500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'اشترك الآن',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
