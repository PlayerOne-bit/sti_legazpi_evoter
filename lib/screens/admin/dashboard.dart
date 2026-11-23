import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/anim.dart';
import '../../data/api.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../../widgets/blue_button.dart';
import 'winner_screen.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _close(BuildContext context, Election e) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => WinnerScreen(election: e)));

  List<Election> _seasons() {
    int rank(Election e) => switch (e.status) {
          ElectionStatus.open => 0,
          ElectionStatus.ended => 1,
          ElectionStatus.upcoming => 2,
        };
    DateTime when(Election e) =>
        e.status == ElectionStatus.upcoming ? e.startDate : e.endDate;
    final list = [...state.elections];
    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : when(a).compareTo(when(b));
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final cur = state.currentElection;
        final total = state.dashEligible;
        final voted = state.dashVoted;
        final pct = total == 0 ? 0 : (voted * 100 / total).round();
        final seasons = _seasons();
        return StaggerListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Text('Welcome ${Api.displayName ?? 'admin'}!',
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('Here is how the voting seasons are doing.',
                style: TextStyle(color: C.muted)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                    child:
                        _Stat(cur == null ? 'Students' : 'Eligible', '$total')),
                const SizedBox(width: 10),
                Expanded(child: _Stat('Voted', '$voted')),
                const SizedBox(width: 10),
                Expanded(child: _Stat('Turnout', '$pct%', accent: true)),
              ],
            ),
            const SizedBox(height: 22),
            const Text('Voting seasons',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (seasons.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: cardBox(),
                child: Row(
                  children: [
                    Icon(Icons.event_busy, color: C.muted),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          'No open or upcoming voting season. Create one in the Seasons tab.',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              )
            else
              for (final e in seasons)
                _SeasonTimerCard(
                  key: ValueKey(
                      '${e.id}-${e.status.name}-${e.startDate.millisecondsSinceEpoch}-${e.endDate.millisecondsSinceEpoch}'),
                  election: e,
                  onFinished: state.touch,
                  onClose: () => _close(context, e),
                ),
          ],
        );
      },
    );
  }
}

class _SeasonTimerCard extends StatefulWidget {
  final Election election;
  final VoidCallback onFinished;
  final VoidCallback onClose;
  const _SeasonTimerCard({
    super.key,
    required this.election,
    required this.onFinished,
    required this.onClose,
  });

  @override
  State<_SeasonTimerCard> createState() => _SeasonTimerCardState();
}

class _SeasonTimerCardState extends State<_SeasonTimerCard> {
  late final ElectionStatus _status = widget.election.status;
  Timer? _timer;
  Duration _left = Duration.zero;
  bool _fired = false;

  DateTime? get _target => switch (_status) {
        ElectionStatus.upcoming => widget.election.startDate,
        ElectionStatus.open => widget.election.endDate,
        ElectionStatus.ended => null,
      };

  void _tick() {
    final target = _target;
    if (target == null) return;
    _left = target.difference(Api.now);
    if (_left <= Duration.zero && !_fired) {
      _fired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (_target != null) {
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(_tick);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _chip() {
    final (String label, Color bg, Color fg) = switch (_status) {
      ElectionStatus.upcoming => ('Upcoming', C.tint, C.blue),
      ElectionStatus.open => ('Open now', C.okBg, C.ok),
      ElectionStatus.ended => ('Tally pending', C.warnBg, C.warnFg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style:
              TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _countdown() {
    final left = _left <= Duration.zero ? Duration.zero : _left;
    String two(int n) => n.toString().padLeft(2, '0');
    final label =
        _status == ElectionStatus.upcoming ? 'Starts in' : 'Closes in';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [C.blue, C.blueDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: C.shadow, blurRadius: 14, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: C.yellow, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Unit(two(left.inDays), 'days'),
              _Unit(two(left.inHours % 24), 'hours'),
              _Unit(two(left.inMinutes % 60), 'minutes'),
              _Unit(two(left.inSeconds % 60), 'seconds', hot: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: C.muted),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final e = widget.election;
    return Container(
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
                    Text(e.club,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('School year ${e.schoolYear}',
                        style: TextStyle(color: C.muted)),
                  ],
                ),
              ),
              _chip(),
            ],
          ),
          const SizedBox(height: 12),
          if (_status == ElectionStatus.ended)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: C.warnBg, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.hourglass_bottom, color: C.warnFg),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Voting has ended. Count the votes to see the winners.',
                        style: TextStyle(
                            color: C.warnFg, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )
          else
            _countdown(),
          const SizedBox(height: 6),
          _info(Icons.play_circle_outline, 'Opens ${fmtDate(e.startDate)}'),
          _info(Icons.stop_circle_outlined, 'Closes ${fmtDate(e.endDate)}'),
          _info(Icons.groups_outlined,
              'Open to ${state.levelsLabel(e.levelIds)}'),
          if (_status == ElectionStatus.ended) ...[
            const SizedBox(height: 14),
            BlueButton(
                label: 'Close season and tally votes',
                icon: Icons.emoji_events,
                onPressed: widget.onClose),
          ],
        ],
      ),
    );
  }
}

class _Unit extends StatelessWidget {
  final String value;
  final String label;
  final bool hot;
  const _Unit(this.value, this.label, {this.hot = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                color: hot ? C.yellow : Colors.white,
                fontSize: MediaQuery.sizeOf(context).width >= 700 ? 40 : 30,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
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
      decoration: cardBox(
          color: accent ? C.navy : C.surface, border: accent ? C.navy : C.line),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(builder: (_) {
            final style = TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: accent ? C.yellow : C.ink);
            final pct = value.endsWith('%');
            final n = int.tryParse(
                pct ? value.substring(0, value.length - 1) : value);
            return n == null
                ? Text(value, style: style)
                : CountUp(value: n, suffix: pct ? '%' : '', style: style);
          }),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: accent ? Colors.white70 : C.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
