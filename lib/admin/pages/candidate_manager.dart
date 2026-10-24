import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../shared/components/blue_button.dart';
import '../../theme.dart';

class CandidateManagerPage extends StatelessWidget {
  const CandidateManagerPage({super.key});

  Future<void> _add(BuildContext context) async {
    final name = TextEditingController();
    final party = TextEditingController();
    final vision = TextEditingController();
    final motto = TextEditingController();
    int pos = state.positions.first.id;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add candidate'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: pos,
                  decoration: const InputDecoration(labelText: 'Position'),
                  items: [for (final p in state.positions) DropdownMenuItem(value: p.id, child: Text(p.title))],
                  onChanged: (v) => setS(() => pos = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: party, decoration: const InputDecoration(labelText: 'Party list')),
                const SizedBox(height: 12),
                TextField(controller: motto, decoration: const InputDecoration(labelText: 'Motto')),
                const SizedBox(height: 12),
                TextField(
                  controller: vision,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Vision'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                state.addCandidate(
                  positionId: pos,
                  name: name.text.trim(),
                  partyList: party.text.trim(),
                  vision: vision.text.trim(),
                  motto: motto.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save candidate'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          BlueButton(label: 'Add candidate', icon: Icons.person_add, onPressed: () => _add(context)),
          const SizedBox(height: 18),
          for (final p in state.positions) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 6),
              child: Text(p.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            if (state.candidatesFor(p.id).isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('No candidates yet. Add one above.', style: TextStyle(color: C.muted)),
              ),
            for (final c in state.candidatesFor(p.id))
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: cardBox(),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: c.color,
                      child: Text(c.initials,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(c.partyList, style: const TextStyle(color: C.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove candidate',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => state.removeCandidate(c.id),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
