import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../main.dart'; // Imports our global 'isar' instance
import '../models/board_game.dart';

class MatchSessionsScreen extends StatefulWidget {
  final BoardGame game;

  const MatchSessionsScreen({super.key, required this.game});

  @override
  State<MatchSessionsScreen> createState() => _MatchSessionsScreenState();
}

class _MatchSessionsScreenState extends State<MatchSessionsScreen> {
  // We keep a local reference to the game object so we can refresh its data
  late BoardGame _currentGame;

  @override
  void initState() {
    super.initState();
    _currentGame = widget.game;
    _listenToDatabaseChanges();
  }

  // Set up a listener so if the parent game updates, this screen reflects it instantly
  void _listenToDatabaseChanges() {
    isar.boardGames.watchObjectLazy(_currentGame.id).listen((_) async {
      final updatedGame = await isar.boardGames.get(_currentGame.id);
      if (updatedGame != null && mounted) {
        setState(() {
          _currentGame = updatedGame;
        });
      }
    });
  }

  void _showAddSessionDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Match Session'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Session Name (Optional)',
              hintText: 'Defaults to "Match #${_currentGame.sessions.length + 1}"',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Determine the next match number based on current list length
                final nextMatchNumber = _currentGame.sessions.length + 1;

                // If the user typed nothing, default to "Match #X"
                final sessionName = nameController.text.trim().isEmpty 
                    ? 'Match #$nextMatchNumber' 
                    : nameController.text.trim();

                // 1. Create the new embedded session object
                final newSession = MatchSession()
                  ..name = sessionName
                  ..dateTime = DateTime.now(); // Automatically timestamp it right now

                // 2. Append this session into our game's session history list
                final updatedSessions = _currentGame.sessions.toList();
                updatedSessions.add(newSession);
                _currentGame.sessions = updatedSessions;

                // 3. Write the whole updated parent object back to Isar
                await isar.writeTxn(() async {
                  await isar.boardGames.put(_currentGame);
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Read the list from our dynamically updated local game variable
    final sessions = _currentGame.sessions;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentGame.name} - Sessions'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: sessions.isEmpty
          ? const Center(
              child: Text('No matches recorded for this game yet.'),
            )
          : ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              // REVERSE ORDER LOGIC: 
              // Instead of counting 0, 1, 2... from the front,
              // we count backwards from the last item in the list.
              final reversedIndex = sessions.length - 1 - index;
              final session = sessions[reversedIndex];
              
              // Use the true list placement index for the default naming fallback
              final sessionName = session.name ?? 'Match #${reversedIndex + 1}';
              
              final sessionDate = session.dateTime != null
                  ? '${session.dateTime!.day}/${session.dateTime!.month}/${session.dateTime!.year}'
                  : 'Unknown Date';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(sessionName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Played on: $sessionDate'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Future home of checking players/scores!
                  },
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSessionDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}