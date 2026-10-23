import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../components/history_card.dart';

class HistoryManagerPage extends StatelessWidget {
  const HistoryManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          if (state.history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No past elections yet. Winners are saved here after you tally.')),
            ),
          for (final h in state.history) HistoryCard(entry: h),
        ],
      ),
    );
  }
}
