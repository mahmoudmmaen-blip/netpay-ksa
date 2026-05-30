import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/services/premium_access.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/core/widgets/premium_gate_sheet.dart';
import 'package:netgulf/features/legal_qa/models/legal_qa_message.dart';
import 'package:netgulf/features/legal_qa/presentation/widgets/legal_qa_country_strip.dart';
import 'package:netgulf/features/legal_qa/providers/legal_qa_provider.dart';

const _quickQuestions = [
  'ما هي حقوقي عند الفصل التعسفي؟',
  'كيف أحسب الشرط الجزائي؟',
  'ما مدة الإجازة المرضية؟',
  'هل يحق لصاحب العمل تأخير الراتب؟',
];

/// شاشة الاستفسار القانوني — Premium.
class LegalQaScreen extends ConsumerStatefulWidget {
  const LegalQaScreen({super.key});

  @override
  ConsumerState<LegalQaScreen> createState() => _LegalQaScreenState();
}

class _LegalQaScreenState extends ConsumerState<LegalQaScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String text) async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      await PremiumAccess.requirePremium(
        context,
        ref,
        feature: PremiumFeature.legalPriority,
      );
      return;
    }
    await ref.read(legalQaProvider.notifier).sendMessage(text);
    _inputController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final qa = ref.watch(legalQaProvider);
    final notifier = ref.read(legalQaProvider.notifier);

    ref.listen<LegalQaState>(legalQaProvider, (_, _) => _scrollToBottom());

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
              'استفسار قانوني',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              'اسأل عن حقوقك بالقانون الخليجي',
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
        actions: [
          if (isPremium && qa.messages.isNotEmpty)
            IconButton(
              tooltip: 'محادثة جديدة',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: notifier.clearChat,
            ),
        ],
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
                child: LegalQaCountryStrip(
                  selected: qa.country,
                  onSelected: notifier.setCountry,
                ),
              ),
              Expanded(
                child: isPremium
                    ? _ChatArea(
                        messages: qa.messages,
                        isTyping: qa.isTyping,
                        scrollController: _scrollController,
                      )
                    : const _LegalQaPaywall(),
              ),
              if (isPremium) ...[
                _QuickChips(onTap: _send),
                _InputBar(
                  controller: _inputController,
                  isTyping: qa.isTyping,
                  onSend: () => _send(_inputController.text),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatArea extends StatelessWidget {
  const _ChatArea({
    required this.messages,
    required this.isTyping,
    required this.scrollController,
  });

  final List<LegalQaMessage> messages;
  final bool isTyping;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty && !isTyping) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'اختر سؤالاً سريعاً أو اكتب استفسارك عن قانون العمل',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (isTyping && index == messages.length) {
          return const _TypingBubble();
        }
        final msg = messages[index];
        return _MessageBubble(message: msg);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final LegalQaMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == LegalQaRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.emerald
              : message.isError
                  ? Colors.red.shade50
                  : Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.glassBorder),
          boxShadow: isUser
              ? [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          message.text,
          style: GoogleFonts.cairo(
            fontSize: 14,
            height: 1.45,
            color: isUser
                ? Colors.white
                : message.isError
                    ? Colors.red.shade800
                    : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GlassSurface(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.emerald.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'جاري الكتابة...',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChips extends StatelessWidget {
  const _QuickChips({required this.onTap});
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickQuestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final q = _quickQuestions[index];
          return ActionChip(
            label: Text(q, style: GoogleFonts.cairo(fontSize: 11)),
            onPressed: () => onTap(q),
            backgroundColor: AppColors.emerald.withValues(alpha: 0.12),
            side: const BorderSide(color: AppColors.emerald),
          );
        },
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isTyping,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isTyping;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (!isTyping) onSend();
              },
              decoration: InputDecoration(
                hintText: 'اكتب سؤالك...',
                hintStyle: GoogleFonts.cairo(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.cairo(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: isTyping ? null : onSend,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _LegalQaPaywall extends ConsumerWidget {
  const _LegalQaPaywall();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassSurface(
          borderRadius: 16,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.gold, size: 44),
              const SizedBox(height: 12),
              Text(
                'الاستفسار القانوني — Premium',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اسأل مستشاراً قانونياً عن حقوقك في قانون العمل الخليجي',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => showPremiumGate(
                  context,
                  feature: PremiumFeature.legalPriority,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: const Color(0xFF1A1500),
                ),
                child: Text(
                  'اشترك الآن',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
