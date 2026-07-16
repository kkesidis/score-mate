import 'package:flutter/material.dart';
import '../main.dart';
import '../models/board_game.dart';
import '../models/app_theme.dart';
import '../widgets/stylized_card.dart';
import '../l10n/app_localizations.dart';
import '../widgets/color_picker_field.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/player_card.dart';
import '../widgets/player_score_history.dart';

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

  void _showPlayerFormBottomSheet({int? playerIndexInDatabase}) {
    final nameController = TextEditingController();
    final bool isEditing = playerIndexInDatabase != null;
    Color currentColor = AppTheme.palette.first;

    // 1. SETUP WORKFLOW MODE CONDITIONS
    if (isEditing) {
      if (_game == null) return;
      final currentMatchSession = _game!.sessions[widget.sessionIndex];
      final targetPlayer = currentMatchSession.players[playerIndexInDatabase];
      nameController.text = targetPlayer.playerName ?? AppLocalizations.of(context)!.genericPlayerName;

      final inheritedColor = targetPlayer.playerColorValue ?? _game?.colorValue;
      currentColor = inheritedColor != null ? Color(inheritedColor) : currentColor;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24.0,
                left: 16.0,
                right: 16.0,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    24.0, // Keyboard safety
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // Stretches elements uniformly
                children: [
                  Text(
                    isEditing ? AppLocalizations.of(context)!.renamePlayer : AppLocalizations.of(context)!.addPlayer,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.playerNameLabel,
                      hintText: AppLocalizations.of(context)!.playerNameHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ColorPickerField(
                    initialColor: currentColor,
                    onColorSelected: (newColor) {
                      currentColor = newColor; 
                    },
                  ),

                  const SizedBox(height: 24),

                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 8.0,
                    overflowSpacing: 8.0,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.primaryForeground,
                        ),
                        onPressed: () async {
                          final textInput = nameController.text.trim();
                          if (_game == null || textInput.isEmpty) return;

                          final sessionsList = _game!.sessions.toList();
                          final currentMatchSession =
                              sessionsList[widget.sessionIndex];
                          final playersList =
                              (currentMatchSession.players ?? <PlayerSession>[])
                                  .toList();

                          if (isEditing) {
                            // 2A. MUTATE THE EXISTING SLOT
                            final targetPlayer =
                                playersList[playerIndexInDatabase];
                            targetPlayer.playerName = textInput;
                            targetPlayer.playerColorValue = currentColor.toARGB32();
                            playersList[playerIndexInDatabase] = targetPlayer;
                          } else {
                            // 2B. APPEND A NEW PLAYER PROFILE
                            final newPlayerSession = PlayerSession()
                              ..playerName = textInput
                               ..playerColorValue = currentColor.toARGB32()
                              ..scores = [];
                            playersList.add(newPlayerSession);
                          }

                          currentMatchSession.players = playersList;
                          sessionsList[widget.sessionIndex] =
                              currentMatchSession;
                          _game!.sessions = sessionsList;

                          await isar.writeTxn(() async {
                            await isar.boardGames.put(_game!);
                          });

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(isEditing ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.add),
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

  void _showScoreEntryFormBottomSheet(
    PlayerSession player,
    int playerIndexInDatabase, {
    int? scoreIndex, // Optional named param for editing
    StateSetter? setSheetState, // Optional named param for history panels
  }) {
    final bool isEditing = scoreIndex != null;
    final ScoreEntry? existingEntry = isEditing
        ? player.scores[scoreIndex]
        : null;

    // Calculate base score excluding the entry being updated (if editing)
    int currentScore = 0;
    for (int i = 0; i < player.scores.length; i++) {
      if (isEditing && i == scoreIndex) continue;
      currentScore += player.scores[i].value ?? 0;
    }

    final scoreController = TextEditingController();
    final descController = TextEditingController(
      text: existingEntry?.description ?? '',
    );

    ScoreOp currentOp = ScoreOp.add;

    if (isEditing && existingEntry != null) {
      final int entryValue = existingEntry.value ?? 0;
      currentOp = entryValue < 0 ? ScoreOp.subtract : ScoreOp.add;
      scoreController.text = entryValue.abs().toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Re-render header calculations dynamically as text is typed
            scoreController.addListener(() {
              if (context.mounted) setModalState(() {});
            });

            final rawValue = int.tryParse(scoreController.text.trim()) ?? 0;
            final parsedValue = rawValue.abs();

            final finalValueModifier = currentOp == ScoreOp.add
                ? parsedValue
                : -parsedValue;
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
                        isEditing
                            ? AppLocalizations.of(context)!.editScore(player.playerName ?? AppLocalizations.of(context)!.genericPlayerName)
                            : (player.playerName ?? AppLocalizations.of(context)!.genericPlayerName),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context)!.scoreChange}: $currentScore → $newScore',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. THE OPERATION CONTROLLER (ADD / SUBTRACT)
                  SegmentedButton<ScoreOp>(
                    segments: <ButtonSegment<ScoreOp>>[
                      ButtonSegment<ScoreOp>(
                        value: ScoreOp.add,
                        label: Text(AppLocalizations.of(context)!.add),
                        icon: const Icon(Icons.add),
                      ),
                      ButtonSegment<ScoreOp>(
                        value: ScoreOp.subtract,
                        label: Text(AppLocalizations.of(context)!.subtract),
                        icon: const Icon(Icons.remove),
                      ),
                    ],
                    selected: <ScoreOp>{currentOp},
                    onSelectionChanged: (Set<ScoreOp> newSelection) {
                      setModalState(() {
                        currentOp = newSelection.first;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // 3. MAIN INPUT FIELD
                  TextField(
                    controller: scoreController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.pointsLabel,
                      hintText: AppLocalizations.of(context)!.pointsHint,
                      prefixIcon: Icon(
                        currentOp == ScoreOp.add ? Icons.add : Icons.remove,
                        color: currentOp == ScoreOp.add
                            ? AppTheme.accent
                            : AppTheme.destructive,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.pointDescriptionLabel,
                      hintText: AppLocalizations.of(context)!.pointDescriptionHint,
                      prefixIcon: const Icon(Icons.notes_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // 4. QUICK SELECT CHIPS
                  Text(
                    AppLocalizations.of(context)!.quickSelect,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [5, 10, 15, 20].map((int value) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _buildEqualWidthChip(
                            value,
                            currentOp,
                            scoreController,
                            setModalState,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 5. ACTION BUTTON CONTROLS FOOTER
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 8.0,
                    overflowSpacing: 8.0,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.primaryForeground,
                        ),
                        onPressed: () async {
                          if (_game == null ||
                              scoreController.text.trim().isEmpty) {
                            return;
                          }

                          final sessionsList = _game!.sessions.toList();
                          final currentMatchSession =
                              sessionsList[widget.sessionIndex];
                          final playersList =
                              (currentMatchSession.players ?? <PlayerSession>[])
                                  .toList();

                          // Instantiate updated score details
                          final targetScoreEntry = ScoreEntry()
                            ..value = finalValueModifier
                            ..description = descController.text.trim().isEmpty
                                ? null
                                : descController.text.trim();

                          final targetPlayer =
                              playersList[playerIndexInDatabase];
                          final updatedScores = targetPlayer.scores.toList();

                          if (isEditing) {
                            // Mutate the existing element at its index placement
                            updatedScores[scoreIndex] = targetScoreEntry;
                          } else {
                            // Append directly to history
                            updatedScores.add(targetScoreEntry);
                          }

                          targetPlayer.scores = updatedScores;
                          playersList[playerIndexInDatabase] = targetPlayer;

                          currentMatchSession.players = playersList;
                          sessionsList[widget.sessionIndex] =
                              currentMatchSession;
                          _game!.sessions = sessionsList;

                          await isar.writeTxn(() async {
                            await isar.boardGames.put(_game!);
                          });

                          // Fire localized view updates back up to the calling history panel
                          if (setSheetState != null) {
                            setSheetState(() {});
                          }

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(isEditing ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.logScore),
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
    StateSetter setModalState,
  ) {
    final String prefix = currentOp == ScoreOp.add ? '+' : '-';
    final isAdd = currentOp == ScoreOp.add;

    return ActionChip(
      // Enforces centered alignment inside the expanded boundaries
      label: Center(
        child: Text(
          '$prefix$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            // Switches typography colors depending on the operational math state
            color: isAdd 
                ? AppTheme.secondaryForeground 
                : AppTheme.destructiveForeground,
          ),
        ),
      ),
      // Solid structural background injection based on the operation type
      backgroundColor: isAdd 
          ? AppTheme.secondary 
          : AppTheme.destructive,
      // We completely strip the border side tinting line since we are using solid fills
      side: BorderSide.none, 
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
          title: Text(AppLocalizations.of(context)!.removePlayerTitle),
          content: Text(
            AppLocalizations.of(context)!.removePlayerDescription(playerName)
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.destructive,
                foregroundColor: AppTheme.destructiveForeground,
              ),
              onPressed: () {
                _deletePlayer(actualIndex);
                Navigator.pop(context); // Close the dialog
              },
              child: Text(AppLocalizations.of(context)!.remove),
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
    final playersList = (currentMatchSession.players ?? <PlayerSession>[])
        .toList();

    playersList.removeAt(playerIndexInList);

    currentMatchSession.players = playersList;
    sessionsList[widget.sessionIndex] = currentMatchSession;
    _game!.sessions = sessionsList;

    await isar.writeTxn(() async {
      await isar.boardGames.put(_game!);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.playerRemoved)),
      );
    }
  }

  void _showPlayerHistorySheet(
    PlayerSession player,
    int playerIndexInDatabase,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to resize when keyboards push up
      useRootNavigator: true,
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

            return PlayerScoreHistory(
              player: livePlayer,
              onEdit: (index) {
                _showScoreEntryFormBottomSheet(
                  livePlayer, // 1. Required positional player data object
                  playerIndexInDatabase, // 2. Required positional target database index slot
                  scoreIndex: index, // Named parameter identifying which entry is targeted
                  setSheetState: setSheetState, // Named parameter callback to force live data rebuilds below
                );
              },
              onDelete: (index) {
                _deleteSingleScoreEntry(
                  playerIndexInDatabase,
                  index,
                  setSheetState,
                );
              }
            );
          },
        );
      },
    );
  }

  // Deletes a single specific round entry out of the player's list
  void _deleteSingleScoreEntry(
    int playerIdx,
    int scoreIdx,
    StateSetter setSheetState,
  ) async {
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.addPlayersBeforeRematch),
        ),
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
      ..name = AppLocalizations.of(context)!.indexedSession(nextMatchNumber)
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
      SnackBar(
        content: Text(AppLocalizations.of(context)!.startedRematch(nextMatchNumber)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentMatchSession = _game!.sessions[widget.sessionIndex];
    final basePlayers = currentMatchSession.players ?? <PlayerSession>[];
    final sessionName = currentMatchSession.name?.isEmpty ?? true ? AppLocalizations.of(context)!.indexedSession(widget.sessionIndex + 1) : currentMatchSession.name!;
    int? topPlayerIndex;

    final List<MapEntry<int, PlayerSession>> indexedPlayers = basePlayers
        .asMap()
        .entries
        .toList();

    if (indexedPlayers.isNotEmpty) {
      final MapEntry<int, PlayerSession> topPlayerEntry = indexedPlayers.reduce((currentMax, next) {
        return next.value.totalScore > currentMax.value.totalScore ? next : currentMax;
      });

      topPlayerIndex = topPlayerEntry.key;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sessionName),
            const SizedBox(height: 2), // Tiny spacer between lines
            Text(
              _game?.name ?? AppLocalizations.of(context)!.boardGame,
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
        additionalActions: [
          if (basePlayers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.replay),
              tooltip: AppLocalizations.of(context)!.rematch,
              onPressed: () => _startRematch(basePlayers),
            ),
        ],
      ),
      body: indexedPlayers.isEmpty
        ? Center(child: Text(AppLocalizations.of(context)!.noPlayersAddedYet),)
        : ListView.builder(
            itemCount: indexedPlayers.length,
            itemBuilder: (context, index) {
              final entry = indexedPlayers[index];
              final trueIndexInDatabase = entry.key;
              final playerSession = entry.value;

              final playerName = playerSession.playerName ?? AppLocalizations.of(context)!.genericPlayerName;
              final isWinner = topPlayerIndex == index;

              return PlayerCard(
                game: _game!,
                player: playerSession,
                isWinner: isWinner,
                onEdit: () {
                  _showPlayerFormBottomSheet(
                    playerIndexInDatabase: trueIndexInDatabase,
                  );
                },
                onDelete: () {
                  _showDeleteConfirmationDialog(
                    trueIndexInDatabase,
                    playerName,
                  );
                },
                onHistory: () {
                  _showPlayerHistorySheet(
                    playerSession,
                    trueIndexInDatabase,
                  );
                },
                onScore: () {
                  _showScoreEntryFormBottomSheet(
                    playerSession,
                    trueIndexInDatabase,
                  );
                }
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _showPlayerFormBottomSheet, // Floating Action Button now strictly registers new names
        child: const Icon(Icons.add),
      ),
    );
  }
}
