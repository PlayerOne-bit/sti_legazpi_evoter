import 'package:flutter/material.dart';
import '../../data/api.dart';
import 'party_widgets.dart';
import 'season_range_picker.dart';
import '../../data/mock.dart';
import '../../theme.dart';

Future<void> showElectionForm(BuildContext context,
    {Election? existing}) async {
  final locked = existing != null && existing.status != ElectionStatus.upcoming;

  await state.loadPartyLists();
  if (!context.mounted) return;

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
  bool saving = false;

  final newPartyCtl = TextEditingController();
  bool addingParty = false;
  String? partyError;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        Future<void> addPartyList() async {
          final name = newPartyCtl.text.trim();
          if (name.isEmpty) return;
          setS(() {
            addingParty = true;
            partyError = null;
          });
          try {
            await state.ensurePartyList(name);
            newPartyCtl.clear();
          } on ApiException catch (e) {
            partyError = e.message;
          }
          if (ctx.mounted) setS(() => addingParty = false);
        }

        Future<void> deletePartyList(PartyList p) async {
          final ok = await showDialog<bool>(
            context: ctx,
            builder: (c) => AlertDialog(
              title: Text('Delete ${p.name}?'),
              content: const Text(
                  'Removes the tag and its logo. Candidates who already use this '
                  'party list keep the name.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: C.danger),
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (ok != true) return;
          final err = await state.deletePartyList(p.id);
          if (ctx.mounted) setS(() => partyError = err);
        }

        Future<void> editLogo(PartyList p) async {
          await showPartyEditor(ctx, p.id);
          if (ctx.mounted) setS(() {});
        }

        return AlertDialog(
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
                    initialValue: year,
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
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        for (final c in state.clubs)
                          _DeletableChip(
                            label: c.name,
                            onPressed: () => setS(() => clubCtl.text = c.name),
                            onDelete: saving
                                ? null
                                : () async {
                                    final ok = await showDialog<bool>(
                                      context: ctx,
                                      builder: (d) => AlertDialog(
                                        title: Text('Delete ${c.name}?'),
                                        content: const Text(
                                            'Removes this club from the suggestions. '
                                            'Clubs that already have a season cannot be deleted.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(d, false),
                                              child: const Text('Cancel')),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                                backgroundColor: C.danger),
                                            onPressed: () =>
                                                Navigator.pop(d, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok != true) return;
                                    final err = await state.deleteClub(c.id);
                                    if (ctx.mounted) setS(() => error = err);
                                  },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  SeasonDatesTile(
                    start: start,
                    end: end,
                    onTap: () async {
                      final r = await showSeasonRangePicker(
                        ctx,
                        start: start,
                        end: end,
                        others:
                            state.elections.where((e) => e.id != existing?.id),
                        startLocked: locked,
                      );
                      if (r != null) {
                        setS(() {
                          start = r.start;
                          end = r.end;
                          error = null;
                        });
                      }
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
                  const Divider(height: 32),
                  const Text('Party lists',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                      'Tap a tag to upload its logo. Party lists typed for candidates are added here too.',
                      style: TextStyle(color: C.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  if (state.partyLists.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text('No party lists yet.',
                          style: TextStyle(color: C.muted)),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final p in state.partyLists)
                        InputChip(
                          avatar: PartyLogo.of(p, radius: 12),
                          label: Text(p.name),
                          tooltip: 'Upload or change the logo',
                          onPressed: saving ? null : () => editLogo(p),
                          deleteButtonTooltipMessage: 'Delete party list',
                          onDeleted: saving ? null : () => deletePartyList(p),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newPartyCtl,
                          enabled: !saving && !addingParty,
                          onSubmitted: (_) => addPartyList(),
                          decoration: const InputDecoration(
                              hintText: 'New party list name', isDense: true),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add party list',
                        icon: addingParty
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.add_circle_outline, color: C.blue),
                        onPressed: saving || addingParty ? null : addPartyList,
                      ),
                    ],
                  ),
                  if (partyError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child:
                          Text(partyError!, style: TextStyle(color: C.danger)),
                    ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: C.tint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.how_to_reg_outlined,
                            size: 18, color: C.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Add candidates and set positions from Candidates on the season card after saving.',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(error!, style: TextStyle(color: C.danger)),
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
                      setS(() {
                        saving = true;
                        error = null;
                      });
                      final err = await state.saveElection(
                        id: existing?.id,
                        schoolYear: year,
                        club: clubCtl.text,
                        start: start,
                        end: end,
                        levels: levels,
                      );
                      if (err != null) {
                        setS(() {
                          saving = false;
                          error = err;
                        });
                        return;
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: Text(saving
                  ? 'Saving...'
                  : (existing == null ? 'Create season' : 'Save changes')),
            ),
          ],
        );
      },
    ),
  );

  newPartyCtl.dispose();
}

class _DeletableChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onDelete;
  const _DeletableChip(
      {required this.label, required this.onPressed, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ActionChip(label: Text(label), onPressed: onPressed),
        Positioned(
          top: -6,
          right: -6,
          child: Tooltip(
            message: 'Delete $label',
            child: Material(
              color: onDelete == null ? C.muted : C.danger,
              shape: const CircleBorder(),
              elevation: 1,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
