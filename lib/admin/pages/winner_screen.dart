import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../shared/components/blue_button.dart';
import '../../theme.dart';

class WinnerScreen extends StatelessWidget {
  const WinnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Winners')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text('${state.club}, ${state.schoolYear}', style: const TextStyle(color: C.muted)),
          const SizedBox(height: 16),
          for (final p in state.positions)
            if (state.candidatesFor(p.id).isNotEmpty) _WinnerTile(p),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: BlueButton(
            label: 'Save to history',
            icon: Icons.save_alt,
            onPressed: () {
              state.saveToHistory();
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Winners saved to history.')));
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }
}

class _WinnerTile extends StatelessWidget {
  final Position p;
  const _WinnerTile(this.p);

  @override
  Widget build(BuildContext context) {
    final w = state.winnerFor(p.id);
    final votes = state.votesFor(w.id);
    final total = state.totalFor(p.id);
    final pct = total == 0 ? 0 : (votes * 100 / total).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: w.color,
            child: Text(w.initials,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, style: const TextStyle(color: C.yellow, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(w.name, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                Text(w.partyList, style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$votes', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              Text('$pct% of votes', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
