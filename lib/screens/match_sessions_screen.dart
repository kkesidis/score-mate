import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../main.dart'; // Imports our global 'isar' instance
import '../models/board_game.dart';
import 'player_scores_screen.dart';

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

  // 1. EDIT DIALOG: Pre-fills with the selected match name to let users rename it
  void _showEditSessionDialog(int actualIndex) {
    final nameController = TextEditingController();
    final session = _currentGame.sessions[actualIndex];
    nameController.text = session.name ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Match Session'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Session Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                // Grab the list, update the name at this index slot, then pass it back
                final updatedSessions = _currentGame.sessions.toList();
                updatedSessions[actualIndex].name = nameController.text.trim();
                _currentGame.sessions = updatedSessions;

                await isar.writeTxn(() async {
                  await isar.boardGames.put(_currentGame);
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // 2. DELETE CONFIRMATION BARRIER
  void _showDeleteConfirmationDialog(int actualIndex, String sessionName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Match Session'),
          content: Text('Are you sure you want to delete "$sessionName"? This will erase all player scores for this match.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _deleteSession(actualIndex);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // 3. ACTUAL ISAR DELETE TRANSACTION
  void _deleteSession(int actualIndex) async {
    final updatedSessions = _currentGame.sessions.toList();
    updatedSessions.removeAt(actualIndex); // Pull it out of the array slot
    _currentGame.sessions = updatedSessions;

    await isar.writeTxn(() async {
      await isar.boardGames.put(_currentGame);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match session removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read the list from our dynamically updated local game variable
    final sessions = _currentGame.sessions;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sessions'),
            const SizedBox(height: 2), // Tiny spacer between lines
            Text(
              _currentGame.name,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), // Fades out the subtitle nicely
              ),
            ),
          ],
        ),
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

              final sessionPlayers = session.players ?? [];

              String winnerText = 'No winner yet';
              if (sessionPlayers.isNotEmpty) {
                final highestScoreWins = _currentGame.highestScoreWins;
                
                // Create a map matching each player to their calculated total score
                final playerScores = <PlayerSession, int>{};
                for (var player in sessionPlayers) {
                  final total = player.scores.fold(0, (sum, item) => sum + (item.value ?? 0));
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
                    .map((entry) => entry.key.playerName ?? 'Unknown')
                    .toList();

                // Format the output string depending on if it's a solo victory or a tie!
                if (winners.length > 1) {
                  winnerText = 'Tie: ${winners.join(', ')} ($winningScore)';
                } else {
                  winnerText = 'Winner: ${winners.first} ($winningScore)';
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        sessionName, 
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        winnerText,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                            tooltip: 'Rename Session',
                            onPressed: () {
                              _showEditSessionDialog(reversedIndex);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            tooltip: 'Delete Session',
                            onPressed: () {
                              _showDeleteConfirmationDialog(reversedIndex, sessionName);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerScoresScreen(
                              gameId: _currentGame.id,
                              sessionIndex: reversedIndex,
                            ),
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
                          Icon(
                            Icons.calendar_today_outlined, 
                            size: 14, 
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Played on: $sessionDate',
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
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.people_outline, 
                            size: 14, 
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${sessionPlayers.length} players',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
        onPressed: _showAddSessionDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}