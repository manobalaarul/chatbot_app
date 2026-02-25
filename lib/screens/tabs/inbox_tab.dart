// ─── screens/tabs/inbox_tab.dart ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';
import '../chat_screen.dart';

class InboxTab extends StatefulWidget {
  final AdminInfo admin;
  const InboxTab({super.key, required this.admin});

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  static const _tabs = ['waiting', 'active', 'bot', 'closed'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        context.read<DashboardBloc>().add(
          SwitchTabEvent(_tabs[_tabCtrl.index]),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppBar(
        backgroundColor: T.surface,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleSpacing: 16,
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: T.textPrimary),
                onChanged: (q) => context.read<DashboardBloc>().add(
                  SearchConversationsEvent(q),
                ),
                decoration: const InputDecoration(
                  hintText: 'Search conversations…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: T.active,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ChatFlow',
                    style: GoogleFonts.inter(
                      color: T.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _searching ? Icons.close_rounded : Icons.search_rounded,
                key: ValueKey(_searching),
                color: T.textSecondary,
                size: 22,
              ),
            ),
            onPressed: () {
              setState(() => _searching = !_searching);
              if (!_searching) {
                _searchCtrl.clear();
                context.read<DashboardBloc>().add(
                  const SearchConversationsEvent(''),
                );
              }
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: T.accentBlue,
            unselectedLabelColor: T.textMuted,
            indicatorColor: T.accentBlue,
            indicatorWeight: 2,
            labelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
            tabs: _tabs.map((t) => Tab(text: _cap(t))).toList(),
          ),
        ),
      ),
      // ── ISOLATED selector: only rebuilds when conv list or unread changes ──
      // Does NOT rebuild when messages, typing, or activeConv changes.
      // This is the key fix — InboxTab is completely decoupled from ChatScreen.
      body: BlocSelector<DashboardBloc, DashboardState, _InboxData>(
        selector: (state) {
          if (state is! DashboardLoaded) {
            return _InboxData(convs: [], unread: {}, tab: 'waiting');
          }
          return _InboxData(
            convs: state.filteredConversations,
            unread: state.unreadIds,
            tab: state.activeTab,
          );
        },
        builder: (ctx, data) {
          if (data.convs.isEmpty) {
            return _EmptyInbox(tab: data.tab);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: data.convs.length,
            separatorBuilder: (_, __) => const Divider(
              color: T.border,
              height: 1,
              indent: 72,
              endIndent: 16,
            ),
            itemBuilder: (_, i) {
              final c = data.convs[i];
              return ConvTile(
                    key: ValueKey(c.id),
                    conv: c,
                    hasUnread: data.unread.contains(c.id),
                    onTap: () {
                      context.read<DashboardBloc>().add(
                        SelectConversationEvent(c),
                      );
                      Navigator.of(
                        context,
                      ).push(_slideRoute(ChatScreen(conv: c)));
                    },
                  )
                  .animate(delay: Duration(milliseconds: i * 35))
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.05, end: 0);
            },
          );
        },
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Selector data class ───────────────────────────────────────────────────────
// Using a dedicated class so BlocSelector equality check works correctly.
class _InboxData {
  final List<Conversation> convs;
  final Set<int> unread;
  final String tab;
  _InboxData({required this.convs, required this.unread, required this.tab});

  @override
  bool operator ==(Object other) {
    if (other is! _InboxData) return false;
    return other.tab == tab &&
        other.unread.length == unread.length &&
        other.convs.length == convs.length &&
        // Deep check: compare ids + last messages (cheap)
        other.convs.asMap().entries.every(
          (e) =>
              e.value.id == convs[e.key].id &&
              e.value.lastMessage == convs[e.key].lastMessage &&
              e.value.status == convs[e.key].status,
        );
  }

  @override
  int get hashCode =>
      Object.hash(tab, unread.length, convs.map((c) => c.id).join());
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyInbox extends StatelessWidget {
  final String tab;
  const _EmptyInbox({required this.tab});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: T.accentBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.inbox_rounded, size: 36, color: T.accentBlue),
        ),
        const SizedBox(height: 16),
        Text(
          'No $tab conversations',
          style: GoogleFonts.inter(
            color: T.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Waiting for visitors to connect',
          style: TextStyle(color: T.textMuted, fontSize: 13),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms),
  );
}

// ── Conversation tile ─────────────────────────────────────────────────────────
class ConvTile extends StatelessWidget {
  final Conversation conv;
  final bool hasUnread;
  final VoidCallback onTap;
  const ConvTile({
    super.key,
    required this.conv,
    required this.hasUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = conv.visitorName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final avatarColor = _hashColor(conv.visitorName);

    return InkWell(
      onTap: onTap,
      splashColor: T.surfaceEl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [avatarColor.withOpacity(0.8), avatarColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: hasUnread
                        ? Border.all(color: T.accentBlue, width: 2.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: T.statusColor(conv.status),
                      border: Border.all(color: T.bg, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.visitorName,
                          style: TextStyle(
                            color: T.textPrimary,
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        timeago.format(conv.lastMessageAt, locale: 'en_short'),
                        style: TextStyle(
                          color: hasUnread ? T.accentBlue : T.textMuted,
                          fontSize: 11,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage ?? 'No messages yet',
                          style: TextStyle(
                            color: hasUnread ? T.textSecondary : T.textMuted,
                            fontSize: 13,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: T.accentBlue,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hashColor(String name) {
    const colors = [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFF3B82F6),
      Color(0xFFEF4444),
      Color(0xFF14B8A6),
    ];
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }
}

// ── Slide route ───────────────────────────────────────────────────────────────
Route _slideRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) => SlideTransition(
    position: Tween(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
    child: child,
  ),
  transitionDuration: const Duration(milliseconds: 280),
);
