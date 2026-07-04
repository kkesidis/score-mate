import 'package:flutter/material.dart';
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

  void _showSessionDialog({int? actualIndex}) {
    final nameController = TextEditingController();
    final isEditing = actualIndex != null;

    if (isEditing) {
      final existingSession = _currentGame.sessions[actualIndex];
      nameController.text = existingSession.name ?? '';
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
                    isEditing ? 'Rename Match Session' : 'New Match Session',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: isEditing ? 'Session Name' : 'Session Name (Optional)',
                      hintText: isEditing 
                        ? null 
                        : 'Defaults to "Match #${_currentGame.sessions.length + 1}"',
                    ),
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
                          final textInput = nameController.text.trim();
                
                          // Edit guard: don't let them clear out an existing name to empty string
                          if (isEditing && textInput.isEmpty) return;

                          final updatedSessions = _currentGame.sessions.toList();

                          if (isEditing) {
                            // 2A. EXECUTE TRANSACTION EDIT UPDATE ROUTINE
                            updatedSessions[actualIndex].name = textInput;
                          } else {
                            // 2B. EXECUTE TRANSACTION CREATE INSERTION ROUTINE
                            final nextMatchNumber = _currentGame.sessions.length + 1;
                            final sessionName = textInput.isEmpty ? 'Match #$nextMatchNumber' : textInput;

                            final newSession = MatchSession()
                              ..name = sessionName
                              ..dateTime = DateTime.now();

                            updatedSessions.add(newSession);
                          }

                          // 3. PERSIST THE SESSION LIST ARRAY STATE CHUNK
                          _currentGame.sessions = updatedSessions;
                          await isar.writeTxn(() async {
                            await isar.boardGames.put(_currentGame);
                          });

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(isEditing ? 'Save' : 'Add'),
                      ),
                    ]
                  ),
                ],
              )
            );
          }
        );
      }
    );
  }

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
                              _showSessionDialog(actualIndex: reversedIndex);
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
        onPressed: _showSessionDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}