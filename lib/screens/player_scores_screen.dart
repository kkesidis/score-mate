import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../main.dart';
import '../models/board_game.dart';

class PlayerScoresScreen extends StatefulWidget {
  final int gameId;
  final int sessionIndex; 

  const PlayerScoresScreen({
    super.key,
    required this.gameId,
    required this.sessionIndex,
  });

  @override
  State<PlayerScoresScreen> createState() => _PlayerScoresScreenState();
}

class _PlayerScoresScreenState extends State<PlayerScoresScreen> {
  BoardGame? _game;

  @override
  void initState() {
    super.initState();
    _loadGameData();
    _listenToDatabaseChanges();
  }

  void _loadGameData() async {
    final game = await isar.boardGames.get(widget.gameId);
    if (mounted) {
      setState(() {
        _game = game;
      });
    }
  }

  void _listenToDatabaseChanges() {
    isar.boardGames.watchObjectLazy(widget.gameId).listen((_) {
      _loadGameData();
    });
  }

  // Combines all historical values inside the scores array
  int _calculateTotalScore(PlayerSession playerSession) {
    return playerSession.scores.fold(0, (sum, item) => sum + (item.value ?? 0));
  }

  // 1. DIALOG: Adds a completely brand new player to the match session
  void _showAddPlayerDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Player to Match'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Player Name',
              hintText: 'e.g., Alice',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_game == null || nameController.text.trim().isEmpty) return;

                final sessionsList = _game!.sessions.toList();
                final currentMatchSession = sessionsList[widget.sessionIndex];
                final playersList = (currentMatchSession.players ?? <PlayerSession>[]).toList();

                // Create a completely new player profile starting with zero entries
                final newPlayerSession = PlayerSession()
                  ..playerName = nameController.text.trim()
                  ..scores = [];

                playersList.add(newPlayerSession);

                currentMatchSession.players = playersList;
                sessionsList[widget.sessionIndex] = currentMatchSession;
                _game!.sessions = sessionsList;

                await isar.writeTxn(() async {
                  await isar.boardGames.put(_game!);
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // 2. DIALOG: Appends a new round/score point entry onto a chosen player
  void _showAddScoreEntryDialog(PlayerSession player, int playerIndexInDatabase) {
    final scoreController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Log Score for ${player.playerName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: scoreController,
                decoration: const InputDecoration(
                  labelText: 'Points to Add',
                  hintText: 'e.g., 10 or -2',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Note / Description (Optional)',
                  hintText: 'e.g., Round 1, Longest Road',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_game == null || scoreController.text.trim().isEmpty) return;
                final parsedValue = int.tryParse(scoreController.text.trim()) ?? 0;

                final sessionsList = _game!.sessions.toList();
                final currentMatchSession = sessionsList[widget.sessionIndex];
                final playersList = (currentMatchSession.players ?? <PlayerSession>[]).toList();

                // Build a standalone entry record chunk
                final newScoreEntry = ScoreEntry()
                  ..value = parsedValue
                  ..description = descController.text.trim().isEmpty ? null : descController.text.trim();

                // Append it securely to this player's active timeline profile array
                final targetPlayer = playersList[playerIndexInDatabase];
                final updatedScores = targetPlayer.scores.toList();
                updatedScores.add(newScoreEntry);
                
                targetPlayer.scores = updatedScores;
                playersList[playerIndexInDatabase] = targetPlayer;

                currentMatchSession.players = playersList;
                sessionsList[widget.sessionIndex] = currentMatchSession;
                _game!.sessions = sessionsList;

                await isar.writeTxn(() async {
                  await isar.boardGames.put(_game!);
                });

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Log Score'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int actualIndex, String playerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Player'),
          content: Text('Are you sure you want to remove "$playerName" from this match? This will permanently delete all their logged scores for this session.'),
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
                _deletePlayer(actualIndex);
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _deletePlayer(int playerIndexInList) async {
    if (_game == null) return;
    
    final sessionsList = _game!.sessions.toList();
    final currentMatchSession = sessionsList[widget.sessionIndex];
    final playersList = (currentMatchSession.players ?? <PlayerSession>[]).toList();

    playersList.removeAt(playerIndexInList);

    currentMatchSession.players = playersList;
    sessionsList[widget.sessionIndex] = currentMatchSession;
    _game!.sessions = sessionsList;

    await isar.writeTxn(() async {
      await isar.boardGames.put(_game!);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Player removed from match')),
      );
    }
  }

  void _showPlayerHistorySheet(PlayerSession player) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final scores = player.scores;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${player.playerName}'s Score Log",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 10),
              scores.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No scores logged yet for this match.')),
                    )
                  : Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: scores.length,
                      itemBuilder: (context, index) {
                        // REVERSE ORDER LOGIC:
                        // Counts backwards from the last item to the first
                        final reversedIndex = scores.length - 1 - index;
                        final entry = scores[reversedIndex];
                        
                        final valueString = (entry.value ?? 0) >= 0 
                            ? '+${entry.value}' 
                            : '${entry.value}';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (entry.value ?? 0) >= 0 ? Colors.teal.shade50 : Colors.red.shade50,
                            child: Text(
                              'R${reversedIndex + 1}', // Keeps the original round number label correct
                              style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            '$valueString points',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(entry.description ?? 'No note provided.'),
                        );
                      },
                    ),
                  ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentMatchSession = _game!.sessions[widget.sessionIndex];
    final basePlayers = currentMatchSession.players ?? <PlayerSession>[];
    
    final List<MapEntry<int, PlayerSession>> indexedPlayers = basePlayers.asMap().entries.toList();

    // Sort leaderboard by accumulated score total totals
    indexedPlayers.sort((a, b) {
      final totalA = _calculateTotalScore(a.value);
      final totalB = _calculateTotalScore(b.value);
      if (_game!.highestScoreWins) {
        return totalB.compareTo(totalA); 
      } else {
        return totalA.compareTo(totalB); 
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(currentMatchSession.name ?? 'Match Scores'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: indexedPlayers.isEmpty
          ? const Center(child: Text('No players added yet. Tap + to add participants!'))
          : ListView.builder(
              itemCount: indexedPlayers.length,
              itemBuilder: (context, index) {
                final entry = indexedPlayers[index];
                final trueIndexInDatabase = entry.key;
                final playerSession = entry.value;
                
                final playerName = playerSession.playerName ?? 'Unknown';
                final totalScore = _calculateTotalScore(playerSession);
                final rank = index + 1;

                // Show a mini tally of how many point entries they have logged total
                final totalRounds = playerSession.scores.length;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rank == 1 ? Colors.amber : Colors.teal.shade100,
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rank == 1 ? Colors.black : Colors.teal.shade900,
                        ),
                      ),
                    ),
                    title: Text(playerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Total Score: $totalScore ($totalRounds entries logged)'),
                    
                    // NEW BEHAVIOR: Tapping the player card appends a new score entry point slot
                    onTap: () {
                      _showAddScoreEntryDialog(playerSession, trueIndexInDatabase);
                    },
                    
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // NEW: History Log Button
                        IconButton(
                          icon: const Icon(Icons.history, color: Colors.blueGrey),
                          tooltip: 'View Score History',
                          onPressed: () {
                            _showPlayerHistorySheet(playerSession);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Remove Player',
                          onPressed: () {
                            _showDeleteConfirmationDialog(trueIndexInDatabase, playerName);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlayerDialog, // Floating Action Button now strictly registers new names
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}