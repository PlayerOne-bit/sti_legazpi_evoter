import 'package:flutter/material.dart';

import '../../data/api.dart';
import '../../data/mock.dart';
import '../../theme.dart';

class SeasonRange {
  final DateTime start;
  final DateTime end;
  const SeasonRange(this.start, this.end);
}

/// Picks a season's first and last voting day on one calendar, then the opening and closing time.
/// The chosen days are joined by a blue band with the first and last day circled in blue.
/// Days used by other seasons ([others]) are circled in red and cannot be picked or crossed.
/// With [startLocked] (a season already open) only the closing day and time can change.
Future<SeasonRange?> showSeasonRangePicker(
  BuildContext context, {
  required DateTime start,
  required DateTime end,
  required Iterable<Election> others,
  bool startLocked = false,
}) {
  return showDialog<SeasonRange>(
    context: context,
    builder: (_) => _RangeDialog(
      start: start,
      end: end,
      taken: _takenDays(others),
      startLocked: startLocked,
    ),
  );
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Every calendar day touched by another season, with that season's name.
Map<DateTime, String> _takenDays(Iterable<Election> others) {
  final map = <DateTime, String>{};
  for (final e in others) {
    var d = _day(e.startDate);
    // A season closing exactly at midnight does not use the next day.
    final last = _day(e.endDate.subtract(const Duration(microseconds: 1)));
    while (!d.isAfter(last)) {
      map[d] = '${e.club} ${e.schoolYear}';
      d = DateTime(d.year, d.month, d.day + 1);
    }
  }
  return map;
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

class _RangeDialog extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  final Map<DateTime, String> taken;
  final bool startLocked;

  const _RangeDialog({
    required this.start,
    required this.end,
    required this.taken,
    required this.startLocked,
  });

  @override
  State<_RangeDialog> createState() => _RangeDialogState();
}

class _RangeDialogState extends State<_RangeDialog> {
  late DateTime? _first = _day(widget.start);
  late DateTime? _last = _day(widget.end);
  late TimeOfDay _opens = TimeOfDay.fromDateTime(widget.start);
  late TimeOfDay _closes = TimeOfDay.fromDateTime(widget.end);
  late DateTime _month = DateTime(widget.start.year, widget.start.month);
  DateTime? _hover;
  String? _error;

  DateTime get _today => _day(Api.now);

  @override
  void initState() {
    super.initState();
    // Seasons saved before this picker may sit on a day another season now uses; start clean then.
    if (!widget.startLocked && _crossesTaken(_first!, _last!) != null) {
      _first = null;
      _last = null;
      _month = DateTime(_today.year, _today.month);
    }
  }

  bool _isPast(DateTime d) => d.isBefore(_today);

  /// The first taken day between [a] and [b] (inclusive), if any.
  DateTime? _crossesTaken(DateTime a, DateTime b) {
    var d = a;
    while (!d.isAfter(b)) {
      if (widget.taken.containsKey(d)) return d;
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return null;
  }

  void _tap(DateTime d) {
    setState(() {
      _error = null;
      if (widget.startLocked) {
        final clash = _crossesTaken(_first!, d);
        if (d.isBefore(_first!)) {
          _error = 'The closing day cannot be before the opening day.';
        } else if (clash != null) {
          _error = 'The dates would run into ${widget.taken[clash]}.';
        } else {
          _last = d;
        }
        return;
      }
      if (_first == null || _last != null || d.isBefore(_first!)) {
        _first = d;
        _last = null;
        return;
      }
      final clash = _crossesTaken(_first!, d);
      if (clash != null) {
        _error =
            'The dates would run into ${widget.taken[clash]}. Pick days that are not circled in red.';
        return;
      }
      _last = d;
    });
  }

  DateTime? get _startValue => _first == null
      ? null
      : (widget.startLocked
          ? widget.start
          : DateTime(_first!.year, _first!.month, _first!.day, _opens.hour,
              _opens.minute));

  DateTime? get _endValue => _last == null
      ? null
      : DateTime(
          _last!.year, _last!.month, _last!.day, _closes.hour, _closes.minute);

  void _done() {
    final s = _startValue, e = _endValue;
    if (s == null || e == null) return;
    if (!e.isAfter(s)) {
      setState(
          () => _error = 'The closing time must be after the opening time.');
      return;
    }
    if (!e.isAfter(Api.now)) {
      setState(() => _error = 'The closing time has already passed.');
      return;
    }
    Navigator.pop(context, SeasonRange(s, e));
  }

  Future<void> _pickTime(bool opening) async {
    final t = await showTimePicker(
        context: context, initialTime: opening ? _opens : _closes);
    if (t == null) return;
    setState(() {
      _error = null;
      if (opening) {
        _opens = t;
      } else {
        _closes = t;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final first = _first, last = _last;
    String summary;
    if (first == null) {
      summary = 'Tap the first voting day';
    } else if (last == null) {
      summary = 'Now tap the last voting day';
    } else {
      final days = last.difference(first).inDays + 1;
      summary =
          '${fmtDay(first)} to ${fmtDay(last)} · $days day${days == 1 ? '' : 's'}';
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Voting dates',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                  widget.startLocked
                      ? 'Voting already started, so only the closing day can change.'
                      : summary,
                  style: TextStyle(color: C.muted)),
              const SizedBox(height: 12),
              _monthBar(),
              const SizedBox(height: 6),
              _weekdays(),
              const SizedBox(height: 4),
              _grid(),
              const SizedBox(height: 10),
              _legend(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _timeChip(
                      icon: Icons.play_circle_outline,
                      label: 'Opens',
                      time: _opens,
                      onTap: widget.startLocked ? null : () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _timeChip(
                      icon: Icons.stop_circle_outlined,
                      label: 'Closes',
                      time: _closes,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: C.danger)),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: first != null && last != null ? _done : null,
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _monthBar() => Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1)),
          ),
          Expanded(
            child: Text('${_monthNames[_month.month - 1]} ${_month.year}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          IconButton(
            tooltip: 'Next month',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1)),
          ),
        ],
      );

  Widget _weekdays() => Row(
        children: [
          for (final w in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
            Expanded(
              child: Text(w,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: C.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      );

  Widget _grid() {
    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final lead = firstOfMonth.weekday % 7; // Sunday first
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = lead + daysInMonth;
    final rows = (cells / 7).ceil();

    // While picking the last day, show where the range would go under the mouse.
    final a = _first;
    var b = _last;
    if (a != null && b == null && _hover != null && !_hover!.isBefore(a)) {
      b = _hover;
    }

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                    child: _cell(r * 7 + c - lead + 1, daysInMonth, c, a, b)),
            ],
          ),
      ],
    );
  }

  Widget _cell(
      int dayNum, int daysInMonth, int column, DateTime? a, DateTime? b) {
    if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox(height: 44);
    final d = DateTime(_month.year, _month.month, dayNum);
    final takenBy = widget.taken[d];
    final past = _isPast(d);
    final lockedStart = widget.startLocked && d.isBefore(_first!);
    final disabled = takenBy != null || past || lockedStart;

    final inRange = a != null && b != null && !d.isBefore(a) && !d.isAfter(b);
    final isEdge = d == a || d == b;
    final preview = _last == null && inRange && !isEdge;
    final today = d == _today;

    // The band: joined across the range, rounded at the ends and at the week edges.
    Widget? band;
    if (inRange && a != b) {
      final roundLeft = d == a || column == 0 || dayNum == 1;
      final roundRight = d == b || column == 6 || dayNum == daysInMonth;
      band = Positioned.fill(
        top: 4,
        bottom: 4,
        child: Container(
          decoration: BoxDecoration(
            color: C.blue.withValues(alpha: preview ? 0.08 : 0.16),
            border: Border(
              top: BorderSide(color: C.blue.withValues(alpha: 0.55)),
              bottom: BorderSide(color: C.blue.withValues(alpha: 0.55)),
              left: roundLeft
                  ? BorderSide(color: C.blue.withValues(alpha: 0.55))
                  : BorderSide.none,
              right: roundRight
                  ? BorderSide(color: C.blue.withValues(alpha: 0.55))
                  : BorderSide.none,
            ),
            borderRadius: BorderRadius.horizontal(
              left: roundLeft ? const Radius.circular(18) : Radius.zero,
              right: roundRight ? const Radius.circular(18) : Radius.zero,
            ),
          ),
        ),
      );
    }

    Color textColor = C.ink;
    BoxDecoration? circle;
    if (takenBy != null) {
      textColor = C.danger;
      circle = BoxDecoration(
        shape: BoxShape.circle,
        color: C.danger.withValues(alpha: 0.10),
        border: Border.all(color: C.danger, width: 1.6),
      );
    } else if (isEdge && a != null) {
      textColor = Colors.white;
      circle = BoxDecoration(shape: BoxShape.circle, color: C.blue);
    } else if (today) {
      circle = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: C.muted, width: 1),
      );
    }
    if (past || lockedStart) textColor = C.muted.withValues(alpha: 0.5);

    final content = SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (band != null) band,
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: circle,
            child: Text(
              '$dayNum',
              style: TextStyle(
                color: textColor,
                fontWeight: isEdge || takenBy != null
                    ? FontWeight.w800
                    : FontWeight.w500,
                decoration: takenBy != null ? TextDecoration.lineThrough : null,
                decorationColor: C.danger,
              ),
            ),
          ),
        ],
      ),
    );

    final cell = MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) {
        if (_first != null && _last == null) setState(() => _hover = d);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : () => _tap(d),
        child: content,
      ),
    );

    return takenBy == null
        ? cell
        : Tooltip(message: 'Taken by $takenBy', child: cell);
  }

  Widget _legend() => Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          _legendItem(
            BoxDecoration(shape: BoxShape.circle, color: C.blue),
            'Voting days',
          ),
          _legendItem(
            BoxDecoration(
              shape: BoxShape.circle,
              color: C.danger.withValues(alpha: 0.10),
              border: Border.all(color: C.danger, width: 1.6),
            ),
            'Taken by another season',
          ),
        ],
      );

  Widget _legendItem(BoxDecoration deco, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 14, height: 14, decoration: deco),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: C.muted, fontSize: 12)),
        ],
      );

  Widget _timeChip({
    required IconData icon,
    required String label,
    required TimeOfDay time,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: C.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: onTap == null ? C.muted : C.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: C.muted, fontSize: 12)),
                    Text(time.format(context),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a season's voting window in a form; tapping it opens [showSeasonRangePicker].
class SeasonDatesTile extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final VoidCallback onTap;

  const SeasonDatesTile(
      {super.key, required this.start, required this.end, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final days = _day(end).difference(_day(start)).inDays + 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: C.tint,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Icon(Icons.date_range, color: C.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Voting dates · $days day${days == 1 ? '' : 's'}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Opens ${fmtDate(start)}',
                          style: TextStyle(color: C.muted, fontSize: 12.5)),
                      Text('Closes ${fmtDate(end)}',
                          style: TextStyle(color: C.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.edit_calendar_outlined, color: C.blue, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
