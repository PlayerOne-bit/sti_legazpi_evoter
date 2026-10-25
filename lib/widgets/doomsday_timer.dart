import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/api.dart';

/// Live countdown to [end]. Used by students ("Voting closes in") and
/// by admins ("Next voting season starts in").
class DoomsdayTimer extends StatefulWidget {
  final DateTime end;
  final String label;
  final String finishedLabel;
  final String? subtitle;
  final VoidCallback? onFinished;

  const DoomsdayTimer({
    super.key,
    required this.end,
    this.label = 'Voting closes in',
    this.finishedLabel = 'Voting is closed',
    this.subtitle,
    this.onFinished,
  });

  @override
  State<DoomsdayTimer> createState() => _DoomsdayTimerState();
}

class _DoomsdayTimerState extends State<DoomsdayTimer> {
  late Timer _t;
  Duration left = Duration.zero;
  bool _fired = false;

  void _tick() {
    left = widget.end.difference(Api.now);
    if (left <= Duration.zero && !_fired) {
      _fired = true;
      final cb = widget.onFinished;
      if (cb != null) WidgetsBinding.instance.addPostFrameCallback((_) => cb());
    }
  }

  @override
  void initState() {
    super.initState();
    _tick();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(_tick));
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = left <= Duration.zero;
    final d = done ? Duration.zero : left;
    String two(int n) => n.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration:
          BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: done ? C.muted : C.yellow,
                      shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(done ? widget.finishedLabel : widget.label,
                    style: const TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Unit(two(d.inDays), 'days'),
              _Unit(two(d.inHours % 24), 'hours'),
              _Unit(two(d.inMinutes % 60), 'minutes'),
              _Unit(two(d.inSeconds % 60), 'seconds', hot: true),
            ],
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 14),
            Text(widget.subtitle!,
                style: const TextStyle(color: Colors.white70)),
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
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              color: hot ? C.yellow : Colors.white,
              fontSize: MediaQuery.sizeOf(context).width >= 700 ? 64 : 44,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }
}
