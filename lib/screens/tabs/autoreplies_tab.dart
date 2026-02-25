// ─── screens/tabs/autoreplies_tab.dart ───────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../bloc/autoreplies/autoreplies_bloc.dart';
import '../../models/models.dart';
import '../../theme/theme.dart';

class AutoRepliesTab extends StatefulWidget {
  const AutoRepliesTab({super.key});

  @override
  State<AutoRepliesTab> createState() => _AutoRepliesTabState();
}

class _AutoRepliesTabState extends State<AutoRepliesTab> {
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
      // ── Uses AutoRepliesBloc exclusively — no DashboardBloc dependency ───
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
                        key: ValueKey(state.rules[i].id),
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

  void _showAddSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: T.surfaceEl,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: ctx.read<AutoRepliesBloc>(),
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
  const _RuleCard({super.key, required this.rule, required this.onDelete});

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
