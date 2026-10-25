import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../../widgets/admin/election_card.dart';
import '../../widgets/blue_button.dart';
import '../../widgets/doomsday_timer.dart';
import 'winner_screen.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _note(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _close(BuildContext context, Election e) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => WinnerScreen(election: e)));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final cur = state.currentElection;
        final total = cur == null ? state.students.length : state.eligibleCount(cur);
        final voted = cur == null ? state.votedCount : state.votedIn(cur);
        final pct = total == 0 ? 0 : (voted * 100 / total).round();
        final next = state.nextElection;
        final current = <Election>[
          if (state.activeElection != null) state.activeElection!,
          ...state.pendingTally,
        ];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            if (next != null)
              DoomsdayTimer(
                key: ValueKey('next-${next.id}-${next.startDate.millisecondsSinceEpoch}'),
                label: 'Next voting season starts in',
                finishedLabel: 'A voting season is starting',
                end: next.startDate,
                subtitle: '${next.club}, ${next.schoolYear}',
                onFinished: state.touch,
              )
            else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: cardBox(),
                child: const Row(
                  children: [
                    Icon(Icons.event_busy, color: C.muted),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('No upcoming voting season. Create one in the Seasons tab.',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _Stat(cur == null ? 'Students' : 'Eligible', '$total')),
                const SizedBox(width: 10),
                Expanded(child: _Stat('Voted', '$voted')),
                const SizedBox(width: 10),
                Expanded(child: _Stat('Turnout', '$pct%', accent: true)),
              ],
            ),
            if (current.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text('Current season', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final e in current) ElectionCard(election: e, onClose: () => _close(context, e)),
            ],
            const SizedBox(height: 10),
            const Text('Excel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Uses the school template for students and candidates.', style: TextStyle(color: C.muted)),
            const SizedBox(height: 12),
            BlueButton(
              label: 'Import students and candidates',
              icon: Icons.upload_file,
              outlined: true,
              onPressed: () => _note(context, 'Prototype: file picker will connect to the backend import.'),
            ),
            const SizedBox(height: 10),
            BlueButton(
              label: 'Export results',
              icon: Icons.download,
              outlined: true,
              onPressed: () => _note(context, 'Prototype: results export will come from the backend.'),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  const _Stat(this.label, this.value, {this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardBox(color: accent ? C.navy : Colors.white, border: accent ? C.navy : C.line),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: accent ? C.yellow : C.ink)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: accent ? Colors.white70 : C.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
