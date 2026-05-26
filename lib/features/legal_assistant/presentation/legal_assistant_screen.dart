import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/api_keys.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/core/widgets/premium_mesh_background.dart';
import 'package:netgulf/features/legal_assistant/models/chat_message.dart';
import 'package:netgulf/features/legal_assistant/providers/legal_assistant_provider.dart';
import 'package:netgulf/features/legal_assistant/services/legal_ai_service.dart';
import 'package:uuid/uuid.dart';

/// محادثة المساعد القانوني — Claude أو وضع تجريبي (RTL).
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

  static const _requestTimeout = Duration(seconds: 15);
  static const _retryLabel = 'تعذر الاتصال بالمساعد. إعادة المحاولة';

  bool _isLoading = false;
  String? _failedMessage;

  static const _exampleQuestions = [
    'عقدي ستين وهمشي بعد سنه',
    'كم نهاية خدمتي بعد 7 سنين؟',
    'إيه حقوقي في الإجازة السنوية والتذكرة؟',
    'الفرق بين GOSI القديم والجديد',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty || _isLoading) return;

    if (preset == null) _inputController.clear();
    await _dispatchQuestion(text, appendUserMessage: true);
  }

  /// إعادة إرسال آخر سؤال فشل دون إضافة رسالة مستخدم مكررة.
  Future<void> _retryFailedMessage() async {
    final text = _failedMessage?.trim();
    if (text == null || text.isEmpty || _isLoading) return;
    await _dispatchQuestion(text, appendUserMessage: false);
  }

  Future<void> _dispatchQuestion(
    String text, {
    required bool appendUserMessage,
  }) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _failedMessage = null;
      if (appendUserMessage) {
        _messages.add(
          ChatMessage(
            id: _uuid.v4(),
            text: text,
            isUser: true,
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    _scrollToBottom();

    try {
      final service = ref.read(legalAiServiceProvider);
      final history = List<ChatMessage>.from(_messages);
      final reply = await service
          .ask(question: text, history: history)
          .timeout(
            _requestTimeout,
            onTimeout: () => throw LegalAiException(_retryLabel),
          );

      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            id: _uuid.v4(),
            text: reply.text.trim(),
            isUser: false,
            isDemo: reply.isDemo,
            timestamp: DateTime.now(),
          ),
        );
      });
      ref.invalidate(legalAiRemainingProvider);
    } on LegalAiException {
      if (!mounted) return;
      setState(() => _failedMessage = text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failedMessage = text);
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
    final isLive = ref.watch(legalAiLiveModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUserMessages = _messages.any((m) => m.isUser);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المساعد القانوني',
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
                  avatar: Icon(
                    isLive ? Icons.bolt_rounded : Icons.science_outlined,
                    size: 16,
                    color: isLive ? AppColors.emerald : AppColors.gold,
                  ),
                  label: Text(
                    isLive
                        ? 'متبقي: $n/${AppConstants.legalAiDailyQuestionLimit}'
                        : 'تجريبي · $n/${AppConstants.legalAiDailyQuestionLimit}',
                    style: GoogleFonts.cairo(fontSize: 11),
                  ),
                  backgroundColor: AppColors.emerald.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: AppColors.emerald.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: PremiumMeshBackground(
        isDark: isDark,
        child: Column(
          children: [
            if (!isLive) const _ActivateAiCard(),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: _messages.length +
                        (_isLoading ? 1 : 0) +
                        (_failedMessage != null && !_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _messages.length) {
                        return _MessageBubble(message: _messages[index]);
                      }

                      var slot = _messages.length;
                      if (_isLoading && index == slot) {
                        return const _TypingIndicator();
                      }
                      slot += _isLoading ? 1 : 0;

                      if (_failedMessage != null &&
                          !_isLoading &&
                          index == slot) {
                        return _SmartRetryBanner(
                          label: _retryLabel,
                          onRetry: _retryFailedMessage,
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                  if (!hasUserMessages && !_isLoading)
                    const _EmptyChatState(),
                ],
              ),
            ),
            _ExampleQuestionsBar(
              examples: _exampleQuestions,
              enabled: !_isLoading,
              onTap: _sendMessage,
            ),
            _InputBar(
              controller: _inputController,
              isLoading: _isLoading,
              onSend: () => _sendMessage(),
            ),
          ],
        ),
      ),
    );
  }
}

