import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../../widgets/admin/student_card.dart';
import '../../widgets/admin/student_form.dart';

/// Student list: create, read (search + two tabs), delete (not for students who voted).
class StudentManagerPage extends StatefulWidget {
  const StudentManagerPage({super.key});

  @override
  State<StudentManagerPage> createState() => _StudentManagerPageState();
}

class _StudentManagerPageState extends State<StudentManagerPage> {
  String q = '';

  Future<void> _delete(Student s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${s.fullName}?'),
        content: const Text('This removes the student from the voter list and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete student')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = state.deleteStudent(s.id);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err ?? '${s.fullName} was deleted.')));
  }

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
      children: [
        for (final s in list)
          StudentCard(student: s, onDelete: s.hasVoted ? null : () => _delete(s)),
      ],
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
        final cur = state.currentElection;
        // Not voted only lists students who are allowed to vote in the current season.
        final notVoted =
            matches.where((s) => !s.hasVoted && (cur == null || cur.allows(s))).toList();
        final voted = matches.where((s) => s.hasVoted).toList();
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search by name or student number',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => q = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      tooltip: 'Add student',
                      style: IconButton.styleFrom(
                        backgroundColor: C.blue,
                        minimumSize: const Size(52, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.person_add),
                      onPressed: () => showStudentForm(context),
                    ),
                  ],
                ),
              ),
              if (cur != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Not voted lists students eligible for ${cur.club}, ${cur.schoolYear} '
                      '(${state.levelsLabel(cur.levelIds)}).',
                      style: const TextStyle(color: C.muted, fontSize: 12),
                    ),
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
