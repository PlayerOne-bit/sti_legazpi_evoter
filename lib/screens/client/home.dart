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
import '../../widgets/loading_view.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  @override
  void initState() {
    super.initState();
    state.loadHome();
  }

  void _signOut(BuildContext context) {
    state.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        if (!state.homeLoaded) {
          return Scaffold(
            appBar: AppBar(actions: [
              IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout),
                  onPressed: () => _signOut(context)),
            ]),
            body: LoadingView(error: state.homeError, onRetry: state.loadHome),
          );
        }
        final me = state.me;
        final active = state.homeActive;
        final next = state.homeNext;
        final openForOthers = state.homeOpenForOthers;
        final waitingTally = state.homeWaiting;
        final nothing = active == null &&
            openForOthers == null &&
            !waitingTally &&
            next == null;

        // Candidates are only shown while a season is in progress or still to come.
        final hasSeason =
            active != null || openForOthers != null || next != null;
        final positions = [
          for (final p in state.positions)
            if (state.candidatesFor(p.id).isNotEmpty) p,
        ];
        final showCandidates = hasSeason && positions.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('STI eVoter',
                style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: state.loadHome),
              IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout),
                  onPressed: () => _signOut(context)),
            ],
          ),
          body: CenteredBody(
            maxWidth: 1000,
            child: RefreshIndicator(
              onRefresh: state.loadHome,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  if (me != null) _ProfileCard(me),
                  const SizedBox(height: 20),

                  // 1. The ongoing season (counts down to when voting closes)
                  if (active != null)
                    _OpenSeasonCard(
                      election: active,
                      hasVoted: state.hasVoted,
                    )
                  else if (openForOthers != null)
                    _Notice(
                      icon: Icons.info_outline,
                      title: '${openForOthers.club} voting is open',
                      body: 'It is open to ${openForOthers.audience} only.',
                    )
                  else if (waitingTally)
                    const _Notice(
                      icon: Icons.lock_clock,
                      title: 'Voting has closed',
                      body:
                          'The results will be posted once the admin finishes the tally.',
                    )
                  else if (nothing)
                    const _Notice(
                      icon: Icons.event_busy,
                      title: 'No election scheduled',
                      body:
                          'Check back later. The admin will announce the next voting season.',
                    ),

                  // 2. The next season (always shown when there is one, even during a vote)
                  if (next != null) ...[
                    const SizedBox(height: 20),
                    const _SectionLabel('Coming up'),
                    DoomsdayTimer(
                      key: ValueKey(
                          'next-${next.id}-${next.startDate.millisecondsSinceEpoch}'),
                      label: 'Next voting season starts in',
                      finishedLabel: 'Voting is about to open',
                      end: next.startDate,
                      subtitle: '${next.club}, ${next.schoolYear}\n'
                          'Open to ${next.audience}',
                      onFinished: state.refreshSoon,
                    ),
                  ],

                  // 3. Candidates, only while a season is in progress or pending
                  if (showCandidates) ...[
                    const SizedBox(height: 32),
                    const Text('Meet the candidates',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Tap a card to read their vision.',
                        style: TextStyle(color: C.muted)),
                    const SizedBox(height: 12),
                    for (final p in positions) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 10),
                        child: Row(
                          children: [
                            Text(p.title,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFE3ECF8),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('${state.candidatesFor(p.id).length}',
                                  style: const TextStyle(
                                      color: C.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 230,
                          mainAxisExtent: 300,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        children: [
                          for (final c in state.candidatesFor(p.id))
                            CandidateCard(
                                candidate: c,
                                onTap: () => showCandidateSheet(context, c)),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Who is signed in: initials, name, student number and grade level.
class _ProfileCard extends StatelessWidget {
  final Student me;
  const _ProfileCard(this.me);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardBox(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: C.blue,
            child: Text(me.initials,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(me.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('${me.studentNum}, ${state.gradeName(me.gradeLevelId)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: C.muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: C.muted,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w700)),
      );
}

/// The season that is open for this student: countdown to closing, then vote or tally.
class _OpenSeasonCard extends StatelessWidget {
  final ClientElection election;
  final bool hasVoted;
  const _OpenSeasonCard({required this.election, required this.hasVoted});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${election.club} election',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('School year ${election.schoolYear}',
                      style: const TextStyle(color: C.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xFFE7F5EE),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Voting open',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: C.ok)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DoomsdayTimer(
          key: ValueKey(
              'close-${election.id}-${election.endDate.millisecondsSinceEpoch}'),
          end: election.endDate,
          onFinished: state.refreshSoon,
        ),
        const SizedBox(height: 14),
        if (hasVoted)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardBox(
                color: const Color(0xFFE7F5EE),
                border: const Color(0xFFB9E2CD)),
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
                  icon: Icons.bar_chart,
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
      ],
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFFF1F3F7),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: C.muted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
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
