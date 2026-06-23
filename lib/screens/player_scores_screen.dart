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
                autofocus: true,
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

void _showPlayerHistorySheet(PlayerSession player, int playerIndexInDatabase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to resize when keyboards push up
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // StatefulBuilder allows the bottom sheet content to refresh in real-time 
        // when a single entry is edited or deleted without closing the sheet!
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            if (_game == null) return const SizedBox.shrink();
            
            // Re-fetch the fresh live player instance from our synced state
            final currentMatch = _game!.sessions[widget.sessionIndex];
            final livePlayer = currentMatch.players![playerIndexInDatabase];
            final scores = livePlayer.scores;

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
                    "${livePlayer.playerName}'s Score Log",
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
                              final reversedIndex = scores.length - 1 - index;
                              final entry = scores[reversedIndex];
                              
                              final valueString = (entry.value ?? 0) >= 0 
                                  ? '+${entry.value}' 
                                  : '${entry.value}';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: (entry.value ?? 0) >= 0 ? Colors.teal.shade50 : Colors.red.shade50,
                                  child: Text(
                                    '#${reversedIndex + 1}',
                                    style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  '$valueString points',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(entry.description ?? 'No note provided.'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // EDIT ENTRY BUTTON
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.teal, size: 20),
                                      onPressed: () {
                                        _showEditScoreEntryInlineDialog(
                                          playerIndexInDatabase, 
                                          reversedIndex, 
                                          entry,
                                          setSheetState,
                                        );
                                      },
                                    ),
                                    // DELETE ENTRY BUTTON
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () {
                                        _deleteSingleScoreEntry(
                                          playerIndexInDatabase, 
                                          reversedIndex,
                                          setSheetState,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // Edits a single round entry inside a player's score log array
  void _showEditScoreEntryInlineDialog(
    int playerIdx, 
    int scoreIdx, 
    ScoreEntry entry, 
    StateSetter setSheetState
  ) {
    final scoreController = TextEditingController(text: entry.value?.toString() ?? '0');
    final descController = TextEditingController(text: entry.description ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Round Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: scoreController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Points'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Note'),
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
                if (_game == null) return;
                final parsedValue = int.tryParse(scoreController.text.trim()) ?? 0;

                final sessionsList = _game!.sessions.toList();
                final currentMatch = sessionsList[widget.sessionIndex];
                final playersList = (currentMatch.players ?? <PlayerSession>[]).toList();
                
                final targetPlayer = playersList[playerIdx];
                final updatedScores = targetPlayer.scores.toList();

                // Mutate the entry at its historical position
                updatedScores[scoreIdx] = ScoreEntry()
                  ..value = parsedValue
                  ..description = descController.text.trim().isEmpty ? null : descController.text.trim();

                targetPlayer.scores = updatedScores;
                playersList[playerIdx] = targetPlayer;
                currentMatch.players = playersList;
                sessionsList[widget.sessionIndex] = currentMatch;
                _game!.sessions = sessionsList;

                await isar.writeTxn(() async {
                  await isar.boardGames.put(_game!);
                });

                // Update the sheet view state so the list changes instantly behind the dialog
                setSheetState(() {}); 

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Deletes a single specific round entry out of the player's list
  void _deleteSingleScoreEntry(int playerIdx, int scoreIdx, StateSetter setSheetState) async {
    if (_game == null) return;

    final sessionsList = _game!.sessions.toList();
    final currentMatch = sessionsList[widget.sessionIndex];
    final playersList = (currentMatch.players ?? <PlayerSession>[]).toList();
    
    final targetPlayer = playersList[playerIdx];
    final updatedScores = targetPlayer.scores.toList();

    // Pull out just this specific round entry
    updatedScores.removeAt(scoreIdx);

    targetPlayer.scores = updatedScores;
    playersList[playerIdx] = targetPlayer;
    currentMatch.players = playersList;
    sessionsList[widget.sessionIndex] = currentMatch;
    _game!.sessions = sessionsList;

    await isar.writeTxn(() async {
      await isar.boardGames.put(_game!);
    });

    // Instantly refresh the bottom sheet log display
    setSheetState(() {});
  }

  // Creates a fresh match session pre-populated with the current players
  void _startRematch(List<PlayerSession> currentPlayers) async {
    if (_game == null) return;

    // 1. Extract player names from the current session
    final existingNames = currentPlayers
        .map((p) => p.playerName?.trim())
        .where((name) => name != null && name.isNotEmpty)
        .cast<String>()
        .toList();

    if (existingNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one player before starting a rematch!')),
      );
      return;
    }

    // 2. Prepare the new match session structures
    final sessionsList = _game!.sessions.toList();
    final nextMatchNumber = sessionsList.length + 1;

    // Construct fresh clean player sheets with empty score arrays
    final cleanRematchPlayers = existingNames.map((name) {
      return PlayerSession()
        ..playerName = name
        ..scores = [];
    }).toList();

    final newMatchSession = MatchSession()
      ..name = 'Match #$nextMatchNumber'
      ..dateTime = DateTime.now()
      ..players = cleanRematchPlayers;

    // Isar expects items appended chronologically (newest at the end of the array)
    sessionsList.add(newMatchSession);
    _game!.sessions = sessionsList;

    // 3. Commit to the database
    await isar.writeTxn(() async {
      await isar.boardGames.put(_game!);
    });

    if (!mounted) return;

    // 4. NAVIGATION TRICK: Pop the current screen off the stack, and replace it
    // with a brand new viewport targeted at the last index of the updated list!
    final newSessionIndex = sessionsList.length - 1;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScoresScreen(
          gameId: widget.gameId,
          sessionIndex: newSessionIndex,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Started Match #$nextMatchNumber with existing players!')),
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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentMatchSession.name ?? 'Match Scores'),
            const SizedBox(height: 2), // Tiny spacer between lines
            Text(
              _game?.name ?? 'Board game',
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), // Fades out the subtitle nicely
              ),
            ),
          ],
        ),
        actions: [
          if (basePlayers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.replay),
              tooltip: 'Rematch (Same Players)',
              onPressed: () => _startRematch(basePlayers),
            ),
        ],
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
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
                        subtitle: Text(
                          'Score: $totalScore',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () {
                          _showAddScoreEntryDialog(playerSession, trueIndexInDatabase);
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.history, color: Colors.blueGrey),
                              tooltip: 'View Score History',
                              onPressed: () {
                                _showPlayerHistorySheet(playerSession, trueIndexInDatabase);
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
                      Divider(
                        height: 1, 
                        thickness: 0.5,
                        color: Colors.teal.shade800,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: Row(
                          children: [
                            // FIX: Swapped calendar icon for a round/layers icon to match the text context
                            Icon(
                              Icons.layers_outlined, 
                              size: 14, 
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$totalRounds rounds logged',
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
        onPressed: _showAddPlayerDialog, // Floating Action Button now strictly registers new names
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}