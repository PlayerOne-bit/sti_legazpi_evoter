import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';

class HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  const HistoryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardBox(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFFFF3C4), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.emoji_events, color: Color(0xFFB88700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.winner, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${entry.position}, ${entry.club}', style: const TextStyle(fontSize: 13)),
                Text(entry.schoolYear, style: const TextStyle(color: C.muted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.voteCount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const Text('votes', style: TextStyle(color: C.muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
