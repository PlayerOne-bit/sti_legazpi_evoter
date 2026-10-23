import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../shared/components/blue_button.dart';
import '../../theme.dart';
import 'winner_screen.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _pick(BuildContext context, bool start) async {
    final init = start ? state.startDate : state.endDate;
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (d == null || !context.mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(init));
    if (t == null) return;
    final v = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    start ? state.setSchedule(start: v) : state.setSchedule(end: v);
  }

  void _note(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final total = state.students.length;
        final voted = state.votedCount;
        final pct = total == 0 ? 0 : (voted * 100 / total).round();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Row(
              children: [
                Expanded(child: _Stat('Students', '$total')),
                const SizedBox(width: 10),
                Expanded(child: _Stat('Voted', '$voted')),
                const SizedBox(width: 10),
                Expanded(child: _Stat('Turnout', '$pct%', accent: true)),
              ],
            ),
            const SizedBox(height: 22),
            const Text('Election settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardBox(),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: state.schoolYear,
                    decoration: const InputDecoration(labelText: 'School year'),
                    items: [for (final y in state.schoolYears) DropdownMenuItem(value: y, child: Text(y))],
                    onChanged: (v) => state.setElection(year: v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: state.club,
                    decoration: const InputDecoration(labelText: 'Club'),
                    items: [for (final c in state.clubs) DropdownMenuItem(value: c, child: Text(c))],
                    onChanged: (v) => state.setElection(clubName: v),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline, color: C.blue),
                    title: const Text('Voting opens'),
                    subtitle: Text(fmtDate(state.startDate)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: () => _pick(context, true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.stop_circle_outlined, color: C.blue),
                    title: const Text('Voting closes'),
                    subtitle: Text(fmtDate(state.endDate)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: () => _pick(context, false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
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
            const SizedBox(height: 22),
            BlueButton(
              label: 'Close election and tally votes',
              icon: Icons.emoji_events,
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const WinnerScreen())),
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
