import 'package:flutter/material.dart';
import '../../data/api.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../../widgets/admin/party_widgets.dart';
import '../../widgets/anim.dart';
import '../../widgets/brand_app_bar.dart';
import '../../widgets/centered_body.dart';

class PartyListsScreen extends StatefulWidget {
  final int electionId;
  final String club;
  final String schoolYear;
  const PartyListsScreen(
      {super.key,
      required this.electionId,
      required this.club,
      required this.schoolYear});

  @override
  State<PartyListsScreen> createState() => _PartyListsScreenState();
}

class _PartyListsScreenState extends State<PartyListsScreen> {
  List<PartyGroup>? _groups;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await state.loadPartyLists(notify: false);
      final g = await state.fetchPartyGroups(widget.electionId);
      if (!mounted) return;
      setState(() {
        _groups = g;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _edit(PartyGroup g) async {
    if (g.id == null) return;
    await showPartyEditor(context, g.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    Widget body;
    if (_loading && groups == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && groups == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              textAlign: TextAlign.center, style: TextStyle(color: C.danger)),
        ),
      );
    } else if (groups!.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.groups_2_outlined, size: 56, color: C.muted),
              const SizedBox(height: 12),
              Text('No candidates in this season yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: C.muted)),
            ],
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            for (var i = 0; i < groups.length; i++)
              FadeSlideIn(
                index: i,
                child: _PartyCard(
                  group: groups[i],
                  onEdit: groups[i].id == null ? null : () => _edit(groups[i]),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: BrandAppBar(
        title: const Text('Party lists'),
        subtitle: '${widget.club}  ·  ${widget.schoolYear}',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: CenteredBody(maxWidth: 960, child: body),
    );
  }
}

class _PartyCard extends StatelessWidget {
  final PartyGroup group;
  final VoidCallback? onEdit;
  const _PartyCard({required this.group, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final color = partyColor(group.id, group.color);
    final fg = onColor(color);
    final positions = group.members.map((m) => m.position).toSet().length;
    final n = group.members.length;
    return HoverLift(
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.line),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: C.dark ? 0.25 : 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 10, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, darker(color)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  PartyLogo(
                    name: group.name,
                    logoUrl: group.logoUrl,
                    color: darker(color, 0.08),
                    radius: 32,
                    ring: 3,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: fg,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                height: 1.15)),
                        const SizedBox(height: 4),
                        Text(
                            '$n member${n == 1 ? '' : 's'}  ·  '
                            '$positions position${positions == 1 ? '' : 's'}',
                            style: TextStyle(
                                color: fg.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      tooltip: 'Logo and color',
                      color: fg,
                      icon: const Icon(Icons.palette_outlined),
                      onPressed: onEdit,
                    ),
                ],
              ),
            ),
            Container(height: 4, color: C.yellow.withValues(alpha: 0.9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: LayoutBuilder(builder: (context, c) {
                final columns = c.maxWidth >= 720
                    ? 3
                    : c.maxWidth >= 460
                        ? 2
                        : 1;
                final width = (c.maxWidth - (columns - 1) * 10) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final m in group.members)
                      SizedBox(
                          width: width,
                          child: _MemberTile(member: m, color: color)),
                  ],
                );
              }),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final PartyMember member;
  final Color color;
  const _MemberTile({required this.member, required this.color});

  @override
  Widget build(BuildContext context) {
    final details = [
      member.gradeLevel,
      if (member.section.isNotEmpty) 'Sec. ${member.section}',
    ].join('  ·  ');
    final initials = Container(
      color: color.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(member.initials,
          style: TextStyle(
              color: C.dark ? Colors.white : darker(color, 0.05),
              fontSize: 20,
              fontWeight: FontWeight.w800)),
    );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: member.imageUrl == null
                ? initials
                : Image.network(member.imageUrl!,
                    key: ValueKey(member.imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => initials),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: C.dark ? 0.35 : 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(member.position.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: C.dark ? Colors.white : darker(color, 0.05),
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 4),
                Text(member.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, height: 1.2)),
                Text(details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: C.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
