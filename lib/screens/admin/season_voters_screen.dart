import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/api.dart';
import '../../data/excel_io.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../../widgets/anim.dart';
import '../../widgets/brand_app_bar.dart';
import '../../widgets/centered_body.dart';

enum _Show { all, notVoted, voted }

class SeasonVotersScreen extends StatefulWidget {
  final int electionId;
  final String club;
  final String schoolYear;
  const SeasonVotersScreen(
      {super.key,
      required this.electionId,
      required this.club,
      required this.schoolYear});

  @override
  State<SeasonVotersScreen> createState() => _SeasonVotersScreenState();
}

class _SeasonVotersScreenState extends State<SeasonVotersScreen> {
  SeasonVoters? _data;
  String? _error;
  bool _loading = true;
  bool _exporting = false;
  _Show _show = _Show.all;
  String _q = '';
  final Set<int> _revealed = {};
  final Map<int, String> _newPasswords = {};

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
      final d = await state.fetchSeasonVoters(widget.electionId);
      if (!mounted) return;
      setState(() {
        _data = d;
        _newPasswords.clear();
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

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _export() async {
    setState(() => _exporting = true);
    final msg = await ExcelIo.saveVoters(
        widget.electionId, '${widget.club}-${widget.schoolYear}-voters.xlsx');
    if (!mounted) return;
    setState(() => _exporting = false);
    _toast(msg);
  }

  Future<void> _reset(SeasonVoter v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New password for ${v.fullName}?'),
        content:
            const Text('The current season password stops working right away.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Make new password')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final pw =
          await state.resetSeasonPassword(widget.electionId, v.studentId);
      if (!mounted) return;
      setState(() {
        _newPasswords[v.studentId] = pw;
        _revealed.add(v.studentId);
      });
      _toast('New password for ${v.fullName}: $pw');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Widget _header(SeasonVoters d) {
    final notVoted = d.total - d.voted;
    final ratio = d.total == 0 ? 0.0 : d.voted / d.total;
    Widget stat(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountUp(
                    value: int.parse(value),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Text(label,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [C.blue, C.blueDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.club,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          Text('School year ${widget.schoolYear}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 14),
          Row(children: [
            stat('${d.total}', 'On the list'),
            const SizedBox(width: 10),
            stat('${d.voted}', 'Voted'),
            const SizedBox(width: 10),
            stat('$notVoted', 'Not voted'),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                color: C.yellow,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('${(ratio * 100).round()}% turnout',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
              d.closed
                  ? 'This season is closed. Passwords are no longer shown.'
                  : 'Each student signs in with the password listed here. '
                      'It only works for this season.',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _filters(SeasonVoters d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search by name or student number',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 10),
        SegmentedButton<_Show>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: _Show.all, label: Text('All (${d.total})')),
            ButtonSegment(
                value: _Show.notVoted,
                label: Text('Not voted (${d.total - d.voted})')),
            ButtonSegment(
                value: _Show.voted, label: Text('Voted (${d.voted})')),
          ],
          selected: {_show},
          onSelectionChanged: (v) => setState(() => _show = v.first),
        ),
      ],
    );
  }

  Widget _tile(SeasonVoter v, bool closed) {
    final pw = _newPasswords[v.studentId] ?? v.password;
    final shown = _revealed.contains(v.studentId);
    final details = [
      v.studentNum,
      v.gradeLevel,
      if (v.programCode != null) v.programCode!,
    ].join('  ·  ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: cardBox(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: v.hasVoted ? C.okBg : C.tint,
            child: v.hasVoted
                ? Icon(Icons.check, color: C.ok)
                : Text(v.initials,
                    style:
                        TextStyle(color: C.blue, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(v.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    if (!v.isActive) ...[
                      const SizedBox(width: 6),
                      _Badge('Inactive', C.surface2, C.muted),
                    ],
                  ],
                ),
                Text(details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: C.muted, fontSize: 12.5)),
                if (!closed && pw != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.key_outlined, size: 16, color: C.muted),
                      const SizedBox(width: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          shown ? pw : '•' * pw.length,
                          key: ValueKey(shown ? pw : 'hidden'),
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              letterSpacing: shown ? 1.2 : 2,
                              color: C.ink),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: shown ? 'Hide password' : 'Show password',
                        iconSize: 18,
                        icon: Icon(shown
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => shown
                            ? _revealed.remove(v.studentId)
                            : _revealed.add(v.studentId)),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Copy password',
                        iconSize: 18,
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: pw));
                          if (mounted) _toast('Password copied.');
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              v.hasVoted
                  ? _Badge('Voted', C.okBg, C.ok)
                  : _Badge('Not voted', C.warnBg, C.warnFg),
              if (v.votedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(fmtDate(v.votedAt!.toLocal()),
                      style: TextStyle(color: C.muted, fontSize: 11)),
                ),
            ],
          ),
          if (!closed)
            PopupMenuButton<String>(
              tooltip: 'Options',
              onSelected: (_) => _reset(v),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'reset',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.lock_reset),
                    title: Text('Make new password'),
                  ),
                ),
              ],
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final list = d == null
        ? const <SeasonVoter>[]
        : d.items.where((v) {
            if (_show == _Show.voted && !v.hasVoted) return false;
            if (_show == _Show.notVoted && v.hasVoted) return false;
            if (_q.isEmpty) return true;
            return v.fullName.toLowerCase().contains(_q) ||
                v.studentNum.toLowerCase().contains(_q);
          }).toList();

    return Scaffold(
      appBar: BrandAppBar(
        title: const Text('Voters'),
        subtitle: '${widget.club}  ·  ${widget.schoolYear}',
        actions: [
          IconButton(
            tooltip: 'Export voter list with passwords',
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download),
            onPressed: _exporting || d == null ? null : _export,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: CenteredBody(
        maxWidth: 820,
        child: _loading && d == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null && d == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: C.danger)),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: [
                        FadeSlideIn(child: _header(d!)),
                        const SizedBox(height: 16),
                        FadeSlideIn(index: 1, child: _filters(d)),
                        const SizedBox(height: 14),
                        if (list.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              d.total == 0
                                  ? 'No students are on this season\'s voter list. '
                                      'Active students of the allowed grade levels are added automatically.'
                                  : 'No students match.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: C.muted),
                            ),
                          ),
                        for (var i = 0; i < list.length; i++)
                          FadeSlideIn(
                              index: i + 2, child: _tile(list[i], d.closed)),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Badge(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
