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

/// "ACOSTA,ANGELINA KATE MILLENA" -> "Angelina". Also handles "Angelina Acosta".
String _firstName(String full) {
  final t = full.trim();
  final comma = t.indexOf(',');
  final given = comma >= 0 ? t.substring(comma + 1).trim() : t;
  final word = given.split(RegExp(r'\s+')).first;
  if (word.isEmpty) return 'there';
  return word[0].toUpperCase() + word.substring(1).toLowerCase();
}

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
        final first = me == null ? 'there' : _firstName(me.fullName);
        final active = state.homeActive;
        final next = state.homeNext;
        final openForOthers = state.homeOpenForOthers;
        final waitingTally = state.homeWaiting;
        final nothing = active == null &&
            openForOthers == null &&
            !waitingTally &&
            next == null;
        // Candidates are only worth showing while a season is in progress or still to come.
        final showCandidates =
            (active != null || openForOthers != null || next != null) &&
                state.positions.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text('Hi, $first',
                style: const TextStyle(fontWeight: FontWeight.w800)),
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
                  if (me != null) _ProfileStrip(student: me),
                  const SizedBox(height: 18),

                  // 1. The ongoing season (counts down to when voting closes)
                  if (active != null) ...[
                    _SectionHeader(
                      title: '${active.club} election',
                      subtitle: 'School year ${active.schoolYear}',
                      chipLabel: 'Voting open',
                      chipBg: const Color(0xFFE7F5EE),
                      chipFg: C.ok,
                    ),
                    const SizedBox(height: 12),
                    DoomsdayTimer(
                      key: ValueKey(
                          'close-${active.id}-${active.endDate.millisecondsSinceEpoch}'),
                      end: active.endDate,
                      onFinished: state.refreshSoon,
                    ),
                    const SizedBox(height: 14),
                    if (state.hasVoted)
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
                                child: Text(
                                    'Your ballot is in. Thanks for voting.',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            BlueButton(
                              label: 'See live tally',
                              icon: Icons.bar_chart,
                              outlined: true,
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const ResultScreen())),
                            ),
                          ],
                        ),
                      )
                    else
                      BlueButton(
                        label: 'Cast your vote',
                        icon: Icons.how_to_vote,
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const VoteScreen())),
                      ),
                  ] else if (openForOthers != null)
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
                    SizedBox(height: active != null ? 24 : 16),
                    _SectionHeader(
                      title: '${next.club} election',
                      subtitle: 'School year ${next.schoolYear}',
                      chipLabel: 'Upcoming',
                      chipBg: const Color(0xFFE3ECF8),
                      chipFg: C.blue,
                    ),
                    const SizedBox(height: 12),
                    DoomsdayTimer(
                      key: ValueKey(
                          'next-${next.id}-${next.startDate.millisecondsSinceEpoch}'),
                      label: 'Voting opens in',
                      finishedLabel: 'Voting is about to open',
                      end: next.startDate,
                      subtitle: 'Open to ${next.audience}',
                      onFinished: state.refreshSoon,
                    ),
                  ],

                  // 3. Candidates (hidden when no season is pending or in progress)
                  if (showCandidates) ...[
                    const SizedBox(height: 32),
                    const Text('Meet the candidates',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Tap a card to read their vision.',
                        style: TextStyle(color: C.muted)),
                    const SizedBox(height: 16),
                    for (final p in state.positions)
                      _PositionSection(position: p),
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

/// Who is signed in: avatar, grade level, student number.
class _ProfileStrip extends StatelessWidget {
  final Student student;
  const _ProfileStrip({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardBox(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: C.navy,
            child: Text(student.initials,
                style: const TextStyle(
                    color: C.yellow, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.gradeName(student.gradeLevelId),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('Student number ${student.studentNum}',
                    style: const TextStyle(color: C.muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String chipLabel;
  final Color chipBg;
  final Color chipFg;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.chipLabel,
    required this.chipBg,
    required this.chipFg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              Text(subtitle, style: const TextStyle(color: C.muted)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: chipBg, borderRadius: BorderRadius.circular(20)),
          child: Text(chipLabel,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: chipFg)),
        ),
      ],
    );
  }
}

/// One position and its candidate cards.
class _PositionSection extends StatelessWidget {
  final Position position;
  const _PositionSection({required this.position});

  @override
  Widget build(BuildContext context) {
    final list = state.candidatesFor(position.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Row(
            children: [
              Text(position.title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFE3ECF8),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${list.length}',
                    style: const TextStyle(
                        color: C.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('No candidates yet.', style: TextStyle(color: C.muted)),
          )
        else
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
              for (final c in list)
                CandidateCard(
                    candidate: c, onTap: () => showCandidateSheet(context, c)),
            ],
          ),
        const SizedBox(height: 10),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
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
