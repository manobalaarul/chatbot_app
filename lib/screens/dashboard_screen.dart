import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../bloc/auth/auth_bloc.dart';
import '../bloc/autoreplies/autoreplies_bloc.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../models/models.dart';
import '../theme/theme.dart';

// ─────────────────────────────────────────────────────────────
// ROOT SCAFFOLD — BottomNavigationBar with 4 tabs
// ─────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  final AdminInfo admin;
  const DashboardScreen({super.key, required this.admin});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  String? _lastToast;

  static const _pages = ['inbox', 'stats', 'autoreplies', 'profile'];

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const InitDashboardEvent());
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: T.bg,
      ),
      child: BlocListener<DashboardBloc, DashboardState>(
        listener: (ctx, state) {
          if (state is DashboardLoaded &&
              state.toastMessage != null &&
              state.toastMessage != _lastToast) {
            _lastToast = state.toastMessage;
            _toast(ctx, state.toastMessage!);
          }
        },
        child: Scaffold(
          backgroundColor: T.bg,
          body: IndexedStack(
            index: _tab,
            children: [
              InboxPage(admin: widget.admin),
              const StatsPage(),
              const AutoRepliesPage(),
              ProfilePage(admin: widget.admin),
            ],
          ),
          bottomNavigationBar: _BottomBar(
            current: _tab,
            onChange: (i) => setState(() => _tab = i),
          ),
        ),
      ),
    );
  }

  void _toast(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: T.textPrimary, fontSize: 13),
        ),
        backgroundColor: T.surfaceEl,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: T.border),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int current;
  final void Function(int) onChange;
  const _BottomBar({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (ctx, state) {
        final unreadCount = state is DashboardLoaded
            ? state.unreadIds.length
            : 0;

        return Container(
          decoration: const BoxDecoration(
            color: T.surface,
            border: Border(top: BorderSide(color: T.border)),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  _BarItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: 'Inbox',
                    index: 0,
                    current: current,
                    badge: unreadCount,
                    onChange: onChange,
                  ),
                  _BarItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart_rounded,
                    label: 'Stats',
                    index: 1,
                    current: current,
                    onChange: onChange,
                  ),
                  _BarItem(
                    icon: Icons.auto_fix_high_outlined,
                    activeIcon: Icons.auto_fix_high_rounded,
                    label: 'Bot',
                    index: 2,
                    current: current,
                    onChange: onChange,
                  ),
                  _BarItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 3,
                    current: current,
                    onChange: onChange,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final int badge;
  final void Function(int) onChange;

  const _BarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onChange,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChange(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    active ? activeIcon : icon,
                    key: ValueKey(active),
                    size: 24,
                    color: active ? T.accentBlue : T.textMuted,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: T.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: active ? T.accentBlue : T.textMuted,
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAGE 1 — INBOX (conversation list, Instagram DMs style)
// ─────────────────────────────────────────────────────────────
class InboxPage extends StatefulWidget {
  final AdminInfo admin;
  const InboxPage({super.key, required this.admin});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage>
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
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (ctx, state) {
          if (state is! DashboardLoaded) {
            return const Center(
              child: CircularProgressIndicator(
                color: T.accentBlue,
                strokeWidth: 2,
              ),
            );
          }
          final convs = state.filteredConversations;
          final unread = state.unreadIds;

          if (convs.isEmpty) {
            return _EmptyInbox(tab: state.activeTab);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: convs.length,
            separatorBuilder: (_, __) => const Divider(
              color: T.border,
              height: 1,
              indent: 72,
              endIndent: 16,
            ),
            itemBuilder: (_, i) {
              final c = convs[i];
              return _ConvTile(
                    conv: c,
                    hasUnread: unread.contains(c.id),
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

// ─────────────────────────────────────────────────────────────
// CONVERSATION TILE — Instagram DM style
// ─────────────────────────────────────────────────────────────
class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final bool hasUnread;
  final VoidCallback onTap;
  const _ConvTile({
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
            // Avatar with online ring
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
                // Status dot
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
            // Content
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
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF14B8A6),
    ];
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }
}

// ─────────────────────────────────────────────────────────────
// PAGE 2 — STATS
// ─────────────────────────────────────────────────────────────
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppBar(
        backgroundColor: T.surface,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: GoogleFonts.inter(
            color: T.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (ctx, state) {
          final s = state is DashboardLoaded
              ? state.stats
              : const DashboardStats();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero metric row
                Row(
                  children: [
                    _BigStatCard(
                      label: 'Waiting',
                      value: s.waiting,
                      color: T.waiting,
                      icon: Icons.hourglass_bottom_rounded,
                    ),
                    const SizedBox(width: 12),
                    _BigStatCard(
                      label: 'Active',
                      value: s.active,
                      color: T.active,
                      icon: Icons.electric_bolt_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _BigStatCard(
                      label: 'Today',
                      value: s.today,
                      color: T.accentBlue,
                      icon: Icons.today_rounded,
                    ),
                    const SizedBox(width: 12),
                    _BigStatCard(
                      label: 'Messages',
                      value: s.messages,
                      color: T.purple,
                      icon: Icons.message_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Live Activity',
                  style: GoogleFonts.inter(
                    color: T.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _ActivityRow(
                  label: 'Waiting queue',
                  value: s.waiting,
                  max: 20,
                  color: T.waiting,
                ),
                const SizedBox(height: 10),
                _ActivityRow(
                  label: 'Active chats',
                  value: s.active,
                  max: 20,
                  color: T.active,
                ),
                const SizedBox(height: 10),
                _ActivityRow(
                  label: 'Resolved today',
                  value: s.today,
                  max: 50,
                  color: T.accentBlue,
                ),
                const SizedBox(height: 10),
                _ActivityRow(
                  label: 'Total messages',
                  value: s.messages,
                  max: 500,
                  color: T.purple,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _BigStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            '$value',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: T.textSecondary, fontSize: 13),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
  );
}

class _ActivityRow extends StatelessWidget {
  final String label;
  final int value, max;
  final Color color;
  const _ActivityRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: T.textSecondary, fontSize: 13),
            ),
            const Spacer(),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAGE 3 — AUTO-REPLIES
// ─────────────────────────────────────────────────────────────
class AutoRepliesPage extends StatefulWidget {
  const AutoRepliesPage({super.key});

  @override
  State<AutoRepliesPage> createState() => _AutoRepliesPageState();
}

class _AutoRepliesPageState extends State<AutoRepliesPage> {
  @override
  void initState() {
    super.initState();
    context.read<AutoRepliesBloc>().add(const LoadAutoRepliesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppBar(
        backgroundColor: T.surface,
        elevation: 0,
        title: Text(
          'Auto-Replies',
          style: GoogleFonts.inter(
            color: T.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: T.accentBlue, size: 26),
            onPressed: () => _showAddSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<AutoRepliesBloc, AutoRepliesState>(
        builder: (ctx, state) {
          if (state is AutoRepliesLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: T.accentBlue,
                strokeWidth: 2,
              ),
            );
          }
          if (state is AutoRepliesLoaded && state.rules.isEmpty) {
            return _EmptyRules(onAdd: () => _showAddSheet(context));
          }
          if (state is AutoRepliesLoaded) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.rules.length,
              itemBuilder: (_, i) =>
                  _RuleCard(
                        rule: state.rules[i],
                        onDelete: () => ctx.read<AutoRepliesBloc>().add(
                          DeleteAutoReplyEvent(state.rules[i].id),
                        ),
                      )
                      .animate(delay: Duration(milliseconds: i * 60))
                      .fadeIn(duration: 300.ms),
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: T.accentBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Rule',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: T.surfaceEl,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: context.read<AutoRepliesBloc>(),
        child: const _AddRuleSheet(),
      ),
    );
  }
}

class _EmptyRules extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyRules({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: T.purple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_fix_high_rounded,
            size: 36,
            color: T.purple,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No rules yet',
          style: GoogleFonts.inter(
            color: T.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: T.accentBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Add your first rule'),
        ),
      ],
    ),
  );
}

class _RuleCard extends StatelessWidget {
  final AutoReply rule;
  final VoidCallback onDelete;
  const _RuleCard({required this.rule, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isKeyword = rule.triggerType == 'keyword';
    final typeColor = isKeyword ? T.accentBlue : T.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: T.surfaceEl,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: typeColor.withOpacity(0.3)),
                ),
                child: Text(
                  rule.triggerType.toUpperCase(),
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rule.triggerValue,
                  style: const TextStyle(
                    color: T.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: T.accent,
                ),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: T.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  size: 14,
                  color: T.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rule.response,
                    style: const TextStyle(
                      color: T.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddRuleSheet extends StatefulWidget {
  const _AddRuleSheet();

  @override
  State<_AddRuleSheet> createState() => _AddRuleSheetState();
}

class _AddRuleSheetState extends State<_AddRuleSheet> {
  final _triggerCtrl = TextEditingController();
  final _responseCtrl = TextEditingController();
  String _type = 'keyword';

  @override
  void dispose() {
    _triggerCtrl.dispose();
    _responseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: T.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'New Auto-Reply Rule',
            style: GoogleFonts.inter(
              color: T.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          // Type selector
          Row(
            children: ['keyword', 'regex'].map((t) {
              final active = t == _type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? T.accentBlue : T.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? T.accentBlue : T.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      t.toUpperCase(),
                      style: TextStyle(
                        color: active ? Colors.white : T.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _triggerCtrl,
            style: const TextStyle(color: T.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Trigger',
              labelStyle: TextStyle(color: T.textMuted),
              hintText: 'e.g. hello',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _responseCtrl,
            maxLines: 4,
            style: const TextStyle(color: T.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Bot Response',
              labelStyle: TextStyle(color: T.textMuted),
              hintText: 'What the bot will reply…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final t = _triggerCtrl.text.trim();
                final r = _responseCtrl.text.trim();
                if (t.isEmpty || r.isEmpty) return;
                context.read<AutoRepliesBloc>().add(
                  AddAutoReplyEvent(type: _type, trigger: t, response: r),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: T.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Add Rule',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAGE 4 — PROFILE
// ─────────────────────────────────────────────────────────────
class ProfilePage extends StatelessWidget {
  final AdminInfo admin;
  const ProfilePage({super.key, required this.admin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.bg,
      appBar: AppBar(
        backgroundColor: T.surface,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            color: T.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: T.surface,
                border: Border(bottom: BorderSide(color: T.border)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [T.accentBlue, T.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: T.accentBlue.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      admin.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    admin.name,
                    style: GoogleFonts.inter(
                      color: T.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    admin.email,
                    style: const TextStyle(
                      color: T.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: T.active.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: T.active.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: T.active,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Online',
                          style: TextStyle(
                            color: T.active,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SettingsSection(
              items: [
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  color: T.accentBlue,
                ),
                _SettingsItem(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark Mode',
                  color: T.purple,
                  trailing: Switch(
                    value: true,
                    onChanged: (_) {},
                    activeColor: T.accentBlue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                _SettingsItem(
                  icon: Icons.security_outlined,
                  label: 'Security',
                  color: T.active,
                ),
                _SettingsItem(
                  icon: Icons.language_outlined,
                  label: 'Language',
                  color: T.waiting,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _SettingsSection(
              items: [
                _SettingsItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  color: T.textSecondary,
                ),
                _SettingsItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About',
                  color: T.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                  onPressed: () {
                    context.read<DashboardBloc>().add(
                      const ShutdownDashboardEvent(),
                    );
                    context.read<AuthBloc>().add(const LogoutEvent());
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: T.accent,
                    side: const BorderSide(color: T.accent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsSection({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: T.surfaceEl,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: T.border),
    ),
    child: Column(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        return Column(
          children: [
            ListTile(
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: e.value.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(e.value.icon, size: 18, color: e.value.color),
              ),
              title: Text(
                e.value.label,
                style: const TextStyle(color: T.textPrimary, fontSize: 14),
              ),
              trailing:
                  e.value.trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: T.textMuted,
                    size: 20,
                  ),
              onTap: () {},
            ),
            if (!isLast) const Divider(color: T.border, height: 1, indent: 60),
          ],
        );
      }).toList(),
    ),
  );
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? trailing;
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
  });
}

// ─────────────────────────────────────────────────────────────
// CHAT SCREEN — Full screen, pushed via Navigator
// ─────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final Conversation conv;
  const ChatScreen({super.key, required this.conv});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  void _sendMsg() {
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
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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
        title: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (ctx, state) {
            final conv = state is DashboardLoaded
                ? (state.activeConv ?? widget.conv)
                : widget.conv;
            return Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
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
                          color: T.statusColor(conv.status),
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
                      conv.visitorName,
                      style: const TextStyle(
                        color: T.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      conv.status,
                      style: TextStyle(
                        color: T.statusColor(conv.status),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (ctx, state) {
              final conv = state is DashboardLoaded
                  ? state.activeConv
                  : widget.conv;
              if (conv == null) return const SizedBox();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (conv.status != 'active')
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
                    onPressed: () => _showConvMenu(context, conv),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (ctx, state) {
          if (state is DashboardLoaded && state.messages.isNotEmpty) {
            _scrollToBottom();
          }
        },
        builder: (ctx, state) {
          final s = state is DashboardLoaded ? state : null;

          return Column(
            children: [
              // Messages
              Expanded(
                child: s == null || s.messagesState == MessagesLoadState.loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: T.accentBlue,
                          strokeWidth: 2,
                        ),
                      )
                    : s.messages.isEmpty
                    ? _EmptyConv(name: widget.conv.visitorName)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                        itemCount: s.messages.length,
                        itemBuilder: (_, i) {
                          final msg = s.messages[i];
                          final prev = i > 0 ? s.messages[i - 1] : null;
                          final showAvatar =
                              prev == null || prev.senderType != msg.senderType;
                          return _Bubble(
                            msg: msg,
                            showAvatar: showAvatar,
                            convName: widget.conv.visitorName,
                          );
                        },
                      ),
              ),

              // Typing indicator
              if (s?.showTyping == true)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(
                    children: [
                      ...List.generate(
                        3,
                        (i) =>
                            _TypingDot(delay: Duration(milliseconds: i * 160)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'typing…',
                        style: TextStyle(color: T.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),

              // Input bar
              _InputBar(
                ctrl: _msgCtrl,
                onSend: _sendMsg,
                enabled: s?.activeConv != null,
              ),
            ],
          );
        },
      ),
    );
  }

  void _showConvMenu(BuildContext context, Conversation conv) {
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
                Navigator.pop(context); // go back to inbox
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MESSAGE BUBBLE — Instagram style
// ─────────────────────────────────────────────────────────────
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
    final isVisitor = msg.senderType == 'visitor';

    final timeStr = DateFormat('HH:mm').format(msg.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isAdmin
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Visitor/Bot avatar
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

          // Bubble
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

// ─────────────────────────────────────────────────────────────
// INPUT BAR
// ─────────────────────────────────────────────────────────────
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
    widget.ctrl.addListener(() {
      final has = widget.ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
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
            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
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

// ─────────────────────────────────────────────────────────────
// TYPING DOTS
// ─────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────
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
