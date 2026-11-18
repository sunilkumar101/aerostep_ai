import 'package:flutter/material.dart';

import '../../core/ai/gemini_coach.dart';
import '../../design_system/design_system.dart';

enum CoachInputMode { voice, chat }

class CoachMessage {
  const CoachMessage(this.text, {required this.fromUser});
  final String text;
  final bool fromUser;
}

/// Conversation bubbles shown directly above the prompt bar.
class CoachChatPanel extends StatelessWidget {
  const CoachChatPanel({
    super.key,
    required this.messages,
    required this.typing,
    required this.controller,
    required this.onClose,
  });

  final List<CoachMessage> messages;
  final bool typing;
  final ScrollController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 0),
            child: Row(
              children: [
                const PulsingDot(size: 8),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    GeminiCoach.instance.enabled ? 'STRIDE AI • POWERED BY GEMINI' : 'STRIDE AI • OFFLINE COACH',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AeroText.labelCaps.copyWith(color: p.textMuted),
                  ),
                ),
                IconButton(
                  tooltip: 'Hide conversation',
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.textMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: messages.length + (typing ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= messages.length) return const _TypingBubble();
                return _Bubble(message: messages[i]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final user = message.fromUser;
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: user ? AeroColors.tangerineGradient : null,
        color: user ? null : (p.isDark ? const Color(0xFF2C241F) : AeroColors.surfaceLow),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(user ? 18 : 4),
          bottomRight: Radius.circular(user ? 4 : 18),
        ),
      ),
      child: Text(
        message.text,
        style: AeroText.bodyMd.copyWith(color: user ? Colors.white : p.text, height: 1.35),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!user) ...[
            const _CoachAvatar(),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: bubble,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar();

  @override
  Widget build(BuildContext context) => Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AeroColors.tangerineGradient),
        child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
      );
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const _CoachAvatar(),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: p.isDark ? const Color(0xFF2C241F) : AeroColors.surfaceLow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.accent.withValues(alpha: ((_c.value * 3 - i) % 3) < 1 ? 1 : 0.3),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating "Ask Stride AI" prompt bar with mic + send buttons.
class CoachPromptBar extends StatelessWidget {
  const CoachPromptBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.mode,
    required this.onSend,
    required this.onMic,
    this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final CoachInputMode mode;
  final VoidCallback onSend;
  final VoidCallback onMic;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.aero;
    final voice = mode == CoachInputMode.voice;
    return Container(
      height: 60,
      padding: const EdgeInsets.only(left: 6, right: 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: voice ? p.accent.withValues(alpha: 0.6) : p.cardBorder),
        boxShadow: p.cardShadow,
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: 'Hide keyboard',
              onPressed: onBack,
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: p.accentText),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: AeroText.bodyMd.copyWith(color: p.text),
              cursorColor: p.accent,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: hint,
                hintMaxLines: 1,
                hintStyle: AeroText.bodyMd.copyWith(color: p.textMuted, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AeroCircleButton(
            icon: voice ? Icons.graphic_eq_rounded : Icons.mic_rounded,
            onPressed: onMic,
            size: 44,
            tooltip: 'Voice input',
            background: AeroColors.tangerine,
            foreground: Colors.white,
          ),
          const SizedBox(width: 6),
          AeroCircleButton(
            icon: Icons.arrow_upward_rounded,
            onPressed: onSend,
            size: 44,
            tooltip: 'Send message',
            background: p.isDark ? Colors.white : AeroColors.charcoal,
            foreground: p.isDark ? AeroColors.charcoal : Colors.white,
          ),
        ],
      ),
    );
  }
}
