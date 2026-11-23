import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/api.dart';
import '../../data/candidate_images.dart';
import '../../data/mock.dart';
import '../../theme.dart';

const _defaultPositions = ['President', 'Vice President', 'Secretary'];

class _Pick {
  final Student student;
  final String position;
  final String partyList;
  final String motto;
  const _Pick(this.student, this.position, this.partyList, this.motto);
}

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

Future<List<String>> _applyCandidates(
    int? electionId, List<_Pick> picks, Set<int> removed) async {
  if (electionId == null) return ['Could not find the saved season.'];
  final problems = <String>[];

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
  await state.loadPartyLists();
  return problems;
}

Future<void> showElectionForm(BuildContext context,
    {Election? existing}) async {
  final locked = existing != null && existing.status != ElectionStatus.upcoming;

  List<Position> positions = [];
  List<Candidate> current = [];
  if (existing != null && !locked) {
    await state.loadAdminCandidates(existing.id);
    positions = List.of(state.adminPositions);
    current = List.of(state.adminCandidates);
    if (!context.mounted) return;
  }
  await state.loadPartyLists();
  if (!context.mounted) return;
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

  final searchCtl = TextEditingController();
  final partyCtl = TextEditingController();
  final mottoCtl = TextEditingController();
  final newPartyCtl = TextEditingController();
  bool addingParty = false;
  String? partyError;
  Timer? debounce;
  int searchToken = 0;
  bool searching = false;
  String? searchError;
  List<Student> results = [];
  Student? selected;
  String position = positionTitles.first;
  final picks = <_Pick>[];
  final removed = <int>{};
  String? notice;

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
          await _showPartyLogoDialog(ctx, p.id);
          if (ctx.mounted) setS(() {});
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    enabled: !locked,
                    leading: Icon(Icons.play_circle_outline, color: C.blue),
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
                    leading: Icon(Icons.stop_circle_outlined, color: C.blue),
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
                          avatar: PartyLogo(party: p, radius: 12),
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
                  const Divider(height: 32),
                  const Text('Candidates',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  if (locked)
                    Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Candidates are locked once voting starts.',
                          style: TextStyle(color: C.muted)),
                    )
                  else ...[
                    const SizedBox(height: 2),
                    Text(
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
                      Padding(
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
                              style: TextStyle(color: C.danger)),
                        )
                      else if (!searching &&
                          searchCtl.text.trim().isNotEmpty &&
                          shown.isEmpty)
                        Padding(
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
                            backgroundColor: C.tint,
                            child: Text(s.initials,
                                style: TextStyle(
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
                          trailing:
                              Icon(Icons.add_circle_outline, color: C.blue),
                          onTap: () => setS(() => selected = s),
                        ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: cardBox(color: C.surface2),
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
                                          style: TextStyle(
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
                              onChanged: (_) => setS(() {}),
                              decoration: const InputDecoration(
                                  labelText: 'Party list'),
                            ),
                            if (state.partyLists.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  for (final p in state.partyLists)
                                    ChoiceChip(
                                      avatar: PartyLogo(party: p, radius: 10),
                                      label: Text(p.name),
                                      selected:
                                          partyCtl.text.trim().toLowerCase() ==
                                              p.name.toLowerCase(),
                                      onSelected: (_) =>
                                          setS(() => partyCtl.text = p.name),
                                    ),
                                ],
                              ),
                            ],
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
  newPartyCtl.dispose();
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
                      style: TextStyle(color: C.muted, fontSize: 12)),
              ],
            ),
          ),
          if (isNew)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: C.tint, borderRadius: BorderRadius.circular(20)),
              child: Text('New',
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

Future<void> _showPartyLogoDialog(BuildContext context, int partyId) async {
  bool busy = false;
  String? error;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final p = state.partyLists.where((x) => x.id == partyId).firstOrNull;
      if (p == null) return const SizedBox.shrink();

      Future<void> run(Future<String?> Function() action) async {
        setS(() {
          busy = true;
          error = null;
        });
        final err = await action();
        if (err == null) await state.loadPartyLists();
        if (ctx.mounted) {
          setS(() {
            busy = false;
            error = err;
          });
        }
      }

      return AlertDialog(
        title: Text(p.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PartyLogo(party: p, radius: 48),
            const SizedBox(height: 12),
            Text(
                p.logoUrl == null
                    ? 'No logo yet. Use a jpg, png or webp image.'
                    : 'Logo saved.',
                style: TextStyle(color: C.muted, fontSize: 12)),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(error!, style: TextStyle(color: C.danger)),
              ),
          ],
        ),
        actions: [
          if (p.logoUrl != null)
            TextButton(
              onPressed:
                  busy ? null : () => run(() => state.removePartyLogo(p.id)),
              child: const Text('Remove logo'),
            ),
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => run(() => CandidateImages.pickAndUploadTo(
                    ctx, '/api/admin/party-lists/${p.id}/logo')),
            icon: const Icon(Icons.upload),
            label: Text(busy
                ? 'Uploading...'
                : (p.logoUrl == null ? 'Upload logo' : 'Change logo')),
          ),
        ],
      );
    }),
  );
}

class PartyLogo extends StatelessWidget {
  final PartyList party;
  final double radius;
  const PartyLogo({super.key, required this.party, required this.radius});

  @override
  Widget build(BuildContext context) {
    final initials = Center(
      child: Text(party.initials,
          style: TextStyle(
              color: C.blue,
              fontSize: radius * 0.75,
              fontWeight: FontWeight.w800)),
    );
    final url = party.logoUrl;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: C.tint, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? initials
          : Image.network(url,
              key: ValueKey(url),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => initials),
    );
  }
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
