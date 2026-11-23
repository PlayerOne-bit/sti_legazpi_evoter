import 'package:flutter/material.dart';
import '../../widgets/anim.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../blue_button.dart';

class ElectionCard extends StatelessWidget {
  final Election election;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;
  final VoidCallback? onCandidates;
  final VoidCallback? onVoters;
  final VoidCallback? onParties;
  const ElectionCard(
      {super.key,
      required this.election,
      this.onEdit,
      this.onDelete,
      this.onClose,
      this.onCandidates,
      this.onVoters,
      this.onParties});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (election.status) {
      case ElectionStatus.upcoming:
        label = 'Upcoming';
        bg = C.tint;
        fg = C.blue;
        break;
      case ElectionStatus.open:
        label = 'Open now';
        bg = C.okBg;
        fg = C.ok;
        break;
      case ElectionStatus.ended:
        label = 'Tally pending';
        bg = C.warnBg;
        fg = C.warnFg;
        break;
    }
    return HoverLift(
        child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(election.club,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('School year ${election.schoolYear}',
                        style: TextStyle(color: C.muted)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(20)),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.play_circle_outline, size: 18, color: C.muted),
            const SizedBox(width: 8),
            Expanded(child: Text('Opens ${fmtDate(election.startDate)}')),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.stop_circle_outlined, size: 18, color: C.muted),
            const SizedBox(width: 8),
            Expanded(child: Text('Closes ${fmtDate(election.endDate)}')),
          ]),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.groups_outlined, size: 18, color: C.muted),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Open to ${state.levelsLabel(election.levelIds)}')),
          ]),
          if (onCandidates != null) ...[
            const SizedBox(height: 12),
            _CandidatesStrip(election: election, onTap: onCandidates!),
          ],
          if (onVoters != null) ...[
            const SizedBox(height: 8),
            _LinkStrip(
              icon: Icons.fact_check_outlined,
              title: 'Voters',
              summary: election.eligibleCount == 0
                  ? 'No eligible students yet'
                  : '${election.votedCount} of ${election.eligibleCount} voted',
              action: 'Open',
              onTap: onVoters!,
            ),
          ],
          if (onParties != null) ...[
            const SizedBox(height: 8),
            _LinkStrip(
              icon: Icons.flag_outlined,
              title: 'Party lists',
              summary: election.candidateCount == 0
                  ? 'Add candidates to see their party lists'
                  : 'See who runs under each party list',
              action: 'Open',
              onTap: onParties!,
            ),
          ],
          if (onClose != null) ...[
            const SizedBox(height: 14),
            BlueButton(
                label: 'Close season and tally votes',
                icon: Icons.emoji_events,
                onPressed: onClose),
          ],
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit')),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: C.danger),
                  ),
              ],
            ),
          ],
        ],
      ),
    ));
  }
}

class _CandidatesStrip extends StatelessWidget {
  final Election election;
  final VoidCallback onTap;
  const _CandidatesStrip({required this.election, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = election.candidateCount;
    final p = election.positionCount;
    final editable = election.status == ElectionStatus.upcoming;
    return _LinkStrip(
      icon: Icons.how_to_reg_outlined,
      title: 'Candidates',
      summary: n == 0
          ? 'No candidates yet'
          : '$n candidate${n == 1 ? '' : 's'} for $p position${p == 1 ? '' : 's'}',
      action: editable ? 'Manage' : 'View',
      onTap: onTap,
    );
  }
}

class _LinkStrip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String summary;
  final String action;
  final VoidCallback onTap;
  const _LinkStrip(
      {required this.icon,
      required this.title,
      required this.summary,
      required this.action,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(color: C.tint, shape: BoxShape.circle),
                child: Icon(icon, color: C.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(summary,
                        style: TextStyle(color: C.muted, fontSize: 13)),
                  ],
                ),
              ),
              Text(action,
                  style: TextStyle(color: C.blue, fontWeight: FontWeight.w700)),
              Icon(Icons.chevron_right, color: C.blue),
            ],
          ),
        ),
      ),
    );
  }
}
