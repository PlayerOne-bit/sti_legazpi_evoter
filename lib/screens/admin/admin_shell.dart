import 'package:flutter/material.dart';
import '../../widgets/centered_body.dart';
import '../auth.dart';
import 'candidate_manager.dart';
import 'dashboard.dart';
import 'history_manager.dart';
import 'season_manager.dart';
import 'student_manager.dart';
import '../../data/mock.dart';
import '../../widgets/loading_view.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int i = 0;
  static const titles = [
    'Dashboard',
    'Seasons',
    'Students',
    'Candidates',
    'History'
  ];
  static const pages = [
    DashboardPage(),
    SeasonManagerPage(),
    StudentManagerPage(),
    CandidateManagerPage(),
    HistoryManagerPage(),
  ];
  @override
  void initState() {
    super.initState();
    state.loadAdmin();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // PC: side rail. Phones and short landscape screens: bottom bar.
        final wide = c.maxWidth >= 800 && c.maxHeight >= 480;
        final body = CenteredBody(
          maxWidth: 900,
          child: ListenableBuilder(
            listenable: state,
            builder: (_, __) {
              if (!state.adminLoaded) {
                return LoadingView(
                    error: state.adminError, onRetry: state.loadAdmin);
              }
              return pages[i];
            },
          ),
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(titles[i],
                style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: [
            IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: state.refreshAdmin),
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () {
                state.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                  (_) => false,
                );
              },
            ),
          ],
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: i,
                      onDestinationSelected: (v) => setState(() => i = v),
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: Colors.white,
                      destinations: const [
                        NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard),
                            label: Text('Dashboard')),
                        NavigationRailDestination(
                            icon: Icon(Icons.event_note_outlined),
                            selectedIcon: Icon(Icons.event_note),
                            label: Text('Seasons')),
                        NavigationRailDestination(
                            icon: Icon(Icons.groups_outlined),
                            selectedIcon: Icon(Icons.groups),
                            label: Text('Students')),
                        NavigationRailDestination(
                            icon: Icon(Icons.badge_outlined),
                            selectedIcon: Icon(Icons.badge),
                            label: Text('Candidates')),
                        NavigationRailDestination(
                            icon: Icon(Icons.history), label: Text('History')),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                )
              : body,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: i,
                  onDestinationSelected: (v) => setState(() => i = v),
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: 'Dashboard'),
                    NavigationDestination(
                        icon: Icon(Icons.event_note_outlined),
                        selectedIcon: Icon(Icons.event_note),
                        label: 'Seasons'),
                    NavigationDestination(
                        icon: Icon(Icons.groups_outlined),
                        selectedIcon: Icon(Icons.groups),
                        label: 'Students'),
                    NavigationDestination(
                        icon: Icon(Icons.badge_outlined),
                        selectedIcon: Icon(Icons.badge),
                        label: 'Candidates'),
                    NavigationDestination(
                        icon: Icon(Icons.history), label: 'History'),
                  ],
                ),
        );
      },
    );
  }
}
