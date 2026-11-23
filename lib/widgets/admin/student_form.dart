import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../data/mock.dart';

Future<void> showStudentForm(BuildContext context) async {
  final numCtl = TextEditingController();
  final nameCtl = TextEditingController();
  int grade = 6;
  int? programId;
  String year = currentSchoolYear();
  final years = {year, ...state.schoolYears, ...state.studentSchoolYears}
      .toList()
    ..sort((a, b) => b.compareTo(a));
  String? error;
  bool saving = false;
  bool added = false;

  bool isTertiary(int id) =>
      state.gradeLevels.firstWhere((g) => g.id == id).tertiary;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('Add student'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: numCtl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Student number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: year,
                  decoration:
                      const InputDecoration(labelText: 'School year added'),
                  items: [
                    for (final y in years)
                      DropdownMenuItem(value: y, child: Text(y)),
                  ],
                  onChanged: (v) => setS(() => year = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: grade,
                  decoration: const InputDecoration(labelText: 'Year level'),
                  items: [
                    for (final g in state.gradeLevels)
                      DropdownMenuItem(value: g.id, child: Text(g.name)),
                  ],
                  onChanged: (v) => setS(() {
                    grade = v!;
                    if (!isTertiary(grade)) programId = null;
                  }),
                ),
                if (isTertiary(grade)) ...[
                  const SizedBox(height: 12),
                  if (state.programs.isEmpty)
                    const Text(
                        'No programs yet. Add programs first, then add this student.')
                  else
                    DropdownButtonFormField<int>(
                      initialValue: programId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Program'),
                      items: [
                        for (final p in state.programs)
                          DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.code}, ${p.name}',
                                overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (v) => setS(() => programId = v),
                    ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: C.tint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.key_outlined, size: 18, color: C.blue),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Students sign in with a season password. Find it in the '
                          'Voters list of each season they can vote in.',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(error!, style: TextStyle(color: C.danger)),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (isTertiary(grade) && programId == null) {
                      setS(() =>
                          error = 'Pick a program for tertiary students.');
                      return;
                    }
                    setS(() {
                      saving = true;
                      error = null;
                    });
                    final err = await state.addStudent(
                      studentNum: numCtl.text,
                      fullName: nameCtl.text,
                      gradeLevelId: grade,
                      schoolYear: year,
                      programId: programId,
                    );
                    if (err != null) {
                      setS(() {
                        saving = false;
                        error = err;
                      });
                      return;
                    }
                    added = true;
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
            child: Text(saving ? 'Adding...' : 'Add student'),
          ),
        ],
      ),
    ),
  );

  if (added && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('${nameCtl.text.trim()} was added as an active student.')));
  }
}
