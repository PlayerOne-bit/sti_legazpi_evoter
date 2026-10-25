import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../widgets/blue_button.dart';
import '../../theme.dart';

class CandidateManagerPage extends StatefulWidget {
  const CandidateManagerPage({super.key});

  @override
  State<CandidateManagerPage> createState() => _CandidateManagerPageState();
}

class _CandidateManagerPageState extends State<CandidateManagerPage> {
  int? _eid;

  Future<void> _add(BuildContext context, int electionId) async {
    final numCtl = TextEditingController();
    final party = TextEditingController();
    final motto = TextEditingController();
    final vision = TextEditingController();
    int? pos =
        state.adminPositions.isEmpty ? null : state.adminPositions.first.id;
    String? error;
    await showDialog<void>(
      context: context,
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
                    decoration: const InputDecoration(
                      labelText: 'Student number',
                      helperText:
                          'The student must already be in the Students list.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: pos,
                    decoration: const InputDecoration(labelText: 'Position'),
                    items: [
                      for (final p in state.adminPositions)
                        DropdownMenuItem(value: p.id, child: Text(p.title)),
                    ],
                    onChanged: (v) => setS(() => pos = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: party,
                      decoration:
                          const InputDecoration(labelText: 'Party list')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: motto,
                      decoration: const InputDecoration(labelText: 'Motto')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: vision,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Vision'),
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (pos == null) {
                  setS(() => error = 'This season has no positions.');
                  return;
                }
                final err = await state.addCandidate(
                  electionId: electionId,
                  studentNum: numCtl.text,
                  positionId: pos!,
                  partyList: party.text,
                  motto: motto.text,
                  vision: vision.text,
                );
                if (err != null) {
                  setS(() => error = err);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save candidate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _remove(Candidate c, int electionId) async {
    final err = await state.removeCandidate(c.id, electionId);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
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
          WidgetsBinding.instance
              .addPostFrameCallback((_) => state.loadAdminCandidates(e.id));
        }
        final editable = e.status == ElectionStatus.upcoming;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            DropdownButtonFormField<int>(
              value: e.id,
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
                  onPressed: () => _add(context, e.id))
            else
              const Text('Candidates are locked once voting starts.',
                  style: TextStyle(color: C.muted)),
            const SizedBox(height: 18),
            for (final p in state.adminPositions) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 6),
                child: Text(p.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              if (state.adminCandidatesFor(p.id).isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('No candidates yet.',
                      style: TextStyle(color: C.muted)),
                ),
              for (final c in state.adminCandidatesFor(p.id))
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: cardBox(),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: c.color,
                        child: Text(c.initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                      ),
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
                          ],
                        ),
                      ),
                      if (editable)
                        IconButton(
                          tooltip: 'Remove candidate',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _remove(c, e.id),
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
