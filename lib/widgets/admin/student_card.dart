import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback? onToggleActive;
  final VoidCallback? onDelete;

  /// Set only for the super admin.
  final VoidCallback? onEdit;
  const StudentCard(
      {super.key,
      required this.student,
      this.onToggleActive,
      this.onDelete,
      this.onEdit});

  @override
  Widget build(BuildContext context) {
    final active = student.isActive;
    final details = [
      student.studentNum,
      state.gradeName(student.gradeLevelId),
      if (student.section.isNotEmpty) 'Sec. ${student.section}',
      if (student.programCode != null) student.programCode!,
    ].join('  ·  ');
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: active ? 1 : 0.75,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        decoration: cardBox(),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: active ? C.tint : C.surface2,
              child: Text(student.initials,
                  style: TextStyle(
                      color: active ? C.blue : C.muted,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: C.muted, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Pill(
                        active ? 'Active' : 'Inactive',
                        active ? C.okBg : C.surface2,
                        active ? C.ok : C.muted,
                        icon: active
                            ? Icons.check_circle_outline
                            : Icons.person_off_outlined,
                      ),
                      if (student.schoolYear.isNotEmpty)
                        _Pill('S.Y. ${student.schoolYear}', C.tint, C.blue,
                            icon: Icons.event_outlined),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Options',
              onSelected: (v) {
                if (v == 'edit') onEdit?.call();
                if (v == 'toggle') onToggleActive?.call();
                if (v == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
                if (onEdit != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit student'),
                    ),
                  ),
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    dense: true,
                    leading: Icon(active
                        ? Icons.person_off_outlined
                        : Icons.person_outline),
                    title: Text(active ? 'Mark inactive' : 'Mark active'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  enabled: onDelete != null,
                  child: ListTile(
                    dense: true,
                    enabled: onDelete != null,
                    leading: Icon(Icons.delete_outline,
                        color: onDelete == null ? C.muted : C.danger),
                    title: Text(
                        onDelete == null
                            ? 'Delete (has voted or ran)'
                            : 'Delete student',
                        style: TextStyle(
                            color: onDelete == null ? C.muted : C.danger)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  const _Pill(this.text, this.bg, this.fg, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
