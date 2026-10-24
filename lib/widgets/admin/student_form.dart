import 'package:flutter/material.dart';
import '../../data/mock.dart';

/// Dialog for adding a student to the voter list.
Future<void> showStudentForm(BuildContext context) async {
  final numCtl = TextEditingController();
  final nameCtl = TextEditingController();
  final passCtl = TextEditingController();
  int grade = 12;
  String? error;

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
                  decoration: const InputDecoration(labelText: 'Student number'),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Full name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: grade,
                  decoration: const InputDecoration(labelText: 'Grade level'),
                  items: const [
                    DropdownMenuItem(value: 11, child: Text('Grade 11')),
                    DropdownMenuItem(value: 12, child: Text('Grade 12')),
                  ],
                  onChanged: (v) => setS(() => grade = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Temporary password',
                    helperText: 'At least 6 characters. The backend will store only a hash.',
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(error!, style: TextStyle(color: Colors.red.shade700)),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (passCtl.text.length < 6) {
                setS(() => error = 'The password needs at least 6 characters.');
                return;
              }
              final err = state.addStudent(
                studentNum: numCtl.text,
                fullName: nameCtl.text,
                gradeLevel: grade,
              );
              if (err != null) {
                setS(() => error = err);
                return;
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add student'),
          ),
        ],
      ),
    ),
  );
}
