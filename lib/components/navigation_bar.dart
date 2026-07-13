import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/app_theme.dart';
import '../l10n/app_localizations.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 6.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: BottomNavigationBar(
                    currentIndex: navigationShell.currentIndex,
                    onTap: (int index) {
                      navigationShell.goBranch(index);
                    },
                    
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    type: BottomNavigationBarType.fixed,
                    
                    selectedItemColor: AppTheme.primary,
                    unselectedItemColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.38),
                    
                    selectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                    
                    items: [
                      BottomNavigationBarItem(
                        icon: const Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.home_outlined),
                        ),
                        activeIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.home),
                        ),
                        label: AppLocalizations.of(context)!.home,
                      ),
                      BottomNavigationBarItem(
                        icon: const Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.settings_outlined),
                        ),
                        activeIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.settings),
                        ),
                        label: AppLocalizations.of(context)!.settings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}