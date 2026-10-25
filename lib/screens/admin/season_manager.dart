import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../../widgets/admin/election_card.dart';
import '../../widgets/admin/election_form.dart';
import '../../widgets/blue_button.dart';
import 'winner_screen.dart';

/// Create, edit, delete, and close voting seasons.
class SeasonManagerPage extends StatelessWidget {
  const SeasonManagerPage({super.key});

  Future<void> _delete(BuildContext context, Election e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${e.club} ${e.schoolYear}?'),
        content: const Text(
            'This season has not started, so nothing is lost except its schedule.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete season')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final err = await state.deleteElection(e.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err ?? 'Season deleted.')));
  }

  void _close(BuildContext context, Election e) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => WinnerScreen(election: e)));

  Widget _heading(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 10),
        child: Text(t,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final open = state.elections
            .where((e) => e.status == ElectionStatus.open)
            .toList();
        final ended = state.pendingTally;
        final upcoming = state.elections
            .where((e) => e.status == ElectionStatus.upcoming)
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            BlueButton(
              label: 'Create voting season',
              icon: Icons.add,
              onPressed: () => showElectionForm(context),
            ),
            if (open.isNotEmpty) _heading('Open now'),
            for (final e in open)
              ElectionCard(
                election: e,
                onClose: () => _close(context, e),
                onEdit: () => showElectionForm(context, existing: e),
              ),
            if (ended.isNotEmpty) _heading('Voting ended, tally pending'),
            for (final e in ended)
              ElectionCard(election: e, onClose: () => _close(context, e)),
            if (upcoming.isNotEmpty) _heading('Upcoming'),
            for (final e in upcoming)
              ElectionCard(
                election: e,
                onEdit: () => showElectionForm(context, existing: e),
                onDelete: () => _delete(context, e),
              ),
            if (open.isEmpty && ended.isEmpty && upcoming.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Text('No seasons yet. Create one to schedule a vote.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: C.muted)),
                ),
              ),
          ],
        );
      },
    );
  }
}
