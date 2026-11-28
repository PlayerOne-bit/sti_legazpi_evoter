import 'package:flutter/material.dart';
import '../../widgets/anim.dart';
import '../../data/admin_accounts.dart';
import '../../data/api.dart';
import '../../data/excel_io.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../../widgets/admin/student_card.dart';
import '../../widgets/admin/student_form.dart';

enum _ExcelAction { importFile, template }

enum _Status { active, inactive, all }

class StudentManagerPage extends StatefulWidget {
  const StudentManagerPage({super.key});

  @override
  State<StudentManagerPage> createState() => _StudentManagerPageState();
}

class _StudentManagerPageState extends State<StudentManagerPage> {
  String q = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool busy = false;
  _Status status = _Status.active;
  String? schoolYear;
  int? gradeLevelId;

  @override
  void initState() {
    super.initState();
    state.loadStudents();
    _checkSuper();
  }

  /// Only the super admin may edit students; others still add, deactivate and delete.
  bool _isSuper = false;

  Future<void> _checkSuper() async {
    try {
      final me = await AdminApi.account();
      if (mounted) setState(() => _isSuper = me.isSuper);
    } on ApiException catch (_) {}
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Asks how Grade 11 and 12 strands in the file are saved. Null means cancelled.
  Future<bool?> _askShsTrack() {
    var modern = false;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Import students'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Grade 11 and 12 track'),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Traditional')),
                    ButtonSegment(value: true, label: Text('Modern')),
                  ],
                  selected: {modern},
                  onSelectionChanged: (v) => setS(() => modern = v.first),
                ),
                const SizedBox(height: 12),
                Text(
                  modern
                      ? 'Strands become modern tracks: ABM, ASSH, BE, STEM and HUMSS '
                          'are saved as ACAD (Academic Track); MAWD and ICT as TECH '
                          '(Technical-Professional Track).'
                      : 'Strands are saved as written in the PROGRAM column '
                          '(ABM, ASSH, BE, STEM, HUMSS, MAWD, ICT).',
                  style: const TextStyle(fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                const Text('Grade 7 to 10 students are saved as JHS.',
                    style: TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, modern),
                child: const Text('Choose file')),
          ],
        ),
      ),
    );
  }

  Future<void> _excel(_ExcelAction action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      switch (action) {
        case _ExcelAction.importFile:
          final modern = await _askShsTrack();
          if (modern == null) return;
          final result = await ExcelIo.pickAndImport(modernShs: modern);
          if (result != null) {
            await state.refreshAdmin();
            if (mounted) await showImportResult(context, result);
          }
        case _ExcelAction.template:
          _toast(await ExcelIo.saveTemplate());
      }
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _setActive(Student s, bool active) async {
    if (!active) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Mark ${s.fullName} inactive?'),
          content: const Text(
              'Use this for students who graduated, were expelled, shifted or transferred. '
              'They are taken off the voter list of upcoming and open seasons and can no '
              'longer sign in. Votes already cast are kept.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Mark inactive')),
          ],
        ),
      );
      if (ok != true) return;
    }
    final err = await state.setStudentActive(s.id, active);
    _toast(err ??
        (active
            ? '${s.fullName} is active again.'
            : '${s.fullName} is now inactive.'));
  }

  Future<void> _delete(Student s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${s.fullName}?'),
        content: const Text(
            'This removes the student for good. To keep their record, mark them inactive instead.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete student')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await state.deleteStudent(s.id);
    _toast(err ?? '${s.fullName} was deleted.');
  }

  Widget _dropdown<T>({
    required T? value,
    required String allLabel,
    required List<(T, String)> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: value == null ? C.surface2 : C.tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: value == null ? C.line : C.blue),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          icon:
              Icon(Icons.expand_more, color: value == null ? C.muted : C.blue),
          style: TextStyle(
              color: value == null ? C.ink : C.blue,
              fontWeight: FontWeight.w700,
              fontSize: 13),
          items: [
            DropdownMenuItem<T?>(value: null, child: Text(allLabel)),
            for (final (v, label) in items)
              DropdownMenuItem<T?>(value: v, child: Text(label)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final term = q.trim().toLowerCase();
        final years = {
          currentSchoolYear(),
          ...state.studentSchoolYears,
        }.toList()
          ..sort((a, b) => b.compareTo(a));
        final active = state.students.where((s) => s.isActive).length;
        final inactive = state.students.length - active;
        final list = state.students.where((s) {
          if (status == _Status.active && !s.isActive) return false;
          if (status == _Status.inactive && s.isActive) return false;
          if (schoolYear != null && s.schoolYear != schoolYear) return false;
          if (gradeLevelId != null && s.gradeLevelId != gradeLevelId) {
            return false;
          }
          if (term.isEmpty) return true;
          return s.fullName.toLowerCase().contains(term) ||
              s.studentNum.toLowerCase().contains(term) ||
              (s.programCode ?? '').toLowerCase().contains(term) ||
              s.section.toLowerCase().contains(term);
        }).toList();
        final filtered = schoolYear != null || gradeLevelId != null;

        final header = <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'Search name, number, section or program',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => q = v),
                  ),
                ),
                const SizedBox(width: 8),
                if (busy)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  )
                else
                  PopupMenuButton<_ExcelAction>(
                    tooltip: 'Excel',
                    icon: Icon(Icons.table_view, color: C.blue),
                    onSelected: _excel,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: _ExcelAction.importFile,
                          child: Text('Import students (.xls, .xlsx)')),
                      PopupMenuItem(
                          value: _ExcelAction.template,
                          child: Text('Download template')),
                    ],
                  ),
                const SizedBox(width: 4),
                Pressable(
                  child: IconButton.filled(
                    tooltip: 'Add student',
                    style: IconButton.styleFrom(
                      backgroundColor: C.yellow,
                      foregroundColor: C.onYellow,
                      minimumSize: const Size(50, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.person_add),
                    onPressed: () => showStudentForm(context),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_Status>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                      value: _Status.active,
                      icon: const Icon(Icons.verified_user_outlined, size: 18),
                      label: Text('Active ($active)')),
                  ButtonSegment(
                      value: _Status.inactive,
                      icon: const Icon(Icons.person_off_outlined, size: 18),
                      label: Text('Inactive ($inactive)')),
                  ButtonSegment(
                      value: _Status.all,
                      label: Text('All (${state.students.length})')),
                ],
                selected: {status},
                onSelectionChanged: (v) => setState(() => status = v.first),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _dropdown<String>(
                  value: schoolYear,
                  allLabel: 'All school years',
                  items: [for (final y in years) (y, 'S.Y. $y')],
                  onChanged: (v) => setState(() => schoolYear = v),
                ),
                const SizedBox(width: 8),
                _dropdown<int>(
                  value: gradeLevelId,
                  allLabel: 'All year levels',
                  items: [for (final g in state.gradeLevels) (g.id, g.name)],
                  onChanged: (v) => setState(() => gradeLevelId = v),
                ),
                if (filtered) ...[
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      schoolYear = null;
                      gradeLevelId = null;
                    }),
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    '${list.length} student${list.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: C.muted, fontWeight: FontWeight.w600))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: C.tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.key_outlined, size: 16, color: C.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Students sign in with a season password. Find each '
                        'student\'s password in the season\'s Voters list.',
                        style: TextStyle(color: C.ink, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ),
        ];

        final empty = Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.students.isEmpty
                ? 'No students yet. Add one or import from Excel.'
                : 'No students match these filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.muted),
          ),
        );
        Widget card(Student s) => StudentCard(
              student: s,
              onToggleActive: () => _setActive(s, !s.isActive),
              onDelete: s.canDelete ? () => _delete(s) : null,
              onEdit:
                  _isSuper ? () => showStudentForm(context, existing: s) : null,
            );

        // On short screens (a phone held sideways) the search and filters scroll away with
        // the list, so the students get the whole height instead of a thin strip.
        if (MediaQuery.sizeOf(context).height < 560) {
          return ListView(
            key: ValueKey('$status-$schoolYear-$gradeLevelId'),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ...header,
              const SizedBox(height: 10),
              if (list.isEmpty)
                empty
              else
                for (var i = 0; i < list.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FadeSlideIn(index: i, child: card(list[i])),
                  ),
            ],
          );
        }

        return Column(
          children: [
            ...header,
            Expanded(
              child: list.isEmpty
                  ? Center(child: empty)
                  : StaggerListView(
                      key: ValueKey('$status-$schoolYear-$gradeLevelId'),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      children: [for (final s in list) card(s)],
                    ),
            ),
          ],
        );
      },
    );
  }
}
