import 'package:flutter/material.dart';
import '../../widgets/brand_app_bar.dart';
import '../../theme.dart';
import '../../data/mock.dart';
import '../../widgets/centered_body.dart';
import '../../widgets/loading_view.dart';
import '../auth.dart';
import 'admin_manager.dart';
import 'dashboard.dart';
import 'history_manager.dart';
import 'season_manager.dart';
import 'student_manager.dart';

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
    'History',
    'Admins'
  ];
  static const pages = [
    DashboardPage(),
    SeasonManagerPage(),
    StudentManagerPage(),
    HistoryManagerPage(),
    AdminManagerPage(),
  ];

  @override
  void initState() {
    super.initState();
    state.loadAdmin();
  }

  void _signOut() {
    state.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final landscape = c.maxWidth > c.maxHeight && c.maxWidth >= 560;
        final wide = (c.maxWidth >= 800 && c.maxHeight >= 480) || landscape;
        // Short screens (phones sideways) only fit the rail without labels under every icon.
        final short = c.maxHeight < 480;
        final body = CenteredBody(
          maxWidth: 900,
          child: ListenableBuilder(
            listenable: state,
            builder: (_, __) {
              final Widget child = !state.adminLoaded
                  ? LoadingView(
                      key: const ValueKey('loading'),
                      error: state.adminError,
                      onRetry: state.loadAdmin)
                  : KeyedSubtree(key: ValueKey(i), child: pages[i]);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position:
                        Tween(begin: const Offset(0, 0.015), end: Offset.zero)
                            .animate(a),
                    child: c,
                  ),
                ),
                child: child,
              );
            },
          ),
        );
        return Scaffold(
          appBar: BrandAppBar(
            title: Text(titles[i]),
            subtitle: 'STI Legazpi eVoter  ·  Admin',
            showLogo: true,
            themeToggle: true,
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: state.refreshAdmin,
              ),
              IconButton(
                tooltip: 'Sign out',
                icon: const Icon(Icons.logout),
                onPressed: _signOut,
              ),
            ],
          ),
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: i,
                      onDestinationSelected: (v) => setState(() => i = v),
                      labelType: short
                          ? NavigationRailLabelType.selected
                          : NavigationRailLabelType.all,
                      minWidth: short ? 72 : 92,
                      groupAlignment: short ? -1 : -0.85,
                      destinations: const [
                        NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard),
                            label: Text('Dashboard')),
                        NavigationRailDestination(
                            icon: Icon(Icons.how_to_vote_outlined),
                            selectedIcon: Icon(Icons.how_to_vote),
                            label: Text('Seasons')),
                        NavigationRailDestination(
                            icon: Icon(Icons.people_outline),
                            selectedIcon: Icon(Icons.people),
                            label: Text('Students')),
                        NavigationRailDestination(
                            icon: Icon(Icons.history), label: Text('History')),
                        NavigationRailDestination(
                            icon: Icon(Icons.admin_panel_settings_outlined),
                            selectedIcon: Icon(Icons.admin_panel_settings),
                            label: Text('Admins')),
                      ],
                    ),
                    VerticalDivider(width: 1, color: C.line),
                    Expanded(
                        child: SafeArea(
                            left: false,
                            top: false,
                            bottom: false,
                            child: body)),
                  ],
                )
              : body,
          bottomNavigationBar: wide
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: C.line)),
                    boxShadow: [
                      BoxShadow(
                          color: C.shadow,
                          blurRadius: 16,
                          offset: const Offset(0, -4))
                    ],
                  ),
                  child: NavigationBar(
                    selectedIndex: i,
                    onDestinationSelected: (v) => setState(() => i = v),
                    destinations: const [
                      NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: 'Dashboard'),
                      NavigationDestination(
                          icon: Icon(Icons.how_to_vote_outlined),
                          selectedIcon: Icon(Icons.how_to_vote),
                          label: 'Seasons'),
                      NavigationDestination(
                          icon: Icon(Icons.people_outline),
                          selectedIcon: Icon(Icons.people),
                          label: 'Students'),
                      NavigationDestination(
                          icon: Icon(Icons.history), label: 'History'),
                      NavigationDestination(
                          icon: Icon(Icons.admin_panel_settings_outlined),
                          selectedIcon: Icon(Icons.admin_panel_settings),
                          label: 'Admins'),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
