import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../shared/components/blue_button.dart';
import '../../shared/pages/auth.dart';
import '../../shared/pages/result_screen.dart';
import '../../theme.dart';
import '../components/candidate_card.dart';
import '../components/doomsday_timer.dart';
import 'vote_screen.dart';

class ClientHome extends StatelessWidget {
  const ClientHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final first = state.students.first.fullName.split(' ').first;
        return Scaffold(
          appBar: AppBar(
            title: Text('Hi, $first', style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout),
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                  (_) => false,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Text('${state.club} election, ${state.schoolYear}',
                  style: const TextStyle(color: C.muted)),
              const SizedBox(height: 12),
              DoomsdayTimer(end: state.endDate),
              const SizedBox(height: 18),
              if (state.hasVoted)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: cardBox(color: const Color(0xFFE7F5EE), border: const Color(0xFFB9E2CD)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(children: [
                        Icon(Icons.check_circle, color: C.ok),
                        SizedBox(width: 10),
                        Expanded(child: Text('Your ballot is in. Thanks for voting.',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                      ]),
                      const SizedBox(height: 12),
                      BlueButton(
                        label: 'See live tally',
                        outlined: true,
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ResultScreen())),
                      ),
                    ],
                  ),
                )
              else
                BlueButton(
                  label: 'Cast your vote',
                  icon: Icons.how_to_vote,
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const VoteScreen())),
                ),
              const SizedBox(height: 28),
              const Text('Meet the candidates',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Tap a card to read their vision.', style: TextStyle(color: C.muted)),
              const SizedBox(height: 16),
              for (final p in state.positions) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 6),
                  child: Text(p.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                for (final c in state.candidatesFor(p.id)) CandidateCard(candidate: c),
              ],
            ],
          ),
        );
      },
    );
  }
}
