import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/api_keys.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/contract_analyzer/providers/contract_analyzer_provider.dart';
import 'package:netgulf/features/eosb/presentation/widgets/eosb_country_grid.dart';

/// تحليل عقد عمل PDF بالذكاء الاصطناعي — ٦ دول خليجية.
class ContractAnalyzerScreen extends ConsumerStatefulWidget {
  const ContractAnalyzerScreen({
    super.key,
    this.embeddedInHub = false,
  });

  final bool embeddedInHub;

  @override
  ConsumerState<ContractAnalyzerScreen> createState() =>
      _ContractAnalyzerScreenState();
}

class _ContractAnalyzerScreenState
    extends ConsumerState<ContractAnalyzerScreen> {
  Uint8List? _pdfBytes;
  String? _fileName;
  GulfCountry _country = GulfCountry.saudiArabia;

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
        _showSnack('تعذر قراءة الملف — جرّب ملفاً أصغراً');
        return;
      }

      HapticFeedback.selectionClick();
      setState(() {
        _pdfBytes = bytes;
        _fileName = file.name;
      });
      ref.read(contractAnalyzerProvider.notifier).reset();
    } catch (e) {
      if (!mounted) return;
      _showSnack('فشل اختيار الملف');
    }
  }

  Future<void> _analyze() async {
    final bytes = _pdfBytes;
    if (bytes == null) {
      _showSnack('ارفع ملف PDF أولاً');
      return;
    }
    if (!ApiKeys.canUseLiveAnthropic) {
      _showSnack(
        ApiKeys.anthropicBlockedByBrowserCors
            ? ApiKeys.anthropicWebCorsMessage
            : ApiKeys.anthropicKeyMissingMessage,
        long: true,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    await ref.read(contractAnalyzerProvider.notifier).analyzeContract(
          pdfBytes: bytes,
          country: _country,
        );
  }

  void _showSnack(String message, {bool long = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        duration: Duration(seconds: long ? 6 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(contractAnalyzerProvider);

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'ارفع عقد العمل (PDF)',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 10),
        _UploadSection(
          fileName: _fileName,
          onPick: _pickPdf,
        ),
        const SizedBox(height: 20),
        Text(
          'دولة العمل (للمقارنة القانونية)',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 10),
        EosbCountryGrid(
          selected: _country,
          onSelected: (c) {
            setState(() => _country = c);
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: analysis.isLoading ? null : _analyze,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: analysis.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.document_scanner_rounded),
            label: Text(
              analysis.isLoading ? 'جاري التحليل…' : 'تحليل العقد',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
        if (!ApiKeys.canUseLiveAnthropic) ...[
          const SizedBox(height: 12),
          _InfoBanner(
            message: ApiKeys.anthropicBlockedByBrowserCors
                ? ApiKeys.anthropicWebCorsMessage
                : ApiKeys.anthropicKeyMissingMessage,
            icon: Icons.cloud_off_rounded,
          ),
        ],
        if (analysis.hasError) ...[
          const SizedBox(height: 16),
          _InfoBanner(
            message: analysis.error.toString().replaceFirst('Exception: ', ''),
            icon: Icons.error_outline_rounded,
            isError: true,
          ),
        ],
        if (analysis.isLoading) ...[
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const CircularProgressIndicator(color: AppColors.emerald),
                const SizedBox(height: 12),
                Text(
                  'Claude يقرأ العقد ويستخرج البنود…',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (analysis.hasValue && analysis.value != null) ...[
          const SizedBox(height: 24),
          _ResultsSection(result: analysis.value!),
        ],
        const SizedBox(height: 16),
        _DisclaimerCard(),
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
              'PDF · بنود مالية · مخاطر · حقوق ناقصة',
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

class _UploadSection extends StatelessWidget {
  const _UploadSection({
    required this.fileName,
    required this.onPick,
  });

  final String? fileName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.isNotEmpty;

    return GlassSurface(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onPick,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.emerald,
              side: const BorderSide(color: AppColors.emerald, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(
              hasFile ? 'تغيير الملف' : 'رفع PDF',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
          if (hasFile) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.emerald,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName!,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({required this.result});

  final ContractAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'نتيجة التحليل — ${result.country.nameAr}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _AnalysisCard(
          title: 'البنود المالية',
          icon: Icons.payments_rounded,
          body: result.financialTerms,
          highlighted: true,
        ),
        const SizedBox(height: 12),
        _AnalysisCard(
          title: 'نقاط الضعف',
          icon: Icons.warning_amber_rounded,
          body: result.weakPoints,
          borderColor: Colors.red.shade300,
          iconColor: Colors.red.shade400,
        ),
        const SizedBox(height: 12),
        _AnalysisCard(
          title: 'الحقوق الناقصة',
          icon: Icons.gavel_rounded,
          body: result.missingRights,
          borderColor: Colors.orange.shade300,
          iconColor: Colors.orange.shade700,
        ),
        const SizedBox(height: 12),
        _AnalysisCard(
          title: 'الملخص',
          icon: Icons.summarize_rounded,
          body: result.summary,
        ),
        const SizedBox(height: 8),
        Text(
          result.country.eosLawChipAr,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.emerald,
          ),
        ),
      ],
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.title,
    required this.icon,
    required this.body,
    this.highlighted = false,
    this.borderColor,
    this.iconColor,
  });

  final String title;
  final IconData icon;
  final String body;
  final bool highlighted;
  final Color? borderColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final content = body.trim().isEmpty ? '— لا توجد بيانات —' : body.trim();

    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.emerald, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: GoogleFonts.cairo(fontSize: 13, height: 1.55),
        ),
      ],
    );

    return GlassSurface(
      highlighted: highlighted,
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: borderColor != null
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor!, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: inner,
              ),
            )
          : inner,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.message,
    required this.icon,
    this.isError = false,
  });

  final String message;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red.shade700 : AppColors.emerald;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.cairo(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 12,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'هذا تحليل تقديري بالذكاء الاصطناعي — راجع محامياً للتأكيد قبل اتخاذ أي قرار.',
              style: GoogleFonts.cairo(
                fontSize: 11,
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
