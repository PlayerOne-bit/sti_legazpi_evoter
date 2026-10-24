import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../shared/components/centered_body.dart';
import '../../theme.dart';

/// Details of one finished season (opened from History).
class SeasonScreen extends StatelessWidget {
  final Season season;
  const SeasonScreen({super.key, required this.season});

  Widget _stat(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: cardBox(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(color: C.muted, fontSize: 13)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final pct = (season.turnout * 100).round();
    return Scaffold(
      appBar: AppBar(title: Text(season.club)),
      body: CenteredBody(
        maxWidth: 800,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text('School year ${season.schoolYear}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${fmtDate(season.startDate)} to ${fmtDate(season.endDate)}',
                style: const TextStyle(color: C.muted)),
            const SizedBox(height: 16),
            Row(
              children: [
                _stat('Students', '${season.totalVoters}'),
                const SizedBox(width: 10),
                _stat('Voted', '${season.votedCount}'),
                const SizedBox(width: 10),
                _stat('Turnout', '$pct%'),
              ],
            ),
            const SizedBox(height: 22),
            const Text('Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final w in season.winners)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: cardBox(),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFFB88700)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.position, style: const TextStyle(color: C.muted, fontSize: 12)),
                          Text(w.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(w.partyList, style: const TextStyle(color: C.muted, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text('${w.votes} votes', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
