import 'package:flutter/material.dart';
import '../../data/api.dart';
import '../../data/excel_io.dart';
import '../../data/mock.dart';
import '../../widgets/centered_body.dart';
import '../../theme.dart';

/// Details of one finished season (opened from History).
class SeasonScreen extends StatelessWidget {
  final Season season;
  const SeasonScreen({super.key, required this.season});

  Widget _stat(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: cardBox(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(color: C.muted, fontSize: 13)),
            ],
          ),
        ),
      );

  Future<void> _export(BuildContext context) async {
    final msg = await ExcelIo.saveHistory(season.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Deletes this finished season for good, so its club and school year can be used again.
  Future<void> _delete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${season.club} ${season.schoolYear}?'),
        content: const Text(
            'This permanently deletes the results, the votes, the candidates and the positions '
            'of this season. The club and school year can be used again, and students who voted '
            'in it can be deleted again. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete season'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.delete('/api/admin/history/${season.id}');
      await state.refreshAdmin();
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Season deleted.')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Creates a new upcoming season with the same club, grade levels, positions and candidates.
  Future<void> _runAgain(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final first =
        int.tryParse(season.schoolYear.split('-').first) ?? DateTime.now().year;
    final nextYear = '${first + 1}-${first + 2}';
    final years = {...state.schoolYears, nextYear}.toList()..sort();
    String year = nextYear;
    final now = DateTime.now();
    DateTime start =
        DateTime(now.year, now.month, now.day, 8).add(const Duration(days: 7));
    DateTime end = start.add(const Duration(days: 2, hours: 9));
    String? error;
    bool saving = false;
    bool created = false;

    Future<DateTime?> pick(BuildContext ctx, DateTime init) async {
      final d = await showDatePicker(
        context: ctx,
        initialDate: init,
        firstDate: DateTime(2024),
        lastDate: DateTime(2035),
      );
      if (d == null || !ctx.mounted) return null;
      final t = await showTimePicker(
          context: ctx, initialTime: TimeOfDay.fromDateTime(init));
      if (t == null) return null;
      return DateTime(d.year, d.month, d.day, t.hour, t.minute);
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Run ${season.club} again'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Creates a new upcoming season with the same grade levels, positions and '
                      'candidates. Votes and results are not copied. You can edit it afterwards in Seasons.',
                      style: TextStyle(color: C.muted, fontSize: 13)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: year,
                    decoration: const InputDecoration(labelText: 'School year'),
                    items: [
                      for (final y in years)
                        DropdownMenuItem(value: y, child: Text(y))
                    ],
                    onChanged: (v) => setS(() => year = v!),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.play_circle_outline, color: C.blue),
                    title: const Text('Voting opens'),
                    subtitle: Text(fmtDate(start)),
                    onTap: () async {
                      final v = await pick(ctx, start);
                      if (v != null) setS(() => start = v);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.stop_circle_outlined, color: C.blue),
                    title: const Text('Voting closes'),
                    subtitle: Text(fmtDate(end)),
                    onTap: () async {
                      final v = await pick(ctx, end);
                      if (v != null) setS(() => end = v);
                    },
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(error!,
                          style: TextStyle(color: Colors.red.shade700)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!end.isAfter(start)) {
                        setS(() => error =
                            'The closing time must be after the opening time.');
                        return;
                      }
                      // Seasons cannot run at the same time.
                      for (final e in state.elections) {
                        if (start.isBefore(e.endDate) &&
                            end.isAfter(e.startDate)) {
                          setS(() => error =
                              'These dates overlap with ${e.club}, ${e.schoolYear} '
                                  '(${fmtDate(e.startDate)} to ${fmtDate(e.endDate)}).');
                          return;
                        }
                      }
                      setS(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await Api.post(
                            '/api/admin/history/${season.id}/run-again', {
                          'schoolYear': year,
                          'startDate': start.toUtc().toIso8601String(),
                          'endDate': end.toUtc().toIso8601String(),
                        });
                        created = true;
                        await state.refreshAdmin();
                        if (ctx.mounted) Navigator.pop(ctx);
                      } on ApiException catch (e) {
                        setS(() {
                          saving = false;
                          error = e.message;
                        });
                      }
                    },
              child: Text(saving ? 'Creating...' : 'Create season'),
            ),
          ],
        ),
      ),
    );

    if (!created) return;
    nav.pop();
    messenger.showSnackBar(const SnackBar(
        content:
            Text('New season created. Find it under Upcoming in Seasons.')));
  }

  @override
  Widget build(BuildContext context) {
    final pct = (season.turnout * 100).round();
    return Scaffold(
      appBar: AppBar(
        title: Text(season.club),
        actions: [
          IconButton(
            tooltip: 'Export results to Excel',
            icon: const Icon(Icons.download),
            onPressed: () => _export(context),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (v) =>
                v == 'again' ? _runAgain(context) : _delete(context),
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'again',
                  child: ListTile(
                      dense: true,
                      leading: Icon(Icons.replay),
                      title: Text('Run again'))),
              PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      dense: true,
                      leading: Icon(Icons.delete_outline),
                      title: Text('Delete season'))),
            ],
          ),
        ],
      ),
      body: CenteredBody(
        maxWidth: 800,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text('School year ${season.schoolYear}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${fmtDate(season.startDate)} to ${fmtDate(season.endDate)}',
                style: const TextStyle(color: C.muted)),
            const SizedBox(height: 2),
            Text('Open to ${season.audience}',
                style: const TextStyle(color: C.muted)),
            const SizedBox(height: 16),
            Row(
              children: [
                _stat('Students', '${season.totalVoters}'),
                const SizedBox(width: 10),
                _stat('Voted', '${season.votedCount}'),
                const SizedBox(width: 10),
                _stat('Turnout', '$pct%'),
              ],
            ),
            const SizedBox(height: 22),
            const Text('Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final w in season.winners)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: cardBox(),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFFB88700)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.position,
                              style: const TextStyle(
                                  color: C.muted, fontSize: 12)),
                          Text(w.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          Text(w.partyList,
                              style: const TextStyle(
                                  color: C.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text('${w.votes} votes',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
