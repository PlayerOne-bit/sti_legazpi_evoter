import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';

class PositionPollCard extends StatelessWidget {
  final PositionTally p;
  final Map<int, String> photos;
  const PositionPollCard(this.p, this.photos, {super.key});

  @override
  Widget build(BuildContext context) {
    final winnerIds = {for (final w in p.winners) w.candidateId};
    final ranked = List.of(p.entries)
      ..sort((a, b) => b.votes.compareTo(a.votes));
    final top = ranked.isEmpty ? 0 : ranked.first.votes;
    final tie = winnerIds.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.line),
        boxShadow: [
          BoxShadow(
              color: C.shadow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.title,
                    style: TextStyle(
                        color: C.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ),
              if (tie) ...[
                const _Chip('TIE', C.yellow, C.navy),
                const SizedBox(width: 6),
              ],
              _Chip('${p.total} vote${p.total == 1 ? '' : 's'}', C.paper,
                  C.muted),
            ],
          ),
          const SizedBox(height: 12),
          for (final e in ranked)
            _PollBar(
              e: e,
              total: p.total,
              top: top,
              winner: winnerIds.contains(e.candidateId),
              photo: photos[e.candidateId],
            ),
          if (winnerIds.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text('No votes were cast for this position.',
                  style: TextStyle(color: C.muted, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _PollBar extends StatelessWidget {
  final TallyEntry e;
  final int total;
  final int top;
  final bool winner;
  final String? photo;
  const _PollBar({
    required this.e,
    required this.total,
    required this.top,
    required this.winner,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    final fill = top == 0 ? 0.0 : e.votes / top;
    final pct = total == 0 ? 0 : (e.votes * 100 / total).round();
    final fg = winner ? C.navy : C.ink;
    final sub = winner ? C.navy.withValues(alpha: 0.7) : C.muted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: C.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: winner ? const Color(0xFFE0A800) : C.line,
              width: winner ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fill.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: winner
                          ? const LinearGradient(
                              colors: [Color(0xFFFFD84D), C.yellow])
                          : LinearGradient(colors: [
                              C.blue.withValues(alpha: 0.12),
                              C.blue.withValues(alpha: 0.24),
                            ]),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  _Avatar(
                      entry: e,
                      photo: photo,
                      radius: 20,
                      ring: winner ? Colors.white : null),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(e.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: fg,
                                      fontSize: 15,
                                      fontWeight: winner
                                          ? FontWeight.w800
                                          : FontWeight.w600)),
                            ),
                            if (winner) ...[
                              const SizedBox(width: 6),
                              const CustomPaint(
                                size: Size(22, 15),
                                painter: CrownPainter(),
                              ),
                            ],
                          ],
                        ),
                        if (e.partyList.isNotEmpty)
                          Text(e.partyList,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: sub, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${e.votes}',
                          style: TextStyle(
                              color: fg,
                              fontSize: 20,
                              height: 1.1,
                              fontWeight: FontWeight.w800)),
                      Text('$pct%',
                          style: TextStyle(
                              color: sub,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final TallyEntry entry;
  final String? photo;
  final double radius;
  final Color? ring;
  const _Avatar(
      {required this.entry,
      required this.photo,
      required this.radius,
      this.ring});

  @override
  Widget build(BuildContext context) {
    final initials = Center(
      child: Text(entry.initials,
          style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.7,
              fontWeight: FontWeight.w800)),
    );
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: entry.color,
        shape: BoxShape.circle,
        border: ring == null ? null : Border.all(color: ring!, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: photo == null
          ? initials
          : Image.network(photo!,
              key: ValueKey(photo),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => initials),
    );
  }
}

class CrownPainter extends CustomPainter {
  const CrownPainter();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final body = Path()
      ..moveTo(0, h * 0.25)
      ..lineTo(w * 0.27, h * 0.55)
      ..lineTo(w * 0.5, 0)
      ..lineTo(w * 0.73, h * 0.55)
      ..lineTo(w, h * 0.25)
      ..lineTo(w * 0.9, h * 0.82)
      ..lineTo(w * 0.1, h * 0.82)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFE0A800));
    canvas.drawPath(
        body,
        Paint()
          ..color = C.navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeJoin = StrokeJoin.round);
    canvas.drawRRect(
        RRect.fromLTRBR(
            w * 0.1, h * 0.8, w * 0.9, h, const Radius.circular(1.5)),
        Paint()..color = C.navy);
    final jewel = Paint()..color = C.navy;
    for (final p in [
      Offset(0, h * 0.25),
      Offset(w * 0.5, 0),
      Offset(w, h * 0.25),
    ]) {
      canvas.drawCircle(p, w * 0.07, jewel);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Chip(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
