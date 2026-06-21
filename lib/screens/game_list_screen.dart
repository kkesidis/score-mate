import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../main.dart'; 
import '../models/board_game.dart';

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
          content: Text('Are you sure you want to delete "${game.name}"? This will permanently remove all associated match sessions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close the dialog, do nothing
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
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

  // SHARED DIALOG: Works for both adding a new game or editing an existing one
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Board Game' : 'Add New Board Game'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Game Name *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description (Optional)'),
                    ),
                    const SizedBox(height: 15),
                    SwitchListTile(
                      title: const Text('Highest Score Wins'),
                      subtitle: Text(highestWins ? 'Standard scoring' : 'Lowest score wins'),
                      value: highestWins,
                      onChanged: (bool value) {
                        setDialogState(() {
                          highestWins = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    // If editing, reuse the old object so Isar overwrites the exact ID slot
                    final gameToSave = isEditing ? existingGame : BoardGame();
                    
                    gameToSave.name = nameController.text.trim();
                    gameToSave.description = descController.text.trim().isEmpty ? null : descController.text.trim();
                    gameToSave.highestScoreWins = highestWins;

                    await isar.writeTxn(() async {
                      await isar.boardGames.put(gameToSave);
                    });

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScoreMate - Board Games'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _games.isEmpty
        ? const Center(child: Text('No games added yet. Tap + to begin!'))
        : ListView.builder(
            itemCount: _games.length,
            itemBuilder: (context, index) {
              final game = _games[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(game.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(game.description ?? 'No description provided.'),
                  // We stack our scoring direction icon AND our delete button side-by-side using a Row
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Keep the row tightly packed
                    children: [
                      Icon(
                        game.highestScoreWins ? Icons.arrow_upward : Icons.arrow_downward,
                        color: game.highestScoreWins ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(width: 8), // A little spacing between the icons
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                        tooltip: 'Edit Game', // Displays a hint on desktop hover
                        onPressed: () {
                          _showGameDialog(existingGame: game); // Opens edit form
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Delete Game', // Displays a hint on desktop hover
                        onPressed: () {
                          // Trigger the confirmation alert box
                          _showDeleteConfirmationDialog(game);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGameDialog(), // Calls dialog without arguments (Defaults to Add Mode)
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}