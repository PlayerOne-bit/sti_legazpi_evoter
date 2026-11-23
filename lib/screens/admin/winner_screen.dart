import 'package:flutter/material.dart';
import '../../widgets/anim.dart';
import '../../widgets/brand_app_bar.dart';
import '../../data/excel_io.dart';
import '../../data/mock.dart';
import '../../widgets/blue_button.dart';
import '../../widgets/centered_body.dart';
import '../../widgets/admin/poll_results.dart';
import '../../theme.dart';

class WinnerScreen extends StatefulWidget {
  final Election election;
  const WinnerScreen({super.key, required this.election});

  @override
  State<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen> {
  late final Future<_Results> _results = _load();
  bool _busy = false;
  bool _exporting = false;

  Future<_Results> _load() async {
    final id = widget.election.id;
    final tally = await state.fetchAdminTally(id);
    var photos = <int, String>{};
    try {
      photos = await state.fetchCandidatePhotos(id);
    } catch (_) {}
    return _Results(tally, photos);
  }

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
      appBar: BrandAppBar(title: const Text('Election Results')),
      body: CenteredBody(
        maxWidth: 800,
        child: FutureBuilder<_Results>(
          future: _results,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) return Center(child: Text('${snap.error}'));
            final r = snap.data!;
            final positions =
                r.tally.where((p) => p.entries.isNotEmpty).toList();
            return StaggerListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                _Header(club: e.club, schoolYear: e.schoolYear),
                const SizedBox(height: 20),
                if (positions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: cardBox(),
                    child: Text('No positions or candidates to show.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: C.muted)),
                  ),
                for (final p in positions) PositionPollCard(p, r.photos),
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

class _Results {
  final List<PositionTally> tally;
  final Map<int, String> photos;
  const _Results(this.tally, this.photos);
}

class _Header extends StatelessWidget {
  final String club;
  final String schoolYear;
  const _Header({required this.club, required this.schoolYear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [C.blue, C.blueDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: C.yellow.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: C.yellow, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Official Results',
                    style: TextStyle(
                        color: C.yellow,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(club,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Text('School Year $schoolYear',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
