import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/game_list_screen.dart';
import 'screens/match_sessions_screen.dart';
import 'screens/player_scores_screen.dart';
import 'components/navigation_bar.dart';

class SettingsScreen extends StatelessWidget { const SettingsScreen({super.key}); @override Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Settings'))); }

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const GameListScreen(),
              routes: [
                GoRoute(
                  path: ':gameId/sessions',
                  builder: (context, state) {
                    final gameIdString = state.pathParameters['gameId'] ?? '0';
                    final int gameId = int.tryParse(gameIdString) ?? 0;

                    return MatchSessionsScreen(gameId: gameId);
                  },
                  routes: [
                    GoRoute(
                      path: ':sessionIndex',
                      builder: (context, state) {
                        final gameIdString = state.pathParameters['gameId'] ?? '0';
                        final sessionIndexString = state.pathParameters['sessionIndex'] ?? '0';

                        final int gameId = int.tryParse(gameIdString) ?? 0;
                        final int sessionIndex = int.tryParse(sessionIndexString) ?? 0;

                        return PlayerScoresScreen(gameId: gameId, sessionIndex: sessionIndex);
                      },
                    )
                  ],
                ),
              ],
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);