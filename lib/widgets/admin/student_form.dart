import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../data/mock.dart';

/// Adds a student, or edits [existing] (super admin only).
Future<void> showStudentForm(BuildContext context, {Student? existing}) async {
  // Names are stored as "Last, First Middle"; when editing, everything after the comma goes in First name.
  final comma = existing?.fullName.indexOf(',') ?? -1;
  final numCtl = TextEditingController(text: existing?.studentNum ?? '');
  final lastCtl = TextEditingController(
      text: existing == null
          ? ''
          : comma < 0
              ? existing.fullName
              : existing.fullName.substring(0, comma).trim());
  final firstCtl = TextEditingController(
      text: existing == null || comma < 0
          ? ''
          : existing.fullName.substring(comma + 1).trim());
  final middleCtl = TextEditingController();
  String fullName() {
    final last = lastCtl.text.trim();
    final given = '${firstCtl.text.trim()} ${middleCtl.text.trim()}'.trim();
    return given.isEmpty ? last : '$last, $given';
  }

  final sectionCtl = TextEditingController(text: existing?.section ?? '');
  int grade = existing?.gradeLevelId ?? 6;
  int? programId = existing?.programId;
  String year = existing != null && existing.schoolYear.isNotEmpty
      ? existing.schoolYear
      : currentSchoolYear();
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
        title: Text(existing == null ? 'Add student' : 'Edit student'),
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
                  controller: lastCtl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: firstCtl,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(labelText: 'First name'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: middleCtl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                            labelText: 'Middle name (optional)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: year,
                  decoration: InputDecoration(
                      labelText: existing == null
                          ? 'School year added'
                          : 'School year'),
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
                const SizedBox(height: 12),
                TextField(
                  controller: sectionCtl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                      labelText: 'Section (optional)',
                      hintText: 'For example 1Y1 or ST. JOHN'),
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
                if (existing == null)
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
                    if (lastCtl.text.trim().isEmpty ||
                        firstCtl.text.trim().isEmpty) {
                      setS(() => error = 'Enter the last name and first name.');
                      return;
                    }
                    if (isTertiary(grade) && programId == null) {
                      setS(() =>
                          error = 'Pick a program for tertiary students.');
                      return;
                    }
                    setS(() {
                      saving = true;
                      error = null;
                    });
                    final err = existing == null
                        ? await state.addStudent(
                            studentNum: numCtl.text,
                            fullName: fullName(),
                            gradeLevelId: grade,
                            schoolYear: year,
                            section: sectionCtl.text,
                            programId: programId,
                          )
                        : await state.updateStudent(
                            id: existing.id,
                            studentNum: numCtl.text,
                            fullName: fullName(),
                            gradeLevelId: grade,
                            schoolYear: year,
                            section: sectionCtl.text,
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
            child: Text(saving
                ? 'Saving...'
                : existing == null
                    ? 'Add student'
                    : 'Save changes'),
          ),
        ],
      ),
    ),
  );

  if (added && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(existing == null
            ? '${fullName()} was added as an active student.'
            : '${fullName()} was saved.')));
  }
}
