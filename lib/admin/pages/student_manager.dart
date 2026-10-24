import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../components/student_card.dart';

class StudentManagerPage extends StatefulWidget {
  const StudentManagerPage({super.key});

  @override
  State<StudentManagerPage> createState() => _StudentManagerPageState();
}

class _StudentManagerPageState extends State<StudentManagerPage> {
  String q = '';

  Widget _list(List<Student> list, String emptyMsg) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(q.isNotEmpty ? 'No students match your search.' : emptyMsg,
              textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [for (final s in list) StudentCard(student: s)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final matches = state.students
            .where((s) => s.fullName.toLowerCase().contains(q.toLowerCase()) || s.studentNum.contains(q))
            .toList();
        final notVoted = matches.where((s) => !s.hasVoted).toList();
        final voted = matches.where((s) => s.hasVoted).toList();
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or student number',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => q = v),
                ),
              ),
              TabBar(
                labelColor: C.blue,
                unselectedLabelColor: C.muted,
                indicatorColor: C.blue,
                dividerColor: C.line,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: [
                  Tab(text: 'Not voted (${notVoted.length})'),
                  Tab(text: 'Voted (${voted.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _list(notVoted, 'Everyone has voted.'),
                    _list(voted, 'No one has voted yet.'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
