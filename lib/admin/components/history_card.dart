import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';

/// A finished voting season: club, school year, dates, turnout.
class HistoryCard extends StatelessWidget {
  final Season season;
  final VoidCallback? onTap;
  const HistoryCard({super.key, required this.season, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = (season.turnout * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: cardBox(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: const Color(0xFFE3ECF8), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.event_available, color: C.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(season.club, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('School year ${season.schoolYear}', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('${fmtDay(season.startDate)} to ${fmtDay(season.endDate)}',
                        style: const TextStyle(color: C.muted, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$pct%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('${season.votedCount} of ${season.totalVoters}',
                      style: const TextStyle(color: C.muted, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: C.muted),
            ],
          ),
        ),
      ),
    );
  }
}
