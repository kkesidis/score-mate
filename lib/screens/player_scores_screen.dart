import 'package:flutter/material.dart';
import '../main.dart';
import '../models/board_game.dart';

enum ScoreOp { add, subtract }

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

  void _showAddPlayerDialog() {
    final nameController = TextEditingController();

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
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Player Name',
                      hintText: 'e.g., Alice',
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
                        child: Text('Add'),
                      ),
                    ]
                  ),
                ]
              )
            );
          }
        );
      }
    );
  }

  void _showAddScoreEntryDialog(PlayerSession player, int playerIndexInDatabase) {
    final scoreController = TextEditingController();
    final descController = TextEditingController();

    final int currentScore = player.scores.fold(0, (sum, item) => sum + (item.value ?? 0));
    
    ScoreOp currentOp = ScoreOp.add;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            // Re-render header when user types
            scoreController.addListener(() {
              if (context.mounted) setModalState(() {});
            });

            // Enforce absolute/positive values only in our parsing calculations
            final rawValue = int.tryParse(scoreController.text.trim()) ?? 0;
            final parsedValue = rawValue.abs(); // Enforces values >= 0
            
            // Flip math preview depending on selector status
            final finalValueModifier = currentOp == ScoreOp.add ? parsedValue : -parsedValue;
            final newScore = currentScore + finalValueModifier;

            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TITLE & CALCULATION HEADER
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.playerName ?? 'Player',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current score: $currentScore → $newScore',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. THE OPERATION CONTROLLER (ADD / SUBTRACT)
                  SegmentedButton<ScoreOp>(
                    segments: const <ButtonSegment<ScoreOp>>[
                      ButtonSegment<ScoreOp>(
                        value: ScoreOp.add,
                        label: Text('Add'),
                        icon: Icon(Icons.add),
                      ),
                      ButtonSegment<ScoreOp>(
                        value: ScoreOp.subtract,
                        label: Text('Subtract'),
                        icon: Icon(Icons.remove),
                      ),
                    ],
                    selected: <ScoreOp>{currentOp},
                    onSelectionChanged: (Set<ScoreOp> newSelection) {
                      setModalState(() {
                        currentOp = newSelection.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: Colors.teal.withValues(alpha: 0.2),
                      selectedForegroundColor: Colors.teal.shade300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // 3. STRICT UNSIGNED NUMBER FIELD
                  TextField(
                    controller: scoreController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Points',
                      hintText: 'e.g., 5',
                      prefixIcon: Icon(
                        currentOp == ScoreOp.add 
                            ? Icons.add 
                            : Icons.remove,
                      ),
                    ),
                    // Standard unsigned number keyboard layout (no negative symbols needed!)
                    keyboardType: TextInputType.number, 
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Note / Description (Optional)',
                      hintText: 'e.g., Round 1, Penalty',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Quick Select',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [5, 10, 15, 20].map((int value) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _buildEqualWidthChip(value, currentOp, scoreController, setModalState),
                        ),
                      );
                    }).toList(),
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
                          if (_game == null || scoreController.text.trim().isEmpty) return;
                          
                          final sessionsList = _game!.sessions.toList();
                          final currentMatchSession = sessionsList[widget.sessionIndex];
                          final playersList = (currentMatchSession.players ?? <PlayerSession>[]).toList();

                          // Commit the correct positive/negative flag variation directly to DB
                          final newScoreEntry = ScoreEntry()
                            ..value = finalValueModifier
                            ..description = descController.text.trim().isEmpty ? null : descController.text.trim();

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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEqualWidthChip(
    int value, 
    ScoreOp currentOp, 
    TextEditingController scoreController, 
    StateSetter setModalState
  ) {
    final String prefix = currentOp == ScoreOp.add ? '+' : '-';
    final isAdd = currentOp == ScoreOp.add;

    return ActionChip(
      // Enforces centered alignment inside the expanded boundaries
      label: Center(
        child: Text(
          '$prefix$value',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      side: BorderSide(
        color: isAdd ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
      ),
      onPressed: () {
        setModalState(() {
          scoreController.text = value.toString();
          scoreController.selection = TextSelection.fromPosition(
            TextPosition(offset: scoreController.text.length),
          );
        });
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
            final livePlayer = currentMatch.players[playerIndexInDatabase];
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