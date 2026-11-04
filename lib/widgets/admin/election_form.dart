import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/api.dart';
import '../../data/mock.dart';
import '../../theme.dart';

/// Used when the season does not exist yet. The server creates these positions for a new season.
const _defaultPositions = ['President', 'Vice President', 'Secretary'];

/// A candidate chosen in the form but not saved yet.
class _Pick {
  final Student student;
  final String position; // position title
  final String partyList;
  final String motto;
  const _Pick(this.student, this.position, this.partyList, this.motto);
}

/// The id of the season that saveElection just created or updated.
int? _savedId(String club, String year) {
  final id = state.savedElectionId;
  if (id != null) return id;
  for (final e in state.elections) {
    if (e.club.toLowerCase() == club.trim().toLowerCase() &&
        e.schoolYear == year) {
      return e.id;
    }
  }
  return null;
}

/// Applies the removals and additions after the season itself is saved.
/// Returns a list of problems (empty when everything worked).
Future<List<String>> _applyCandidates(
    int? electionId, List<_Pick> picks, Set<int> removed) async {
  if (electionId == null) return ['Could not find the saved season.'];
  final problems = <String>[];

  // Reload so position ids are fresh (a new season only has them after it is created).
  await state.loadAdminCandidates(electionId);
  final idByTitle = {
    for (final p in state.adminPositions) p.title.toLowerCase(): p.id
  };

  for (final id in removed) {
    final err = await state.removeCandidate(id, electionId);
    if (err != null) problems.add(err);
  }
  for (final p in picks) {
    final positionId = idByTitle[p.position.toLowerCase()];
    if (positionId == null) {
      problems.add('${p.student.fullName}: no position called ${p.position}.');
      continue;
    }
    final err = await state.addCandidateFor(
      electionId: electionId,
      studentId: p.student.id,
      positionId: positionId,
      partyList: p.partyList,
      motto: p.motto,
    );
    if (err != null) problems.add('${p.student.fullName}: $err');
  }

  await state.loadAdminCandidates(electionId);
  return problems;
}

