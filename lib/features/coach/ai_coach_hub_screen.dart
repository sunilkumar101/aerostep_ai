import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/state/activity_state.dart';
import '../../core/state/app_settings.dart';
import '../../design_system/design_system.dart';
import 'coach_brain.dart';
import 'coach_chat.dart';
import 'stride_coach_view.dart';
import 'weight_loss_hub_view.dart';

enum _CoachTab { weightLoss, gait }

/// AI Coach Hub: "Weight-Loss & Hydration" + "Gait & Audio Drills" with a
/// shared offline Stride AI conversation bar.
class AiCoachHubScreen extends ConsumerStatefulWidget {
  const AiCoachHubScreen({super.key});

  @override
  ConsumerState<AiCoachHubScreen> createState() => _AiCoachHubScreenState();
}

class _AiCoachHubScreenState extends ConsumerState<AiCoachHubScreen> {
  _CoachTab _tab = _CoachTab.weightLoss;
  CoachInputMode _mode = CoachInputMode.chat;

  final _messages = <CoachMessage>[];
  final _pending = <Timer>{};
  bool _chatOpen = false;

  final _input = TextEditingController();
  final _focus = FocusNode();
  final _chatScroll = ScrollController();

  @override
  void dispose() {
    for (final t in _pending) {
      t.cancel();
    }
    _input.dispose();
    _focus.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AeroRoutes.home);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScroll.hasClients) return;
      _chatScroll.animateTo(
        _chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _answer(String question) => coachReply(
        question,
        ref.read(activityProvider),
        ref.read(hydrationProvider),
        shields: ref.read(streakShieldProvider),
        weightKg: ref.read(userProfileProvider).weightKg,
      );

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) {
      _focus.requestFocus();
      return;
    }
    _input.clear();
    setState(() {
      _messages.add(CoachMessage(text, fromUser: true));
      _chatOpen = true;
    });
    _scrollToEnd();
    late final Timer timer;
    timer = Timer(const Duration(milliseconds: 650), () {
      _pending.remove(timer);
      if (!mounted) return;
      setState(() => _messages.add(CoachMessage(_answer(text), fromUser: false)));
      _scrollToEnd();
    });
    _pending.add(timer);
  }

  void _speakInsight() {
    setState(() {
      _messages.add(CoachMessage(_answer('how many steps left'), fromUser: false));
      _chatOpen = true;
    });
    _scrollToEnd();
  }

  void _onMic() {
    setState(() => _mode = CoachInputMode.voice);
    _focus.requestFocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Offline voice capture is coming soon. Type your question and Stride AI answers instantly.'),
        ),
      );
  }

  void _onModeChanged(CoachInputMode m) {
    setState(() => _mode = m);
    if (m == CoachInputMode.chat) {
      _focus.requestFocus();
    } else {
      _onMic();
    }
  }

  String get _hint {
    if (_mode == CoachInputMode.voice) return 'Stride Voice ready… type to ask';
    return _tab == _CoachTab.weightLoss
        ? 'Ask Stride AI anything about fat loss, rest...'
        : 'Ask Stride AI: "How\'s my stride angle?"';
  }

  @override
  Widget build(BuildContext context) {
    // Read outside the Scaffold so the real keyboard inset is visible.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomSafe = keyboardOpen ? 0.0 : MediaQuery.paddingOf(context).bottom;
    final pending = _pending.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AeroCanvas(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(onClose: _close),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: LayoutBuilder(
                  // Each pill gets (width - 8) / 2; the full label needs ~180dp.
                  builder: (context, c) {
                    final narrow = (c.maxWidth - 8) / 2 < 182;
                    return AeroSegmented<_CoachTab>(
                      options: _CoachTab.values,
                      selected: _tab,
                      activeTangerine: true,
                      labelOf: (t) => switch (t) {
                        _CoachTab.weightLoss => narrow ? 'Weight-Loss & Water' : 'Weight-Loss & Hydration',
                        _CoachTab.gait => 'Gait & Audio Drills',
                      },
                      onChanged: (t) => setState(() => _tab = t),
                    );
                  },
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final showChat = _chatOpen && _messages.isNotEmpty;
                    return Column(
                      children: [
                        Expanded(
                          child: IndexedStack(
                            index: _tab.index,
                            children: [
                              TickerMode(
                                enabled: _tab == _CoachTab.weightLoss,
                                child: WeightLossHubView(
                                  mode: _mode,
                                  onModeChanged: _onModeChanged,
                                  onSpeakInsight: _speakInsight,
                                ),
                              ),
                              TickerMode(
                                enabled: _tab == _CoachTab.gait,
                                child: StrideCoachView(active: _tab == _CoachTab.gait),
                              ),
                            ],
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.bottomCenter,
                          child: showChat
                              ? SizedBox(
                                  height: math.min(280, box.maxHeight * 0.48),
                                  child: CoachChatPanel(
                                    messages: _messages,
                                    typing: pending,
                                    controller: _chatScroll,
                                    onClose: () => setState(() => _chatOpen = false),
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + bottomSafe),
                child: CoachPromptBar(
                  controller: _input,
                  focusNode: _focus,
                  hint: _hint,
                  mode: _mode,
                  onSend: _send,
                  onMic: _onMic,
                  onBack: () {
                    _focus.unfocus();
                    if (_messages.isNotEmpty) setState(() => _chatOpen = !_chatOpen);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.aero;
    final name = ref.watch(userProfileProvider.select((u) => u.name)).trim();
    final initial = name.isEmpty ? '' : name.characters.first.toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
      child: Row(
        children: [
          AeroCircleButton(icon: Icons.close_rounded, onPressed: onClose, size: 44, tooltip: 'Close'),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Coach Hub',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.headlineMd.copyWith(color: p.text),
                ),
                Text(
                  'AI Stride Coach & Weight-Loss Hub',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AeroText.caption.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AeroColors.tangerineDeep),
            child: initial.isEmpty
                ? const Icon(Icons.person_rounded, color: Colors.white, size: 22)
                : Text(initial, style: AeroText.titleMd.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
