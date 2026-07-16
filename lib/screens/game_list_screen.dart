import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../main.dart';
import '../models/board_game.dart';
import '../models/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/game_card.dart';
import '../widgets/game_form.dart';

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
            return GameForm(
              existingGame: existingGame,
              onSubmit: (gameToSave) async {
                await isar.writeTxn(() async {
                  await isar.boardGames.put(gameToSave);
                });

                if (context.mounted) Navigator.pop(context);
              }
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

              return GameCard(
                game: game,
                onSelect: () {
                  context.go('/home/${game.id}/sessions');
                },
                onEdit: () {
                  _showGameDialog(existingGame: game);
                },
                onDelete: () {
                  _showDeleteConfirmationDialog(game);
                },
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
