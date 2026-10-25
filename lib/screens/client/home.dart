import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../../widgets/blue_button.dart';
import '../../widgets/centered_body.dart';
import '../../widgets/client/candidate_card.dart';
import '../../widgets/doomsday_timer.dart';
import '../auth.dart';
import '../result_screen.dart';
import 'vote_screen.dart';

class ClientHome extends StatelessWidget {
  const ClientHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final me = state.me;
        final first = me?.fullName.split(' ').first ?? 'there';
        // Only seasons this student's grade level may vote in
        final active = state.activeFor(me);
        final next = state.nextFor(me);
        final openForOthers = active == null ? state.activeElection : null;
        final waitingTally = state.pendingTallyFor(me);
        final nothing = active == null && openForOthers == null && !waitingTally && next == null;
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
          body: CenteredBody(
            maxWidth: 1000,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                if (me != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(state.gradeName(me.gradeLevelId), style: const TextStyle(color: C.muted)),
                  ),

                // 1. The ongoing season (counts down to when voting closes)
                if (active != null) ...[
                  Text('${active.club} election, ${active.schoolYear}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  DoomsdayTimer(
                    key: ValueKey('close-${active.id}-${active.endDate.millisecondsSinceEpoch}'),
                    end: active.endDate,
                    onFinished: state.touch,
                  ),
                  const SizedBox(height: 14),
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
                            Expanded(
                              child: Text('Your ballot is in. Thanks for voting.',
                                  style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          BlueButton(
                            label: 'See live tally',
                            outlined: true,
                            onPressed: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => const ResultScreen())),
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
                ] else if (openForOthers != null)
                  _Notice(
                    icon: Icons.info_outline,
                    title: '${openForOthers.club} voting is open',
                    body: 'It is open to ${state.levelsLabel(openForOthers.levelIds)} only.',
                  )
                else if (waitingTally)
                  const _Notice(
                    icon: Icons.lock_clock,
                    title: 'Voting has closed',
                    body: 'The results will be posted once the admin finishes the tally.',
                  )
                else if (nothing)
                  const _Notice(
                    icon: Icons.event_busy,
                    title: 'No election scheduled',
                    body: 'Check back later. The admin will announce the next voting season.',
                  ),

                // 2. The next season (always shown when there is one, even during a vote)
                if (next != null) ...[
                  const SizedBox(height: 16),
                  DoomsdayTimer(
                    key: ValueKey('next-${next.id}-${next.startDate.millisecondsSinceEpoch}'),
                    label: 'Next voting season starts in',
                    finishedLabel: 'Voting is about to open',
                    end: next.startDate,
                    subtitle: '${next.club}, ${next.schoolYear}\n'
                        'Open to ${state.levelsLabel(next.levelIds)}',
                    onFinished: state.touch,
                  ),
                ],

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
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 230,
                      mainAxisExtent: 300,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    children: [
                      for (final c in state.candidatesFor(p.id))
                        CandidateCard(candidate: c, onTap: () => showCandidateSheet(context, c)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Notice({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardBox(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: C.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(color: C.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