/// حالة فارغة قبل أول سؤال من المستخدم.
class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: GlassSurface(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.emerald.withValues(alpha: 0.28),
                      AppColors.navyMid.withValues(alpha: 0.5),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.balance_rounded,
                  size: 48,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'المساعد القانوني',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'اكتب سؤالك عن حقوقك، نهاية الخدمة، الإجازات، '
                'أو أي موضوع قانوني في السعودية أو الإمارات',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  height: 1.6,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// أسئلة مقترحة فوق شريط الإدخال.
class _ExampleQuestionsBar extends StatelessWidget {
  const _ExampleQuestionsBar({
    required this.examples,
    required this.enabled,
    required this.onTap,
  });

  final List<String> examples;
  final bool enabled;
  final void Function(String question) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 8),
        itemCount: examples.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final q = examples[index];
          return ActionChip(
            label: Text(
              q,
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            avatar: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 16,
              color: AppColors.emerald.withValues(alpha: enabled ? 1 : 0.4),
            ),
            backgroundColor: AppColors.emerald.withValues(alpha: 0.1),
            side: BorderSide(
              color: AppColors.emerald.withValues(alpha: enabled ? 0.45 : 0.2),
            ),
            onPressed: enabled ? () => onTap(q) : null,
          );
        },
      ),
    );
  }
}

/// بطاقة تفعيل المساعد الذكي عند غياب مفتاح API.
class _ActivateAiCard extends StatelessWidget {
  const _ActivateAiCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.emerald.withValues(alpha: 0.18),
              AppColors.gold.withValues(alpha: 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.emerald,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'فعّل المساعد الذكي',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emerald,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'وضع تجريبي',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldBright,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ApiKeys.anthropicKeyMissingMessage,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        height: 1.45,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يمكنك المحادثة الآن — الردود تجريبية حتى إضافة المفتاح.',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emerald,
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = message.isError
        ? AppColors.error.withValues(alpha: 0.14)
        : isUser
            ? AppColors.emerald.withValues(alpha: isDark ? 0.22 : 0.16)
            : AppColors.navyMid.withValues(alpha: isDark ? 0.92 : 0.88);
    final borderColor = message.isError
        ? AppColors.error.withValues(alpha: 0.45)
        : isUser
            ? AppColors.emerald.withValues(alpha: 0.5)
            : AppColors.navyLight.withValues(alpha: 0.55);
    final textColor = message.isError
        ? AppColors.error
        : isUser
            ? Theme.of(context).colorScheme.onSurface
            : Colors.white.withValues(alpha: 0.95);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 12,
          right: isUser ? 6 : 0,
          left: isUser ? 0 : 6,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          child: _BubbleWithTail(
            isUser: isUser,
            color: bg,
            borderColor: borderColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser && !message.isError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.smart_toy_outlined,
                          size: 14,
                          color: AppColors.emeraldLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'المساعد القانوني',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emeraldLight,
                          ),
                        ),
                        if (message.isDemo) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'تجريبي',
                              style: GoogleFonts.cairo(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldBright,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Text(
                  message.text,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    height: 1.55,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// فقاعة محادثة مع ذيل سفلي — المستخدم يمين، المساعد يسار.
class _BubbleWithTail extends StatelessWidget {
  const _BubbleWithTail({
    required this.isUser,
    required this.color,
    required this.borderColor,
    required this.child,
  });

  final bool isUser;
  final Color color;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChatBubblePainter(
        fillColor: color,
        borderColor: borderColor,
        tailOnRight: isUser,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 10, 14, isUser ? 14 : 12),
        child: child,
      ),
    );
  }
}

