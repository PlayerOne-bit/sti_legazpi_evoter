import 'package:flutter/material.dart';
import '../../widgets/anim.dart';
import '../../data/mock.dart';
import '../../widgets/admin/history_card.dart';
import 'season_screen.dart';

class HistoryManagerPage extends StatelessWidget {
  const HistoryManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => StaggerListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          if (state.history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: Text(
                      'No finished seasons yet. Close an election and it will appear here.')),
            ),
          for (final s in state.history)
            HistoryCard(
              season: s,
              onTap: () async {
                final err = await state.loadSeasonWinners(s);
                if (!context.mounted) return;
                if (err != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(err)));
                  return;
                }
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SeasonScreen(season: s)));
              },
            ),
        ],
      ),
    );
  }
}
