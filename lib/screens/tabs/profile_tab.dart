// ─── screens/tabs/profile_tab.dart ───────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';

class ProfileTab extends StatelessWidget {
  final AdminInfo admin;
  const ProfileTab({super.key, required this.admin});

  // ── No BlocBuilder here — static content, zero rebuilds from any bloc ─────
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
            // Header
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
            _Section(
              items: [
                _Item(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  color: T.accentBlue,
                ),
                _Item(
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
                _Item(
                  icon: Icons.security_outlined,
                  label: 'Security',
                  color: T.active,
                ),
                _Item(
                  icon: Icons.language_outlined,
                  label: 'Language',
                  color: T.waiting,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Section(
              items: [
                _Item(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  color: T.textSecondary,
                ),
                _Item(
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

class _Section extends StatelessWidget {
  final List<_Item> items;
  const _Section({required this.items});

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

class _Item {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? trailing;
  const _Item({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
  });
}
