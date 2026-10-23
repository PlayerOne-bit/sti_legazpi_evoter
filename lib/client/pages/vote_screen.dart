import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../shared/components/blue_button.dart';
import '../../theme.dart';
import '../components/candidate_card.dart';

class VoteScreen extends StatelessWidget {
  const VoteScreen({super.key});

  Future<void> _review(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit your ballot?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in state.positions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${p.title}: ', style: const TextStyle(color: C.muted)),
                  TextSpan(
                    text: state.candidates.firstWhere((c) => c.id == state.selections[p.id]).name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ])),
              ),
            const SizedBox(height: 6),
            const Text('You cannot change your vote after submitting.', style: TextStyle(color: C.muted)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Go back')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit ballot')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      state.submitVote();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ballot submitted. Thanks for voting.')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final done = state.positions.every((p) => state.selections.containsKey(p.id));
        return Scaffold(
          appBar: AppBar(title: const Text('Your ballot')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const Text('Pick one candidate for each position.', style: TextStyle(color: C.muted)),
              const SizedBox(height: 16),
              for (final p in state.positions) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 6),
                  child: Text(p.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                for (final c in state.candidatesFor(p.id))
                  CandidateCard(
                    candidate: c,
                    selectable: true,
                    selected: state.selections[p.id] == c.id,
                    onTap: () => state.select(p.id, c.id),
                  ),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: BlueButton(
                label: done ? 'Review ballot' : 'Choose a candidate for every position',
                onPressed: done ? () => _review(context) : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
