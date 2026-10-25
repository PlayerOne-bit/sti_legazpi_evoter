import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';

/// One row of the student list. Swap this widget when the table design changes.
/// [onDelete] is only offered for students who have not voted.
class StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback? onDelete;
  const StudentCard({super.key, required this.student, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final v = student.hasVoted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: cardBox(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE3ECF8),
            child: Text(student.initials, style: const TextStyle(color: C.blue, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${student.studentNum}, ${state.gradeName(student.gradeLevelId)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: v ? const Color(0xFFE7F5EE) : const Color(0xFFF1F3F7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(v ? 'Voted' : 'Not yet',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: v ? C.ok : C.muted)),
          ),
          if (v)
            const Tooltip(
              message: 'Students who voted cannot be deleted',
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.lock_outline, color: C.muted, size: 22),
              ),
            )
          else
            IconButton(
              tooltip: 'Delete student',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