class _ChatBubblePainter extends CustomPainter {
  _ChatBubblePainter({
    required this.fillColor,
    required this.borderColor,
    required this.tailOnRight,
  });

  final Color fillColor;
  final Color borderColor;
  final bool tailOnRight;

  static const _radius = 16.0;
  static const _tailW = 10.0;
  static const _tailH = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = fillColor;
    final stroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = _bubblePath(size);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  Path _bubblePath(Size size) {
    final w = size.width;
    final h = size.height;
    final bodyBottom = h - _tailH;
    final r = _radius;
    final path = Path();

    if (tailOnRight) {
      path.moveTo(r, 0);
      path.lineTo(w - r, 0);
      path.quadraticBezierTo(w, 0, w, r);
      path.lineTo(w, bodyBottom - r);
      path.quadraticBezierTo(w, bodyBottom, w - r, bodyBottom);
      path.lineTo(w - 4, bodyBottom);
      path.lineTo(w + _tailW - 4, h);
      path.lineTo(w - 10, bodyBottom);
      path.lineTo(r, bodyBottom);
      path.quadraticBezierTo(0, bodyBottom, 0, bodyBottom - r);
      path.lineTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
    } else {
      path.moveTo(r, 0);
      path.lineTo(w - r, 0);
      path.quadraticBezierTo(w, 0, w, r);
      path.lineTo(w, bodyBottom - r);
      path.quadraticBezierTo(w, bodyBottom, w - r, bodyBottom);
      path.lineTo(10, bodyBottom);
      path.lineTo(4 - _tailW, h);
      path.lineTo(4, bodyBottom);
      path.lineTo(r, bodyBottom);
      path.quadraticBezierTo(0, bodyBottom, 0, bodyBottom - r);
      path.lineTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _ChatBubblePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.tailOnRight != tailOnRight;
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.navyMid.withValues(alpha: 0.9);

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _BubbleWithTail(
          isUser: false,
          color: bg,
          borderColor: AppColors.navyLight.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      final phase = (_pulse.value + i * 0.22) % 1.0;
                      final scale = 0.65 + (0.35 * (1 - (phase - 0.5).abs() * 2));
                      final opacity = 0.35 + (0.65 * (1 - (phase - 0.5).abs() * 2));
                      return Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: i == 2 ? 0 : 6,
                        ),
                        child: Transform.scale(
                          scale: scale.clamp(0.65, 1.0),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.emeraldLight
                                  .withValues(alpha: opacity.clamp(0.35, 1.0)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.emerald
                                      .withValues(alpha: opacity * 0.35),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (bounds) {
                      final t = _pulse.value;
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.85),
                          Colors.white.withValues(alpha: 0.25),
                        ],
                        stops: [
                          (t - 0.35).clamp(0.0, 1.0),
                          t.clamp(0.0, 1.0),
                          (t + 0.35).clamp(0.0, 1.0),
                        ],
                      ).createShader(bounds);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 88,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'المساعد بيفكر...',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر إعادة المحاولة الذكية — يظهر عند فشل الاتصال دون إضافة رسالة خطأ.
class _SmartRetryBanner extends StatelessWidget {
  const _SmartRetryBanner({
    required this.label,
    required this.onRetry,
  });

  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.error.withValues(alpha: 0.12),
                    AppColors.gold.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 20,
                      color: AppColors.error.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: AppColors.emerald,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 12),
          child: GlassSurface(
            borderRadius: 28,
            padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 6, 6),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final canSend =
                    !isLoading && value.text.trim().isNotEmpty;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        enabled: !isLoading,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        textInputAction: TextInputAction.send,
                        onSubmitted: canSend ? (_) => onSend() : null,
                        style: GoogleFonts.cairo(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'اكتب سؤالك القانوني...',
                          hintStyle: GoogleFonts.cairo(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.45),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.navyMid.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.85),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(
                              color: AppColors.emerald.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          contentPadding:
                              const EdgeInsetsDirectional.fromSTEB(
                            16,
                            12,
                            16,
                            12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: canSend ? onSend : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.emerald.withValues(alpha: 0.35),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
