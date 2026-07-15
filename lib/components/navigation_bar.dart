import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class ScaffoldWithDrawer extends StatelessWidget {
  const ScaffoldWithDrawer({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: drawerScaffoldKey,
      body: navigationShell,
      endDrawer: NavigationDrawer(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          Navigator.of(context).pop(); 
          navigationShell.goBranch(index);
        },
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 24.0,
              right: 16.0,
              top: MediaQuery.of(context).padding.top + 24.0,
              bottom: 24.0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.sidebarAccent,
                  AppTheme.sidebarAccent.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32.0), 
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ScoreDen',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppTheme.sidebarAccentForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Board Game Score Tracker',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppTheme.sidebarAccentForeground.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),

          NavigationDrawerDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: Text(AppLocalizations.of(context)!.home),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.translate_outlined),
            selectedIcon: const Icon(Icons.translate),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.language),
                Text(
                  AppLocalizations.of(context)!.languageName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5,),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}