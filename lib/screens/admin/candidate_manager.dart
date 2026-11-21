import 'package:flutter/material.dart';
import '../../data/candidate_images.dart';
import '../../data/mock.dart';
import '../../widgets/blue_button.dart';
import '../../widgets/candidate_avatar.dart';
import '../../theme.dart';

class CandidateManagerPage extends StatefulWidget {
  const CandidateManagerPage({super.key});

  @override
  State<CandidateManagerPage> createState() => _CandidateManagerPageState();
}

class _CandidateManagerPageState extends State<CandidateManagerPage> {
  int? _eid;
  int? _busyId; // candidate whose photo is uploading

  List<Candidate> _candidatesFor(int positionId) =>
      state.adminCandidates.where((c) => c.positionId == positionId).toList();

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _photo(Candidate c, int electionId) async {
    setState(() => _busyId = c.id);
    final err = await CandidateImages.pickAndUpload(c.id);
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

  Future<void> _add(BuildContext context, int electionId) async {
    final numCtl = TextEditingController();
    final party = TextEditingController();
    final motto = TextEditingController();
    int? pos =
        state.adminPositions.isEmpty ? null : state.adminPositions.first.id;
    String? error;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add candidate'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: numCtl,
                    enabled: !saving,
                    decoration: const InputDecoration(
                      labelText: 'Student number',
                      helperText:
                          'The student must already be in the Students list.',
                    ),
                  ),
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
                    decoration: const InputDecoration(labelText: 'Party list'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: motto,
                    enabled: !saving,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Motto'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                      'After saving, tap the candidate\'s photo circle to add a photo.',
                      style: TextStyle(color: C.muted, fontSize: 12)),
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
                      if (pos == null) {
                        setS(() => error = 'This season has no positions.');
                        return;
                      }
                      setS(() {
                        saving = true;
                        error = null;
                      });
                      final err = await state.addCandidate(
                        electionId: electionId,
                        studentNum: numCtl.text,
                        positionId: pos!,
                        partyList: party.text,
                        motto: motto.text,
                      );
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
        ),
      ),
    );

    numCtl.dispose();
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
              decoration:
                  const BoxDecoration(color: C.blue, shape: BoxShape.circle),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final list = state.elections;
        if (list.isEmpty) {
          return const Center(
            child: Text('Create a voting season first.',
                style: TextStyle(color: C.muted)),
          );
        }

        final e =
            list.firstWhere((x) => x.id == _eid, orElse: () => list.first);

        if (state.adminCandElectionId != e.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (state.adminCandElectionId != e.id) {
              state.loadAdminCandidates(e.id);
            }
          });
        }

        final loaded = state.adminCandElectionId == e.id;
        final editable = e.status == ElectionStatus.upcoming;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            DropdownButtonFormField<int>(
              initialValue: e.id,
              decoration: const InputDecoration(labelText: 'Season'),
              items: [
                for (final x in list)
                  DropdownMenuItem(
                      value: x.id, child: Text('${x.club}, ${x.schoolYear}')),
              ],
              onChanged: (v) => setState(() => _eid = v),
            ),
            const SizedBox(height: 12),
            if (editable)
              BlueButton(
                label: 'Add candidate',
                icon: Icons.person_add,
                onPressed: loaded ? () => _add(context, e.id) : null,
              )
            else
              const Text('Candidates are locked once voting starts.',
                  style: TextStyle(color: C.muted)),
            const SizedBox(height: 18),
            if (!loaded)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.adminPositions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No positions available for this season.',
                      style: TextStyle(color: C.muted)),
                ),
              )
            else
              for (final p in state.adminPositions) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 6),
                  child: Text(p.title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                if (_candidatesFor(p.id).isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text('No candidates yet.',
                        style: TextStyle(color: C.muted)),
                  ),
                for (final c in _candidatesFor(p.id))
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: cardBox(),
                    child: Row(
                      children: [
                        _avatar(c, e.id, editable),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text('${c.studentNum}, ${c.partyList}',
                                  style: const TextStyle(
                                      color: C.muted, fontSize: 13)),
                              if (c.motto.isNotEmpty)
                                Text('"${c.motto}"',
                                    style: const TextStyle(
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
                                  child: Text(c.imageUrl == null
                                      ? 'Add photo'
                                      : 'Change photo')),
                              if (c.imageUrl != null)
                                const PopupMenuItem(
                                    value: 'clear',
                                    child: Text('Remove photo')),
                              const PopupMenuItem(
                                  value: 'remove',
                                  child: Text('Remove candidate')),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
          ],
        );
      },
    );
  }
}
