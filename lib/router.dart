import 'package:go_router/go_router.dart';
import 'package:score_den/screens/language_screen.dart';
import 'screens/game_list_screen.dart';
import 'screens/match_sessions_screen.dart';
import 'screens/player_scores_screen.dart';
import 'components/navigation_bar.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithDrawer(navigationShell: navigationShell);
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
              path: '/language',
              builder: (context, state) => const LanguageScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);