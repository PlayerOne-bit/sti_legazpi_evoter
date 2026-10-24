import 'package:flutter/material.dart';
import '../data/mock.dart';
import '../widgets/centered_body.dart';
import '../theme.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live tally')),
      body: CenteredBody(maxWidth: 800, child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(state.electionLabel, style: const TextStyle(color: C.muted)),
            const SizedBox(height: 16),
            for (final p in state.positions) ...[
              Text(p.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: cardBox(),
                child: Column(
                  children: [
                    for (final c in state.candidatesFor(p.id)) _Bar(c: c, total: state.totalFor(p.id)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],
          ],
        ),
      )),
    );
  }
}

class _Bar extends StatelessWidget {
  final Candidate c;
  final int total;
  const _Bar({required this.c, required this.total});

  @override
  Widget build(BuildContext context) {
    final v = state.votesFor(c.id);
    final pct = total == 0 ? 0.0 : v / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('$v votes', style: const TextStyle(color: C.muted)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: C.line,
              valueColor: AlwaysStoppedAnimation(c.color),
            ),
          ),
        ],
      ),
    );
  }
}
