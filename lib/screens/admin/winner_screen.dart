import 'package:flutter/material.dart';
import '../../data/excel_io.dart';
import '../../data/mock.dart';
import '../../widgets/blue_button.dart';
import '../../widgets/centered_body.dart';
import '../../theme.dart';

class WinnerScreen extends StatefulWidget {
  final Election election;
  const WinnerScreen({super.key, required this.election});

  @override
  State<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen> {
  late final Future<List<PositionTally>> _tally =
      state.fetchAdminTally(widget.election.id);
  bool _busy = false;
  bool _exporting = false;

  Future<void> _close() async {
    setState(() => _busy = true);
    final err = await state.closeSeason(widget.election);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Season saved to history.')));
    if (err == null) Navigator.of(context).pop();
  }

  Future<void> _export() async {
    final e = widget.election;
    setState(() => _exporting = true);
    final msg = await ExcelIo.saveResults(
        e.id, '${e.club}-${e.schoolYear}-results.xlsx');
    if (!mounted) return;
    setState(() => _exporting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.election;
    return Scaffold(
      appBar: AppBar(title: const Text('Winners')),
      body: CenteredBody(
        maxWidth: 800,
        child: FutureBuilder<List<PositionTally>>(
          future: _tally,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) return Center(child: Text('${snap.error}'));
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text('${e.club}, ${e.schoolYear}',
                    style: const TextStyle(color: C.muted)),
                const SizedBox(height: 16),
                for (final p in snap.data!)
                  if (p.entries.isNotEmpty) _WinnerTile(p),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: CenteredBody(
          maxWidth: 800,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlueButton(
                  label:
                      _exporting ? 'Exporting...' : 'Export results to Excel',
                  icon: Icons.download,
                  outlined: true,
                  onPressed: _exporting ? null : _export,
                ),
                const SizedBox(height: 10),
                BlueButton(
                  label:
                      _busy ? 'Closing...' : 'Close season and save to history',
                  icon: Icons.save_alt,
                  onPressed: _busy ? null : _close,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WinnerTile extends StatelessWidget {
  final PositionTally p;
  const _WinnerTile(this.p);

  @override
  Widget build(BuildContext context) {
    final ws = p.winners;
    if (ws.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: cardBox(),
        child: Text('${p.title}: no votes were cast.',
            style: const TextStyle(color: C.muted)),
      );
    }
    return Column(
      children: [
        for (final w in ws)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: C.navy, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: w.color,
                  child: Text(w.initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ws.length > 1 ? '${p.title} (tie)' : p.title,
                          style: const TextStyle(
                              color: C.yellow, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(w.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800)),
                      Text(w.partyList,
                          style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${w.votes}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                    Text(
                        '${p.total == 0 ? 0 : (w.votes * 100 / p.total).round()}% of votes',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
