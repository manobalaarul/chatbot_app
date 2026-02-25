// ─── screens/dashboard_screen.dart ───────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/dashboard/dashboard_bloc.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import 'tabs/autoreplies_tab.dart';
import 'tabs/inbox_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/stats_tab.dart';

class DashboardScreen extends StatefulWidget {
  final AdminInfo admin;
  const DashboardScreen({super.key, required this.admin});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final PageController _pageCtrl;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
    _pageCtrl.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: T.bg,
      ),
      child: Scaffold(
        backgroundColor: T.bg,
        // ── Toast listener lives here — single place for all tab toasts ──────
        body: BlocListener<DashboardBloc, DashboardState>(
          listenWhen: (prev, curr) {
            if (curr is! DashboardLoaded) return false;
            if (prev is! DashboardLoaded) return curr.toastMessage != null;
            return curr.toastMessage != null &&
                curr.toastMessage != prev.toastMessage;
          },
          listener: (ctx, state) {
            if (state is DashboardLoaded && state.toastMessage != null) {
              ScaffoldMessenger.of(ctx).clearSnackBars();
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(
                    state.toastMessage!,
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
          },
          // ── PageView makes tabs swipable ──────────────────────────────────
          child: PageView(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _tab = i),
            // Each tab is a fully independent widget with its own BlocSelector
            children: [
              InboxTab(admin: widget.admin),
              const StatsTab(),
              const AutoRepliesTab(),
              ProfileTab(admin: widget.admin),
            ],
          ),
        ),
        bottomNavigationBar: _BottomBar(current: _tab, onChange: _goTo),
      ),
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────
// Only rebuilds when unread count changes — uses BlocSelector not BlocBuilder
class _BottomBar extends StatelessWidget {
  final int current;
  final void Function(int) onChange;
  const _BottomBar({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DashboardBloc, DashboardState, int>(
      selector: (s) => s is DashboardLoaded ? s.unreadIds.length : 0,
      builder: (ctx, unread) => Container(
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
                  badge: unread,
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
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current, badge;
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
