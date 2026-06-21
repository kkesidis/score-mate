import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../main.dart'; // Imports the global 'isar' instance
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

  // Fetch all board games currently saved in Isar
  void _readGamesFromDatabase() async {
    final allGames = await isar.boardGames.where().findAll();
    setState(() {
      _games = allGames;
    });
  }

  // Automatically refresh the screen whenever the database changes
  void _listenToDatabaseChanges() {
    isar.boardGames.watchLazy().listen((_) {
      _readGamesFromDatabase();
    });
  }

  void _showAddGameDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool highestWins = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Board Game'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Game Name *',
                        hintText: 'e.g., Carcassonne',
                      ),
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

                    final newGame = BoardGame()
                      ..name = nameController.text.trim()
                      ..description = descController.text.trim().isEmpty ? null : descController.text.trim()
                      ..highestScoreWins = highestWins;

                    // WRITE TO ISAR: Transactions must run inside isar.writeTxn
                    await isar.writeTxn(() async {
                      await isar.boardGames.put(newGame);
                    });

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Add'),
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
                    trailing: Icon(
                      game.highestScoreWins ? Icons.arrow_upward : Icons.arrow_downward,
                      color: game.highestScoreWins ? Colors.green : Colors.blue,
                    ),
                    onTap: () {
                      // TODO: We will use this later to navigate to match sessions!
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGameDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}