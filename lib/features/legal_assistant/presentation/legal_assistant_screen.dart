import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/features/legal_assistant/models/chat_message.dart';
import 'package:netgulf/features/legal_assistant/providers/legal_assistant_provider.dart';
import 'package:netgulf/features/legal_assistant/services/legal_ai_service.dart';
import 'package:uuid/uuid.dart';

/// محادثة المساعد القانوني — Claude (RTL).
class LegalAssistantScreen extends ConsumerStatefulWidget {
  const LegalAssistantScreen({super.key});

  @override
  ConsumerState<LegalAssistantScreen> createState() =>
      _LegalAssistantScreenState();
}

class _LegalAssistantScreenState extends ConsumerState<LegalAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  final _uuid = const Uuid();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        text:
            'مرحباً، أنا مساعدك القانوني في نظام العمل السعودي والإماراتي. '
            'اسأل عن حقوقك، الإجازات، مكافأة نهاية الخدمة، أو GOSI/GPSSA.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _messages.add(
        ChatMessage(
          id: _uuid.v4(),
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _inputController.clear();
    });
    _scrollToBottom();

    try {
      final service = ref.read(legalAiServiceProvider);
      final history = List<ChatMessage>.from(_messages);
      final reply = await service.ask(question: text, history: history);

      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            id: _uuid.v4(),
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      ref.invalidate(legalAiRemainingProvider);
    } on LegalAiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            id: _uuid.v4(),
            text: e.message,
            isUser: false,
            isError: true,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            id: _uuid.v4(),
            text: 'حدث خطأ غير متوقع. حاول مرة أخرى.',
            isUser: false,
            isError: true,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final remainingAsync = ref.watch(legalAiRemainingProvider);
    final hasKey = ref.read(legalAiServiceProvider).hasApiKey;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المساعد القانوني 🤖',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        actions: [
          remainingAsync.when(
            data: (n) => Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: Chip(
                  label: Text(
                    'متبقي: $n/${AppConstants.legalAiDailyQuestionLimit}',
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  backgroundColor: AppColors.emerald.withValues(alpha: 0.15),
                  side: BorderSide(color: AppColors.emerald.withValues(alpha: 0.4)),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!hasKey)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppColors.warning.withValues(alpha: 0.15),
              child: Text(
                'لتفعيل المساعد: flutter run --dart-define=ANTHROPIC_API_KEY=...',
                style: GoogleFonts.cairo(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          _InputBar(
            controller: _inputController,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final alignment =
        isUser ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd;
    final bg = message.isError
        ? AppColors.error.withValues(alpha: 0.12)
        : isUser
            ? AppColors.emerald.withValues(alpha: 0.14)
            : Theme.of(context).colorScheme.surfaceContainerHighest;
    final borderColor = message.isError
        ? AppColors.error.withValues(alpha: 0.4)
        : isUser
            ? AppColors.emerald.withValues(alpha: 0.45)
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 4 : 16),
            bottomRight: Radius.circular(isUser ? 16 : 4),
          ),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && !message.isError)
              Text(
                'المساعد القانوني',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emerald,
                ),
              ),
            Text(
              message.text,
              style: GoogleFonts.cairo(
                fontSize: 14,
                height: 1.5,
                color: message.isError ? AppColors.error : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.emerald,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'جاري الكتابة...',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.emerald,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: GoogleFonts.cairo(),
                  decoration: InputDecoration(
                    hintText: 'اكتب سؤالك القانوني...',
                    hintStyle: GoogleFonts.cairo(),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isLoading ? null : onSend,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                  shape: const CircleBorder(),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
