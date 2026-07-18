import 'package:flutter/material.dart';
import '../models/board_game.dart';
import '../theme/app_theme.dart';
import './stylized_card.dart';
import '../l10n/app_localizations.dart';

class GameCard extends StatelessWidget {
  final BoardGame game;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GameCard({
    super.key,
    required this.game,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color highlightColor = game.colorValue != null ? Color(game.colorValue!) : AppTheme.palette.first;
    final l10n = AppLocalizations.of(context);

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
            title: Text(
              game.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Tooltip(
                    message: game.highestScoreWins 
                      ? l10n!.highestScoretWins 
                      : l10n!.lowestScoretWins,
                    triggerMode: TooltipTriggerMode.tap, 
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: game.highestScoreWins
                          ? Theme.of(context).colorScheme.primaryFixed
                          : Theme.of(context).colorScheme.secondaryFixed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        game.highestScoreWins 
                          ? Icons.trending_up_rounded 
                          : Icons.trending_down_rounded,
                        size: 16,
                        color: game.highestScoreWins
                          ? Theme.of(context).colorScheme.onPrimaryFixed
                          : Theme.of(context).colorScheme.onSecondaryFixed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer, 
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${game.sessions.length} ',
                            style: TextStyle(
                              color: highlightColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: l10n.sessions,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          fontSize: 12,
                        ),
                      ),
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
                  tooltip: l10n.editGame,
                  onPressed: () {
                    onEdit();
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  tooltip: l10n.deleteGame,
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