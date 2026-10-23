import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  const StudentCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final v = student.hasVoted;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
                Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${student.studentNum}, Grade ${student.gradeLevel}',
                    style: const TextStyle(color: C.muted, fontSize: 13)),
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
        ],
      ),
    );
  }
}
