import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../main.dart'; 
import '../models/board_game.dart';
import 'match_sessions_screen.dart';

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
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.0, // Keyboard safety
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Board Game' : 'Add New Board Game',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),

                  const SizedBox(height: 10),

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

                  const SizedBox(height: 24),

                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 8.0,       // Horizontal gap between buttons when side-by-side
                    overflowSpacing: 8.0, // Vertical gap between buttons if they drop/stack vertically!
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
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
                    ]
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScoreMate'),
      ),
      body: _games.isEmpty
        ? const Center(child: Text('No games added yet. Tap + to begin!'))
        : ListView.builder(
            itemCount: _games.length,
            itemBuilder: (context, index) {
              final game = _games[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        game.name, 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                      subtitle: Text(
                        game.description ?? '-',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                            tooltip: 'Edit Game',
                            onPressed: () {
                              _showGameDialog(existingGame: game);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            tooltip: 'Delete Game',
                            onPressed: () {
                              _showDeleteConfirmationDialog(game);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchSessionsScreen(game: game),
                          ),
                        );
                      },
                    ),

                    Divider(
                      height: 1, 
                      thickness: 0.5,
                      color: Colors.teal.shade800,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      child: Row(
                        children: [
                          Text(
                            '${game.sessions.length} matches played',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '|',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          
                          Text(
                            game.highestScoreWins ? 'Highest score wins' : 'Lowest score wins',
                            style: TextStyle(
                              fontSize: 12,
                              color: game.highestScoreWins ? Colors.green.shade600 : Colors.blue.shade600,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGameDialog(), // Calls dialog without arguments (Defaults to Add Mode)
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}