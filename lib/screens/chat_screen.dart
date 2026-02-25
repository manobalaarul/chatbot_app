// ─── screens/chat_screen.dart ─────────────────────────────────────────────────
// Pushed via Navigator — completely separate from the tab scaffold.
// Uses isolated BlocSelector/BlocConsumer so it ONLY rebuilds when
// messages, typing, or activeConv status change — never on conv list updates.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../bloc/dashboard/dashboard_bloc.dart';
import '../models/models.dart';
import '../theme/theme.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conv;
  const ChatScreen({super.key, required this.conv});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final int _prevMsgCount = 0;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    context.read<DashboardBloc>().add(SendMessageEvent(text));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.conv.visitorName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppBar(
        backgroundColor: T.surface,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: T.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        // ── AppBar: only rebuilds for status changes ───────────────────────
        title:
            BlocSelector<
              DashboardBloc,
              DashboardState,
              ({String name, String status})
            >(
              selector: (s) {
                final conv = s is DashboardLoaded
                    ? (s.activeConv ?? widget.conv)
                    : widget.conv;
                return (name: conv.visitorName, status: conv.status);
              },
              builder: (_, data) => Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(
                          0xFF6366F1,
                        ).withOpacity(0.2),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: T.statusColor(data.status),
                            border: Border.all(color: T.surface, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          color: T.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        data.status,
                        style: TextStyle(
                          color: T.statusColor(data.status),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        // ── Actions: only rebuilds for status changes ──────────────────────
        actions: [
          BlocSelector<DashboardBloc, DashboardState, String>(
            selector: (s) => s is DashboardLoaded
                ? (s.activeConv?.status ?? widget.conv.status)
                : widget.conv.status,
            builder: (ctx, status) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status != 'active')
                  TextButton(
                    onPressed: () =>
                        ctx.read<DashboardBloc>().add(const TakeOverEvent()),
                    style: TextButton.styleFrom(foregroundColor: T.waiting),
                    child: const Text(
                      '⚡ Take',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: T.textSecondary,
                  ),
                  onPressed: () {
                    final s = context.read<DashboardBloc>().state;
                    final conv = s is DashboardLoaded
                        ? (s.activeConv ?? widget.conv)
                        : widget.conv;
                    _showMenu(context, conv);
                  },
                ),
              ],
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Messages list ─────────────────────────────────────────────────
          // BlocConsumer: listener scrolls on new message, builder renders list.
          // buildWhen: ONLY rebuilds when messages or typing changes —
          // ignores conv list updates, stats, unread badge changes entirely.
          Expanded(
            child: BlocConsumer<DashboardBloc, DashboardState>(
              listenWhen: (prev, curr) {
                if (curr is! DashboardLoaded || prev is! DashboardLoaded) {
                  return false;
                }
                return curr.messages.length > prev.messages.length;
              },
              listener: (_, __) => _scrollToBottom(),
              buildWhen: (prev, curr) {
                if (curr is! DashboardLoaded) return true;
                if (prev is! DashboardLoaded) return true;
                // Only rebuild for these specific fields:
                return curr.messages != prev.messages ||
                    curr.messagesState != prev.messagesState ||
                    curr.showTyping != prev.showTyping;
              },
              builder: (ctx, state) {
                final s = state is DashboardLoaded ? state : null;

                if (s == null || s.messagesState == MessagesLoadState.loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: T.accentBlue,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (s.messagesState == MessagesLoadState.error) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: T.accent,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load messages',
                          style: GoogleFonts.inter(
                            color: T.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (s.messages.isEmpty) {
                  return _EmptyConv(name: widget.conv.visitorName);
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                        itemCount: s.messages.length,
                        itemBuilder: (_, i) {
                          final msg = s.messages[i];
                          final prev = i > 0 ? s.messages[i - 1] : null;
                          return _Bubble(
                            msg: msg,
                            showAvatar:
                                prev == null ||
                                prev.senderType != msg.senderType,
                            convName: widget.conv.visitorName,
                          );
                        },
                      ),
                    ),
                    // Typing indicator
                    if (s.showTyping)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 0, 6),
                        child: Row(
                          children: [
                            ...List.generate(
                              3,
                              (i) => _TypingDot(
                                delay: Duration(milliseconds: i * 160),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'typing…',
                              style: TextStyle(
                                color: T.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // ── Input bar: only rebuilds when activeConv presence changes ─────
          BlocSelector<DashboardBloc, DashboardState, bool>(
            selector: (s) => s is DashboardLoaded && s.activeConv != null,
            builder: (ctx, enabled) =>
                _InputBar(ctrl: _msgCtrl, onSend: _send, enabled: enabled),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context, Conversation conv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: T.surfaceEl,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: T.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.person_outline_rounded,
                color: T.textSecondary,
              ),
              title: Text(
                '${conv.visitorName} · #${conv.id}',
                style: const TextStyle(color: T.textPrimary),
              ),
              subtitle: Text(
                conv.visitorEmail ?? 'No email',
                style: const TextStyle(color: T.textMuted, fontSize: 12),
              ),
            ),
            const Divider(color: T.border, height: 1),
            if (conv.status != 'active')
              ListTile(
                leading: const Icon(
                  Icons.electric_bolt_rounded,
                  color: T.waiting,
                ),
                title: const Text(
                  'Take Over',
                  style: TextStyle(color: T.waiting),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<DashboardBloc>().add(const TakeOverEvent());
                },
              ),
            ListTile(
              leading: const Icon(Icons.close_rounded, color: T.accent),
              title: const Text(
                'Close Conversation',
                style: TextStyle(color: T.accent),
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.read<DashboardBloc>().add(
                  const CloseConversationEvent(),
                );
                Navigator.pop(context); // back to inbox
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  final bool showAvatar;
  final String convName;
  const _Bubble({
    required this.msg,
    required this.showAvatar,
    required this.convName,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = msg.senderType == 'admin';
    final isBot = msg.senderType == 'bot';
    final timeStr = DateFormat('HH:mm').format(msg.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isAdmin
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isAdmin) ...[
            if (showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 2),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: isBot
                      ? T.purple.withOpacity(0.2)
                      : T.accentBlue.withOpacity(0.2),
                  child: Text(
                    isBot
                        ? '🤖'
                        : convName.isNotEmpty
                        ? convName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
            else
              const SizedBox(width: 34),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAdmin
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (showAvatar && !isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 2),
                    child: Text(
                      isBot ? '🤖 Bot' : convName,
                      style: const TextStyle(color: T.textMuted, fontSize: 11),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? T.accentBlue
                        : isBot
                        ? T.purple.withOpacity(0.25)
                        : T.surfaceEl,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isAdmin ? 18 : 4),
                      bottomRight: Radius.circular(isAdmin ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    msg.body,
                    style: TextStyle(
                      color: isAdmin ? Colors.white : T.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 2, right: 2),
                  child: Text(
                    timeStr,
                    style: const TextStyle(color: T.textMuted, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0),
    );
  }
}

class _EmptyConv extends StatelessWidget {
  final String name;
  const _EmptyConv({required this.name});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.waving_hand_rounded, size: 48, color: T.waiting),
        const SizedBox(height: 16),
        Text(
          'Start chatting with $name',
          style: GoogleFonts.inter(color: T.textSecondary, fontSize: 15),
        ),
      ],
    ),
  );
}

// ── Input bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatefulWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  final bool enabled;
  const _InputBar({
    required this.ctrl,
    required this.onSend,
    required this.enabled,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onChanged);
  }

  void _onChanged() {
    final has = widget.ctrl.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 12,
      ),
      decoration: const BoxDecoration(
        color: T.surface,
        border: Border(top: BorderSide(color: T.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 40,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: T.surfaceEl,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: T.border),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  controller: widget.ctrl,
                  enabled: widget.enabled,
                  maxLines: 5,
                  minLines: 1,
                  style: const TextStyle(color: T.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Message…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasText && widget.enabled ? T.accentBlue : T.surfaceEl,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: _hasText && widget.enabled ? widget.onSend : null,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _hasText ? Icons.send_rounded : Icons.mic_rounded,
                    key: ValueKey(_hasText),
                    size: 20,
                    color: _hasText && widget.enabled
                        ? Colors.white
                        : T.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Typing dot ────────────────────────────────────────────────────────────────
class _TypingDot extends StatelessWidget {
  final Duration delay;
  const _TypingDot({required this.delay});

  @override
  Widget build(BuildContext context) =>
      Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: T.textMuted,
            ),
          )
          .animate(onPlay: (c) => c.repeat())
          .fadeIn(duration: 400.ms, delay: delay)
          .fadeOut(
            duration: 400.ms,
            delay: delay + const Duration(milliseconds: 400),
          );
}
