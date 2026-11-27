import 'dart:async';

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
  final Set<int> _sending = {};
  MailJob? _job;
  Timer? _poll;
  Timer? _countdown;
  DateTime _now = Api.now;

  @override
  void initState() {
    super.initState();
    _load();
    _checkJob();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _countdown?.cancel();
    super.dispose();
  }

  Future<void> _checkJob() async {
    try {
      final j = await state.emailAllStatus(widget.electionId);
      if (!mounted || (j.total == 0 && !j.running && j.nextAvailableAt == null))
        return;
      setState(() => _job = j);
      _syncCountdown();
      if (j.running) _startPolling();
    } on ApiException {
      return;
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final j = await state.emailAllStatus(widget.electionId);
        if (!mounted) return;
        setState(() => _job = j);
        _syncCountdown();
        if (!j.running) {
          _poll?.cancel();
          _load();
        }
      } on ApiException {
        return;
      }
    });
  }

  void _syncCountdown() {
    if (_job?.nextAvailableAt == null) {
      _countdown?.cancel();
      _countdown = null;
      return;
    }
    if (_countdown?.isActive == true) return;
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _now = Api.now);
      if (!_now.isBefore(_job!.nextAvailableAt!)) {
        timer.cancel();
        _countdown = null;
      }
    });
  }

  Future<void> _emailOne(SeasonVoter v) async {
    if (v.email == null) {
      _toast('No school email for ${v.studentNum}. '
          'The student number must look like 02000XXXXXX or 2000XXXXXX.');
      return;
    }
    if (v.passwordSentAt != null) {
      final again = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Email ${v.fullName} again?'),
          content: Text('The password was already sent to ${v.email} on '
              '${fmtDate(v.passwordSentAt!.toLocal())}.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Send again')),
          ],
        ),
      );
      if (again != true) return;
    }
    setState(() => _sending.add(v.studentId));
    try {
      final to =
          await state.emailSeasonPassword(widget.electionId, v.studentId);
      if (!mounted) return;
      _toast('Password sent to $to');
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _sending.remove(v.studentId));
    }
  }

  Future<void> _emailAll(SeasonVoters d) async {
    final pending = d.items.where((v) => v.isActive && !v.hasVoted).toList();
    final unsent = pending.where((v) => v.passwordSentAt == null).length;
    final noEmail = pending.where((v) => v.email == null).length;
    var onlyUnsent = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Widget option(bool value, String title, String subtitle) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                    onlyUnsent == value
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: onlyUnsent == value ? C.blue : C.muted),
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(subtitle),
                onTap: () => setLocal(() => onlyUnsent = value),
              );
          final skipNote = noEmail == 1
              ? '1 student has no school email'
              : '$noEmail students have no school email';
          return AlertDialog(
            title: const Text('Email season passwords'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Each student gets their password at '
                      'lastname.XXXXXX@legazpi.sti.edu.ph.',
                      style: TextStyle(color: C.muted)),
                  const SizedBox(height: 8),
                  option(true, 'Not emailed yet ($unsent)',
                      'Skips students who already got this password.'),
                  option(
                      false,
                      'Everyone who has not voted (${pending.length})',
                      'Sends again to students who were already emailed.'),
                  if (noEmail > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                        '$skipNote (number is not 02000XXXXXX or 2000XXXXXX). '
                        'They will be skipped.',
                        style: TextStyle(color: C.danger, fontSize: 13)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send')),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    try {
      final job = await state.emailAllSeasonPasswords(widget.electionId,
          onlyUnsent: onlyUnsent);
      if (!mounted) return;
      setState(() => _job = job);
      _syncCountdown();
      _startPolling();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Widget _emailProgressCard(SeasonVoters d) {
    final eligible = d.items.where((v) => v.email != null).length;
    final sent = d.items
        .where((v) => v.email != null && v.passwordSentAt != null)
        .length;
    final remaining = eligible - sent;
    final ratio = eligible == 0 ? 0.0 : sent / eligible;
    final next = _job?.nextAvailableAt;
    final wait = next == null ? null : next.difference(_now);
    String countdown(Duration duration) {
      final seconds = duration.inSeconds.clamp(0, 999999);
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final secs = seconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.mark_email_read_outlined, color: C.blue),
            const SizedBox(width: 9),
            Expanded(
                child: Text('Season password emails',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            Text('$sent / $eligible',
                style: TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                color: C.blue,
                backgroundColor: C.tint),
          ),
          const SizedBox(height: 7),
          Text(
              '$remaining remaining${eligible < d.items.length ? ' · ${d.items.length - eligible} without a school email' : ''}',
              style: TextStyle(color: C.muted, fontSize: 12.5)),
          if (next != null && remaining > 0) ...[
            const SizedBox(height: 9),
            Row(children: [
              Icon(Icons.schedule,
                  size: 17,
                  color: wait != null && wait.inSeconds > 0 ? C.danger : C.ok),
              const SizedBox(width: 7),
              Expanded(
                  child: Text(
                wait != null && wait.inSeconds > 0
                    ? 'Next batch available in ${countdown(wait)}'
                    : 'Next batch is available now. Send all to continue with remaining students.',
                style: TextStyle(
                    fontSize: 12.5,
                    color: wait != null && wait.inSeconds > 0 ? C.danger : C.ok,
                    fontWeight: FontWeight.w600),
              )),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _jobCard(MailJob j) {
    final ratio = j.total == 0 ? 1.0 : j.done / j.total;
    final title = j.running
        ? 'Sending passwords... ${j.done} of ${j.total}'
        : j.total == 0
            ? 'Nobody to email.'
            : 'Emailed ${j.sent} of ${j.total} students';
    final extra = [
      if (j.skipped > 0) '${j.skipped} skipped (no school email)',
      if (j.failed > 0) '${j.failed} failed',
    ].join('  ·  ');
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
      decoration: cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  j.running
                      ? Icons.outgoing_mail
                      : j.failed > 0
                          ? Icons.error_outline
                          : Icons.mark_email_read_outlined,
                  color: j.running
                      ? C.blue
                      : j.failed > 0
                          ? C.danger
                          : C.ok),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
              if (!j.running)
                IconButton(
                  tooltip: 'Dismiss',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _job = null),
                )
              else
                const SizedBox(height: 40),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                color: j.failed > 0 && !j.running ? C.danger : C.blue,
                backgroundColor: C.tint,
              ),
            ),
          ),
          if (extra.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(extra, style: TextStyle(color: C.muted, fontSize: 12.5)),
          ],
          if (j.lastError != null) ...[
            const SizedBox(height: 4),
            Text(j.lastError!,
                style: TextStyle(color: C.danger, fontSize: 12.5)),
          ],
        ],
      ),
    );
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
            hintText: 'Search name, number or section',
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

  Widget _tile(SeasonVoter v, bool closed, bool emailReady) {
    final pw = _newPasswords[v.studentId] ?? v.password;
    final shown = _revealed.contains(v.studentId);
    final details = [
      v.studentNum,
      v.gradeLevel,
      if (v.section.isNotEmpty) 'Sec. ${v.section}',
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
                if (!closed)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(
                            v.passwordSentAt != null
                                ? Icons.mark_email_read_outlined
                                : Icons.mail_outline,
                            size: 14,
                            color: v.email == null
                                ? C.danger
                                : v.passwordSentAt != null
                                    ? C.ok
                                    : C.muted),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            v.email == null
                                ? 'No school email. Check the student number.'
                                : v.passwordSentAt != null
                                    ? '${v.email}  ·  sent ${fmtDate(v.passwordSentAt!.toLocal())}'
                                    : v.email!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: v.email == null ? C.danger : C.muted,
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      if (emailReady && v.email != null)
                        _sending.contains(v.studentId)
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              )
                            : IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: v.passwordSentAt != null
                                    ? 'Email password again'
                                    : 'Email password to ${v.email}',
                                iconSize: 18,
                                color: v.passwordSentAt != null ? C.ok : C.blue,
                                icon: const Icon(Icons.send_rounded),
                                onPressed: () => _emailOne(v),
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
              onSelected: (value) =>
                  value == 'email' ? _emailOne(v) : _reset(v),
              itemBuilder: (_) => [
                if (emailReady)
                  PopupMenuItem(
                    value: 'email',
                    enabled: v.email != null,
                    child: const ListTile(
                      dense: true,
                      leading: Icon(Icons.send_rounded),
                      title: Text('Email password'),
                    ),
                  ),
                const PopupMenuItem(
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
        : (d.items.where((v) {
            if (_show == _Show.voted && !v.hasVoted) return false;
            if (_show == _Show.notVoted && v.hasVoted) return false;
            if (_q.isEmpty) return true;
            return v.fullName.toLowerCase().contains(_q) ||
                v.studentNum.toLowerCase().contains(_q) ||
                v.section.toLowerCase().contains(_q);
          }).toList()
          ..sort((a, b) => byName(a.fullName, b.fullName)));

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
                        const SizedBox(height: 12),
                        FadeSlideIn(
                          index: 1,
                          child: Pressable(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: C.yellow,
                                foregroundColor: C.onYellow,
                                minimumSize: const Size.fromHeight(50),
                              ),
                              onPressed: _exporting ? null : _export,
                              icon: _exporting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: C.onYellow))
                                  : const Icon(Icons.download),
                              label: Text(_exporting
                                  ? 'Exporting...'
                                  : d.closed
                                      ? 'Export voter list (Excel)'
                                      : 'Export voter list with passwords (Excel)'),
                            ),
                          ),
                        ),
                        if (!d.closed) ...[
                          const SizedBox(height: 10),
                          FadeSlideIn(child: _emailProgressCard(d)),
                          const SizedBox(height: 10),
                          FadeSlideIn(
                            index: 1,
                            child: Pressable(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                                onPressed:
                                    !d.emailReady || (_job?.running ?? false)
                                        ? null
                                        : () => _emailAll(d),
                                icon: const Icon(Icons.forward_to_inbox),
                                label:
                                    const Text('Send all passwords by email'),
                              ),
                            ),
                          ),
                          if (!d.emailReady)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                  'Gmail email is not configured on the server yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: C.muted, fontSize: 12.5)),
                            ),
                        ],
                        if (_job != null) ...[
                          const SizedBox(height: 12),
                          FadeSlideIn(child: _jobCard(_job!)),
                        ],
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
                              index: i + 2,
                              child: _tile(list[i], d.closed, d.emailReady)),
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
