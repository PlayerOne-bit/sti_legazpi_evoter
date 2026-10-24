import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../blue_button.dart';

/// A voting season (upcoming, open, or ended and waiting to be tallied).
/// Buttons only appear for the callbacks you pass.
class ElectionCard extends StatelessWidget {
  final Election election;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;
  const ElectionCard({super.key, required this.election, this.onEdit, this.onDelete, this.onClose});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (election.status) {
      case ElectionStatus.upcoming:
        label = 'Upcoming';
        bg = const Color(0xFFE3ECF8);
        fg = C.blue;
        break;
      case ElectionStatus.open:
        label = 'Open now';
        bg = const Color(0xFFE7F5EE);
        fg = C.ok;
        break;
      case ElectionStatus.ended:
        label = 'Tally pending';
        bg = const Color(0xFFFFF3C4);
        fg = const Color(0xFF8A6500);
        break;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(election.club, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('School year ${election.schoolYear}', style: const TextStyle(color: C.muted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.play_circle_outline, size: 18, color: C.muted),
            const SizedBox(width: 8),
            Expanded(child: Text('Opens ${fmtDate(election.startDate)}')),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.stop_circle_outlined, size: 18, color: C.muted),
            const SizedBox(width: 8),
            Expanded(child: Text('Closes ${fmtDate(election.endDate)}')),
          ]),
          if (onClose != null) ...[
            const SizedBox(height: 14),
            BlueButton(label: 'Close season and tally votes', icon: Icons.emoji_events, onPressed: onClose),
          ],
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Edit')),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
