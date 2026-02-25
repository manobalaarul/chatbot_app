// ─── screens/tabs/stats_tab.dart ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

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
      // ── Only rebuilds when stats change — ignores messages/convs/typing ──
      body: BlocSelector<DashboardBloc, DashboardState, DashboardStats>(
        selector: (s) =>
            s is DashboardLoaded ? s.stats : const DashboardStats(),
        builder: (_, stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatCard(
                    label: 'Waiting',
                    value: stats.waiting,
                    color: T.waiting,
                    icon: Icons.hourglass_bottom_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Active',
                    value: stats.active,
                    color: T.active,
                    icon: Icons.electric_bolt_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    label: 'Today',
                    value: stats.today,
                    color: T.accentBlue,
                    icon: Icons.today_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Messages',
                    value: stats.messages,
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
                value: stats.waiting,
                max: 20,
                color: T.waiting,
              ),
              const SizedBox(height: 10),
              _ActivityRow(
                label: 'Active chats',
                value: stats.active,
                max: 20,
                color: T.active,
              ),
              const SizedBox(height: 10),
              _ActivityRow(
                label: 'Resolved today',
                value: stats.today,
                max: 50,
                color: T.accentBlue,
              ),
              const SizedBox(height: 10),
              _ActivityRow(
                label: 'Total messages',
                value: stats.messages,
                max: 500,
                color: T.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatCard({
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
