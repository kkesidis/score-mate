import 'package:flutter/material.dart';
import '../models/board_game.dart';
import '../models/app_theme.dart';
import './stylized_card.dart';
import '../l10n/app_localizations.dart';

class SessionCard extends StatelessWidget {
  final BoardGame game;
  final MatchSession session;
  final int sessionIndex;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SessionCard({
    super.key,
    required this.game,
    required this.session,
    required this.sessionIndex,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  String _getWinnerText(BoardGame game, MatchSession session, AppLocalizations l10n) {
    final sessionPlayers = session.players;
    String winnerText = l10n.noWinnerYet;

    if (sessionPlayers.isNotEmpty) {
      final highestScoreWins = game.highestScoreWins;

      // Create a map matching each player to their calculated total score
      final playerScores = <PlayerSession, int>{};
      for (var player in sessionPlayers) {
        final total = player.scores.fold(
          0,
          (sum, item) => sum + (item.value ?? 0),
        );
        playerScores[player] = total;
      }

      // Find the winning score value based on game settings
      int winningScore = playerScores.values.first;
      for (var score in playerScores.values) {
        if (highestScoreWins) {
          if (score > winningScore) winningScore = score;
        } else {
          if (score < winningScore) winningScore = score;
        }
      }

      // Collect all players who hit that exact winning score target
      final winners = playerScores.entries
          .where((entry) => entry.value == winningScore)
          .map((entry) => entry.key.playerName ?? l10n.notAvailable)
          .toList();

      // Format the output string depending on if it's a solo victory or a tie!
      if (winners.length > 1) {
        winnerText = '${winners.join(', ')} ($winningScore)';
      } else {
        winnerText = '${winners.first} ($winningScore)';
      }
    }

    return winnerText;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final highlightColor = game.colorValue != null ? Color(game.colorValue!) : AppTheme.palette.first;
    final sessionName = session.name ?? l10n.indexedSession(sessionIndex + 1);
    final sessionPlayers = session.players;
    final sessionDate = session.dateTime != null
      ? '${session.dateTime!.day}/${session.dateTime!.month}/${session.dateTime!.year}'
      : l10n.notAvailable;

    final winnerText = _getWinnerText(game, session, l10n);

    return StylizedCard(
      shadowColor: highlightColor,
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Wrap(
              spacing: 8.0,
              children: [
                Text(
                  sessionName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  sessionDate,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
                )
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x12FFFFFF), 
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 13,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${sessionPlayers.length} ',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: AppLocalizations.of(context)!.players,
                              ),
                            ],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: game.highestScoreWins
                          ? AppTheme.highestWins
                          : AppTheme.lowestWins,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Wrap(
                      direction: Axis.horizontal,
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: [
                        Icon(
                          game.highestScoreWins 
                            ? Icons.trending_up_rounded 
                            : Icons.trending_down_rounded,
                          size: 14,
                          color: game.highestScoreWins
                            ? AppTheme.highestWinsForeground
                            : AppTheme.lowestWinsForeground,
                        ),
                        Text(
                          winnerText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: game.highestScoreWins
                              ? AppTheme.highestWinsForeground
                              : AppTheme.lowestWinsForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: highlightColor,
                  ),
                  tooltip: AppLocalizations.of(context)!.renameSession,
                  onPressed: () {
                    onEdit();
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.destructive,
                  ),
                  tooltip: AppLocalizations.of(context)!.deleteSession,
                  onPressed: () {
                    onDelete();
                  },
                ),
              ],
            ),
            onTap: () {
              onSelect();
            },
          ),
        ],
      ),
    );
  }
}