import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';

/// Create a voting season, or edit one when [existing] is given.
/// Seasons that already started keep their club, school year, opening time,
/// and who-can-vote list locked.
Future<void> showElectionForm(BuildContext context,
    {Election? existing}) async {
  final locked = existing != null && existing.status != ElectionStatus.upcoming;
  final clubCtl = TextEditingController(text: existing?.club ?? '');
  String year = existing?.schoolYear ?? state.schoolYears[1];
  final now = DateTime.now();
  DateTime start = existing?.startDate ??
      DateTime(now.year, now.month, now.day, 8).add(const Duration(days: 7));
  DateTime end =
      existing?.endDate ?? start.add(const Duration(days: 2, hours: 9));
  Set<int> levels = {
    ...(existing?.levelIds ?? state.gradeLevels.map((g) => g.id))
  };
  String? error;

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
        title: Text(
            existing == null ? 'Create voting season' : 'Edit voting season'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: year,
                  decoration: const InputDecoration(labelText: 'School year'),
                  items: [
                    for (final y in state.schoolYears)
                      DropdownMenuItem(value: y, child: Text(y))
                  ],
                  onChanged: locked ? null : (v) => setS(() => year = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: clubCtl,
                  enabled: !locked,
                  decoration: const InputDecoration(labelText: 'Club'),
                ),
                if (!locked) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in state.clubs)
                        ActionChip(
                            label: Text(c),
                            onPressed: () => setS(() => clubCtl.text = c)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: !locked,
                  leading: const Icon(Icons.play_circle_outline, color: C.blue),
                  title: const Text('Voting opens'),
                  subtitle: Text(fmtDate(start)),
                  onTap: locked
                      ? null
                      : () async {
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Who can vote',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    if (!locked) ...[
                      TextButton(
                        onPressed: () => setS(() =>
                            levels = {...state.gradeLevels.map((g) => g.id)}),
                        child: const Text('All'),
                      ),
                      TextButton(
                        onPressed: () => setS(() => levels = <int>{}),
                        child: const Text('Clear'),
                      ),
                    ],
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final g in state.gradeLevels)
                      FilterChip(
                        label: Text(g.name),
                        selected: levels.contains(g.id),
                        onSelected: locked
                            ? null
                            : (v) => setS(() {
                                  if (v) {
                                    levels.add(g.id);
                                  } else {
                                    levels.remove(g.id);
                                  }
                                }),
                      ),
                  ],
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
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final err = await state.saveElection(
                id: existing?.id,
                schoolYear: year,
                club: clubCtl.text,
                start: start,
                end: end,
                levels: levels,
              );
              if (err != null) {
                setS(() => error = err);
                return;
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(existing == null ? 'Create season' : 'Save changes'),
          ),
        ],
      ),
    ),
  );
}
