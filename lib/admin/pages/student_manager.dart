import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../components/student_card.dart';

class StudentManagerPage extends StatefulWidget {
  const StudentManagerPage({super.key});

  @override
  State<StudentManagerPage> createState() => _StudentManagerPageState();
}

class _StudentManagerPageState extends State<StudentManagerPage> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final list = state.students
            .where((s) => s.fullName.toLowerCase().contains(q.toLowerCase()) || s.studentNum.contains(q))
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or student number',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => q = v),
            ),
            const SizedBox(height: 14),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No students match. Try a different name or number.')),
              ),
            for (final s in list) StudentCard(student: s),
          ],
        );
      },
    );
  }
}
