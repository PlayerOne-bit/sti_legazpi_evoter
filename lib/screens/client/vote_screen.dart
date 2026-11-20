import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/mock.dart';
import '../../widgets/blue_button.dart';
import '../../widgets/centered_body.dart';
import '../../theme.dart';
import '../../widgets/client/candidate_card.dart';
import '../../widgets/client/vote_stepper.dart';

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final _pc = PageController();
  int page = 0;
  bool _busy = false;

  List<Position> get _ps => state.positions
      .where((p) => state.candidatesFor(p.id).isNotEmpty)
      .toList();

  bool _chosen(int i) => state.selections.containsKey(_ps[i].id);

  bool _canGoTo(int i) {
    for (int j = 0; j < i && j < _ps.length; j++) {
      if (!_chosen(j)) return false;
    }
    return true;
  }

  void _go(int i) => _pc.animateToPage(i,
      duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);

  void _onPageChanged(int i) {
    if (i > page && !_canGoTo(i)) {
      _go(page);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Choose your ${_ps[page].title} first.')),
      );
      return;
    }
    setState(() => page = i);
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final err = await state.submitVote();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Ballot submitted. Thanks for voting.')));
    if (err == null || state.hasVoted || state.homeActive == null)
      Navigator.of(context).pop();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final lastIndex = _ps.length;
    if (e.logicalKey == LogicalKeyboardKey.arrowRight &&
        page < lastIndex &&
        _chosen(page)) {
      _go(page + 1);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowLeft && page > 0) {
      _go(page - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final ps = _ps;
        final isLast = page == ps.length;
        return Focus(
          autofocus: true,
          onKeyEvent: _onKey,
          child: Scaffold(
            appBar: AppBar(title: const Text('Your ballot')),
            body: CenteredBody(
              maxWidth: 1040,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: VoteStepper(
                      labels: [...ps.map((p) => p.title), 'Submit'],
                      current: page,
                      canGoTo: _canGoTo,
                      onTap: _go,
                    ),
                  ),
                  const Divider(height: 1, color: C.line),
                  Expanded(
                    child: PageView(
                      controller: _pc,
                      onPageChanged: _onPageChanged,
                      children: [
                        for (final p in ps) _PositionPage(position: p),
                        _ReviewPage(positions: ps, onChange: _go),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: CenteredBody(
                maxWidth: 1040,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      if (page > 0) ...[
                        SizedBox(
                          width: 56,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => _go(page - 1),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              foregroundColor: C.blue,
                              side: const BorderSide(color: C.blue, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Icon(Icons.arrow_back),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: isLast
                            ? BlueButton(
                                label: 'Submit ballot',
                                icon: Icons.how_to_vote,
                                onPressed: _submit)
                            : BlueButton(
                                label: _chosen(page)
                                    ? 'Next'
                                    : 'Choose a candidate',
                                icon:
                                    _chosen(page) ? Icons.arrow_forward : null,
                                onPressed:
                                    _chosen(page) ? () => _go(page + 1) : null,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PositionPage extends StatelessWidget {
  final Position position;
  const _PositionPage({required this.position});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose your ${position.title}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                const Text('Tap a card, then swipe left or press Next.',
                    style: TextStyle(color: C.muted)),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 230,
              mainAxisExtent: 300,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            delegate: SliverChildListDelegate([
              for (final c in state.candidatesFor(position.id))
                CandidateCard(
                  candidate: c,
                  selectable: true,
                  selected: state.selections[position.id] == c.id,
                  onTap: () => state.select(position.id, c.id),
                  onInfo: () => showCandidateSheet(context, c),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ReviewPage extends StatelessWidget {
  final List<Position> positions;
  final ValueChanged<int> onChange;
  const _ReviewPage({required this.positions, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        const Text('Review your ballot',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        const Text('You cannot change your vote after submitting.',
            style: TextStyle(color: C.muted)),
        const SizedBox(height: 16),
        for (int i = 0; i < positions.length; i++)
          Builder(builder: (context) {
            final p = positions[i];
            final id = state.selections[p.id];
            final c = id == null
                ? null
                : state.candidates.firstWhere((x) => x.id == id);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: cardBox(),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: c?.color ?? C.line,
                    child: Text(c?.initials ?? '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title,
                            style:
                                const TextStyle(color: C.muted, fontSize: 12)),
                        Text(c?.name ?? 'No choice yet',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        if (c != null)
                          Text(c.partyList,
                              style: const TextStyle(
                                  color: C.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  TextButton(
                      onPressed: () => onChange(i),
                      child: const Text('Change')),
                ],
              ),
            );
          }),
      ],
    );
  }
}
