import 'package:flutter/material.dart';
import '../../shared/components/centered_body.dart';
import '../../shared/pages/auth.dart';
import 'candidate_manager.dart';
import 'dashboard.dart';
import 'history_manager.dart';
import 'student_manager.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int i = 0;
  static const titles = ['Dashboard', 'Students', 'Candidates', 'History'];
  static const pages = [DashboardPage(), StudentManagerPage(), CandidateManagerPage(), HistoryManagerPage()];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // PC: side rail. Phones and short landscape screens: bottom bar.
        final wide = c.maxWidth >= 800 && c.maxHeight >= 480;
        final body = CenteredBody(maxWidth: 900, child: pages[i]);
        return Scaffold(
          appBar: AppBar(
            title: Text(titles[i], style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout),
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                  (_) => false,
                ),
              ),
            ],
          ),
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: i,
                      onDestinationSelected: (v) => setState(() => i = v),
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: Colors.white,
                      destinations: const [
                        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                        NavigationRailDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: Text('Students')),
                        NavigationRailDestination(icon: Icon(Icons.badge_outlined), selectedIcon: Icon(Icons.badge), label: Text('Candidates')),
                        NavigationRailDestination(icon: Icon(Icons.history), label: Text('History')),
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
                    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
                    NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Students'),
                    NavigationDestination(icon: Icon(Icons.badge_outlined), selectedIcon: Icon(Icons.badge), label: 'Candidates'),
                    NavigationDestination(icon: Icon(Icons.history), label: 'History'),
                  ],
                ),
        );
      },
    );
  }
}