/// Create a voting season, or edit one when [existing] is given.
/// Seasons that already started keep their club, school year, opening time,
/// who-can-vote list, and candidates locked. Only the closing time can change.
///
/// Candidates are searched by name or student number, picked, and given a
/// position, party list, and motto. They are saved together with the season.
Future<void> showElectionForm(BuildContext context,
    {Election? existing}) async {
  final locked = existing != null && existing.status != ElectionStatus.upcoming;

  // Editing an upcoming season: load its positions and current candidates first.
  List<Position> positions = [];
  List<Candidate> current = [];
  if (existing != null && !locked) {
    await state.loadAdminCandidates(existing.id);
    positions = List.of(state.adminPositions);
    current = List.of(state.adminCandidates);
    if (!context.mounted) return;
  }
  final positionTitles = positions.isNotEmpty
      ? [for (final p in positions) p.title]
      : _defaultPositions;

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

  // candidate search and picking
  final searchCtl = TextEditingController();
  final partyCtl = TextEditingController();
  final mottoCtl = TextEditingController();
  Timer? debounce;
  int searchToken = 0;
  bool searching = false;
  String? searchError;
  List<Student> results = [];
  Student? selected;
  String position = positionTitles.first;
  final picks = <_Pick>[];
  final removed = <int>{};
  String? notice; // shown after the dialog closes

  String titleOf(int positionId) {
    for (final p in positions) {
      if (p.id == positionId) return p.title;
    }
    return '';
  }

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
      builder: (ctx, setS) {
        // Search while typing, 300 ms after the last key. Old answers are ignored.
        void onSearchChanged(String text) {
          debounce?.cancel();
          final term = text.trim();
          if (term.isEmpty) {
            searchToken++;
            setS(() {
              results = [];
              searching = false;
              searchError = null;
            });
            return;
          }
          setS(() {
            searching = true;
            searchError = null;
          });
          debounce = Timer(const Duration(milliseconds: 300), () async {
            final token = ++searchToken;
            try {
              final found = await state.searchStudents(term);
              if (!ctx.mounted || token != searchToken) return;
              setS(() {
                results = found;
                searching = false;
              });
            } on ApiException catch (e) {
              if (!ctx.mounted || token != searchToken) return;
              setS(() {
                results = [];
                searching = false;
                searchError = e.message;
              });
            }
          });
        }

        void addPick() {
          final s = selected;
          if (s == null) return;
          setS(() {
            picks.add(
                _Pick(s, position, partyCtl.text.trim(), mottoCtl.text.trim()));
            selected = null;
            results = [];
            searchCtl.clear();
            partyCtl.clear();
            mottoCtl.clear();
          });
        }

        // Students who are already candidates here cannot be picked again.
        final taken = <String>{
          for (final c in current)
            if (!removed.contains(c.id)) c.studentNum,
          for (final p in picks) p.student.studentNum,
        };
        final shown =
            results.where((s) => !taken.contains(s.studentNum)).toList();
        final keptCurrent =
            current.where((c) => !removed.contains(c.id)).toList();

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
                    leading:
                        const Icon(Icons.play_circle_outline, color: C.blue),
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

                  // ---------------- candidates ----------------
                  const Divider(height: 32),
                  const Text('Candidates',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  if (locked)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Candidates are locked once voting starts.',
                          style: TextStyle(color: C.muted)),
                    )
                  else ...[
                    const SizedBox(height: 2),
                    const Text(
                        'Search a student, choose a position, then add. Everything is saved with the season.',
                        style: TextStyle(color: C.muted, fontSize: 12)),
                    const SizedBox(height: 8),
                    for (final c in keptCurrent)
                      _CandidateTile(
                        initials: c.initials,
                        color: c.color,
                        name: c.name,
                        subtitle: _subtitle(titleOf(c.positionId), c.partyList),
                        isNew: false,
                        onRemove:
                            saving ? null : () => setS(() => removed.add(c.id)),
                      ),
                    for (final p in picks)
                      _CandidateTile(
                        initials: p.student.initials,
                        color: colorFor(p.student.id),
                        name: p.student.fullName,
                        subtitle: _subtitle(p.position, p.partyList),
                        isNew: true,
                        onRemove:
                            saving ? null : () => setS(() => picks.remove(p)),
                      ),
                    if (keptCurrent.isEmpty && picks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('No candidates yet.',
                            style: TextStyle(color: C.muted)),
                      ),
                    const SizedBox(height: 4),
                    if (selected == null) ...[
                      TextField(
                        controller: searchCtl,
                        enabled: !saving,
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search students by name or number',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (searchError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(searchError!,
                              style: TextStyle(color: Colors.red.shade700)),
                        )
                      else if (!searching &&
                          searchCtl.text.trim().isNotEmpty &&
                          shown.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('No students found.',
                              style: TextStyle(color: C.muted)),
                        ),
                      for (final s in shown)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFE3ECF8),
                            child: Text(s.initials,
                                style: const TextStyle(
                                    color: C.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800)),
                          ),
                          title: Text(s.fullName,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${s.studentNum}, ${state.gradeName(s.gradeLevelId)}'
                            '${s.programCode == null ? '' : ', ${s.programCode}'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.add_circle_outline,
                              color: C.blue),
                          onTap: () => setS(() => selected = s),
                        ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: cardBox(color: const Color(0xFFF7F9FD)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: colorFor(selected!.id),
                                  child: Text(selected!.initials,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(selected!.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      Text(selected!.studentNum,
                                          style: const TextStyle(
                                              color: C.muted, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Choose a different student',
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setS(() => selected = null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: position,
                              decoration:
                                  const InputDecoration(labelText: 'Position'),
                              items: [
                                for (final t in positionTitles)
                                  DropdownMenuItem(value: t, child: Text(t))
                              ],
                              onChanged: (v) => setS(() => position = v!),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: partyCtl,
                              decoration: const InputDecoration(
                                  labelText: 'Party list'),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: mottoCtl,
                              decoration:
                                  const InputDecoration(labelText: 'Motto'),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: addPick,
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('Add to candidates'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
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

                      // The season is saved. Now apply the candidate changes.
                      if (!locked && (picks.isNotEmpty || removed.isNotEmpty)) {
                        final problems = await _applyCandidates(
                          existing?.id ?? _savedId(clubCtl.text, year),
                          picks,
                          removed,
                        );
                        if (problems.isNotEmpty) {
                          notice = 'Season saved, but some candidate changes '
                              'failed: ${problems.join(' ')}';
                        }
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

  debounce?.cancel();
  final message = notice;
  if (message != null && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

String _subtitle(String position, String party) {
  if (position.isEmpty) return party;
  return party.isEmpty ? position : '$position, $party';
}

/// One candidate row in the form. [isNew] marks candidates that are not saved yet.
class _CandidateTile extends StatelessWidget {
  final String initials;
  final Color color;
  final String name;
  final String subtitle;
  final bool isNew;
  final VoidCallback? onRemove;
  const _CandidateTile({
    required this.initials,
    required this.color,
    required this.name,
    required this.subtitle,
    required this.isNew,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: cardBox(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color,
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: C.muted, fontSize: 12)),
              ],
            ),
          ),
          if (isNew)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFE3ECF8),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('New',
                  style: TextStyle(
                      color: C.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          IconButton(
            tooltip: 'Remove candidate',
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
