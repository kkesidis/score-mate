import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../main.dart';
import '../models/board_game.dart';
import '../models/app_theme.dart';
import '../components/stylized_card.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../components/color_picker_field.dart';
import '../components/custom_app_bar.dart';

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  List<BoardGame> _games = [];

  @override
  void initState() {
    super.initState();
    _readGamesFromDatabase();
    _listenToDatabaseChanges();
  }

  void _readGamesFromDatabase() async {
    final allGames = await isar.boardGames.where().findAll();
    setState(() {
      _games = allGames;
    });
  }

  void _listenToDatabaseChanges() {
    isar.boardGames.watchLazy().listen((_) {
      _readGamesFromDatabase();
    });
  }

  void _showDeleteConfirmationDialog(BoardGame game) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteBoardGameTitle),
          content: Text(AppLocalizations.of(context)!.deleteBoardGameDescription(game.name)),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context), // Close the dialog, do nothing
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.destructive,
                foregroundColor: AppTheme.destructiveForeground,
              ),
              onPressed: () {
                _deleteGame(game.id); // Run the actual Isar delete code
                Navigator.pop(context); // Close the dialog
              },
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );
  }

  void _deleteGame(int id) async {
    await isar.writeTxn(() async {
      await isar.boardGames.delete(id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.gameDeleted)),
      );
    }
  }

  void _showGameDialog({BoardGame? existingGame}) {
    final nameController = TextEditingController();
    bool highestWins = true;
    Color currentColor = AppTheme.palette.first;

    // If we are editing, pre-fill the form fields with the current values
    final isEditing = existingGame != null;
    if (isEditing) {
      nameController.text = existingGame.name;
      highestWins = existingGame.highestScoreWins;
      currentColor = existingGame.colorValue != null ? Color(existingGame.colorValue!) : currentColor;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to resize when keyboards push up
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    isEditing ? AppLocalizations.of(context)!.editGame : AppLocalizations.of(context)!.newGame,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    autofocus: true,
                    controller: nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.gameNameLabel,
                      hintText: AppLocalizations.of(context)!.gameNameHint,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ColorPickerField(
                    initialColor: currentColor,
                    onColorSelected: (newColor) {
                      currentColor = newColor; 
                    },
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      // --- Button 1: Highest Score Wins ---
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              highestWins = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10), // Even vertical padding for alignment
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              // Lights up with color if active, otherwise shows standard subtle chip background
                              color: highestWins
                                  ? AppTheme.highestWins
                                  : const Color(0x12FFFFFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  size: 14,
                                  color: highestWins
                                      ? AppTheme.highestWinsForeground
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)!.highestWins,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: highestWins
                                        ? AppTheme.highestWinsForeground
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8), // Gap between the two 50% components
                      
                      // --- Button 2: Lowest Score Wins ---
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              highestWins = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              // Lights up with color if active, otherwise shows standard subtle chip background
                              color: !highestWins
                                  ? AppTheme.lowestWins
                                  : const Color(0x12FFFFFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_down_rounded,
                                  size: 14,
                                  color: !highestWins
                                      ? AppTheme.lowestWinsForeground
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(context)!.lowestWins,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: !highestWins
                                        ? AppTheme.lowestWinsForeground
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing:
                        8.0, // Horizontal gap between buttons when side-by-side
                    overflowSpacing:
                        8.0, // Vertical gap between buttons if they drop/stack vertically!
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.primaryForeground,
                        ),
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) return;

                          // If editing, reuse the old object so Isar overwrites the exact ID slot
                          final gameToSave = isEditing
                              ? existingGame
                              : BoardGame();

                          gameToSave.name = nameController.text.trim();
                          gameToSave.highestScoreWins = highestWins;
                          gameToSave.colorValue = currentColor.toARGB32();

                          await isar.writeTxn(() async {
                            await isar.boardGames.put(gameToSave);
                          });

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(isEditing ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.add),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedGames = List.from(_games)..sort((a, b) => 
      a.name.toLowerCase().compareTo(b.name.toLowerCase())
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ScoreDen'),
            const SizedBox(height: 2), // Tiny spacer between lines
            Text(
              AppLocalizations.of(context)!.gamesTracked(_games.length),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ), // Fades out the subtitle nicely
              ),
            ),
          ],
        ),
      ),
      body: sortedGames.isEmpty
        ? Center(child: Text(AppLocalizations.of(context)!.noGamesYet))
        : ListView.builder(
            itemCount: sortedGames.length,
            itemBuilder: (context, index) {
              final BoardGame game = sortedGames[index];
              final Color highlightColor = game.colorValue != null ? Color(game.colorValue!) : AppTheme.palette.first;

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
                                  ? AppLocalizations.of(context)!.highestScoretWins 
                                  : AppLocalizations.of(context)!.lowestScoretWins,
                              triggerMode: TooltipTriggerMode.tap, 
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: game.highestScoreWins
                                      ? AppTheme.highestWins
                                      : AppTheme.lowestWins,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  game.highestScoreWins 
                                      ? Icons.trending_up_rounded 
                                      : Icons.trending_down_rounded,
                                  size: 16,
                                  color: game.highestScoreWins
                                      ? AppTheme.highestWinsForeground
                                      : AppTheme.lowestWinsForeground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                // rgba(255, 255, 255, 0.07) -> Alpha hex 12
                                color: const Color(0x12FFFFFF), 
                                borderRadius: BorderRadius.circular(16), // Match standard chip radius
                              ),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${game.sessions.length} ',
                                      style: TextStyle(
                                        color: highlightColor,
                                        fontWeight: FontWeight.w600, // Slightly bolder for visibility
                                      ),
                                    ),
                                    TextSpan(
                                      text: AppLocalizations.of(context)!.sessions,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  style: const TextStyle(
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
                            tooltip: AppLocalizations.of(context)!.editGame,
                            onPressed: () {
                              _showGameDialog(existingGame: game);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppTheme.destructive,
                            ),
                            tooltip: AppLocalizations.of(context)!.deleteGame,
                            onPressed: () {
                              _showDeleteConfirmationDialog(game);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        context.go('/home/${game.id}/sessions');
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showGameDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
