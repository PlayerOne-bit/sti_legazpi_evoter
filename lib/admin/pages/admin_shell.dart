import 'package:flutter/material.dart';
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
      body: pages[i],
      bottomNavigationBar: NavigationBar(
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
  }
}
