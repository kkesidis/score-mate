import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../main.dart';
import '../models/board_game.dart';
import '../models/app_theme.dart';
import '../components/stylized_card.dart';
import '../helpers/custom_fab_location.dart';
import 'package:go_router/go_router.dart';

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
          title: const Text('Delete Board Game'),
          content: Text(
            'Are you sure you want to delete "${game.name}"? This will permanently remove all associated match sessions.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context), // Close the dialog, do nothing
              child: const Text('Cancel'),
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
              child: const Text('Delete'),
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
        const SnackBar(content: Text('Game deleted successfully')),
      );
    }
  }

  void _showGameDialog({BoardGame? existingGame}) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool highestWins = true;

    // If we are editing, pre-fill the form fields with the current values
    final isEditing = existingGame != null;
    if (isEditing) {
      nameController.text = existingGame.name;
      descController.text = existingGame.description ?? '';
      highestWins = existingGame.highestScoreWins;
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
                    isEditing ? 'Edit Game' : 'New Game',
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
                    decoration: const InputDecoration(
                      labelText: 'Game Name *',
                      hintText: 'e.g. Wingspan',
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: descController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Short description of the game..',
                    ),
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
                                  'Highest Wins',
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
                                  'Lowest Wins',
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
                        child: const Text('Cancel'),
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
                          gameToSave.description =
                              descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim();
                          gameToSave.highestScoreWins = highestWins;

                          await isar.writeTxn(() async {
                            await isar.boardGames.put(gameToSave);
                          });

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(isEditing ? 'Save' : 'Add'),
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
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ScoreDen'),
            const SizedBox(height: 2), // Tiny spacer between lines
            Text(
              '${_games.length} games tracked',
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
          ? const Center(child: Text('No games added yet. Tap + to begin!'))
          : ListView.builder(
              itemCount: sortedGames.length,
              itemBuilder: (context, index) {
                final game = sortedGames[index];

                return StylizedCard(
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
                        subtitle: Text(
                          game.description ?? '-',
                          style: const TextStyle(color: AppTheme.mutedForeground),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppTheme.primary,
                              ),
                              tooltip: 'Edit Game',
                              onPressed: () {
                                _showGameDialog(existingGame: game);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.destructive,
                              ),
                              tooltip: 'Delete Game',
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

                      const SizedBox(height: 4),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        child: Row(
                          children: [
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
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600, // Slightly bolder for visibility
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'matches',
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

                            const SizedBox(width: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                // Evaluates your custom win condition themes built earlier
                                color: game.highestScoreWins
                                    ? AppTheme.highestWins
                                    : AppTheme.lowestWins,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // Prevents chip from stretching full-width
                                children: [
                                  Icon(
                                    // Dynamic icons mapping to the ruleset structure
                                    game.highestScoreWins 
                                        ? Icons.trending_up_rounded 
                                        : Icons.trending_down_rounded,
                                    size: 14,
                                    color: game.highestScoreWins
                                        ? AppTheme.highestWinsForeground
                                        : AppTheme.lowestWinsForeground,
                                  ),
                                  const SizedBox(width: 6), // Crisp spacing between icon and labels
                                  Text(
                                    game.highestScoreWins ? 'Highest score wins' : 'Lowest score wins',
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
                    ],
                  ),
                );
              },
            ),
      floatingActionButtonLocation: const CustomFabLocation(
        offsetY: 80.0, 
        offsetX: 6.0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showGameDialog(), // Calls dialog without arguments (Defaults to Add Mode)
        child: const Icon(Icons.add),
      ),
    );
  }
}
