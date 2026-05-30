import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/contract_explainer/data/contract_terms_data.dart';
import 'package:netgulf/features/contract_explainer/models/contract_term.dart';

class ContractExplainerScreen extends StatefulWidget {
  const ContractExplainerScreen({super.key});

  @override
  State<ContractExplainerScreen> createState() => _ContractExplainerScreenState();
}

class _ContractExplainerScreenState extends State<ContractExplainerScreen> {
  String _query = '';
  String _category = 'الكل';

  List<ContractTerm> get _filtered {
    var list = ContractTermsData.all;
    if (_category != 'الكل') {
      list = list.where((t) => t.category == _category).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list
          .where(
            (t) =>
                t.term.toLowerCase().contains(q) ||
                t.simple.toLowerCase().contains(q) ||
                t.legal.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final terms = _filtered;

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
              'مصطلحات العقد',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              'فهم بنود عقدك بلغة بسيطة',
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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مصطلح...',
                    hintStyle: GoogleFonts.cairo(),
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.cairo(),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ContractTermsData.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = ContractTermsData.categories[index];
                    final selected = cat == _category;
                    return FilterChip(
                      label: Text(cat, style: GoogleFonts.cairo(fontSize: 12)),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = cat),
                      selectedColor: AppColors.emerald.withValues(alpha: 0.25),
                      checkmarkColor: AppColors.emerald,
                      side: BorderSide(
                        color: selected
                            ? AppColors.emerald
                            : AppColors.glassBorder,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: terms.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد نتائج',
                          style: GoogleFonts.cairo(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: terms.length,
                        itemBuilder: (context, index) =>
                            _TermCard(term: terms[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermCard extends StatefulWidget {
  const _TermCard({required this.term});
  final ContractTerm term;

  @override
  State<_TermCard> createState() => _TermCardState();
}

class _TermCardState extends State<_TermCard> {
  bool _legalExpanded = false;

  @override
  Widget build(BuildContext context) {
    final term = widget.term;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    term.term,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    term.category,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'بلغة بسيطة',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.emerald,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              term.simple,
              style: GoogleFonts.cairo(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _legalExpanded = !_legalExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'التفاصيل القانونية',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _legalExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_legalExpanded) ...[
              const SizedBox(height: 4),
              Text(
                term.legal,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  height: 1.45,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.amber.shade700.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      term.tip,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
