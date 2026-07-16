import 'package:flutter/material.dart';
import '../models/board_game.dart';
import '../models/app_theme.dart';
import '../l10n/app_localizations.dart';

class PlayerScoreHistory extends StatelessWidget {
  final PlayerSession player;
  final void Function(int) onEdit;
  final void Function(int) onDelete;

  const PlayerScoreHistory({
    super.key,
    required this.player,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scores = player.scores;

    return Padding(
      padding: EdgeInsets.only(
        top: 16.0,
        left: 16.0,
        right: 16.0,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            16.0, // Keyboard safety
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.scoreHistory(player.playerName ?? l10n.genericPlayerName),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          scores.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(AppLocalizations.of(context)!.noScoresYet),
                ),
              )
            : Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: scores.length,
                itemBuilder: (context, index) {
                  final reversedIndex = scores.length - 1 - index;
                  final entry = scores[reversedIndex];

                  final valueString = (entry.value ?? 0) >= 0
                      ? '+${entry.value}'
                      : '${entry.value}';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (entry.value ?? 0) >= 0
                          ? AppTheme.secondary
                          : AppTheme.destructive,
                      child: Text(
                        '#${reversedIndex + 1}',
                        style: TextStyle(
                          color: (entry.value ?? 0) >= 0
                            ? AppTheme.secondaryForeground
                            : AppTheme.destructiveForeground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '$valueString ${AppLocalizations.of(context)!.points}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      entry.description ?? AppLocalizations.of(context)!.notAvailable,
                      style: const TextStyle(
                        color: AppTheme.mutedForeground
                      )
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // EDIT ENTRY BUTTON
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            onEdit(reversedIndex);
                          },
                        ),
                        // DELETE ENTRY BUTTON
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.destructive,
                            size: 20,
                          ),
                          onPressed: () {
                            onDelete(reversedIndex);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}