import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api.dart';
import '../theme.dart';

class PublicSeason {
  final int id;
  final String club;
  final String schoolYear;
  final DateTime start;
  final DateTime end;
  final String levels;

  PublicSeason.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        club = j['club'] as String,
        schoolYear = j['schoolYear'] as String,
        start = parseUtc(j['startDate'] as String),
        end = parseUtc(j['endDate'] as String),
        levels = (j['levels'] ?? '') as String;
}

/// Ongoing and upcoming seasons on the sign-in screen. Works without signing in.
/// [onBlue] is true on the blue brand panel (wide screens), false on the plain page (phones).
class SeasonPreview extends StatefulWidget {
  final bool onBlue;
  const SeasonPreview({super.key, required this.onBlue});

  @override
  State<SeasonPreview> createState() => _SeasonPreviewState();
}

class _SeasonPreviewState extends State<SeasonPreview> {
  List<PublicSeason> _ongoing = [];
  List<PublicSeason> _upcoming = [];
  bool _loaded = false;
  bool _failed = false;
  Timer? _tick;
  Timer? _reload;

  @override
  void initState() {
    super.initState();
    _load();
    // Countdowns move every 30 seconds; the list itself is fetched again every 2 minutes.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final now = Api.now;
      final changed = _ongoing.any((s) => !now.isBefore(s.end)) ||
          _upcoming.any((s) => !now.isBefore(s.start));
      if (changed) {
        _load();
      } else {
        setState(() {});
      }
    });
    _reload = Timer.periodic(const Duration(minutes: 2), (_) => _load());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _reload?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final j = await Api.get('/api/seasons/public');
      Api.syncFrom(j['serverTime'] as String);
      if (!mounted) return;
      setState(() {
        _ongoing = [
          for (final s in j['ongoing'] as List)
            PublicSeason.fromJson(s as Map<String, dynamic>)
        ];
        _upcoming = [
          for (final s in j['upcoming'] as List)
            PublicSeason.fromJson(s as Map<String, dynamic>)
        ];
        _loaded = true;
        _failed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Color get _text => widget.onBlue ? Colors.white : C.ink;
  Color get _soft => widget.onBlue ? Colors.white70 : C.muted;

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      if (_failed) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: _soft),
            ),
            const SizedBox(width: 10),
            Text('Checking voting seasons...',
                style: TextStyle(color: _soft, fontSize: 13)),
          ],
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_ongoing.isEmpty && _upcoming.isEmpty)
            _emptyCard()
          else ...[
            if (_ongoing.isNotEmpty) ...[
              _heading('Voting now', live: true),
              for (final s in _ongoing) _card(s, ongoing: true),
            ],
            if (_upcoming.isNotEmpty) ...[
              if (_ongoing.isNotEmpty) const SizedBox(height: 10),
              _heading('Coming up'),
              for (final s in _upcoming) _card(s, ongoing: false),
            ],
          ],
        ],
      ),
    );
  }

  Widget _heading(String text, {bool live = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            if (live) ...[
              const _LiveDot(),
              const SizedBox(width: 8),
            ] else ...[
              Icon(Icons.event_outlined, size: 16, color: _soft),
              const SizedBox(width: 6),
            ],
            Text(text.toUpperCase(),
                style: TextStyle(
                    color: _soft,
                    fontSize: 12,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      );

  BoxDecoration _box({bool highlight = false}) => widget.onBlue
      ? BoxDecoration(
          color: Colors.white.withValues(alpha: highlight ? 0.16 : 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: highlight
                  ? C.yellow.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.18)),
        )
      : cardBox(border: highlight ? C.blue : null);

  Widget _emptyCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: _box(),
        child: Row(
          children: [
            Icon(Icons.event_busy_outlined, color: _soft),
            const SizedBox(width: 12),
            Expanded(
              child: Text('No voting seasons are scheduled right now.',
                  style: TextStyle(color: _soft)),
            ),
          ],
        ),
      );

  Widget _card(PublicSeason s, {required bool ongoing}) {
    final now = Api.now;
    final accent = widget.onBlue ? C.yellow : C.blue;
    final when = ongoing
        ? 'Closes in ${_span(s.end.difference(now))}'
        : 'Opens in ${_span(s.start.difference(now))}';
    final date = ongoing ? 'Until ${fmtDate(s.end)}' : fmtDate(s.start);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: _box(highlight: ongoing),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ongoing
                    ? accent
                    : (widget.onBlue
                        ? Colors.white.withValues(alpha: 0.14)
                        : C.tint),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                ongoing ? Icons.how_to_vote : Icons.schedule,
                size: 22,
                color: ongoing
                    ? (widget.onBlue ? C.onYellow : Colors.white)
                    : (widget.onBlue ? Colors.white : C.blue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.club,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: _text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                      '${s.schoolYear}${s.levels.isEmpty ? '' : ' · ${s.levels}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _soft, fontSize: 12.5)),
                  const SizedBox(height: 2),
                  Text(date, style: TextStyle(color: _soft, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ongoing
                    ? accent.withValues(alpha: widget.onBlue ? 1 : 0.12)
                    : (widget.onBlue
                        ? Colors.white.withValues(alpha: 0.12)
                        : C.surface2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(when,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ongoing
                          ? (widget.onBlue ? C.onYellow : C.blue)
                          : _text)),
            ),
          ],
        ),
      ),
    );
  }

  static String _span(Duration d) {
    if (d.isNegative) return '0m';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    if (days > 0) return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins < 1 ? 1 : mins}m';
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF34D27B);
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 6 + 8 * _c.value,
              height: 6 + 8 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: green.withValues(alpha: 0.45 * (1 - _c.value)),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration:
                  const BoxDecoration(shape: BoxShape.circle, color: green),
            ),
          ],
        ),
      ),
    );
  }
}
