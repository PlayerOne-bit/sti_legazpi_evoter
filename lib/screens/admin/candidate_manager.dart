import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/anim.dart';
import '../../widgets/brand_app_bar.dart';
import '../../data/api.dart';
import '../../data/candidate_images.dart';
import '../../data/mock.dart';
import '../../widgets/centered_body.dart';
import '../../widgets/candidate_avatar.dart';
import '../../theme.dart';

class SeasonCandidatesScreen extends StatefulWidget {
  final Election election;
  const SeasonCandidatesScreen({super.key, required this.election});

  @override
  State<SeasonCandidatesScreen> createState() => _SeasonCandidatesScreenState();
}

class _SeasonCandidatesScreenState extends State<SeasonCandidatesScreen> {
  int? _busyId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await state.loadAdminCandidates(widget.election.id);
    if (mounted) setState(() => _loading = false);
  }

  Election get _election {
    for (final e in state.elections) {
      if (e.id == widget.election.id) return e;
    }
    return widget.election;
  }

  List<Candidate> _candidatesFor(int positionId) =>
      state.adminCandidates.where((c) => c.positionId == positionId).toList();

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _photo(Candidate c, int electionId) async {
    setState(() => _busyId = c.id);
    final err = await CandidateImages.pickAndUpload(context, c.id);
    if (err == null) await state.loadAdminCandidates(electionId);
    if (!mounted) return;
    setState(() => _busyId = null);
    if (err != null) _snack(err);
  }

  Future<void> _removePhoto(Candidate c, int electionId) async {
    setState(() => _busyId = c.id);
    final err = await CandidateImages.remove(c.id);
    if (err == null) await state.loadAdminCandidates(electionId);
    if (!mounted) return;
    setState(() => _busyId = null);
    if (err != null) _snack(err);
  }

  Future<void> _add(BuildContext context, int electionId,
      {int? positionId}) async {
    final search = TextEditingController();
    final party = TextEditingController();
    final motto = TextEditingController();
    int? pos = positionId ??
        (state.adminPositions.isEmpty ? null : state.adminPositions.first.id);
    final taken = {for (final c in state.adminCandidates) c.studentNum};

    Student? picked;
    List<Student> results = [];
    bool searching = false;
    String? error;
    bool saving = false;
    Timer? debounce;
    int ticket = 0;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          void onSearch(String text) {
            debounce?.cancel();
            if (text.trim().isEmpty) {
              setS(() {
                results = [];
                searching = false;
              });
              return;
            }
            setS(() => searching = true);
            debounce = Timer(const Duration(milliseconds: 300), () async {
              final mine = ++ticket;
              try {
                final r = await state.searchStudents(text, limit: 6);
                if (mine != ticket || !ctx.mounted) return;
                setS(() {
                  results = r;
                  searching = false;
                });
              } on ApiException catch (e) {
                if (mine != ticket || !ctx.mounted) return;
                setS(() {
                  results = [];
                  searching = false;
                  error = e.message;
                });
              }
            });
          }

          return AlertDialog(
            title: const Text('Add candidate'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (picked != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: cardBox(),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorFor(picked!.id),
                              child: Text(picked!.initials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(picked!.fullName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                      '${picked!.studentNum}, ${state.gradeName(picked!.gradeLevelId)}',
                                      style: TextStyle(
                                          color: C.muted, fontSize: 13)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Choose another student',
                              icon: const Icon(Icons.close),
                              onPressed: saving
                                  ? null
                                  : () => setS(() {
                                        picked = null;
                                        search.clear();
                                        results = [];
                                      }),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      TextField(
                        controller: search,
                        enabled: !saving,
                        autofocus: true,
                        onChanged: onSearch,
                        decoration: InputDecoration(
                          labelText: 'Search student',
                          helperText: 'Type a name or student number.',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                )
                              : null,
                        ),
                      ),
                      if (results.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: cardBox(),
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (final s in results)
                                ListTile(
                                  dense: true,
                                  enabled: !taken.contains(s.studentNum),
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: colorFor(s.id),
                                    child: Text(s.initials,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                  title: Text(s.fullName),
                                  subtitle: Text(
                                      '${s.studentNum}, ${taken.contains(s.studentNum) ? 'Already a candidate' : state.gradeName(s.gradeLevelId)}'),
                                  onTap: () => setS(() {
                                    picked = s;
                                    error = null;
                                  }),
                                ),
                            ],
                          ),
                        )
                      else if (!searching && search.text.trim().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('No matching students.',
                              style: TextStyle(color: C.muted)),
                        ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: pos,
                      decoration: const InputDecoration(labelText: 'Position'),
                      items: [
                        for (final p in state.adminPositions)
                          DropdownMenuItem(value: p.id, child: Text(p.title)),
                      ],
                      onChanged: saving ? null : (v) => setS(() => pos = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: party,
                      enabled: !saving,
                      decoration:
                          const InputDecoration(labelText: 'Party list'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: motto,
                      enabled: !saving,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Motto'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                        'After saving, tap the candidate\'s photo circle to add a photo.',
                        style: TextStyle(color: C.muted, fontSize: 12)),
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
                        if (picked == null) {
                          setS(() => error = 'Search and choose a student.');
                          return;
                        }
                        if (pos == null) {
                          setS(() => error = 'This season has no positions.');
                          return;
                        }
                        setS(() {
                          saving = true;
                          error = null;
                        });
                        final err = await state.addCandidateFor(
                          electionId: electionId,
                          studentId: picked!.id,
                          positionId: pos!,
                          partyList: party.text,
                          motto: motto.text,
                        );
                        if (err == null) {
                          await state.loadAdminCandidates(electionId);
                        }
                        if (!ctx.mounted) return;
                        if (err != null) {
                          setS(() {
                            saving = false;
                            error = err;
                          });
                          return;
                        }
                        Navigator.pop(ctx);
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save candidate'),
              ),
            ],
          );
        },
      ),
    );

    debounce?.cancel();
    search.dispose();
    party.dispose();
    motto.dispose();
  }

  Future<void> _remove(Candidate c, int electionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove candidate'),
        content:
            Text('Are you sure you want to remove ${c.name} from this season?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: C.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final err = await state.removeCandidate(c.id, electionId);
    if (err != null) _snack(err);
  }

  Widget _avatar(Candidate c, int electionId, bool editable) {
    final avatar = Stack(
      children: [
        CandidateAvatar(candidate: c, radius: 28),
        if (_busyId == c.id)
          const Positioned.fill(
            child: CircularProgressIndicator(strokeWidth: 3),
          )
        else if (editable)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: C.blue, shape: BoxShape.circle),
              child:
                  const Icon(Icons.camera_alt, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
    if (!editable) return avatar;
    return Tooltip(
      message: c.imageUrl == null ? 'Add photo' : 'Change photo',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _busyId == null ? () => _photo(c, electionId) : null,
        child: avatar,
      ),
    );
  }

  Widget _header(Election e, bool editable) {
    final total = state.adminCandidates.length;
    final positions = state.adminPositions.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [C.blue, C.blueDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.club,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          Text('School year ${e.schoolYear}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeaderStat(value: '$total', label: 'Candidates'),
              const SizedBox(width: 10),
              _HeaderStat(value: '$positions', label: 'Positions'),
              const SizedBox(width: 10),
              _HeaderStat(
                  value:
                      '${state.adminPositions.where((p) => _candidatesFor(p.id).isEmpty).length}',
                  label: 'Still empty'),
            ],
          ),
          if (!editable) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: C.yellow, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Voting has started, so candidates are locked.',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _positionSection(Position p, Election e, bool editable) {
    final list = _candidatesFor(p.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: list.isEmpty ? C.warnBg : C.tint,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                    list.isEmpty
                        ? 'Empty'
                        : '${list.length} candidate${list.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: list.isEmpty ? C.warnFg : C.blue)),
              ),
              if (editable)
                IconButton(
                  tooltip: 'Add a ${p.title} candidate',
                  icon: Icon(Icons.person_add_alt_1, color: C.blue),
                  onPressed: () => _add(context, e.id, positionId: p.id),
                )
              else
                const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 6),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 6, 6),
              child: Text(
                  editable
                      ? 'No candidates yet. Use the add button to pick a student.'
                      : 'No candidates.',
                  style: TextStyle(color: C.muted, fontSize: 13)),
            ),
          for (final c in list) _candidateTile(c, e, editable),
        ],
      ),
    );
  }

  Widget _candidateTile(Candidate c, Election e, bool editable) {
    final details = [
      c.studentNum,
      if (c.partyList.isNotEmpty) c.partyList,
    ].join('  ·  ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 6),
      padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          _avatar(c, e.id, editable),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: C.muted, fontSize: 13)),
                if (c.motto.isNotEmpty)
                  Text('"${c.motto}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: C.muted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          if (editable)
            PopupMenuButton<String>(
              tooltip: 'Options',
              onSelected: (v) {
                switch (v) {
                  case 'photo':
                    _photo(c, e.id);
                  case 'clear':
                    _removePhoto(c, e.id);
                  case 'remove':
                    _remove(c, e.id);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'photo',
                    child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.photo_camera_outlined),
                        title: Text(c.imageUrl == null
                            ? 'Add photo'
                            : 'Change photo'))),
                if (c.imageUrl != null)
                  const PopupMenuItem(
                      value: 'clear',
                      child: ListTile(
                          dense: true,
                          leading: Icon(Icons.hide_image_outlined),
                          title: Text('Remove photo'))),
                PopupMenuItem(
                    value: 'remove',
                    child: ListTile(
                        dense: true,
                        leading:
                            Icon(Icons.person_remove_outlined, color: C.danger),
                        title: Text('Remove candidate',
                            style: TextStyle(color: C.danger)))),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final e = _election;
        final editable = e.status == ElectionStatus.upcoming;
        final ready = !_loading && state.adminCandElectionId == e.id;
        return Scaffold(
          appBar: BrandAppBar(
            title: const Text('Candidates',
                style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: _loading ? null : _reload,
              ),
            ],
          ),
          floatingActionButton:
              editable && ready && state.adminPositions.isNotEmpty
                  ? FloatingActionButton.extended(
                      onPressed: () => _add(context, e.id),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add candidate'),
                    )
                  : null,
          body: CenteredBody(
            maxWidth: 800,
            child: StaggerListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
              children: [
                _header(e, editable),
                const SizedBox(height: 18),
                if (!ready)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.adminPositions.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('This season has no positions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: C.muted)),
                  )
                else
                  for (final p in state.adminPositions)
                    _positionSection(p, e, editable),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeaderStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
