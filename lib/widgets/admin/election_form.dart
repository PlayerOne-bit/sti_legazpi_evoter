import 'package:flutter/material.dart';
import '../../data/mock.dart';

/// Dialog for adding a student to the voter list.
Future<void> showStudentForm(BuildContext context) async {
  final numCtl = TextEditingController();
  final nameCtl = TextEditingController();
  final passCtl = TextEditingController();
  int grade = 6; // Grade 12
  int? programId;
  String? error;

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
                    decoration: const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: grade,
                  decoration: const InputDecoration(labelText: 'Grade level'),
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
                      value: programId,
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
                const SizedBox(height: 12),
                TextField(
                  controller: passCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Temporary password',
                    helperText:
                        'At least 6 characters. The backend will store only a hash.',
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(error!,
                        style: TextStyle(color: Colors.red.shade700)),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (passCtl.text.length < 6) {
                setS(() => error = 'The password needs at least 6 characters.');
                return;
              }
              if (isTertiary(grade) && programId == null) {
                setS(() => error = 'Pick a program for tertiary students.');
                return;
              }
              final err = await state.addStudent(
                studentNum: numCtl.text,
                fullName: nameCtl.text,
                gradeLevelId: grade,
                password: passCtl.text,
                programId: programId,
              );
              if (err != null) {
                setS(() => error = err);
                return;
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add student'),
          ),
        ],
      ),
    ),
  );
}
