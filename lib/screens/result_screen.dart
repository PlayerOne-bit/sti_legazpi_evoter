import 'package:flutter/material.dart';
import '../widgets/anim.dart';
import '../widgets/brand_app_bar.dart';
import '../data/mock.dart';
import '../widgets/centered_body.dart';
import '../theme.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<List<PositionTally>> _f = state.fetchStudentTally();

  void _reload() => setState(() => _f = state.fetchStudentTally());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(
        title: const Text('Live tally'),
        actions: [
          IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _reload)
        ],
      ),
      body: CenteredBody(
        maxWidth: 800,
        child: FutureBuilder<List<PositionTally>>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('${snap.error}', textAlign: TextAlign.center),
                ),
              );
            }
            return StaggerListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(state.electionLabel, style: TextStyle(color: C.muted)),
                const SizedBox(height: 16),
                for (final p in snap.data!) ...[
                  Text(p.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: cardBox(),
                    child: Column(children: [
                      for (final e in p.entries) _Bar(e: e, total: p.total)
                    ]),
                  ),
                  const SizedBox(height: 22),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final TallyEntry e;
  final int total;
  const _Bar({required this.e, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : e.votes / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text(e.name,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            Text('${e.votes} votes', style: TextStyle(color: C.muted)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: C.line,
              valueColor: AlwaysStoppedAnimation(e.color),
            ),
          ),
        ],
      ),
    );
  }
}
